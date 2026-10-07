# Syntax tree nodes. Every node has `line` and `col`: the token at which
# errors about the node are reported (an operator, a `(`, a `[`, a keyword...).
# Declared names are kept as their :name tokens, for positions in messages.
module Mini
  module AST
    def self.node(*fields)
      Struct.new(*fields, :line, :col, keyword_init: true)
    end

    # ---- expressions ----

    Literal   = node(:value)                  # int, true, false, nil
    StringLit = node(:parts)                  # Strings and expressions
    ArrayLit  = node(:elements)
    MapLit    = node(:entries)                # [[key, value], ...]
    # `slot` is filled by the static checks: how many scopes up the
    # declaration is (`hops`) and the depth of its scope (`depth`).
    Name      = node(:name, :hops, :depth)
    Function  = node(:name, :params, :body)   # name is nil when anonymous
    Param     = node(:name, :default)
    Unary     = node(:op, :operand)           # "-" or "not"
    Binary    = node(:op, :left, :right)      # arithmetic, comparison, "in"
    Logical   = node(:op, :left, :right)      # "and" / "or"
    Call      = node(:callee, :args)          # at the "("
    Index     = node(:object, :index)         # at the "["
    Slice     = node(:object, :from, :to)     # at the "["; bounds may be nil
    Field     = node(:object, :name)          # at the "."

    # ---- statements ----

    Let       = node(:name, :value)           # name is a token; value may be nil
    LetArray  = node(:names, :value)          # at the "["
    Const     = node(:name, :value)
    FnDecl    = node(:name, :function)        # name is a token
    If        = node(:branches, :else_body)   # [[condition, body], ...]
    Match     = node(:subject, :arms, :else_body) # [[values, body], ...]
    While     = node(:condition, :body)
    For       = node(:names, :iterable, :body)
    Break     = node
    Continue  = node
    Return    = node(:value)
    Throw     = node(:value)
    Assert    = node(:condition, :message)
    Try       = node(:body, :catch_name, :catch_body, :finally_body)
    Assign    = node(:op, :targets, :values)  # at the assignment operator
    ExprStmt  = node(:expr)

    JUMPS = [Break, Continue, Return, Throw].freeze

    def self.jump_keyword(stmt)
      { Break => "break", Continue => "continue", Return => "return", Throw => "throw" }[stmt.class]
    end
  end
end
