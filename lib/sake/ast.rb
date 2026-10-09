# frozen_string_literal: true

module Sake
  # SakeAST: the resolved program the interpreter runs. Every call names its target (a built-in, a user
  # function, a module's dispatch table, an operator, or indexing), sugar is expanded, and local variables
  # are slots of the function's frame (a block's parameters and locals too: blocks are second-class).
  # Each node keeps `origin`, the Prism node it came from, for lines in messages and the typer's facts.
  module AST
    KINDS = {}

    def self.node(name, *fields)
      klass = Struct.new(*fields, :origin, keyword_init: true)
      klass.define_singleton_method(:fields) { fields }
      const_set(name, klass)
      KINDS[name] = klass
    end

    node :Lit, :value                       # Integer Float Rational Complex Symbol Regexp true false nil
    node :Str, :string                      # a new String each time
    node :LVarGet, :slot
    node :LVarSet, :slot, :value
    node :Seq, :body                        # [node]
    node :If, :cond, :then_, :else_
    node :While, :cond, :body, :until_
    node :And, :left, :right
    node :Or, :left, :right
    node :MakeTuple, :elems
    node :MakeRecord, :keys, :values
    node :MakePairs, :keys, :values         # `Hash[k => v]` arguments
    node :MakeRange, :left, :right, :exclusive
    node :MakeRegexp, :parts, :options      # interpolated
    node :Interp, :parts                    # String parts; ToS around embedded values
    node :ToS, :value                       # Kernel.to_s (a type's own to_s)
    node :ToSym, :value
    node :Splat, :value                     # `*xs` among a built-in's rest arguments (a Tuple or an Array)
    node :CallBuiltin, :fn, :args, :block
    node :CallUser, :fn, :args, :block
    node :CallDispatch, :dispatch, :args, :block
    node :CallUnion, :union, :args, :block   # `(A|B).f(x, ...)`: union.table maps x's type to f
    node :BinOp, :op, :left, :right         # dispatched on the left operand
    node :IsNil, :value, :negate            # `x == nil` / `x != nil`
    node :UnOp, :op, :value                 # `-x` / `+x` / `~x`, dispatched on x (`!x` is an If)
    node :FieldGet, :type, :field, :fn, :subject # `@x` / `T.x(s)`; fn: the getter (it checks the subject)
    node :FieldSet, :type, :field, :fn, :subject, :value
    node :IndexGet, :recv, :key, :extra        # extra: a second index (`s[i, n]`, `m[r, c]`) or nil
    node :IndexSet, :recv, :key, :extra, :value
    node :IndexUpdate, :recv, :key, :op, :value # `x[k] OP= v` (op: "||" for ||=); x and k evaluated once
    node :ArgDefault, :slot, :value         # an optional parameter's default, when the call did not give it
    node :Missing                           # an argument the call does not give (an omitted keyword, ...)
    node :Block, :params, :locals, :body, :rest # params/locals: slots; locals are cleared on entry; rest: `|a, *r|`'s index in params
    node :Yield, :args
    node :BlockPass                         # `&b`: the function's own block, passed on to a call
    node :BlockGiven                        # `block_given?`: whether the function was given a block
    node :Return, :value
    node :Next, :value
    node :Break, :value, :target           # target: :loop (the innermost while) or :block
    node :Retry
    node :Raise, :type, :args               # type: name for `raise T, msg`, else nil
    node :ReRaise
    node :Begin, :body, :rescues, :else_, :ensure_
    node :Rescue, :names, :slot, :body      # names: [] catches every rescuable error; slot: nil or `=> e`
    node :RescueMod, :expr, :rescue_
    node :MultiWrite, :targets, :value      # targets: TLocal / TIndex / TField, assigned left to right
    node :TLocal, :slot
    node :TRest, :slot                      # `*r` (slot nil for a bare `*`): an Array of the elements between
    node :TIndex, :recv, :key               # recv and key are evaluated before the right side
    node :TField, :type, :field, :fn, :subject
    node :CaseIn, :subject, :clauses, :else_ # clauses: [[pattern, body]]
    node :MatchP, :value, :pattern
    node :MatchRecord, :value, :keys, :slots
    node :PType, :name                      # a type name, or Record
    node :PAlt, :left, :right
    node :PRecord, :keys, :slots
    node :PValue, :value
    node :PTuple, :elems                    # `in [p, q]`: a Tuple of that length whose positions match
    node :PBind, :slot                      # `in x` inside a Tuple pattern: matches anything, binds it
    node :Unresolved, :message              # a call never resolved here (unreachable when checks pass)

    # nslots: the frame size (parameters first); slot_names: slot => variable name (for messages).
    # fn: the UserFunction (nil for the top level).
    Function = Struct.new(:name, :fn, :nparams, :nslots, :slot_names, :body, keyword_init: true)
    Program = Struct.new(:main, :functions, keyword_init: true) # functions: UserFunction => Function

    # S-expression dump: (kind operand ...). Built-ins, functions and dispatches are shown by name.
    def self.dump(x, indent = 0)
      case x
      when Function then "(function #{x.name} #{x.nparams} #{x.nslots}\n#{"  " * (indent + 1)}#{dump(x.body, indent + 1)})"
      when *KINDS.values
        name = KINDS.key(x.class).to_s.gsub(/(?<=[a-z\d])(?=[A-Z])/, "_").downcase
        ops = x.class.fields.map { |f| dump(x[f], indent + 1) }
        ops.empty? ? "(#{name})" : "(#{name} #{ops.join(" ")})"
      when Array then "[#{x.map { dump(_1, indent) }.join(" ")}]"
      when Builtin then x.full_name
      when UserFunction then "fn:#{x.full_name}"
      when Dispatch then "dispatch:#{x.module}.#{x.name}"
      when nil then "nil"
      else x.inspect
      end
    end
  end
end
