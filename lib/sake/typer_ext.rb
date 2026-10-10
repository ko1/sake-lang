# frozen_string_literal: true

module Sake
  # Typer support for Symbol, Range, Hash, Set, Regexp/MatchData, and the extra built-ins.
  # A Hash or Set carries its allocation site, like an Array; a Range carries its element type.
  class Typer
    # default: the type a missing key gives (nil unless made by Hash.new(default)).
    HashSite = Struct.new(:id, :label, :key, :val, :default)
    Tracked.setter(HashSite, :key, :val)
    SetSite = Struct.new(:id, :label, :elem)
    Tracked.setter(SetSite, :elem)

    def hash_sites = (@hash_sites ||= {})
    def set_sites = (@set_sites ||= {})
    # Thread.new's site keeps the block's value type; Queue.new's the types pushed (like a Set's elements).
    def thread_sites = (@thread_sites ||= {})
    def queue_sites = (@queue_sites ||= {})

    def thread_site(node)
      id = site_id(node)
      thread_sites[id] ||= SetSite.new(id, site_label(id, node), [])
      site_type(:thread, id)
    end

    def queue_site(node)
      id = site_id(node)
      queue_sites[id] ||= SetSite.new(id, site_label(id, node), [])
      site_type(:queue, id)
    end

    def queue_elem(ty) = u(*atoms_of(ty, :queue).map { queue_sites[_1[1]].elem })

    def hash_site(node, label = "")
      id = site_id(node)
      hash_sites[id] ||= HashSite.new(id, site_label(id, node, label), [], [], t("Nil"))
      site_type(:hash, id)
    end

    def set_site(node, label = "")
      id = site_id(node)
      set_sites[id] ||= SetSite.new(id, site_label(id, node, label), [])
      site_type(:set, id)
    end

    # Runs a type's own to_s / inspect for each Struct type in ty, and checks that it returns a String.
    def show_types(ty, kind, node)
      ty.each do |a|
        next unless struct_atom?(a) && (fn = @program.functions.dig(struct_name(a), kind.to_s))
        r = call_user(fn, [one(a)], nil)
        record(node, fn.full_name, "result", "String", r)
      end
    end

    def atoms_of(ty, kind) = ty.select { _1.is_a?(Array) && _1[0] == kind }
    def hash_kv(ty) = atoms_of(ty, :hash).map { hash_sites[_1[1]] }.then { |ss| [u(*ss.map(&:key)), u(*ss.map(&:val))] }
    def set_elem(ty) = u(*atoms_of(ty, :set).map { set_sites[_1[1]].elem })
    def range_elem(ty) = u(*atoms_of(ty, :range).map { _1[1] })
    def pair_type(k, v) = tuple([k, v])

    # Elements that a block over this collection receives.
    def each_elem(ty)
      u(elem_of(ty), set_elem(ty), range_elem(ty), *atoms_of(ty, :hash).map { |a| s = hash_sites[a[1]]; pair_type(s.key, s.val) })
    end

    def constructor_ext(ns, name, args, node)
      case [ns, name]
      when ["Hash", CTOR]
        site = hash_site(node)
        s = hash_sites[site[0][1]]
        args.each { |ty| atoms_of(ty, :pairs).each { |p| p[1].each { |k, v| s.key = u(s.key, k); s.val = u(s.val, v) } } }
        site
      when %w[Hash new]
        site = hash_site(node)
        hash_sites[site[0][1]].default = args[0] || t("Nil")
        site
      when ["Set", CTOR]
        site = set_site(node)
        set_sites[site[0][1]].elem = u(set_sites[site[0][1]].elem, *args)
        site
      end
    end

    def index_get_ext(_node, a, key)
      case a
      when "MatchData" then u(t("String"), t("IndexNil"))
      when "String" then atoms_of(key, :range).any? ? u(t("String"), t("IndexNil")) : nil
      else
        return nil unless a.is_a?(Array)
        case a[0]
        when :hash then u(hash_sites[a[1]].val, hash_sites[a[1]].default.map { _1 == "Nil" ? "IndexNil" : _1 }.then { u(*_1.map { |x| [x] }) })
        when :array then atoms_of(key, :range).any? ? u(one(a), t("IndexNil")) : nil
        end
      end
    end

    FIXED_EXT = {
      "Integer" => %w[Symbol.length Symbol.size Hash.length Hash.size Set.length Set.size Range.size
                      Integer.gcd Integer.lcm Integer.pow Integer.bit_length Integer.sqrt Integer.clamp
                      Float.truncate String.ord String.hex String.oct
                      Kernel.Integer File.write Array.count Range.count Hash.count
                      Rational.numerator Rational.denominator Rational.to_i Rational.floor Rational.ceil
                      Rational.round Rational.truncate Time.year Time.month Time.day Time.hour Time.min
                      Time.sec Time.wday Time.yday Time.to_i],
      "Float" => %w[Kernel.Float Float.clamp Rational.to_f Integer.fdiv Time.to_f Complex.arg],
      "Rational" => %w[Kernel.Rational Integer.to_r Float.to_r Float.rationalize Rational.abs],
      "Complex" => %w[Kernel.Complex Complex.conjugate],
      "Time" => %w[Time.now Time.at Time.new Time.utc],
      "String" => %w[Kernel.to_s Kernel.inspect Symbol.to_s Regexp.source Regexp.escape MatchData.to_s MatchData.pre_match MatchData.post_match
                     String.center String.tr String.delete String.squeeze String.succ String.next
                     Kernel.format Kernel.sprintf Integer.chr File.read Rational.to_s Complex.to_s
                     Time.to_s Time.strftime Array.pack String.force_encoding String.encoding],
      "Symbol" => %w[Symbol.to_sym String.to_sym String.intern],
      "Boolean" => %w[String.valid_encoding? Hash.empty? Hash.key? Hash.has_key? Hash.include? Hash.member? Hash.value? Hash.has_value?
                      Set.empty? Set.include? Set.member? Set.subset? Set.superset? Set.disjoint? Set.intersect?
                      Range.include? Range.cover? Range.member? Range.exclude_end? Range.any? Range.all? Range.none?
                      Hash.any? Hash.all? Hash.none? Regexp.match? String.match? String.casecmp? File.exist?
                      Integer.between? Float.finite? Rational.zero?],
      "Regexp" => %w[Regexp.new],
      "Nil" => %w[]
    }.flat_map { |type, names| names.map { [_1, type] } }.to_h.freeze

    # Built-ins that show values run each type's own to_s / inspect, so the typer analyzes those too.
    SHOWS = { "Kernel.to_s" => :to_s, "Kernel.inspect" => :inspect, "Kernel.puts" => :to_s, "Kernel.print" => :to_s, "Kernel.p" => :inspect, "Kernel.pp" => :inspect,
              "IO.puts" => :to_s, "IO.print" => :to_s,
              "Kernel.format" => :to_s, "Kernel.sprintf" => :to_s, "Array.join" => :to_s }.freeze

    def show_deep(ty, kind, node, seen = {})
      ty.each do |a|
        next if seen[a]
        seen[a] = true
        if a.is_a?(String) || a[0] == :obj
          show_types([a], kind, node)
          next
        end
        inner = case a[0]
                when :array then elem_of([a])
                when :tuple then u(*a[1])
                when :record then u(*a[1].map(&:last))
                when :hash then u(*hash_kv([a]))
                when :set then set_elem([a])
                else []
                end
        # Elements are shown with inspect, except that puts and join show Array elements with to_s.
        show_deep(inner, kind == :to_s && a[0] == :array ? :to_s : :inspect, node, seen)
      end
    end

    # String.scan gives Strings, or with capture groups a Tuple per match. Only a literal Regexp's
    # groups are known; a group is possibly nil unless the pattern has no alternation or optional group.
    def scan_elem(pat)
      return t("String") if pat.is_a?(Prism::StringNode)
      return u(t("String"), unknown("scan groups")) unless pat.is_a?(Prism::RegularExpressionNode)
      src = pat.unescaped
      n = Regexp.new("(?:#{src})|", (pat.extended? ? Regexp::EXTENDED : 0) | (pat.ascii_8bit? ? Regexp::NOENCODING : 0)).match("").size - 1
      return t("String") if n.zero?
      g = src.match?(/\||\)(?:[?*]|{0|{,)/) ? u(t("String"), t("Nil")) : t("String")
      tuple(Array.new(n) { g })
    rescue RegexpError
      u(t("String"), unknown("scan groups"))
    end

    UNPACK_INT = "cCsSlLqQjJnNvVUwiI"
    UNPACK_STR = "aAZbBhHmMuP"
    UNPACK_FLOAT = "dDfFeEgG"

    # The element type of String.unpack's result, from its format when it is a literal.
    def unpack_elem(node)
      fmt = node.respond_to?(:arguments) && node.arguments&.arguments&.[](1)
      kinds = fmt.is_a?(Prism::StringNode) ? fmt.unescaped.scan(/[a-zA-Z]/).uniq : nil
      return u(t("Integer"), t("String"), t("Float")) unless kinds && !kinds.empty?
      u(*([t("Integer")] if kinds.any? { UNPACK_INT.include?(_1) }), *([t("String")] if kinds.any? { UNPACK_STR.include?(_1) }),
        *([t("Float")] if kinds.any? { UNPACK_FLOAT.include?(_1) }))
    end

    # Positions, bytes, replacement blocks, the program's arguments (stdlib_text.rb).
    def text_result(name, args, blk, node)
      case name
      when "String.index", "String.rindex", "String.byteindex" then u(t("Integer"), t("Nil"))
      when "String.byteslice" then u(t("String"), t("IndexNil")) # as s[i, n]: nil past the end (index-nil)
      when "String.slice" then u(t("String"), t("IndexNil")) # as s[i, n]: nil past the end (index-nil)
      when "String.b" then t("String")
      when "String.unpack" then new_site(node, " String.unpack", unpack_elem(node))
      when "String.unpack1" then u(unpack_elem(node), t("Nil"))
      when "String.sub", "String.gsub"
        call_block(blk, [t("String")]) if blk
        t("String")
      when "String.sub!", "String.gsub!"
        call_block(blk, [t("String")]) if blk
        u(t("String"), t("Nil"))
      when "String.slice!" then u(t("String"), t("Nil"))
      when "Process.CLOCK_REALTIME", "Process.CLOCK_MONOTONIC", "Process.CLOCK_PROCESS_CPUTIME_ID" then t("Integer")
      when "Kernel.system" then u(t("Boolean"), t("Nil"))
      when "Kernel.at_exit"
        call_block(blk, [])
        t("Nil")
      when "Record.to_h", "Record.keys", "Record.values"
        recs = atoms_of(args[0], :record)
        return unknown("record") if recs.empty?
        keys = u(*recs.flat_map { |a| a[1].map { |f, _| one([:sym, f]) } })
        vals = u(*recs.flat_map { |a| a[1].map { |_, ty| ty } })
        case name
        when "Record.to_h" then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = keys; s.val = vals }
        when "Record.keys" then new_site(node, " #{name}", keys)
        else new_site(node, " #{name}", vals)
        end
      when "Open3.capture2", "Open3.capture2e" then tuple([t("String"), t("Integer")])
      when "Open3.capture3" then tuple([t("String"), t("String"), t("Integer")])
      when "Hash.set_default"
        atoms_of(args[0], :hash).each { |a| s = hash_sites[a[1]]; s.default = u(s.default, args[1]) }
        args[1]
      when "Hash.transform_keys!"
        k, = hash_kv(args[0])
        atoms_of(args[0], :hash).each { |a| s = hash_sites[a[1]]; s.key = u(s.key, call_block(blk, [k])) } unless k.empty?
        args[0]
      when "Set.map!", "Set.collect!"
        e = set_elem(args[0])
        atoms_of(args[0], :set).each { |a| s = set_sites[a[1]]; s.elem = u(s.elem, call_block(blk, [e])) } unless e.empty?
        args[0]
      when "Regexp.match", "String.match" then u(t("MatchData"), t("Nil"))
      when "Regexp.match?", "String.match?" then t("Boolean")
      when "Kernel.warn" then t("Nil")
      when "Kernel.exit" then [] # never returns
      when "Kernel.ARGV" then new_site(node, " ARGV", t("String"))
      when "Kernel.loop"
        call_block(blk, [])
        [] # only a break leaves it (its values are added to the call's result)
      when "Hash.dup" then args[0]
      when "Kernel.dup" # the same types (a copy); a type's own dup gives what it returns
        u(*args[0].map { |a| (own = struct_atom?(a) && @program.functions.dig(struct_name(a), "dup")) ? call_user(own, [one(a)], nil) : [a] })
      when "Math.PI", "Math.E", "Float.INFINITY", "Float.NAN", "Float.EPSILON", "Float.MAX", "Float.MIN" then t("Float")
      when "Kernel.once"
        # One value for the place, whichever call computes it first: the union over every evaluation.
        site = (@once_types ||= {}.compare_by_identity)
        read(site)
        new = u(site[node] || [], call_block(blk, []))
        dirty(site) unless new.equal?(site[node])
        site[node] = new
      when "File.delete" then t("Integer")
      else :none
      end
    end

    # Threads, Queue, Mutex, sockets (stdlib_net.rb).
    def io_result(name, args, blk, node)
      a0 = args[0]
      case name
      when "Thread.new"
        thread_site(node).tap { |s| site = thread_sites[s[0][1]]; site.elem = u(site.elem, call_block(blk, [])) }
      when "Thread.value", "Thread.join"
        # Thread.raise(t, msg) raises a RuntimeError in t, which value / join bring to the caller.
        merge_raised("RuntimeError" => [node]) if thread_raise_used?
        next_result = name == "Thread.value" ? u(*atoms_of(a0, :thread).map { thread_sites[_1[1]].elem }) : (args.size == 2 ? u(a0, t("Nil")) : a0)
        next_result
      when "Thread.current" then t("Thread")
      when "Thread.kill", "Thread.raise", "Socket.set_timeout" then a0
      when "Mutex.lock", "Mutex.unlock" then a0
      when "Mutex.try_lock", "Mutex.locked?", "Mutex.owned?" then t("Boolean")
      when "IO.seek", "IO.pos", "IO.rewind", "IO.truncate", "IO.size" then t("Integer")
      when "IO.getc" then u(t("String"), t("Nil"))
      when "Zlib.inflate", "Zlib.deflate", "Zlib.gzip", "Zlib.gunzip", "Kernel.PROGRAM_NAME" then t("String")
      when "Kernel.equal?" then t("Boolean")
      when "Thread.alive?", "Queue.empty?", "Queue.closed?" then t("Boolean")
      when "Mutex.new" then t("Mutex")
      when "Mutex.synchronize" then call_block(blk, [])
      when "Queue.new" then queue_site(node)
      when "Queue.push"
        atoms_of(a0, :queue).each { |a| s = queue_sites[a[1]]; s.elem = u(s.elem, args[1]) }
        a0
      when "Queue.pop" then u(queue_elem(a0), t("Nil")) # nil once closed and empty
      when "Queue.close" then a0
      when "Queue.size", "TCPServer.port", "Socket.write" then t("Integer")
      when "TCPServer.new" then t("TCPServer")
      when "TCPServer.accept", "Socket.connect", "Socket.connect_ssl" then t("Socket")
      when "TCPServer.close", "Socket.close", "Socket.close_write" then t("Nil")
      when "Socket.gets", "Socket.read", "IO.gets" then u(t("String"), t("Nil"))
      when "IO.stdin", "IO.stdout", "IO.stderr", "IO.flush" then t("IO")
      when "IO.puts", "IO.print", "IO.close" then t("Nil")
      when "IO.write" then t("Integer")
      when "IO.read" then args.size == 2 ? u(t("String"), t("Nil")) : t("String")
      when "IO.eof?", "IO.closed?", "IO.tty?" then t("Boolean")
      when "IO.winsize" then tuple([t("Integer"), t("Integer")])
      when "IO.raw", "IO.noecho" then call_block(blk, [])
      when "IO.getch" then u(t("String"), t("Nil"))
      when "ENV.replace"
        k, v = hash_kv(a0)
        record(node, name, "key", "String", k)
        record(node, name, "value", "String", v)
        t("Nil")
      when "IO.readlines" then new_site(node, " IO.readlines", t("String"))
      when "IO.each_line"
        call_block(blk, [t("String")])
        a0
      when "File.open" then blk ? call_block(blk, [t("IO")]) : t("IO")
      when "Dir.mktmpdir" then blk ? call_block(blk, [t("String")]) : t("String")
      else :none
      end
    end

    # Arithmetic.round(x) etc.: per number type, as Ruby's methods give (round without digits: Integer).
    def arithmetic_result(name, args)
      return :none unless name.start_with?("Arithmetic.")
      op = name.delete_prefix("Arithmetic.")
      return t("Float") if op == "to_f"
      return t("Integer") if op == "to_i"
      return t("Boolean") if op == "zero?"
      return :none unless %w[round floor ceil truncate abs].include?(op)
      u(*args[0].map do |a|
        n = atom_type_name(a)
        next unknown("number") unless %w[Integer Float Rational].include?(n)
        op != "abs" && args.size == 1 ? t("Integer") : t(n)
      end)
    end

    def builtin_result_ext(name, args, blk, node)
      if (kind = SHOWS[name])
        (%w[Kernel.format Kernel.sprintf IO.puts IO.print].include?(name) ? args.drop(1) : args).each { show_deep(_1, kind, node) }
      end
      table = table_result(name, args, blk, node)
      return table unless table == :none
      a0 = args[0]
      io = io_result(name, args, blk, node)
      return io unless io == :none
      text = text_result(name, args, blk, node)
      return text unless text == :none
      real = arithmetic_result(name, args)
      return real unless real == :none
      if (ty = FIXED_EXT[name])
        call_block(blk, [each_elem(a0)]) if blk && !each_elem(a0).empty?
        return t(ty)
      end
      case name
      when "Kernel.gets", "String.index" then name == "Kernel.gets" ? u(t("String"), t("Nil")) : u(t("Integer"), t("Nil"))
      when "Complex.real", "Complex.imaginary" then u(t("Integer"), t("Float"), t("Rational"))
      when "Complex.abs" then u(t("Integer"), t("Float"))
      when "Complex.rectangular" then tuple([u(t("Integer"), t("Float"), t("Rational"))] * 2)
      when "Complex.polar" then tuple([u(t("Integer"), t("Float")), u(t("Integer"), t("Float"))])
      when "Kernel.rand" then args.empty? || args[0] == ["Float"] ? t("Float") : t("Integer")
      when "MatchData.begin", "MatchData.end" then u(t("Integer"), t("IndexNil")) # nil for a group that did not take part
      when "Kernel.pp" then a0
      when "File.readlines", "String.bytes", "MatchData.captures", "MatchData.names", "MatchData.to_a"
        elem = name == "String.bytes" ? t("Integer") : (name == "MatchData.captures" ? u(t("String"), t("Nil")) : t("String"))
        new_site(node, " #{name}", elem)
      when "String.each_line"
        call_block(blk, [t("String")])
        a0
      when "Regexp.match", "String.match" then u(t("MatchData"), t("Nil"))
      when "String.scan" then new_site(node, " #{name}", scan_elem(node.arguments.arguments[1]))
      when "MatchData.named_captures"
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = t("String"); s.val = u(t("String"), t("Nil")) }
      when "Float.infinite?" then u(t("Integer"), t("Nil"))
      when "Integer.divmod" then tuple([t("Integer"), t("Integer")])
      when "Float.divmod"
        record(node, name, 2, %w[Float Integer], args[1])
        tuple([t("Integer"), t("Float")]) # Ruby: 7.5.divmod(2) is [3, 1.5]
      when "Integer.digits" then site_for(node, " #{name}", declared: "Integer") # an Integer[]
      # Range
      when "Range.each", "Range.step", "Range.each_with_index"
        call_block(blk, name == "Range.each_with_index" ? [range_elem(a0), t("Integer")] : [range_elem(a0)])
        a0
      when "Range.to_a" then new_site(node, " #{name}", range_elem(a0))
      when "Range.map" then new_site(node, " #{name}", call_block(blk, [range_elem(a0)]))
      when "Range.select", "Range.filter", "Range.reject"
        call_block(blk, [range_elem(a0)])
        new_site(node, " #{name}", range_elem(a0))
      when "Range.find", "Range.detect"
        call_block(blk, [range_elem(a0)])
        u(range_elem(a0), t("Nil"))
      when "Range.reduce", "Range.inject" then fold(args[1], range_elem(a0), blk)
      when "Range.first", "Range.last"
        args.size > 1 ? new_site(node, " #{name}", range_elem(a0)) : u(range_elem(a0), t("Nil"))
      when "Range.min", "Range.max", "Range.begin", "Range.end" then u(range_elem(a0), t("Nil"))
      # Hash
      when "Hash.fetch" then u(hash_kv(a0)[1], args[2] || [])
      when "Hash.delete" then u(hash_kv(a0)[1], t("Nil"))
      when "Hash.dig" then dig_result(node, name, a0, args.drop(1))
      when "Hash.store"
        atoms_of(a0, :hash).each { |a| s = hash_sites[a[1]]; s.key = u(s.key, args[1]); s.val = u(s.val, args[2]) }
        args[2]
      when "Hash.keys" then new_site(node, " #{name}", hash_kv(a0)[0])
      when "Hash.values" then new_site(node, " #{name}", hash_kv(a0)[1])
      when "Hash.to_a", "Hash.sort_by"
        k, v = hash_kv(a0)
        keys = blk && !k.empty? ? call_block(blk, [pair_type(k, v)]) : []
        check_sortable(node, name, keys) if name == "Hash.sort_by"
        new_site(node, " #{name}", k.empty? ? [] : pair_type(k, v))
      when "Hash.key" then u(hash_kv(a0)[0], t("Nil"))
      when "Hash.invert" then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key, s.val = hash_kv(a0).reverse }
      when "Hash.merge"
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = u(hash_kv(a0)[0], hash_kv(args[1])[0]); s.val = u(hash_kv(a0)[1], hash_kv(args[1])[1]) }
      when "Hash.clear" then a0
      when "Hash.each", "Hash.each_pair", "Hash.each_key", "Hash.each_value"
        k, v = hash_kv(a0)
        unless k.empty?
          call_block(blk, [{ "Hash.each_key" => k, "Hash.each_value" => v }.fetch(name, pair_type(k, v))])
        end
        a0
      when "Hash.map"
        k, v = hash_kv(a0)
        new_site(node, " #{name}", k.empty? ? [] : call_block(blk, [pair_type(k, v)]))
      when "Hash.select", "Hash.filter", "Hash.reject"
        k, v = hash_kv(a0)
        call_block(blk, [pair_type(k, v)]) unless k.empty?
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k; s.val = v }
      when "Hash.find", "Hash.detect", "Hash.min_by", "Hash.max_by"
        k, v = hash_kv(a0)
        keys = k.empty? ? [] : call_block(blk, [pair_type(k, v)])
        check_sortable(node, name, keys) if name.end_with?("_by")
        k.empty? ? t("Nil") : u(pair_type(k, v), t(name.end_with?("_by") ? "IndexNil" : "Nil"))
      when "Hash.sum"
        k, v = hash_kv(a0)
        k.empty? ? (args[1] || t("Integer")) : sum_type(args[1], call_block(blk, [pair_type(k, v)]))
      when "Hash.transform_values"
        k, v = hash_kv(a0)
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k; s.val = v.empty? ? [] : call_block(blk, [v]) }
      when "Hash.transform_keys"
        k, v = hash_kv(a0)
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k.empty? ? [] : call_block(blk, [k]); s.val = v }
      # Set
      when "Set.add", "Set.add?"
        atoms_of(a0, :set).each { |a| s = set_sites[a[1]]; s.elem = u(s.elem, args[1]) }
        name == "Set.add" ? a0 : u(a0, t("Nil"))
      when "Set.delete" then a0
      when "Set.to_a" then new_site(node, " #{name}", set_elem(a0))
      when "Set.each"
        call_block(blk, [set_elem(a0)]) unless set_elem(a0).empty?
        a0
      when "Set.map" then new_site(node, " #{name}", set_elem(a0).empty? ? [] : call_block(blk, [set_elem(a0)]))
      when "Set.select", "Set.filter", "Set.reject" # an Array, as in Ruby
        call_block(blk, [set_elem(a0)]) unless set_elem(a0).empty?
        new_site(node, " #{name}", set_elem(a0))
      when "Set.union", "Set.intersection", "Set.difference"
        set_site(node).tap { |s| set_sites[s[0][1]].elem = u(set_elem(a0), *args.drop(1).map { set_elem(_1) }) }
      # more Array
      when "Array.zip"
        new_site(node, " #{name}", tuple([elem_of(a0), *args.drop(1).map { u(elem_of(_1), t("Nil")) }]))
      when "Array.each_slice", "Array.each_cons"
        slice = new_site(node, " #{name} slice", elem_of(a0))
        if blk
          call_block(blk, [slice]) unless elem_of(a0).empty?
          a0
        else
          aux_site(node, "#{name} slices", slice)
        end
      when "Array.flatten" then new_site(node, " #{name}", u(*elem_of(a0).map { |e| e.is_a?(Array) && e[0] == :array ? elem_of([e]) : [e] }))
      when "Array.compact" then new_site(node, " #{name}", without_nil(elem_of(a0)))
      when "Array.uniq", "Array.rotate", "Array.shuffle" then new_site(node, " #{name}", elem_of(a0))
      when "Array.sample", "Array.delete_at" then u(elem_of(a0), t("IndexNil"))
      when "Array.delete" then u(elem_of(a0), t("Nil"))
      when "Array.tally" then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = elem_of(a0); s.val = t("Integer") }
      when "Array.group_by"
        e = elem_of(a0)
        k = e.empty? ? [] : call_block(blk, [e])
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k; s.val = new_site(node.block || node, " group", e) }
      when "Array.partition"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        arr = new_site(node, " #{name}", e)
        tuple([arr, arr])
      when "Array.flat_map"
        e = elem_of(a0)
        new_site(node, " #{name}", e.empty? ? [] : elem_of(call_block(blk, [e])))
      when "Array.each_with_object"
        e = elem_of(a0)
        call_block(blk, [e, args[1]]) unless e.empty?
        args[1]
      when "Array.product" then new_site(node, " #{name}", tuple([elem_of(a0), elem_of(args[1])]))
      when "Array.to_h"
        hash_site(node).tap do |h|
          s = hash_sites[h[0][1]]
          elem_of(a0).each { |tp| next unless tp.is_a?(Array) && tp[0] == :tuple && tp[1].size == 2; s.key = u(s.key, tp[1][0]); s.val = u(s.val, tp[1][1]) }
        end
      when "Array.delete_if", "Array.insert", "Array.clear", "Array.dup"
        call_block(blk, [elem_of(a0)]) if blk && !elem_of(a0).empty?
        write_elems(a0, args.drop(2), node, name) if name == "Array.insert"
        a0
      when "Tuple.to_a"
        new_site(node, " #{name}", u(*atoms_of(a0, :tuple).flat_map { _1[1] }))
      else :none
      end
    end

    def fold(init, elem, blk)
      acc = init
      return acc if elem.empty?
      MAX_LOOP_ITER.times do
        nxt = u(acc, call_block(blk, [acc, elem]))
        break if nxt == acc
        acc = nxt
      end
      acc
    end
  end
