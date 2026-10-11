# frozen_string_literal: true

require_relative "rust"

module Sake
  # Compiles a checked program to C (GNU C: statement expressions and __builtin_*_overflow), for the same
  # subset as the Rust backend, whose type inference it reuses. Integer is int64_t (an overflow is an
  # error), an Array, a String or an object is a pointer shared by every variable that holds it, nil is
  # an Option struct, a union of classes is a tagged pointer. Nothing is freed: there is no GC.
  # A block passed to a user function becomes a C function that receives the caller's frame (a struct
  # holding the caller's variables); a block of Array.each, Integer.times, ... is inlined as a loop.
  module C
    Unsupported = Rust::Unsupported
    ArrT = Rust::ArrT
    TupT = Rust::TupT
    ObjT = Rust::ObjT
    OptT = Rust::OptT
    UnionT = Rust::UnionT

    def self.generate(program, elide: true) = Gen.new(program, elide:).generate

    class Gen < Rust::Gen
      PRIMS = %w[i64 f64 bool Nil Str].freeze

      def backend_name = "C"

      def generate
        main = infer
        @ctypes = {}   # C type name => Sake type, in the order they were needed
        @protos = []
        @blkfns = []
        @frames = {}   # inst name => struct body
        @tmp = 0
        fns = @order.map { fn_code(_1) }
        entry = main_code(main)
        close_types
        [prelude, types_code, frames_code, show_code, *@protos, *fns, *@blkfns, entry].join("\n")
      end

      # --- C types ---

      def cn(t, node = nil)
        case t
        when :int then "i64"
        when :float then "f64"
        when :bool then "bool"
        when :str then "Str"
        when :nil, :never then "Nil"
        when ArrT
          e = t.root.elem
          unsupported(node, "the element type of an Array is never fixed") if e == :unknown || e.nil?
          "A_#{cn(e, node)}"
        when OptT then "O_#{cn(t.inner, node)}"
        when TupT then "T#{t.elems.size}_#{t.elems.map { cn(_1, node) }.join("_")}"
        when ObjT then "C_#{rs_name(t.name)}"
        when UnionT then union_name(t)
        else unsupported(node, "a value whose type is not known")
        end
      end

      # The C type name of t, registered so that its definition is emitted.
      def ct(t, node = nil)
        name = cn(t, node)
        return name if @ctypes.key?(name)
        @ctypes[name] = t.is_a?(ArrT) ? t.root : t
        case t
        when ArrT
          ct(t.root.elem, node)
          ct(OptT.new(t.root.elem), node)
        when OptT then ct(t.inner, node)
        when TupT then t.elems.each { ct(_1, node) }
        when UnionT then t.names.each { ct(ObjT.new(_1), node) }
        end
        name
      end

      def void?(t) = t.nil? || t == :nil || t == :never || t == :unknown
      def field_type(cls, f) = (t = @fields[cls][f]).nil? || t == :unknown ? :nil : t
      def cfield(f) = "f_#{f}"
      def zero(t, node = nil) = "((#{ct(t, node)}){0})"

      # Every class reachable from a registered type has its fields' types registered too.
      def close_types
        loop do
          before = @ctypes.size
          @ctypes.values.grep(ObjT).each do |o|
            st = @program.struct_types.fetch(o.name)
            st.fields.each { ct(field_type(o.name, _1)) }
          end
          break if @ctypes.size == before
        end
      end

      def types_code
        out = []
        @ctypes.each { |name, t| out << "typedef struct #{name}_s *#{name};" if t.is_a?(ArrT) || t.is_a?(ObjT) }
        done = {}
        emit = lambda do |name|
          next if done[name]
          done[name] = true
          t = @ctypes[name]
          case t
          when OptT
            emit.(cn(t.inner))
            out << "typedef struct { bool some; #{cn(t.inner)} v; } #{name};"
          when TupT
            t.elems.each { emit.(cn(_1)) }
            out << "typedef struct { #{t.elems.each_with_index.map { |e, k| "#{cn(e)} f#{k};" }.join(" ")} } #{name};"
          when UnionT
            out << "typedef struct { int tag; void *p; } #{name};"
          end
        end
        @ctypes.each_key { emit.(_1) }
        @ctypes.each do |name, t|
          case t
          when ObjT
            st = @program.struct_types.fetch(t.name)
            fields = st.fields.map { |f| "#{cn(field_type(t.name, f))} #{cfield(f)};" }
            out << "struct #{name}_s { #{fields.empty? ? "char unused_;" : fields.join(" ")} };"
            params = st.fields.map { |f| "#{cn(field_type(t.name, f))} #{cfield(f)}" }
            sets = st.fields.map { |f| "o->#{cfield(f)} = #{cfield(f)};" }
            out << "SF #{name} #{name}_new(#{params.empty? ? "void" : params.join(", ")}) { #{name} o = xmalloc(sizeof *o); #{sets.join(" ")} return o; }"
          when ArrT
            e = cn(t.elem)
            out << "DEFARR(#{name}, #{e}, O_#{e})"
            out << "DEFARR_ORD(#{name}, #{e}, O_#{e}, cmp_#{e})" if %w[i64 f64 Str].include?(e)
            out << "DEFARR_SUM(#{name}, #{e}, #{e == "i64" ? "add_(s, x, ln)" : "s + x"})" if %w[i64 f64].include?(e)
          end
        end
        out.join("\n")
      end

      # to_s (ts_), inspect (in_), puts and == (eq_) for each type that is not built in.
      def show_code
        protos = []
        defs = []
        @ctypes.each do |name, t|
          next if PRIMS.include?(name)
          protos << "SF void ts_#{name}(SB *b, #{name} x); SF void in_#{name}(SB *b, #{name} x); SF void puts_#{name}(#{name} x); SF bool eq_#{name}(#{name} x, #{name} y);"
          case t
          when OptT
            i = cn(t.inner)
            defs << "SF void ts_#{name}(SB *b, #{name} x) { if (x.some) ts_#{i}(b, x.v); }"
            defs << "SF void in_#{name}(SB *b, #{name} x) { if (x.some) in_#{i}(b, x.v); else sb_cstr(b, \"nil\"); }"
            defs << "SF void puts_#{name}(#{name} x) { if (x.some) puts_#{i}(x.v); else sk_out(\"\\n\", 1); }"
            defs << "SF bool eq_#{name}(#{name} x, #{name} y) { return x.some == y.some && (!x.some || eq_#{i}(x.v, y.v)); }"
          when ArrT
            e = cn(t.elem)
            defs << "SF void in_#{name}(SB *b, #{name} x) { sb_ch(b, '['); for (i64 k = 0; k < x->len; k++) { if (k) sb_cstr(b, \", \"); in_#{e}(b, x->p[k]); } sb_ch(b, ']'); }"
            defs << "SF void ts_#{name}(SB *b, #{name} x) { in_#{name}(b, x); }"
            defs << "SF void puts_#{name}(#{name} x) { if (!x->len) sk_out(\"\\n\", 1); for (i64 k = 0; k < x->len; k++) puts_#{e}(x->p[k]); }"
            defs << "SF bool eq_#{name}(#{name} x, #{name} y) { if (x == y) return true; if (x->len != y->len) return false; for (i64 k = 0; k < x->len; k++) if (!eq_#{e}(x->p[k], y->p[k])) return false; return true; }"
            defs << "SF bool #{name}_includes(#{name} a, #{e} v) { for (i64 k = 0; k < a->len; k++) if (eq_#{e}(a->p[k], v)) return true; return false; }"
            defs << "SF #{name} #{name}_uniq(#{name} a) { #{name} r = #{name}_new(0); for (i64 k = 0; k < a->len; k++) if (!#{name}_includes(r, a->p[k])) #{name}_push(r, a->p[k]); return r; }"
            defs << "SF Str #{name}_join(#{name} a, Str sep) { SB b; sb_init(&b); for (i64 k = 0; k < a->len; k++) { if (k) sb_putS(&b, sep); ts_#{e}(&b, a->p[k]); } return sb_str(&b); }"
          when TupT
            ins = t.elems.each_with_index.map { |e, k| "#{k.zero? ? "" : "sb_cstr(b, \", \"); "}in_#{cn(e)}(b, x.f#{k});" }
            defs << "SF void in_#{name}(SB *b, #{name} x) { sb_ch(b, '['); #{ins.join(" ")} sb_ch(b, ']'); }"
            defs << "SF void ts_#{name}(SB *b, #{name} x) { in_#{name}(b, x); }"
            defs << "SF void puts_#{name}(#{name} x) { #{t.elems.each_with_index.map { |e, k| "puts_#{cn(e)}(x.f#{k});" }.join(" ")} }"
            defs << "SF bool eq_#{name}(#{name} x, #{name} y) { return #{t.elems.each_with_index.map { |e, k| "eq_#{cn(e)}(x.f#{k}, y.f#{k})" }.join(" && ")}; }"
          when ObjT
            st = @program.struct_types.fetch(t.name)
            ins = st.fields.each_with_index.map { |f, k| "sb_cstr(b, \"#{k.zero? ? " " : ", "}#{f}=\"); in_#{cn(field_type(t.name, f))}(b, x->#{cfield(f)});" }
            eqs = st.fields.map { |f| "eq_#{cn(field_type(t.name, f))}(x->#{cfield(f)}, y->#{cfield(f)})" }
            defs << "SF void in_#{name}(SB *b, #{name} x) { sb_cstr(b, \"#<struct #{t.name}\"); #{ins.join(" ")} sb_ch(b, '>'); }"
            defs << "SF void ts_#{name}(SB *b, #{name} x) { in_#{name}(b, x); }"
            defs << "SF void puts_#{name}(#{name} x) { SB b; sb_init(&b); ts_#{name}(&b, x); sb_ch(&b, '\\n'); sk_outsb(&b); }"
            defs << "SF bool eq_#{name}(#{name} x, #{name} y) { return x == y#{eqs.map { " || (#{eqs.join(" && ")})" }.first || " || true"}; }"
          when UnionT
            arms = ->(f) { t.names.each_with_index.map { |nm, k| "case #{k}: #{f.call(cn(ObjT.new(nm)))}; break;" }.join(" ") }
            defs << "SF void in_#{name}(SB *b, #{name} x) { switch (x.tag) { #{arms.(->(c) { "in_#{c}(b, (#{c})x.p)" })} } }"
            defs << "SF void ts_#{name}(SB *b, #{name} x) { in_#{name}(b, x); }"
            defs << "SF void puts_#{name}(#{name} x) { switch (x.tag) { #{arms.(->(c) { "puts_#{c}((#{c})x.p)" })} } }"
            defs << "SF bool eq_#{name}(#{name} x, #{name} y) { if (x.tag != y.tag) return false; switch (x.tag) { #{t.names.each_with_index.map { |nm, k| c = cn(ObjT.new(nm)); "case #{k}: return eq_#{c}((#{c})x.p, (#{c})y.p);" }.join(" ")} } return false; }"
          end
        end
        (protos + defs).join("\n")
      end

      # --- frames: the variables of a function that passes a block to another function ---

      def needs_frame?(func)
        (@needs_frame ||= {}.compare_by_identity).fetch(func) { @needs_frame[func] = closure_call?(func.body) }
      end

      def closure_call?(n)
        return false unless ast_node?(n)
        return true if (n.is_a?(CallUser) || n.is_a?(CallDispatch)) && n.block.is_a?(Block)
        n.each_pair.any? do |k, v|
          next false if k == :origin
          v.is_a?(Array) ? v.any? { closure_call?(_1) } : closure_call?(v)
        end
      end

      def frame_def(inst)
        fields = (0...inst.func.nslots).filter_map { |s| (t = inst.slots[s]) && t != :unknown && t != :never ? "#{ct(t)} v#{s};" : nil }
        fields << "struct Frame_#{inst.block[0].name} *E_;" if inst.block
        @frames[inst.name] = "struct Frame_#{inst.name} { #{fields.empty? ? "char unused_;" : fields.join(" ")} };"
      end

      def frames_code
        (@frames.keys.map { "typedef struct Frame_#{_1} Frame_#{_1};" } + @frames.values).join("\n")
      end

      def sv(s) = @frame ? "F->v#{s}" : "v#{s}"
      def env_ref = @frame ? "F->E_" : "E"
      def tmp = "t#{@tmp += 1}_"
      def new_label = (@label += 1)
      def labels(lab) = ["c#{lab}: __attribute__((unused));", "b#{lab}: __attribute__((unused));"]

      # --- functions ---

      def decls(inst)
        (0...inst.func.nslots).filter_map do |s|
          t = inst.slots[s]
          next if t.nil? || t == :unknown || t == :never
          init = inst.given[s] ? coerce("a#{s}", given_type(inst, s), t, inst.func.body) : zero(t)
          "    __attribute__((unused)) #{ct(t)} v#{s} = #{init};"
        end.join("\n")
      end

      def given_type(inst, slot) = inst.args[inst.given.take(slot).count(true)]

      def params_of(inst)
        params = inst.given.each_index.select { inst.given[_1] }.map { |s| "#{ct(given_type(inst, s))} a#{s}" }
        params << "Frame_#{inst.block[0].name} *E" if inst.block
        params.empty? ? "void" : params.join(", ")
      end

      def body_code(inst)
        ret = inst.ret
        if @frame
          frame_def(inst)
          init = inst.given.each_index.select { inst.given[_1] }.map { |s| "F->v#{s} = #{coerce("a#{s}", given_type(inst, s), inst.slots[s], inst.func.body)};" }
          init << "F->E_ = E;" if inst.block
          pre = "    Frame_#{inst.name} F_ = {0}, *F = &F_;\n    #{init.join(" ")}"
        else
          pre = decls(inst)
        end
        body = void?(ret) ? stmt(inst.func.body, inst) : "    return #{val(inst.func.body, inst, ret)};"
        "#{pre}\n#{body}"
      end

      def fn_code(inst)
        @cur = inst
        @ctx = []
        @label = 0
        @frame = needs_frame?(inst.func)
        ret = inst.ret
        sig = "static #{void?(ret) ? "void" : ct(ret)} #{inst.name}(#{params_of(inst)})"
        @protos << "#{sig};"
        code = "#{sig} {\n#{body_code(inst)}\n}\n"
        blk_code(inst) if inst.block
        code
      end

      def main_code(main)
        @cur = main
        @ctx = []
        @label = 0
        @frame = needs_frame?(main.func)
        <<~C
          static void sake_main(void) {
          #{body_code(main)}
          }
          int main(int argc, char **argv) {
              g_argc = argc;
              g_argv = argv;
              sk_init();
              sake_main();
              sk_flush();
              return 0;
          }
        C
      end

      # The block that inst was called with, as a C function over the caller's frame. `next` returns.
      def blk_code(inst)
        caller, b = inst.block
        saved = [@frame, @ctx, @label, @cur]
        @frame = true
        ret = inst.blk_ret
        @ctx = [[:closure, ret]]
        @label = 0
        @cur = caller
        params = (inst.blk_params || []).each_with_index.map { |t, k| ", #{ct(t)} p#{k}" }
        sig = "static #{void?(ret) ? "void" : ct(ret)} blk_#{inst.name}(Frame_#{caller.name} *F#{params.join})"
        @protos << "#{sig};"
        bind = bind_block(b, caller, (inst.blk_params || []).each_with_index.map { |t, k| ["p#{k}", t] })
        body = void?(ret) ? stmt(b.body, caller) : "    return #{val(b.body, caller, ret)};"
        @blkfns << "#{sig} {\n    #{bind}\n#{body}\n}\n"
      ensure
        @frame, @ctx, @label, @cur = saved
      end

      # Assigns a block's parameters (vals: [C expression, type]) and clears its locals.
      def bind_block(b, i, vals)
        out = b.params.each_with_index.filter_map do |s, k|
          t = i.slots[s]
          next if t.nil? || t == :unknown || t == :never
          code, from = vals[k]
          "#{sv(s)} = #{code ? coerce(code, from, t, b) : zero(t)};"
        end
        out += b.locals.filter_map { |s| (t = i.slots[s]) && t != :unknown && t != :never ? "#{sv(s)} = #{zero(t)};" : nil }
        out.join(" ")
      end

      # --- statements and expressions ---

      # code (a C expression of Sake type from) as a value of type to.
      def coerce(code, from, to, node)
        return code if to.nil? || to == :unknown || from == :unknown || from == :never || to == :never || same?(from, to)
        case to
        when OptT
          return "({ #{code}; #{zero(to)}; })" if from == :nil
          if from.is_a?(OptT)
            s = tmp
            return "({ #{ct(from)} #{s} = #{code}; (#{ct(to)}){#{s}.some, #{s}.some ? #{coerce("#{s}.v", from.inner, to.inner, node)} : #{zero(to.inner)}}; })"
          end
          "((#{ct(to)}){true, #{coerce(code, from, to.inner, node)}})"
        when UnionT
          case from
          when ObjT then "((#{ct(to)}){#{to.names.index(from.name)}, #{code}})"
          when UnionT
            s = tmp
            map = from.names.map { to.names.index(_1) }
            "({ #{ct(from)} #{s} = #{code}; static const int m_[] = {#{map.join(", ")}}; (#{ct(to)}){m_[#{s}.tag], #{s}.p}; })"
          else unsupported(node, "a #{show(from)} where #{show(to)} is expected")
          end
        when :float then from == :int ? "((f64)(#{code}))" : code
        when :nil then "({ #{code}; (Nil)0; })"
        else code
        end
      end

      # n as a C value of type want (a nil or a never-completing expression still yields a value).
      def val(n, i, want)
        t = ty(n, i)
        want = t if want.nil? || want == :unknown
        if t == :never
          return "({ #{stmt(n, i).strip} #{zero(void?(want) ? :nil : want)}; })"
        end
        if t == :nil
          return "((Nil)0)" if n.is_a?(Lit) && void?(want)
          return "({ #{stmt(n, i).strip} #{zero(void?(want) ? :nil : want)}; })"
        end
        coerce(expr(n, i), t, want, n)
      end

      def assign_or_stmt(target, n, i, want)
        ty(n, i) == :never ? stmt(n, i) : "    #{target} = #{val(n, i, want)};"
      end

      def stmt(n, i)
        case n
        when Seq then n.body.map { stmt(_1, i) }.join("\n")
        when LVarSet
          d = i.slots[n.slot]
          return "    #{stmt(n.value, i).strip}" if void?(d)
          "    #{sv(n.slot)} = #{val(n.value, i, d)};"
        when If
          c = cond(n.cond, i)
          th = with_narrow(i, n.cond, :then) { stmt(n.then_, i) }
          els = n.else_.is_a?(Lit) && n.else_.value.nil? ? "" : " else {\n#{with_narrow(i, n.cond, :else) { stmt(n.else_, i) }}\n    }"
          "    if (#{c}) {\n#{th}\n    }#{els}"
        when While
          lab = new_label
          @ctx.push([:while, lab])
          body = stmt(n.body, i)
          @ctx.pop
          head = n.cond.is_a?(Lit) && n.cond.value == !n.until_ ? "for (;;)" : "while (#{n.until_ ? "!(#{cond(n.cond, i)})" : cond(n.cond, i)})"
          c, b = labels(lab)
          "    #{head} {\n#{body}\n    #{c} }\n    #{b}"
        when Lit, Str, LVarGet, BlockGiven then ""
        when Return
          unsupported(n, "`return` inside a block passed to a function") if @ctx.any? { _1[0] == :closure }
          if void?(i.ret)
            n.value ? "    #{stmt(n.value, i).strip} return;" : "    return;"
          else
            "    return #{val(n.value || Lit.new(value: nil), i, i.ret)};"
          end
        when Next
          kind, lab = @ctx.last
          case kind
          when :closure
            void?(lab) ? "    #{n.value ? stmt(n.value, i).strip : ""} return;" : "    return #{val(n.value || Lit.new(value: nil), i, lab)};"
          when :inline, :while then "    #{n.value ? stmt(n.value, i).strip : ""} goto c#{lab};"
          when :inline_value then unsupported(n, "`next` in a block whose value is used")
          else unsupported(n, "`next` outside a loop or block")
          end
        when Break
          want = n.target == :loop ? [:while] : %i[inline inline_value]
          idx = @ctx.rindex { want.include?(_1[0]) }
          unsupported(n, "`break` out of a block passed to a function") if idx.nil? || @ctx[(idx + 1)..].any? { _1[0] == :closure }
          "    #{n.value ? stmt(n.value, i).strip : ""} goto b#{@ctx[idx][1]};"
        when Raise then "    #{raise_code(n, i)};"
        when FieldSet then "    #{recv(n.subject, i)}->#{cfield(n.field)} = #{val(n.value, i, field_type(n.type, n.field))};"
        when IndexSet
          v = val(n.value, i, elem_of(ty(n.recv, i), n))
          return "    (#{recv(n.recv, i)})->p[#{val(n.key, i, :int)}] = #{v};" if safe?(n, :index)
          "    #{cn(ty(n.recv, i))}_set(#{recv(n.recv, i)}, #{val(n.key, i, :int)}, #{v}, #{line(n)});"
        when CaseIn then case_code(n, i, false)
        when ArgDefault then i.given[n.slot] ? "" : "    #{sv(n.slot)} = #{val(n.value, i, i.slots[n.slot])};"
        when MultiWrite
          v = ty(n.value, i)
          s = tmp
          sets = n.targets.each_with_index.map { |t, k| "#{sv(t.slot)} = #{coerce("#{s}.f#{k}", v.elems[k], i.slots[t.slot], n)};" }
          "    { #{ct(v)} #{s} = #{val(n.value, i, v)}; #{sets.join(" ")} }"
        else
          ty(n, i) == :nil || ty(n, i) == :never ? "    #{expr(n, i)};" : "    (void)(#{expr(n, i)});"
        end
      end

      def raise_code(n, i)
        kind = n.type || "RuntimeError"
        return "sk_fail(#{line(n)}, \"#{kind}\", \"#{kind}\")" unless n.args[0]
        unsupported(n, "a raise whose message is not a String") unless ty(n.args[0], i) == :str
        "sk_failS(#{line(n)}, \"#{kind}\", #{val(n.args[0], i, :str)})"
      end

      def cond(n, i)
        t = ty(n, i)
        case t
        when :bool then expr(n, i)
        when :nil then "({ #{stmt(n, i).strip} false; })"
        when OptT then "(#{expr(n, i)}).some"
        else unsupported(n, "a condition of type #{show(t)}")
        end
      end

      # A variable, read as the type the checker narrowed it to at this node.
      def get_node(n, i)
        t = ty(n, i)
        d = i.slots[n.slot]
        base = sv(n.slot)
        if d.is_a?(OptT) && !t.is_a?(OptT) && !void?(t) then "#{base}.v"
        elsif d.is_a?(UnionT) && t.is_a?(ObjT) then "((#{ct(t)})#{base}.p)"
        else base
        end
      end

      def recv(n, i) = n.is_a?(LVarGet) ? get_node(n, i) : expr(n, i)

      def expr(n, i)
        t = ty(n, i)
        case n
        when Lit
          case n.value
          when Integer then n.value == -(2**63) ? "INT64_MIN" : "((i64)#{n.value}LL)"
          when Float
            unsupported(n, "a non-finite Float literal") unless n.value.finite?
            "((f64)#{n.value})"
          when true, false then n.value.to_s
          when nil then "((Nil)0)"
          end
        when Str then "str_new(#{c_str(n.string)}, #{n.string.bytesize})"
        when Interp
          b = tmp
          parts = n.parts.map do |p|
            if p.is_a?(Str) then "sb_putn(&#{b}, #{c_str(p.string)}, #{p.string.bytesize});"
            elsif p.is_a?(ToS) then show_into(b, p.value, i)
            else "sb_putS(&#{b}, #{val(p, i, :str)});"
            end
          end
          "({ SB #{b}; sb_init(&#{b}); #{parts.join(" ")} sb_str(&#{b}); })"
        when ToS
          return val(n.value, i, :str) if ty(n.value, i) == :str
          b = tmp
          "({ SB #{b}; sb_init(&#{b}); #{show_into(b, n.value, i)} sb_str(&#{b}); })"
        when LVarGet then get_node(n, i)
        when LVarSet
          d = i.slots[n.slot]
          void?(d) ? "({ #{stmt(n, i).strip} })" : "(#{sv(n.slot)} = #{val(n.value, i, d)})"
        when Seq
          return "((Nil)0)" if n.body.empty?
          return "({ #{stmt(n, i).strip} })" if void?(t)
          *init, last = n.body
          "({\n#{init.map { stmt(_1, i) }.join("\n")}\n    #{val(last, i, t)}; })"
        when If
          return "({ #{stmt(n, i).strip} })" if void?(t)
          r = tmp
          th = with_narrow(i, n.cond, :then) { assign_or_stmt(r, n.then_, i, t) }
          el = with_narrow(i, n.cond, :else) { assign_or_stmt(r, n.else_, i, t) }
          "({ #{ct(t)} #{r}; if (#{cond(n.cond, i)}) {\n#{th}\n    } else {\n#{el}\n    } #{r}; })"
        when And then "(#{cond(n.left, i)} && #{with_narrow(i, n.left, :then) { cond(n.right, i) }})"
        when Or then "(#{cond(n.left, i)} || #{cond(n.right, i)})"
        when MakeTuple then "((#{ct(t)}){#{n.elems.each_with_index.map { |e, k| val(e, i, t.elems[k]) }.join(", ")}})"
        when CallBuiltin then builtin_code(n, i)
        when CallUser then user_call_code(n, i)
        when CallDispatch then dispatch_code(n, i)
        when CaseIn then case_code(n, i, true)
        when BinOp then binop_code(n, i)
        when IsNil
          v = ty(n.value, i)
          case v
          when :nil then "({ #{stmt(n.value, i).strip} #{!n.negate}; })"
          when OptT then n.negate ? "(#{expr(n.value, i)}).some" : "!(#{expr(n.value, i)}).some"
          else "({ (void)(#{expr(n.value, i)}); #{n.negate}; })"
          end
        when UnOp
          v = expr(n.value, i)
          next_t = ty(n.value, i)
          n.op == "+" ? v : (next_t == :int && !safe?(n, :arith) ? "neg_(#{v}, #{line(n)})" : "(-(#{v}))")
        when FieldGet then "(#{recv(n.subject, i)})->#{cfield(n.field)}"
        when FieldSet
          s = tmp
          ft = field_type(n.type, n.field)
          "({ #{ct(ft)} #{s} = #{val(n.value, i, ft)}; (#{recv(n.subject, i)})->#{cfield(n.field)} = #{s}; #{s}; })"
        when IndexGet
          r = ty(n.recv, i)
          case r
          when TupT then "(#{recv(n.recv, i)}).f#{n.key.value}"
          when ArrT
            return "((#{ct(OptT.new(r.root.elem))}){true, (#{recv(n.recv, i)})->p[#{val(n.key, i, :int)}]})" if safe?(n, :index)
            "#{ct(r)}_get(#{recv(n.recv, i)}, #{val(n.key, i, :int)})"
          end
        when IndexSet
          r = ty(n.recv, i)
          e = elem_of(r, n)
          s = tmp
          return "({ #{ct(e)} #{s} = #{val(n.value, i, e)}; (#{recv(n.recv, i)})->p[#{val(n.key, i, :int)}] = #{s}; #{s}; })" if safe?(n, :index)
          "({ #{ct(e)} #{s} = #{val(n.value, i, e)}; #{ct(r)}_set(#{recv(n.recv, i)}, #{val(n.key, i, :int)}, #{s}, #{line(n)}); #{s}; })"
        when IndexUpdate
          r = ty(n.recv, i)
          e = elem_of(r, n)
          a = tmp
          k = tmp
          cur = "#{a}->p[#{k}]"
          v = val(n.value, i, e)
          op = e == :int ? { "+" => "add_", "-" => "sub_", "*" => "mul_" }.fetch(n.op) : nil
          upd = op ? "#{op}(#{cur}, #{v}, #{line(n)})" : "(#{cur} #{n.op} #{v})"
          return "({ #{ct(r)} #{a} = #{recv(n.recv, i)}; i64 #{k} = #{val(n.key, i, :int)}; #{cur} = #{upd}; #{cur}; })" if safe?(n, :index)
          "({ #{ct(r)} #{a} = #{recv(n.recv, i)}; i64 #{k} = #{ct(r)}_pos(#{a}, #{val(n.key, i, :int)}); if (#{k} < 0) sk_fail(#{line(n)}, \"NoMethodError\", \"x[k] is nil: the index is outside of the array\"); #{cur} = #{upd}; #{cur}; })"
        when Yield
          return "sk_fail(#{line(n)}, \"LocalJumpError\", \"no block given (yield)\")" unless i.block
          ps = i.blk_params || []
          args = ps.each_with_index.map { |pt, k| n.args[k] ? val(n.args[k], i, pt) : zero(pt) }
          extra = n.args.drop(ps.size).map { "(void)(#{expr(_1, i)});" }
          call = "blk_#{i.name}(#{[env_ref, *args].join(", ")})"
          extra.empty? ? call : "({ #{extra.join(" ")} #{call}; })"
        when BlockGiven then i.block ? "true" : "false"
        when Return, Next, Break, MultiWrite, ArgDefault, While then "({ #{stmt(n, i).strip} })"
        when Raise then raise_code(n, i)
        else unsupported(n, kind_words(n))
        end
      end

      # Appends v's to_s to the SB named b (a statement).
      def show_into(b, v, i)
        t = ty(v, i)
        t == :str ? "sb_putS(&#{b}, #{val(v, i, :str)});" : "ts_#{ct(void?(t) ? :nil : t)}(&#{b}, #{val(v, i, void?(t) ? :nil : t)});"
      end

      def c_str(s)
        "\"" + s.bytes.map { |c| c >= 0x20 && c < 0x7f && !"\"\\?".include?(c.chr) ? c.chr : format("\\%03o", c) }.join + "\""
      end

      def eq_code(a, b, t)
        case t
        when :int, :float, :bool then "(#{a} == #{b})"
        when :nil then "true"
        else "eq_#{ct(t)}(#{a}, #{b})"
        end
      end

      def binop_code(n, i)
        l = ty(n.left, i)
        r = ty(n.right, i)
        op = n.op
        l = r if l == :never
        r = l if r == :never
        a = val(n.left, i, l)
        b = val(n.right, i, r)
        ln = line(n)
        if l == :int && r == :int
          if %w[+ - *].include?(op) && safe?(n, :arith)
            return "(#{a} #{op} #{b})"
          elsif %w[/ %].include?(op) && safe?(n, :plain)
            return "(#{a} #{op} #{b})"
          elsif %w[/ %].include?(op) && safe?(n, :div)
            return "#{op == "/" ? "idiv_p" : "imod_p"}(#{a}, #{b})"
          end
          case op
          when "+" then "add_(#{a}, #{b}, #{ln})"
          when "-" then "sub_(#{a}, #{b}, #{ln})"
          when "*" then "mul_(#{a}, #{b}, #{ln})"
          when "/" then "idiv(#{a}, #{b}, #{ln})"
          when "%" then "imod(#{a}, #{b}, #{ln})"
          when "**" then "ipow(#{a}, #{b}, #{ln})"
          else "(#{a} #{op} #{b})"
          end
        elsif %i[int float].include?(l) && %i[int float].include?(r)
          a = "((f64)#{a})" if l == :int
          b = "((f64)#{b})" if r == :int
          case op
          when "%" then "fmod_(#{a}, #{b})"
          when "**" then "pow(#{a}, #{b})"
          else "(#{a} #{op} #{b})"
          end
        elsif l == :str && r == :str
          case op
          when "+" then "str_cat(#{a}, #{b})"
          when "==" then "str_eq(#{a}, #{b})"
          when "!=" then "!str_eq(#{a}, #{b})"
          else "(str_cmp(#{a}, #{b}) #{op} 0)"
          end
        elsif l == :str && op == "*" then "str_mul(#{a}, #{b}, #{ln})"
        elsif l.is_a?(ArrT) && op == "<<" then "#{ct(l)}_push(#{a}, #{coerce(b, r, l.root.elem, n)})"
        elsif op == "==" || op == "!="
          if l == :nil || r == :nil
            e, o = l == :nil ? [b, r] : [a, l]
            return "({ (void)(#{a}); (void)(#{b}); #{op == "=="}; })" if o == :nil
            o.is_a?(OptT) ? "#{op == "==" ? "!" : ""}(#{e}).some" : "({ (void)(#{e}); #{op == "!="}; })"
          else
            "#{op == "!=" ? "!" : ""}#{eq_code(a, b, l)}"
          end
        else unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}")
        end
      end

      def call_args(n, i, inst)
        args = n.args.reject { ty(_1, i) == :missing }.map { val(_1, i, ty(_1, i)) }
        args << "F" if n.block.is_a?(Block)
        args << env_ref if n.block.is_a?(BlockPass)
        args
      end

      def user_call_code(n, i)
        inst = call_user(n, i)
        "#{inst.name}(#{call_args(n, i, inst).join(", ")})"
      end

      # `M.f(x, ...)`: a direct call when x's class is known, else a switch on the union's tag.
      def dispatch_code(n, i)
        a0 = ty(n.args[0], i)
        arg_types = n.args.map { ty(_1, i) }
        case a0
        when ObjT
          inst = dispatch_inst(n, i, a0.name, arg_types)
          "#{inst.name}(#{call_args(n, i, inst).join(", ")})"
        when UnionT
          ret = ty(n, i)
          u = tmp
          r = void?(ret) ? nil : tmp
          rest = n.args.drop(1).map { val(_1, i, ty(_1, i)) }
          rest << "F" if n.block.is_a?(Block)
          rest << env_ref if n.block.is_a?(BlockPass)
          arms = a0.names.each_with_index.map do |name, k|
            inst = dispatch_inst(n, i, name, arg_types)
            call = "#{inst.name}(#{["(#{ct(ObjT.new(name))})#{u}.p", *rest].join(", ")})"
            "case #{k}: #{r ? "#{r} = #{coerce(call, inst.ret, ret, n)}" : call}; break;"
          end
          "({ #{ct(a0)} #{u} = #{recv(n.args[0], i)}; #{r ? "#{ct(ret)} #{r}; " : ""}switch (#{u}.tag) { #{arms.join(" ")} default: __builtin_unreachable(); } #{r ? "#{r}; " : ""}})"
        end
      end

      def pattern_code(pat, st, i, s)
        case pat
        when PValue
          v = ty(pat.value, i)
          return "!#{s}.some" if v == :nil
          st.is_a?(OptT) ? "(#{s}.some && #{eq_code("#{s}.v", val(pat.value, i, st.inner), st.inner)})" : eq_code(s, val(pat.value, i, st), st)
        when PType
          case st
          when UnionT then "(#{s}.tag == #{st.names.index(pat.name) || -1})"
          when ObjT then (st.name == pat.name).to_s
          when OptT then st.inner.is_a?(UnionT) ? "(#{s}.some && #{s}.v.tag == #{st.inner.names.index(pat.name) || -1})" : "#{s}.some"
          else (SCALAR_NAMES[pat.name] == st).to_s
          end
        when PAlt then "(#{pattern_code(pat.left, st, i, s)} || #{pattern_code(pat.right, st, i, s)})"
        end
      end

      def case_code(n, i, value)
        st = ty(n.subject, i)
        t = ty(n, i)
        s = tmp
        r = value && !void?(t) ? tmp : nil
        arms = n.clauses.map do |pat, body|
          b = with_case_narrow(i, n.subject, pat, st) { r ? assign_or_stmt(r, body, i, t) : stmt(body, i) }
          "if (#{pattern_code(pat, st, i, s)}) {\n#{b}\n    }"
        end
        els = r ? assign_or_stmt(r, n.else_, i, t) : stmt(n.else_, i)
        code = "{ #{ct(st)} #{s} = #{val(n.subject, i, st)}; #{arms.join(" else ")} else {\n#{els}\n    } }"
        if r then "({ #{ct(t)} #{r}; #{code} #{r}; })"
        elsif value then "({ #{code} })"
        else "    #{code}"
        end
      end

      # --- built-ins ---

      def num_f(node, code, i) = ty(node, i) == :int ? "((f64)#{code})" : code

      # A loop over head (a C for/while header) whose body is block b, with its parameters from vals.
      def loop_c(head, b, i, vals, pre = "")
        lab = new_label
        @ctx.push([:inline, lab])
        body = stmt(b.body, i)
        @ctx.pop
        c, brk = labels(lab)
        "({ #{pre} #{head} { #{bind_block(b, i, vals)}\n#{body}\n    #{c} } #{brk} })"
      end

      # The value of block b for parameters vals, inlined; a `break` jumps to b<lab>.
      def inline_value(b, i, vals, lab, want)
        @ctx.push([:inline_value, lab])
        "({ #{bind_block(b, i, vals)} #{val(b.body, i, want)}; })"
      ensure
        @ctx.pop
      end

      def builtin_code(n, i)
        name = n.fn.full_name
        ln = line(n)
        types = n.args.map { _1.is_a?(MakeRange) ? :range : ty(_1, i) }
        args = n.args.each_with_index.map { |x, k| x.is_a?(MakeRange) ? nil : (k.zero? ? recv(x, i) : val(x, i, types[k])) }
        a, b = args
        at = types[0]
        if n.fn.name == CTOR
          c = cell(n)
          e = c.root.elem
          return "#{ct(c)}_new(0)" if n.args.empty?
          return "#{ct(c)}_from(#{n.args.size}, (#{ct(e)}[]){#{n.args.each_with_index.map { |x, k| val(x, i, e) }.join(", ")}})"
        end
        if @program.struct_types.key?(n.fn.namespace)
          st = @program.struct_types[n.fn.namespace]
          cls = st.name
          case n.fn.name
          when "new"
            ct(ObjT.new(cls))
            return "C_#{rs_name(cls)}_new(#{st.fields.each_with_index.map { |f, k| val(n.args[k], i, field_type(cls, f)) }.join(", ")})"
          when *st.fields then return "(#{a})->#{cfield(n.fn.name)}"
          else
            f = n.fn.name.delete_prefix("set_")
            s = tmp
            ft = field_type(cls, f)
            return "({ #{ct(ft)} #{s} = #{val(n.args[1], i, ft)}; (#{a})->#{cfield(f)} = #{s}; #{s}; })"
          end
        end
        case name
        when "Kernel.puts" then n.args.empty? ? "sk_out(\"\\n\", 1)" : "({ #{n.args.map { "puts_#{ct(vt = void?(ty(_1, i)) ? :nil : ty(_1, i))}(#{val(_1, i, vt)});" }.join(" ")} })"
        when "Kernel.print", "Kernel.p"
          f = name == "Kernel.p" ? "in" : "ts"
          s = tmp
          nl = name == "Kernel.p" ? "sb_ch(&#{s}, '\\n'); " : ""
          "({ #{n.args.map { |x| vt = void?(ty(x, i)) ? :nil : ty(x, i); "{ SB #{s}; sb_init(&#{s}); #{f}_#{ct(vt)}(&#{s}, #{val(x, i, vt)}); #{nl}sk_outsb(&#{s}); }" }.join(" ")} })"
        when "Kernel.ARGV"
          c = ct(cell(n, :str))
          r = tmp
          "({ #{c} #{r} = #{c}_new(0); for (int k_ = 1; k_ < g_argc; k_++) #{c}_push(#{r}, str_c(g_argv[k_])); #{r}; })"
        when "Kernel.rand" then n.args.empty? ? "rand_f()" : (at == :int ? "rand_i(#{a}, #{ln})" : "(rand_f() * #{a})")
        when "Kernel.exit" then "sk_exit(#{n.args.empty? ? "0" : a})"
        when "String.to_i" then "str_to_i(#{a})"
        when "String.to_f" then "str_to_f(#{a})"
        when "String.length", "String.size" then "str_length(#{a})"
        when "String.bytesize" then "(#{a})->len"
        when "String.bytes"
          c = ct(cell(n, :int))
          s = tmp
          r = tmp
          "({ Str #{s} = #{a}; #{c} #{r} = #{c}_new(#{s}->len); for (i64 k_ = 0; k_ < #{s}->len; k_++) #{r}->p[k_] = (unsigned char)#{s}->p[k_]; #{r}; })"
        when "String.chars"
          c = ct(cell(n, :str))
          s = tmp
          r = tmp
          "({ Str #{s} = #{a}; #{c} #{r} = #{c}_new(0); for (i64 k_ = 0; k_ < #{s}->len; ) { int w_ = utf8_len(#{s}->p[k_]); if (k_ + w_ > #{s}->len) w_ = (int)(#{s}->len - k_); #{c}_push(#{r}, str_new(#{s}->p + k_, w_)); k_ += w_; } #{r}; })"
        when "String.upcase" then "str_upcase(#{a})"
        when "String.downcase" then "str_downcase(#{a})"
        when "String.strip" then "str_strip(#{a})"
        when "String.reverse" then "str_reverse(#{a})"
        when "String.include?" then "str_include(#{a}, #{b})"
        when "String.start_with?" then "str_start_with(#{a}, #{b})"
        when "String.end_with?" then "str_end_with(#{a}, #{b})"
        when "String.empty?" then "((#{a})->len == 0)"
        when "String.to_s" then a
        when "String.==" then "str_eq(#{a}, #{b})"
        when "String.+" then "str_cat(#{a}, #{b})"
        when "Integer.to_s" then "str_i64(#{a})"
        when "Integer.to_f" then "((f64)#{a})"
        when "Integer.abs" then "iabs(#{a}, #{ln})"
        when "Integer.chr" then "str_chr(#{a}, #{ln})"
        when "Integer.even?" then "((#{a}) % 2 == 0)"
        when "Integer.odd?" then "((#{a}) % 2 != 0)"
        when "Integer.zero?" then "((#{a}) == 0)"
        when "Integer.times"
          k = tmp
          m = tmp
          loop_c("for (i64 #{k} = 0; #{k} < #{m}; #{k}++)", n.block, i, [[k, :int]], "i64 #{m} = #{a};")
        when "Float.to_i", "Float.truncate" then "f_to_i(trunc(#{a}), #{ln})"
        when "Float.floor" then "f_to_i(floor(#{a}), #{ln})"
        when "Float.ceil" then "f_to_i(ceil(#{a}), #{ln})"
        when "Float.round" then "f_to_i(round(#{a}), #{ln})"
        when "Float.to_s"
          s = tmp
          "({ SB #{s}; sb_init(&#{s}); ts_f64(&#{s}, #{a}); sb_str(&#{s}); })"
        when "Float.abs" then "fabs(#{a})"
        when "Float.nan?" then "isnan(#{a})"
        when "Math.sqrt" then "sk_sqrt(#{num_f(n.args[0], a, i)}, #{ln})"
        when "Math.sin", "Math.cos", "Math.tan", "Math.atan", "Math.exp", "Math.log", "Math.log2", "Math.log10"
          "#{name.split(".")[1]}(#{num_f(n.args[0], a, i)})"
        when "Math.PI" then "M_PI"
        when "Math.E" then "M_E"
        when "Range.each"
          r = n.args[0]
          k = tmp
          hi = tmp
          loop_c("for (i64 #{k} = #{val(r.left, i, :int)}; #{k} #{r.exclusive ? "<" : "<="} #{hi}; #{k}++)", n.block, i, [[k, :int]], "i64 #{hi} = #{val(r.right, i, :int)};")
        when "Range.to_a"
          r = n.args[0]
          c = ct(cell(n, :int))
          res = tmp
          hi = tmp
          "({ i64 #{hi} = #{val(r.right, i, :int)}; #{c} #{res} = #{c}_new(0); for (i64 k_ = #{val(r.left, i, :int)}; k_ #{r.exclusive ? "<" : "<="} #{hi}; k_++) #{c}_push(#{res}, k_); #{res}; })"
        when "Array.new"
          c = cell(n)
          e = c.root.elem
          if n.block
            lab = new_label
            m = tmp
            res = tmp
            k = tmp
            v = inline_value(n.block, i, [[k, :int]], lab, e)
            "({ i64 #{m} = nonneg(#{a}, #{ln}); #{ct(c)} #{res} = #{ct(c)}_new(0); for (i64 #{k} = 0; #{k} < #{m}; #{k}++) #{ct(c)}_push(#{res}, #{v}); #{labels(lab)[1]} #{res}; })"
          else
            "#{ct(c)}_fill(#{a}, #{val(n.args[1], i, e)}, #{ln})"
          end
        when "Array.fetch" then safe?(n, :index) ? "(#{a})->p[#{b}]" : "#{ct(at)}_fetch(#{a}, #{b}, #{ln})"
        when "Array.length", "Array.size" then "(#{a})->len"
        when "Array.push", "Array.<<", "Array.append"
          e = elem_of(at, n)
          n.args.drop(1).reduce(a) { |acc, x| "#{ct(at)}_push(#{acc}, #{val(x, i, e)})" }
        when "Array.each", "Array.each_with_index"
          e = elem_of(at, n)
          arr = tmp
          k = tmp
          vals = [["#{arr}->p[#{k}]", e]]
          vals << [k, :int] if name == "Array.each_with_index"
          loop_c("for (i64 #{k} = 0; #{k} < #{arr}->len; #{k}++)", n.block, i, vals, "#{ct(at)} #{arr} = #{a};")
        when "Array.map"
          e = elem_of(at, n)
          c = cell(n)
          lab = new_label
          arr = tmp
          res = tmp
          k = tmp
          v = inline_value(n.block, i, [["#{arr}->p[#{k}]", e]], lab, c.root.elem)
          "({ #{ct(at)} #{arr} = #{a}; #{ct(c)} #{res} = #{ct(c)}_new(0); for (i64 #{k} = 0; #{k} < #{arr}->len; #{k}++) #{ct(c)}_push(#{res}, #{v}); #{labels(lab)[1]} #{res}; })"
        when "Array.select", "Array.filter", "Array.reject"
          e = elem_of(at, n)
          lab = new_label
          arr = tmp
          res = tmp
          k = tmp
          x = tmp
          bt = ty(n.block.body, i)
          v = inline_value(n.block, i, [[x, e]], lab, bt)
          test = case bt
                 when :bool then v
                 when OptT then "(#{v}).some"
                 else "({ (void)(#{v}); false; })"
                 end
          "({ #{ct(at)} #{arr} = #{a}; #{ct(at)} #{res} = #{ct(at)}_new(0); for (i64 #{k} = 0; #{k} < #{arr}->len; #{k}++) { #{ct(e)} #{x} = #{arr}->p[#{k}]; if (#{name == "Array.reject" ? "!" : ""}#{test}) #{ct(at)}_push(#{res}, #{x}); } #{labels(lab)[1]} #{res}; })"
        when "Array.sum"
          e = elem_of(at, n)
          init = n.args[1] ? val(n.args[1], i, e) : (e == :int ? "0" : "0.0")
          "#{ct(at)}_sum(#{a}, #{init}, #{ln})"
        when "Array.first", "Array.last", "Array.pop", "Array.shift", "Array.dup" then "#{ct(at)}_#{n.fn.name}(#{a})"
        when "Array.reverse" then "#{ct(at)}_reversed(#{a})"
        when "Array.min", "Array.max", "Array.sort"
          unsupported(n, "`#{name}` on #{show(at)}") unless %i[int float str].include?(elem_of(at, n))
          "#{ct(at)}_#{{ "min" => "min_", "max" => "max_", "sort" => "sorted" }.fetch(n.fn.name)}(#{a})"
        when "Array.include?" then "#{ct(at)}_includes(#{a}, #{val(n.args[1], i, elem_of(at, n))})"
        when "Array.uniq" then "#{ct(at)}_uniq(#{a})"
        when "Array.empty?" then "((#{a})->len == 0)"
        when "Array.join" then "#{ct(at)}_join(#{a}, #{b || "str_new(\"\", 0)"})"
        else unsupported(n, "the built-in `#{name}`")
        end
      end

      # --- the run-time support, in every generated program ---

      def prelude
        <<~C
          /* generated by ceec from #{File.basename(@path.to_s)} */
          #define _GNU_SOURCE
          #include <stdint.h>
          #include <stdbool.h>
          #include <stdio.h>
          #include <stdlib.h>
          #include <string.h>
          #include <stdarg.h>
          #include <math.h>
          #include <time.h>
          typedef int64_t i64;
          typedef double f64;
          typedef char Nil;
          #define SF static inline __attribute__((unused))
          static const char *FILE_ = #{c_str(File.basename(@path.to_s))};
          static int g_argc;
          static char **g_argv;

          static void sk_init(void) { static char buf[1 << 16]; setvbuf(stdout, buf, _IOFBF, sizeof buf); }
          SF void sk_flush(void) { fflush(stdout); }
          SF void sk_out(const char *s, i64 n) { fwrite(s, 1, (size_t)n, stdout); }
          static __attribute__((noreturn, unused)) void sk_fail(int ln, const char *kind, const char *msg) {
              fflush(stdout);
              fprintf(stderr, "%s:%d: %s: %s\\n", FILE_, ln, kind, msg);
              exit(1);
          }
          static __attribute__((noreturn, unused, format(printf, 3, 4))) void sk_failf(int ln, const char *kind, const char *fmt, ...) {
              char m[256];
              va_list ap;
              va_start(ap, fmt);
              vsnprintf(m, sizeof m, fmt, ap);
              va_end(ap);
              sk_fail(ln, kind, m);
          }
          static __attribute__((noreturn, unused)) void sk_exit(i64 code) { fflush(stdout); exit((int)code); }
          static __attribute__((noreturn, unused)) void sk_ovf(int ln) { sk_fail(ln, "RangeError", "Integer overflow (the C backend's Integer is 64 bits)"); }
          SF void *xmalloc(size_t n) { void *p = malloc(n ? n : 1); if (!p) sk_fail(0, "NoMemoryError", "failed to allocate memory"); return p; }
          SF void *xrealloc(void *q, size_t n) { void *p = realloc(q, n ? n : 1); if (!p) sk_fail(0, "NoMemoryError", "failed to allocate memory"); return p; }

          /* Strings are immutable here: no operation in the subset changes one in place. */
          typedef struct Str_s { i64 len; char p[]; } *Str;
          SF Str str_new(const char *s, i64 n) { Str r = xmalloc(sizeof *r + (size_t)n + 1); r->len = n; memcpy(r->p, s, (size_t)n); r->p[n] = 0; return r; }
          SF Str str_c(const char *s) { return str_new(s, (i64)strlen(s)); }
          static __attribute__((noreturn, unused)) void sk_failS(int ln, const char *kind, Str msg) { sk_fail(ln, kind, msg->p); }

          typedef struct { char *p; i64 len, cap; } SB;
          SF void sb_init(SB *b) { b->cap = 64; b->len = 0; b->p = xmalloc(64); }
          SF void sb_putn(SB *b, const char *s, i64 n) {
              if (b->len + n > b->cap) { while (b->len + n > b->cap) b->cap *= 2; b->p = xrealloc(b->p, (size_t)b->cap); }
              memcpy(b->p + b->len, s, (size_t)n);
              b->len += n;
          }
          SF void sb_cstr(SB *b, const char *s) { sb_putn(b, s, (i64)strlen(s)); }
          SF void sb_ch(SB *b, char c) { sb_putn(b, &c, 1); }
          SF void sb_putS(SB *b, Str s) { sb_putn(b, s->p, s->len); }
          SF Str sb_str(SB *b) { Str r = str_new(b->p, b->len); free(b->p); return r; }
          SF void sk_outsb(SB *b) { sk_out(b->p, b->len); free(b->p); }

          /* Integer: 64 bits, an overflow is an error; / and % round toward negative infinity, as in Ruby. */
          SF i64 add_(i64 a, i64 b, int ln) { i64 r; if (__builtin_add_overflow(a, b, &r)) sk_ovf(ln); return r; }
          SF i64 sub_(i64 a, i64 b, int ln) { i64 r; if (__builtin_sub_overflow(a, b, &r)) sk_ovf(ln); return r; }
          SF i64 mul_(i64 a, i64 b, int ln) { i64 r; if (__builtin_mul_overflow(a, b, &r)) sk_ovf(ln); return r; }
          SF i64 neg_(i64 a, int ln) { if (a == INT64_MIN) sk_ovf(ln); return -a; }
          SF i64 iabs(i64 a, int ln) { return a < 0 ? neg_(a, ln) : a; }
          SF i64 idiv(i64 a, i64 b, int ln) {
              if (b == 0) sk_fail(ln, "ZeroDivisionError", "divided by 0");
              if (a == INT64_MIN && b == -1) sk_ovf(ln);
              i64 q = a / b;
              if ((a % b != 0) && ((a < 0) != (b < 0))) q--;
              return q;
          }
          SF i64 imod(i64 a, i64 b, int ln) {
              if (b == 0) sk_fail(ln, "ZeroDivisionError", "divided by 0");
              if (b == -1) return 0;
              i64 r = a % b;
              if (r != 0 && ((r < 0) != (b < 0))) r += b;
              return r;
          }
          SF i64 ipow(i64 a, i64 b, int ln) {
              if (b < 0) sk_failf(ln, "ArgumentError", "Integer ** negative Integer (%lld ** %lld) is an error", (long long)a, (long long)b);
              i64 r = 1;
              while (b) { if (b & 1) r = mul_(r, a, ln); b >>= 1; if (b) a = mul_(a, a, ln); }
              return r;
          }
          SF i64 nonneg(i64 n, int ln) { if (n < 0) sk_fail(ln, "ArgumentError", "negative array size"); return n; }
          SF i64 idiv_p(i64 a, i64 b) { i64 q = a / b; return (a % b != 0 && a < 0) ? q - 1 : q; } /* b > 0, proved */
          SF i64 imod_p(i64 a, i64 b) { i64 r = a % b; return r < 0 ? r + b : r; }
          SF f64 fmod_(f64 a, f64 b) { f64 r = fmod(a, b); if (r != 0 && ((r < 0) != (b < 0))) r += b; return r; }
          SF f64 sk_sqrt(f64 x, int ln) { if (x < 0) sk_fail(ln, "Math::DomainError", "Numerical argument is out of domain - \\"sqrt\\""); return sqrt(x); }

          SF void ts_i64(SB *b, i64 x) { char t[24]; int n = snprintf(t, sizeof t, "%lld", (long long)x); sb_putn(b, t, n); }
          SF void in_i64(SB *b, i64 x) { ts_i64(b, x); }
          SF void ts_bool(SB *b, bool x) { sb_cstr(b, x ? "true" : "false"); }
          SF void in_bool(SB *b, bool x) { ts_bool(b, x); }
          SF void ts_Nil(SB *b, Nil x) { (void)b; (void)x; }
          SF void in_Nil(SB *b, Nil x) { (void)x; sb_cstr(b, "nil"); }
          SF void ts_Str(SB *b, Str x) { sb_putS(b, x); }
          SF void in_Str(SB *b, Str x) {
              sb_ch(b, '"');
              for (i64 k = 0; k < x->len; k++) {
                  unsigned char c = (unsigned char)x->p[k];
                  switch (c) {
                  case '"': sb_cstr(b, "\\\\\\""); break;
                  case '\\\\': sb_cstr(b, "\\\\\\\\"); break;
                  case '\\n': sb_cstr(b, "\\\\n"); break;
                  case '\\t': sb_cstr(b, "\\\\t"); break;
                  case '\\r': sb_cstr(b, "\\\\r"); break;
                  case 27: sb_cstr(b, "\\\\e"); break;
                  default:
                      if (c < 32) { char t[8]; snprintf(t, sizeof t, "\\\\x%02X", c); sb_cstr(b, t); }
                      else sb_ch(b, (char)c);
                  }
              }
              sb_ch(b, '"');
          }
          /* Float#to_s: the shortest digits that read back as the same double, laid out as Ruby does. */
          SF void ts_f64(SB *b, f64 x) {
              if (isnan(x)) { sb_cstr(b, "NaN"); return; }
              if (isinf(x)) { sb_cstr(b, x > 0 ? "Infinity" : "-Infinity"); return; }
              char buf[64];
              for (int p = 1; p <= 17; p++) { snprintf(buf, sizeof buf, "%.*e", p - 1, x); if (strtod(buf, NULL) == x) break; }
              char *e = strchr(buf, 'e');
              int ex = atoi(e + 1);
              *e = 0;
              bool neg = buf[0] == '-';
              char dig[32];
              int nd = 0;
              for (char *q = buf + neg; *q; q++) if (*q != '.') dig[nd++] = *q;
              while (nd > 1 && dig[nd - 1] == '0') nd--;
              f64 a = fabs(x);
              if (neg) sb_ch(b, '-');
              if (a == 0) { sb_cstr(b, "0.0"); return; }
              if (a >= 1e16 || a < 1e-4) {
                  sb_ch(b, dig[0]); sb_ch(b, '.');
                  if (nd > 1) sb_putn(b, dig + 1, nd - 1); else sb_ch(b, '0');
                  char t[16]; snprintf(t, sizeof t, "e%c%02d", ex < 0 ? '-' : '+', ex < 0 ? -ex : ex); sb_cstr(b, t);
                  return;
              }
              if (ex >= 0) {
                  for (int k = 0; k <= ex; k++) sb_ch(b, k < nd ? dig[k] : '0');
                  sb_ch(b, '.');
                  if (nd > ex + 1) sb_putn(b, dig + ex + 1, nd - ex - 1); else sb_ch(b, '0');
              } else {
                  sb_cstr(b, "0.");
                  for (int k = 0; k < -ex - 1; k++) sb_ch(b, '0');
                  sb_putn(b, dig, nd);
              }
          }
          SF void in_f64(SB *b, f64 x) { ts_f64(b, x); }
          #define DEFPUTS(X) SF void puts_##X(X x) { SB b; sb_init(&b); ts_##X(&b, x); sb_ch(&b, '\\n'); sk_outsb(&b); }
          DEFPUTS(i64)
          DEFPUTS(f64)
          DEFPUTS(bool)
          SF void puts_Str(Str x) { sk_out(x->p, x->len); if (!x->len || x->p[x->len - 1] != '\\n') sk_out("\\n", 1); }
          SF void puts_Nil(Nil x) { (void)x; sk_out("\\n", 1); }
          SF bool eq_i64(i64 a, i64 b) { return a == b; }
          SF bool eq_f64(f64 a, f64 b) { return a == b; }
          SF bool eq_bool(bool a, bool b) { return a == b; }
          SF bool eq_Nil(Nil a, Nil b) { (void)a; (void)b; return true; }
          SF bool str_eq(Str a, Str b) { return a == b || (a->len == b->len && memcmp(a->p, b->p, (size_t)a->len) == 0); }
          SF bool eq_Str(Str a, Str b) { return str_eq(a, b); }
          SF int cmp_i64(i64 a, i64 b) { return (a > b) - (a < b); }
          SF int cmp_f64(f64 a, f64 b) { return (a > b) - (a < b); }
          SF int str_cmp(Str a, Str b) {
              i64 n = a->len < b->len ? a->len : b->len;
              int c = memcmp(a->p, b->p, (size_t)n);
              return c ? (c > 0) - (c < 0) : (a->len > b->len) - (a->len < b->len);
          }
          SF int cmp_Str(Str a, Str b) { return str_cmp(a, b); }

          SF i64 f_to_i(f64 x, int ln) {
              if (isnan(x) || isinf(x)) { SB b; sb_init(&b); ts_f64(&b, x); sb_ch(&b, 0); sk_fail(ln, "FloatDomainError", b.p); }
              if (x >= 9223372036854775808.0 || x < -9223372036854775808.0) sk_fail(ln, "RangeError", "the Float does not fit the C backend's 64-bit Integer");
              return (i64)x;
          }
          SF int utf8_len(char c) { unsigned char u = (unsigned char)c; return u < 0x80 ? 1 : u < 0xE0 ? 2 : u < 0xF0 ? 3 : 4; }
          SF i64 str_length(Str s) { i64 n = 0; for (i64 k = 0; k < s->len; k++) if (((unsigned char)s->p[k] & 0xC0) != 0x80) n++; return n; }
          SF Str str_cat(Str a, Str b) { Str r = str_new(a->p, a->len + b->len); memcpy(r->p + a->len, b->p, (size_t)b->len); r->p[r->len] = 0; return r; }
          SF Str str_mul(Str a, i64 n, int ln) {
              if (n < 0) sk_fail(ln, "ArgumentError", "negative argument");
              Str r = str_new("", 0);
              r = xrealloc(r, sizeof *r + (size_t)(a->len * n) + 1);
              r->len = a->len * n;
              for (i64 k = 0; k < n; k++) memcpy(r->p + k * a->len, a->p, (size_t)a->len);
              r->p[r->len] = 0;
              return r;
          }
          /* upcase and downcase change ASCII letters only (Ruby changes every Unicode letter). */
          SF Str str_upcase(Str a) { Str r = str_new(a->p, a->len); for (i64 k = 0; k < r->len; k++) if (r->p[k] >= 'a' && r->p[k] <= 'z') r->p[k] -= 32; return r; }
          SF Str str_downcase(Str a) { Str r = str_new(a->p, a->len); for (i64 k = 0; k < r->len; k++) if (r->p[k] >= 'A' && r->p[k] <= 'Z') r->p[k] += 32; return r; }
          SF bool is_space_(char c) { return c == ' ' || c == '\\t' || c == '\\n' || c == '\\v' || c == '\\f' || c == '\\r'; }
          SF Str str_strip(Str a) {
              i64 s = 0, e = a->len;
              while (s < e && is_space_(a->p[s])) s++;
              while (e > s && (is_space_(a->p[e - 1]) || a->p[e - 1] == 0)) e--;
              return str_new(a->p + s, e - s);
          }
          SF Str str_reverse(Str a) {
              Str r = str_new(a->p, a->len);
              i64 k = 0;
              while (k < a->len) { int w = utf8_len(a->p[k]); if (k + w > a->len) w = (int)(a->len - k); memcpy(r->p + a->len - k - w, a->p + k, (size_t)w); k += w; }
              return r;
          }
          SF bool str_include(Str a, Str b) { return b->len == 0 || memmem(a->p, (size_t)a->len, b->p, (size_t)b->len) != NULL; }
          SF bool str_start_with(Str a, Str b) { return a->len >= b->len && memcmp(a->p, b->p, (size_t)b->len) == 0; }
          SF bool str_end_with(Str a, Str b) { return a->len >= b->len && memcmp(a->p + a->len - b->len, b->p, (size_t)b->len) == 0; }
          SF Str str_i64(i64 x) { SB b; sb_init(&b); ts_i64(&b, x); return sb_str(&b); }
          SF Str str_chr(i64 x, int ln) {
              if (x < 0 || x > 0x10FFFF) sk_failf(ln, "RangeError", "%lld out of char range", (long long)x);
              char t[4]; int n;
              if (x < 0x80) { t[0] = (char)x; n = 1; }
              else if (x < 0x800) { t[0] = (char)(0xC0 | (x >> 6)); t[1] = (char)(0x80 | (x & 0x3F)); n = 2; }
              else if (x < 0x10000) { t[0] = (char)(0xE0 | (x >> 12)); t[1] = (char)(0x80 | ((x >> 6) & 0x3F)); t[2] = (char)(0x80 | (x & 0x3F)); n = 3; }
              else { t[0] = (char)(0xF0 | (x >> 18)); t[1] = (char)(0x80 | ((x >> 12) & 0x3F)); t[2] = (char)(0x80 | ((x >> 6) & 0x3F)); t[3] = (char)(0x80 | (x & 0x3F)); n = 4; }
              return str_new(t, n);
          }
          SF i64 str_to_i(Str s) {
              i64 k = 0, v = 0;
              while (k < s->len && is_space_(s->p[k])) k++;
              bool neg = false;
              if (k < s->len && (s->p[k] == '-' || s->p[k] == '+')) neg = s->p[k++] == '-';
              for (; k < s->len; k++) {
                  char c = s->p[k];
                  if (c == '_') continue;
                  if (c < '0' || c > '9') break;
                  if (__builtin_mul_overflow(v, 10, &v) || __builtin_add_overflow(v, c - '0', &v)) v = INT64_MAX;
              }
              return neg ? -v : v;
          }
          SF f64 str_to_f(Str s) {
              char buf[128];
              int n = 0;
              i64 k = 0;
              while (k < s->len && is_space_(s->p[k])) k++;
              for (; k < s->len && n < 127; k++) {
                  char c = s->p[k];
                  if (c == '_') continue;
                  if (!((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E')) break;
                  buf[n++] = c;
              }
              buf[n] = 0;
              return strtod(buf, NULL);
          }
          static uint64_t seed_;
          SF uint64_t rand_u64(void) {
              if (!seed_) { seed_ = 0x9E3779B97F4A7C15ULL ^ (uint64_t)time(NULL) ^ ((uint64_t)clock() << 32); if (!seed_) seed_ = 1; }
              seed_ ^= seed_ << 13; seed_ ^= seed_ >> 7; seed_ ^= seed_ << 17;
              return seed_;
          }
          SF f64 rand_f(void) { return (f64)(rand_u64() >> 11) / (f64)(1ULL << 53); }
          SF i64 rand_i(i64 n, int ln) { if (n <= 0) sk_failf(ln, "ArgumentError", "invalid argument - %lld", (long long)n); return (i64)(rand_u64() % (uint64_t)n); }

          /* Arrays: a pointer shared by every variable that holds it, as in Sake. */
          #define DEFARR(A, T, OT) \\
          struct A##_s { i64 len, cap; T *p; }; \\
          SF A A##_new(i64 n) { A a = xmalloc(sizeof *a); a->len = n; a->cap = n < 4 ? 4 : n; a->p = xmalloc(sizeof(T) * (size_t)a->cap); return a; } \\
          SF A A##_from(i64 n, const T *xs) { A a = A##_new(n); memcpy(a->p, xs, sizeof(T) * (size_t)n); return a; } \\
          SF A A##_fill(i64 n, T x, int ln) { A a = A##_new(nonneg(n, ln)); for (i64 k = 0; k < n; k++) a->p[k] = x; return a; } \\
          SF A A##_push(A a, T x) { if (a->len == a->cap) { a->cap *= 2; a->p = xrealloc(a->p, sizeof(T) * (size_t)a->cap); } a->p[a->len++] = x; return a; } \\
          SF i64 A##_pos(A a, i64 i) { i64 k = i < 0 ? i + a->len : i; return k < 0 || k >= a->len ? -1 : k; } \\
          SF T A##_fetch(A a, i64 i, int ln) { i64 k = A##_pos(a, i); if (k < 0) sk_failf(ln, "IndexError", "index %lld outside of array bounds: %lld...%lld", (long long)i, (long long)-a->len, (long long)a->len); return a->p[k]; } \\
          SF OT A##_get(A a, i64 i) { i64 k = A##_pos(a, i); OT r = {0}; if (k >= 0) { r.some = true; r.v = a->p[k]; } return r; } \\
          SF void A##_set(A a, i64 i, T x, int ln) { \\
              if (i == a->len) { A##_push(a, x); return; } \\
              i64 k = A##_pos(a, i); \\
              if (k < 0) sk_failf(ln, "IndexError", "index %lld outside of array bounds: %lld...%lld (the C backend cannot fill the gap with nil)", (long long)i, (long long)-a->len, (long long)a->len); \\
              a->p[k] = x; \\
          } \\
          SF OT A##_first(A a) { return A##_get(a, 0); } \\
          SF OT A##_last(A a) { return A##_get(a, -1); } \\
          SF OT A##_pop(A a) { OT r = A##_get(a, -1); if (r.some) a->len--; return r; } \\
          SF OT A##_shift(A a) { OT r = A##_get(a, 0); if (r.some) { memmove(a->p, a->p + 1, sizeof(T) * (size_t)(a->len - 1)); a->len--; } return r; } \\
          SF A A##_dup(A a) { return A##_from(a->len, a->p); } \\
          SF A A##_reversed(A a) { A r = A##_new(a->len); for (i64 k = 0; k < a->len; k++) r->p[k] = a->p[a->len - 1 - k]; return r; }
          #define DEFARR_ORD(A, T, OT, CMP) \\
          static __attribute__((unused)) int A##_qcmp(const void *x, const void *y) { return CMP(*(const T *)x, *(const T *)y); } \\
          SF A A##_sorted(A a) { A r = A##_dup(a); qsort(r->p, (size_t)r->len, sizeof(T), A##_qcmp); return r; } \\
          SF OT A##_min_(A a) { OT r = {0}; for (i64 k = 0; k < a->len; k++) if (!r.some || CMP(a->p[k], r.v) < 0) { r.some = true; r.v = a->p[k]; } return r; } \\
          SF OT A##_max_(A a) { OT r = {0}; for (i64 k = 0; k < a->len; k++) if (!r.some || CMP(a->p[k], r.v) > 0) { r.some = true; r.v = a->p[k]; } return r; }
          #define DEFARR_SUM(A, T, ADD) \\
          SF T A##_sum(A a, T s, int ln) { (void)ln; for (i64 k = 0; k < a->len; k++) { T x = a->p[k]; s = ADD; } return s; }
        C
      end
    end
  end
end
