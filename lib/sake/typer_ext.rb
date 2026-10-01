# frozen_string_literal: true

module Sake
  # Typer support for Symbol, Range, Hash, Set, Regexp/MatchData, and the extra built-ins.
  # A Hash or Set carries its allocation site, like an Array; a Range carries its element type.
  class Typer
    # default: the type a missing key gives (nil unless made by Hash.new(default)).
    HashSite = Struct.new(:id, :label, :key, :val, :default)
    SetSite = Struct.new(:id, :label, :elem)

    def hash_sites = (@hash_sites ||= {})
    def set_sites = (@set_sites ||= {})

    def hash_site(node, label = "")
      id = (@site_ids[node] ||= @site_ids.size + 1)
      hash_sites[id] ||= HashSite.new(id, "L#{node.location.start_line}#{label}", [], [], t("Nil"))
      [[:hash, id]].freeze
    end

    def set_site(node, label = "")
      id = (@site_ids[node] ||= @site_ids.size + 1)
      set_sites[id] ||= SetSite.new(id, "L#{node.location.start_line}#{label}", [])
      [[:set, id]].freeze
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

    def ev_ext(node, env)
      case node
      when Prism::SymbolNode then t("Symbol")
      when Prism::RegularExpressionNode then t("Regexp")
      when Prism::RangeNode
        ends = u(*[node.left, node.right].compact.map { ev(_1, env) })
        [[:range, u(*(ends - ["Nil"]).map { [_1] })]].freeze
      when Prism::KeywordHashNode
        [[:pairs, node.elements.map { [ev(_1.key, env), ev(_1.value, env)] }]].freeze
      else unknown("node #{node.type}")
      end
    end

    def constructor_ext(ns, name, args, node)
      case [ns, name]
      when %w[Hash []]
        site = hash_site(node)
        s = hash_sites[site[0][1]]
        args.each { |ty| atoms_of(ty, :pairs).each { |p| p[1].each { |k, v| s.key = u(s.key, k); s.val = u(s.val, v) } } }
        site
      when %w[Hash new]
        site = hash_site(node)
        hash_sites[site[0][1]].default = args[0] || t("Nil")
        site
      when %w[Set []]
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
        when :array then atoms_of(key, :range).any? ? u([a].freeze, t("IndexNil")) : nil
        end
      end
    end

    FIXED_EXT = {
      "Integer" => %w[Symbol.length Symbol.size Hash.length Hash.size Set.length Set.size Range.sum Range.size
                      Integer.gcd Integer.lcm Integer.pow Integer.bit_length Integer.sqrt Integer.clamp
                      Float.truncate String.ord String.hex String.oct MatchData.begin MatchData.end
                      Kernel.Integer File.write Array.count Range.count Hash.count],
      "Float" => %w[Kernel.Float Float.clamp],
      "String" => %w[Symbol.to_s Regexp.source Regexp.escape MatchData.to_s MatchData.pre_match MatchData.post_match
                     String.center String.tr String.delete String.squeeze String.succ String.next
                     Kernel.format Kernel.sprintf Integer.chr File.read],
      "Symbol" => %w[Symbol.to_sym String.to_sym String.intern],
      "Boolean" => %w[Hash.empty? Hash.key? Hash.has_key? Hash.include? Hash.member? Hash.value? Hash.has_value?
                      Set.empty? Set.include? Set.member? Set.subset? Set.superset? Set.disjoint? Set.intersect?
                      Range.include? Range.cover? Range.member? Range.exclude_end? Range.any? Range.all? Range.none?
                      Hash.any? Hash.all? Hash.none? Regexp.match? String.match? String.casecmp? File.exist?
                      Integer.between? Float.finite?],
      "Regexp" => %w[Regexp.new],
      "Nil" => %w[]
    }.flat_map { |type, names| names.map { [_1, type] } }.to_h.freeze

    def builtin_result_ext(name, args, blk, node)
      a0 = args[0]
      if (ty = FIXED_EXT[name])
        call_block(blk, [each_elem(a0)]) if blk && !each_elem(a0).empty?
        return t(ty)
      end
      case name
      when "Kernel.gets" then u(t("String"), t("Nil"))
      when "Kernel.rand" then args.empty? || args[0] == ["Float"] ? t("Float") : t("Integer")
      when "Kernel.pp" then a0
      when "File.readlines", "String.bytes", "MatchData.captures", "MatchData.names", "MatchData.to_a"
        elem = name == "String.bytes" ? t("Integer") : (name == "MatchData.captures" ? u(t("String"), t("Nil")) : t("String"))
        new_site(node, " #{name}", elem)
      when "String.each_line"
        call_block(blk, [t("String")])
        a0
      when "Regexp.match", "String.match" then u(t("MatchData"), t("Nil"))
      when "String.scan" then new_site(node, " #{name}", u(t("String"), unknown("scan groups")))
      when "MatchData.named_captures"
        hash_site(node).tap { |h| s = hash_sites[h[0][1]]; s.key = t("String"); s.val = u(t("String"), t("Nil")) }
      when "Float.infinite?" then u(t("Integer"), t("Nil"))
      when "Integer.divmod" then tuple([t("Integer"), t("Integer")])
      when "Float.divmod" then tuple([t("Float"), t("Float")])
      when "Integer.digits" then new_site(node, " #{name}", t("Integer"))
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
      when "Hash.dig", "Hash.delete" then u(hash_kv(a0)[1], t("Nil"))
      when "Hash.store"
        atoms_of(a0, :hash).each { |a| s = hash_sites[a[1]]; s.key = u(s.key, args[1]); s.val = u(s.val, args[2]) }
        args[2]
      when "Hash.keys" then new_site(node, " #{name}", hash_kv(a0)[0])
      when "Hash.values" then new_site(node, " #{name}", hash_kv(a0)[1])
      when "Hash.to_a", "Hash.sort_by"
        k, v = hash_kv(a0)
        call_block(blk, [pair_type(k, v)]) if blk && !k.empty?
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
        call_block(blk, [pair_type(k, v)]) unless k.empty?
        k.empty? ? t("Nil") : u(pair_type(k, v), t("Nil"))
      when "Hash.sum"
        k, v = hash_kv(a0)
        k.empty? ? t("Integer") : call_block(blk, [pair_type(k, v)])
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
      when "Set.select", "Set.filter", "Set.reject", "Set.union", "Set.intersection", "Set.difference"
        call_block(blk, [set_elem(a0)]) if blk && !set_elem(a0).empty?
        set_site(node).tap { |s| set_sites[s[0][1]].elem = u(set_elem(a0), *args.drop(1).map { set_elem(_1) }) }
      # more Array
      when "Array.zip"
        new_site(node, " #{name}", tuple([elem_of(a0), *args.drop(1).map { u(elem_of(_1), t("Nil")) }]))
      when "Array.each_slice", "Array.each_cons"
        call_block(blk, [new_site(node, " #{name} slice", elem_of(a0))]) unless elem_of(a0).empty?
        a0
      when "Array.flatten" then new_site(node, " #{name}", u(*elem_of(a0).map { |e| e.is_a?(Array) && e[0] == :array ? elem_of([e]) : [e] }))
      when "Array.compact" then new_site(node, " #{name}", without_nil(elem_of(a0)))
      when "Array.uniq", "Array.rotate", "Array.shuffle" then new_site(node, " #{name}", elem_of(a0))
      when "Array.sample", "Array.delete", "Array.delete_at" then u(elem_of(a0), t("Nil"))
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