end

module Sake
  class Typer
    TABLE = StdlibTable::ROWS.to_h { |ns, name, _params, result, opts| ["#{ns}.#{name}", [result, opts || {}]] }

    # A second site created by the same call (an inner Array, a group's values, ...).
    def aux_site(node, tag, elem)
      key = ((@aux_keys ||= {})[[node.object_id, tag]] ||= Object.new)
      id = site_id(key)
      @sites[id] ||= Site.new(id, key, site_label(id, node, " #{tag}"), nil, elem, elem).tap { note_contents(id, elem) }
      @sites[id].elem = u(@sites[id].elem, elem)
      site_type(:array, id)
    end

    # Process.clock_gettime(clock[, unit]): a Float, or an Integer for the whole-number units (:millisecond, ...).
    def clock_result(node)
      unit = node.arguments&.arguments&.[](1)
      return t("Float") if unit.nil?
      return u(t("Integer"), t("Float")) unless unit.is_a?(Prism::SymbolNode)
      %w[second millisecond microsecond nanosecond].include?(unit.unescaped) ? t("Integer") : t("Float")
    end

    def thread_raise_used?
      if @thread_raise_used.nil? # calls: node => {namespace => target}
        @thread_raise_used = @program.calls.each_value.any? { |by_ns| by_ns.each_value.any? { _1.respond_to?(:full_name) && _1.full_name == "Thread.raise" } }
      end
      @thread_raise_used
    end

    def table_result(name, args, blk, node)
      result, opts = TABLE[name]
      return :none unless result
      a0 = opts[:kernel] || opts[:on] ? [] : args[0]
      elem = each_elem(a0)
      elem = t("Integer") if elem.empty? && opts[:int_range]
      k, v = hash_kv(a0)
      bres = []
      if blk && !%i[acc_elem acc_pair].include?(opts[:yields])
        yargs =
          case opts[:yields]
          when :two then [elem, elem]
          when :with_index then [elem, t("Integer")]
          when :val then [v]
          when :key then [k]
          when :elem_memo, :pair_memo then [elem, args[1]]
          when :slice then [aux_site(node, "slice", elem)]
          else [opts[:yield_type] ? t(opts[:yield_type]) : elem]
          end
        bres = call_block(blk, yargs) unless yargs.any?(&:empty?)
      end
      write_elems(a0, opts[:check_elems] == :all ? [elem_of(args[1])] : [args[1]], node, name) if opts[:check_elems]
      check_sortable(node, name, opts[:block] ? bres : elem) if opts[:compare]
      case result
      when /\AArray<(\w+)>\z/ then new_site(node, " #{name}", t($1))
      when :dig then dig_result(node, name, a0, args.drop(1))
      when :elem_index_nil then u(elem, t("IndexNil"))
      when :clock then clock_result(node)
      when String then t(result)
      when :bool then t("Boolean")
      when :bool_nil then u(t("Boolean"), t("Nil"))
      when :int_nil then u(t("Integer"), t("Nil"))
      when :int_index_nil then u(t("Integer"), t("IndexNil")) # a group that did not take part: a miss, as m[i]'s
      when :string_index_nil then u(t("String"), t("IndexNil"))
      when :tuple_int_index_nil2 then tuple([u(t("Integer"), t("IndexNil"))] * 2)
      when :string_nil then u(t("String"), t("Nil"))
      when :recv then a0
      when :recv_nil then u(a0, t("Nil"))
      when :elem_nil then u(elem, t("Nil"))
      when :elem_sum then sum_type(args[1], elem)
      when :array then new_site(node, " #{name}", elem)
      when :array_block then new_site(node, " #{name}", bres)
      when :array_block_truthy then new_site(node, " #{name}", without_nil(bres))
      when :array_flat then new_site(node, " #{name}", elem_of(bres))
      when :array_of_arrays then new_site(node, " #{name}", aux_site(node, "inner", elem))
      when :array_elem_nil then new_site(node, " #{name}", u(elem, t("Nil")))
      when :array_union then new_site(node, " #{name}", u(elem, *args.drop(1).map { elem_of(_1) }))
      when :array_zip then new_site(node, " #{name}", tuple([elem, *args.drop(1).map { u(elem_of(_1), t("Nil")) }]))
      when :transpose then new_site(node, " #{name}", aux_site(node, "inner", elem_of(elem)))
      when :tuple3_string then tuple([t("String")] * 3)
      when :tuple_int2 then tuple([t("Integer")] * 2)
      when :tuple_string2 then tuple([t("String")] * 2)
      when :tuple_elem_nil2 then tuple([u(elem, t("IndexNil"))] * 2) # [nil, nil] for an empty collection: a miss
      when :tuple_arrays, :tuple_pair_arrays then aux_site(node, "part", elem).then { tuple([_1, _1]) }
      when :set_elem then set_site(node).tap { set_sites[_1[0][1]].elem = u(set_sites[_1[0][1]].elem, elem) }
      when :memo then args[1]
      when :fold then fold(args[1], elem, blk)
      when :hash_group then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = bres; s.val = aux_site(node, "group", elem) }
      when :hash_tally then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = elem; s.val = t("Integer") }
      when :hash_compact then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k; s.val = without_nil(v) }
      when :hash_same then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = k; s.val = v }
      when :array_val_nil then new_site(node, " #{name}", u(v, t("Nil")))
      when :array_val then new_site(node, " #{name}", v)
      when :hash_default then u(*atoms_of(a0, :hash).map { hash_sites[_1[1]].default })
      when :pair_nil then k.empty? ? t("Nil") : u(pair_type(k, v), t("Nil"))
      when :array_pairs then new_site(node, " #{name}", k.empty? ? [] : pair_type(k, v))
      # 2026-10-09: the rest of the core API
      when :int_float then u(t("Integer"), t("Float"))
      when :real_part then u(t("Integer"), t("Float"), t("Rational"))
      when :int_rational then u(t("Integer"), t("Rational"))
      when :tuple_real2 then tuple([u(t("Integer"), t("Float"), t("Rational"))] * 2)
      when :matchdata_nil then u(t("MatchData"), t("Nil"))
      when :float_nil then u(t("Float"), t("Nil"))
      when :tuple_int_nil2 then tuple([u(t("Integer"), t("Nil"))] * 2)
      when :tuple_float_int then tuple([t("Float"), t("Integer")])
      when :time_to_a then tuple([t("Integer")] * 8 + [t("Boolean"), u(t("String"), t("Nil"))]) # the zone is nil for a fixed offset
      when :array_kv then new_site(node, " #{name}", u(k, v))
      when :array_string_nil then new_site(node, " #{name}", u(t("String"), t("Nil")))
      when :hash_string_string then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = t("String"); s.val = t("String") }
      when :hash_names_ints then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = t("String"); s.val = new_site(node, " #{name}", t("Integer")) }
      when :hash_classify then hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = bres; s.val = set_site(node, " classify").tap { set_sites[_1[0][1]].elem = u(set_sites[_1[0][1]].elem, elem) } }
      when :recv_write_block # map!: the block's results join the elements
        write_elems(a0, [bres], node, name)
        a0
      when :recv_flatten # flatten!: the inner Arrays' elements join
        write_elems(a0, [u(*elem.map { |e| e.is_a?(Array) && e[0] == :array ? elem_of([e]) : [e] })], node, name)
        u(a0, t("Nil"))
      when :recv_elems_of # replace: the other Array's elements join
        write_elems(a0, [elem_of(args[1])], node, name)
        a0
      when :recv_merge # merge! / update / replace: the other Hash's keys and values join
        ok, ov = hash_kv(args[1])
        atoms_of(a0, :hash).each { |a| s = hash_sites[a[1]]; s.key = u(s.key, ok); s.val = u(s.val, ov) }
        a0
      when :recv_write_val # transform_values!: the block's results join the values
        atoms_of(a0, :hash).each { |a| s = hash_sites[a[1]]; s.val = u(s.val, bres) }
        a0
      when :recv_set_elems_of
        atoms_of(a0, :set).each { |a| s = set_sites[a[1]]; s.elem = u(s.elem, set_elem(args[1])) }
        a0
      else raise "BUG: table result #{result.inspect}"
      end
    end
  end
end
