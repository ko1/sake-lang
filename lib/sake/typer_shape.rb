# frozen_string_literal: true

module Sake
  # Instantiation keys by shape (experiments/2026-10-09-typer-shape-keys/).
  #
  # Typer instantiates a function per argument types, and a container's type is its allocation site, so a
  # function that reads rows is analyzed once per place that made an Array of rows. A parameter the body only
  # reads (never writes through, never lets escape: returned, stored, passed on to a function that does) sees
  # nothing of the site but what it holds, so such an argument is keyed by its shape: each container atom
  # replaced by its element types. The body still runs on the actual arguments (the memo's reads follow the
  # caller's sites), so results and checks are as before; only the number of bodies walked drops.
  class Typer
    SHAPE_KEYS = [ENV["SAKE_TYPER_SHAPE"] != "0"] # settable, for A/B measurement
    DEFER_BOTTOM = [ENV["SAKE_TYPER_DEFER"] == "1"]

    # Built-ins that write through their subject, and those that give their subject back (so it escapes
    # through the call's value).
    WRITERS = %w[Array.push Array.append Array.unshift Array.concat Array.insert Array.delete Array.delete_at Array.delete_if
                 Array.pop Array.shift Array.clear Array.fill Array.replace Array.keep_if Array.sort! Array.map! Array.select!
                 Array.reject! Array.uniq! Array.compact! Array.flatten! Array.reverse! Array.shuffle!
                 Hash.store Hash.delete Hash.clear Hash.merge! Hash.update Hash.transform_values! Hash.transform_keys!
                 Hash.select! Hash.reject! Hash.delete_if Hash.keep_if Hash.compact!
                 Set.add Set.add? Set.delete Set.merge Set.clear Set.subtract Queue.push Queue.pop Queue.close].freeze
    RETURNS_SUBJECT = (%w[Kernel.p Kernel.pp Kernel.dup Hash.dup Array.dup Array.push Array.append Array.unshift Array.concat
                          Array.insert Array.delete_if Array.clear Array.each Array.each_with_index Array.cycle
                          Hash.each Hash.each_pair Hash.each_key Hash.each_value Hash.clear Set.add Set.delete Set.each
                          Thread.join Queue.push Queue.close IO.each_line String.each_line] +
                       StdlibTable::ROWS.filter_map { |ns, name, _p, result, _o| "#{ns}.#{name}" if %i[recv recv_nil].include?(result) }).freeze

    ParamUse = Struct.new(:escapes, :written, :flows)

    # Which parameters of fn may be keyed by shape: the body neither writes through them nor lets them escape.
    def shape_ok(fn) = (@shape_ok ||= shape_params)[fn]

    def shape_params
      uses = @ast.functions.to_h { |fn, f| [fn, ParamScan.new(f.nparams).scan(f.body)] }
      loop do # a parameter handed to another function's parameter is at least what that one is
        changed = false
        uses.each_value do |ps|
          ps.each do |p|
            p.flows.each do |g, j|
              q = uses[g]&.[](j)
              if (q.nil? || q.escapes) && !p.escapes
                p.escapes = changed = true
              end
              if q&.written && !p.written
                p.written = changed = true
              end
            end
          end
        end
        break unless changed
      end
      uses.transform_values { |ps| ps.map { !_1.escapes && !_1.written } }
    end

    # A syntactic walk of one function body: for each parameter (and the locals that alias it, `x = param`),
    # whether it escapes, whether a container is written through it, and the callee parameters it is handed to.
    class ParamScan
      include AST

      def initialize(nparams)
        @n = nparams
        @uses = Array.new(nparams) { ParamUse.new(false, false, []) }
        @alias = {}
      end

      def scan(body)
        go(body, :escape)
        @uses
      end

      def param_of(slot) = slot < @n ? slot : @alias[slot]

      def mark(n, what) = n.is_a?(LVarGet) && (p = param_of(n.slot)) && @uses[p][what] = true

      # ctx: where the node's value goes. :escape (out of the function, into a store, ...), :read (looked at
      # by an operation that keeps nothing), :stmt (dropped).
      def go(n, ctx)
        case n
        when nil then nil
        when LVarGet then mark(n, :escapes) if ctx == :escape
        when LVarSet
          if n.value.is_a?(LVarGet) && param_of(n.value.slot) && n.slot >= @n && !@alias.key?(n.slot)
            @alias[n.slot] = param_of(n.value.slot)
          else
            (p = param_of(n.slot)) && (@uses[p].escapes = true) # reassigned: not followed
            go(n.value, :escape)
          end
        when Seq then n.body.each_with_index { |s, i| go(s, i == n.body.size - 1 ? ctx : :stmt) }
        when If then go(n.cond, :read); go(n.then_, ctx); go(n.else_, ctx)
        when While then go(n.cond, :read); go(n.body, :stmt)
        when And, Or then go(n.left, ctx == :stmt ? :read : ctx); go(n.right, ctx)
        when MatchP, IsNil, UnOp, ToS, ToSym, MatchRecord then go(n.value, :read)
        when CaseIn then go(n.subject, :read); n.clauses.each { go(_1[1], ctx) }; go(n.else_, ctx)
        when BinOp then go(n.left, :read); go(n.right, :read)
        when IndexGet then go(n.recv, :read); go(n.key, :read); go(n.extra, :read)
        when IndexSet then mark(n.recv, :written); go(n.recv, :read); go(n.key, :read); go(n.extra, :read); go(n.value, :escape)
        when IndexUpdate then mark(n.recv, :written); go(n.recv, :read); go(n.key, :read); go(n.value, :read)
        when FieldGet then go(n.subject, :read)
        when FieldSet then mark(n.subject, :written); go(n.subject, :read); go(n.value, :escape)
        when Splat then go(n.value, :escape)
        when MultiWrite
          go(n.value, :read)
          n.targets.each { |t| next unless t.is_a?(TIndex); mark(t.recv, :written); go(t.recv, :read); go(t.key, :read) }
        when CallDispatch, CallUnion then n.args.each { go(_1, :escape) }; go(n.block, :stmt)
        when CallBuiltin
          mark(n.args[0], :escapes) if ctx == :escape && RETURNS_SUBJECT.include?(n.fn.full_name)
          n.args.each_with_index do |a, i|
            mark(a, :written) if i.zero? && WRITERS.include?(n.fn.full_name)
            go(a, n.fn.param_type(i) == "Any" ? :escape : :read)
          end
          go(n.block, :stmt)
        when CallUser
          n.args.each_with_index do |a, i|
            if a.is_a?(LVarGet) && (p = param_of(a.slot)) then @uses[p].flows << [n.fn, i] else go(a, :escape) end
          end
          go(n.block, :stmt)
        when Block then go(n.body, :escape)
        when Return, Next, Break then go(n.value, :escape)
        when Yield then n.args.each { go(_1, :escape) }
        when Begin then go(n.body, ctx); n.rescues.each { go(_1.body, ctx) }; go(n.else_, ctx); go(n.ensure_, :stmt)
        when RescueMod then go(n.expr, ctx); go(n.rescue_, ctx)
        else
          return unless n.is_a?(Struct) && n.class.respond_to?(:fields)
          n.class.fields.each do |f|
            v = n[f]
            if v.is_a?(Array) then v.flatten.each { go(_1, :escape) if _1.is_a?(Struct) }
            elsif v.is_a?(Struct) then go(v, :escape)
            end
          end
        end
      end
    end

    # The shape of an argument type: its container atoms (Array, Hash, Set) replaced by what they hold, when
    # what they hold has no containers inside (those would carry sites of the caller into the body's results).
    # nil when the type must be keyed as it is. Reading a site's contents here puts it in the caller's read set,
    # so the caller is evaluated again, and keys anew, when the contents change.
    def shape_key(ty)
      return ty unless ty.any? { |a| a.is_a?(Array) && CONTAINER_KINDS[a[0]] }
      desc = ty.map do |a|
        next a unless a.is_a?(Array)
        case a[0]
        when :array
          s = @sites[a[1]]
          return nil if deep?(s.elem)
          [:array_shape, s.elem.__id__, s.declared]
        when :hash
          s = hash_sites[a[1]]
          return nil if deep?(s.key) || deep?(s.val) || deep?(s.default)
          [:hash_shape, s.key.__id__, s.val.__id__, s.default.__id__]
        when :set
          s = set_sites[a[1]]
          return nil if deep?(s.elem)
          [:set_shape, s.elem.__id__]
        when :tuple, :record then (return nil if deep?([a])) || a
        when :queue, :thread then return nil
        else a
        end
      end
      desc = desc.uniq.sort_by!(&:inspect) # many sites of one shape are one shape
      (@shape_descs ||= {})[desc] ||= desc.freeze
    end

    # Whether a type holds a container (or an unknown) anywhere inside.
    def deep?(ty)
      ty.any? do |a|
        next false unless a.is_a?(Array)
        case a[0]
        when :tuple then a[1].any? { deep?(_1) }
        when :record then a[1].any? { deep?(_1[1]) }
        when :range then deep?(a[1])
        when :sym, :obj then false # a Struct value is keyed by its site (identity)
        else true # containers and unknowns
        end
      end
    end
  end
end
