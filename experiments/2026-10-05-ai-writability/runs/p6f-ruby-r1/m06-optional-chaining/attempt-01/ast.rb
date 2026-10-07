# AST nodes. The parser makes them, the resolver checks them (and fills in
# Name#depth), and the interpreter runs them.
#
# Every node except ExprStmt, IfBranch, MatchArm and Program has a `pos`. For
# most nodes it is the position of the node's first token (for Let, Const and
# FnDecl, of the declared name); for Binary and Logical it is the operator, for
# Call the "(", for Index the "[" (or the "." of `m.name`), and for Assign the
# assignment operator. Errors are reported at these positions. A function body
# or block body is a plain Array of statement nodes.

# ---- Expressions ----

IntLit = Struct.new(:value, :pos)
StrLit = Struct.new(:value, :pos)

# A string with interpolations: parts are Strings and expression nodes, in order.
InterpStr = Struct.new(:parts, :pos)

BoolLit = Struct.new(:value, :pos)
NilLit = Struct.new(:pos)

# A use of a variable. `depth` is set by the resolver: how many scopes out from
# the current one the variable lives (0 = the innermost scope).
Name = Struct.new(:name, :pos, :depth)

ArrayLit = Struct.new(:elements, :pos)

# keys[i] maps to values[i]; both are expression nodes.
MapLit = Struct.new(:keys, :values, :pos)

# A function, both `fn name(...) ... end` and `fn(...) ... end`.
# name is nil for an anonymous function; params is an Array of Param.
FnExpr = Struct.new(:name, :params, :body, :pos)

# A parameter, loop variable or catch variable. default is the expression of
# `name = default` in a parameter list, else nil.
Param = Struct.new(:name, :default, :pos)

# op is "-" or "not".
Unary = Struct.new(:op, :operand, :pos)

# op is one of + - * / % ** == != < <= > >= in.
Binary = Struct.new(:op, :left, :right, :pos)

# op is "and" or "or"; the right side is evaluated only when needed.
Logical = Struct.new(:op, :left, :right, :pos)

Call = Struct.new(:callee, :args, :pos)

# `a[i]`, and also `m.name`, which is `m["name"]`.
Index = Struct.new(:target, :index, :pos, :optional)

# `a[start:stop]`; start and stop are nil when left out. pos is the "[".
Slice = Struct.new(:target, :start, :stop, :pos, :optional)

# A chain containing `?.` or `?[`: a nil receiver there skips the rest of the chain.
Chain = Struct.new(:expr, :pos)

# ---- Statements ----

Program = Struct.new(:body)

# `let name = value`; value is nil when there is no initializer. pos is the name's.
Let = Struct.new(:name, :value, :pos)

# `const name = value`. pos is the name's.
Const = Struct.new(:name, :value, :pos)

# `let [a, b, c] = value`: names is an Array of Param. pos is the "[".
LetList = Struct.new(:names, :value, :pos)

# `fn name(...) ... end` as a statement; pos is the name's.
FnDecl = Struct.new(:fn, :pos)

# target is a Name or an Index; op is one of ASSIGNMENT_OPERATORS.
Assign = Struct.new(:target, :op, :value, :pos)

# `t1, t2 = v1, v2`: as many values as targets; each target is a Name or an
# Index. pos is the "=".
MultiAssign = Struct.new(:targets, :values, :pos)

ExprStmt = Struct.new(:expr)

IfBranch = Struct.new(:cond, :body)

# branches: the `if` and each `elif`, in order; else_body is nil without `else`.
If = Struct.new(:branches, :else_body, :pos)

While = Struct.new(:cond, :body, :pos)

# vars: one Param (`for x in`) or two (`for k, v in`): the loop variables.
For = Struct.new(:vars, :iterable, :body, :pos)

# values: the expressions after `when`, compared with == to the subject.
MatchArm = Struct.new(:values, :body)

# arms: the `when` arms in order; else_body is nil without `else`.
Match = Struct.new(:subject, :arms, :else_body, :pos)

Break = Struct.new(:pos)
Continue = Struct.new(:pos)

# value is nil for a bare `return`.
Return = Struct.new(:value, :pos)

Throw = Struct.new(:value, :pos)

# `assert cond` or `assert cond, message`; message is nil when left out.
Assert = Struct.new(:cond, :message, :pos)

# var is a Param: the variable that holds the caught value in the handler.
# var and handler are nil without `catch`; finally_body is nil without `finally`.
Try = Struct.new(:body, :var, :handler, :finally_body, :pos)
