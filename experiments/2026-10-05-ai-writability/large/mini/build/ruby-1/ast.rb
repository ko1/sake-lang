# frozen_string_literal: true

module Mini
  # Syntax tree nodes. A `body` is an Array of statements. Positions point at
  # the token where errors about the node are reported (SPEC sections 6 to 10):
  # the operator, the `(` of a call, the `[` of an index, the keyword, ...
  module AST
    # A name being declared, with where it is written.
    DeclName = Struct.new(:text, :position)
    Param = Struct.new(:name, :default) # name: DeclName; default: expression or nil

    Program = Struct.new(:body)

    # --- statements ---
    Let = Struct.new(:name, :value) # value nil for `let x`
    LetArray = Struct.new(:position, :names, :value) # position of `[`
    Const = Struct.new(:name, :value)
    FnDecl = Struct.new(:name, :function) # function: FunctionLit
    If = Struct.new(:branches, :else_body)
    Branch = Struct.new(:condition, :body)
    Match = Struct.new(:position, :subject, :arms, :else_body)
    Arm = Struct.new(:values, :body)
    While = Struct.new(:condition, :body)
    For = Struct.new(:position, :names, :iterable, :body)
    Break = Struct.new(:position)
    Continue = Struct.new(:position)
    Return = Struct.new(:position, :value) # value nil for a bare `return`
    Throw = Struct.new(:position, :value)
    Assert = Struct.new(:position, :condition, :message)
    Try = Struct.new(:body, :catch_name, :catch_body, :finally_body)
    Assign = Struct.new(:target, :operator, :position, :value) # operator "=", "+=", ...
    MultiAssign = Struct.new(:targets, :position, :values)
    ExprStmt = Struct.new(:expression)

    # The statements after which nothing in the same list can run, with the
    # keyword used in the "unreachable" message.
    JUMP_KEYWORDS = { Break => "break", Continue => "continue", Return => "return", Throw => "throw" }.freeze

    # --- expressions ---
    Literal = Struct.new(:value) # int, plain string, true, false, nil
    Interpolation = Struct.new(:parts) # Strings and expressions
    # `decl`, `hops` and `depth` are filled in by the static checks: the
    # declaration referred to, how many scopes out it lives, and that scope's
    # depth (0 is the built-in scope).
    Name = Struct.new(:text, :position, :decl, :hops, :depth)
    ArrayLit = Struct.new(:elements)
    MapLit = Struct.new(:entries)
    MapEntry = Struct.new(:key, :value, :position) # position of the key
    FunctionLit = Struct.new(:name, :params, :body) # name nil when anonymous
    Negate = Struct.new(:position, :operand)
    Not = Struct.new(:operand)
    Binary = Struct.new(:operator, :position, :left, :right) # arithmetic, comparison, in
    Logical = Struct.new(:operator, :left, :right) # and, or
    Call = Struct.new(:callee, :position, :arguments)
    Index = Struct.new(:object, :position, :index)
    Slice = Struct.new(:object, :position, :from, :to) # from / to nil when omitted
    Field = Struct.new(:object, :position, :name)
  end
end
