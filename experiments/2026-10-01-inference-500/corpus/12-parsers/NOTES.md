# Notes (12-parsers)

## calc_rd
- No unary minus in Sake: `-unary` is written `0 - unary(c)`.
- `abs` on a value that may be Integer or Float: Ruby calls `x.abs`; Sake has no dispatching `abs`, so it is written `a < 0 ? 0 - a : a`.
- `loop do ... case/when ... end` in Ruby becomes `while true` + `if/elsif` + `break` in Sake (no `case/when`, no `loop`).

## shunting_yard
- Ruby's `OPERATORS[t][:prec]` (Hash of Hashes) is a Hash of Records in Sake, read with `ops[t] => {prec:, right:}`.
- Ruby version cannot name its exception `SyntaxError` (built-in ScriptError subclass); both versions use `ExprSyntaxError`.

## stack_vm
- `Array.sort_by` with a Tuple key (`[-n, name]`) fails at run time: "ArgumentError: Array.sort_by: cannot compare elements of types Tuple". Workaround: a String key `format("%08d %s", 99999999 - n, op)`.
- `case/when` with several values (`when :add, :sub`) is `in :add | :sub` in Sake; `loop do` is `while true`.

## rpn_calc
- Ruby applies the arithmetic word with `a.send(w, b)`; Sake forbids `send`, so the four operators are an if-chain.
- Ruby's `a.is_a?(Integer) && b.is_a?(Integer)` is two nested `if x in Integer` in Sake so that both locals are narrowed.

## json_parser
- `String.gsub` with a String replacement interprets backslashes as Ruby does, so `\` -> `\\` needs the replacement `"\\\\\\\\"` in both versions (first draft of the Sake version used `"\\\\"`, as one might expect; caught by adding a backslash to the data).
- Ruby's `def self.parse` constructor-style function is `Json.parse(text)` inside `class Json`; its first argument is a String, so `@pos` cannot be used there and the accessors are called explicitly.

## csv_parser
- `unless field.empty? && row.empty?` is written `if String.empty?(field) == false || Array.empty?(row) == false` (no `!`).

## lisp_interp
- `==` between values of different types is a TypeError in Sake (`1 == :a` -> "TypeError: Kernel.==: no implementation for (Integer, Symbol)"), while Ruby returns false. Comparing a Lisp form's head (Symbol, Integer or Array) against `:quote` etc. is therefore written `case head in :quote` (literal patterns do not raise), and `test == :else` is `(test in :else)`.
- `x in Array ? a : b` is a syntax error (Prism: "unexpected '?'"); it needs parentheses `(x in Array) ? a : b`. Ruby has the same rule, it is just easy to hit in Sake where `in` replaces `is_a?`.
- Ruby keeps primitives as a Hash of lambdas (`PRIMITIVES = { :+ => ->(args) { ... } }`); Sake has no first-class functions, so `Prim` holds only the name and `primitive(name, args)` dispatches with `case name in :+ ...`.

## regex_matcher
- Ruby compares match spans with `found == builtin(pat, s)` (Array/nil equality). In Sake `==` on Tuples is not defined, so a helper `same_span?` checks nil on each side and destructures both Tuples.
- Ruby's small lookup Hashes (`{ one: "", star: "*" }[@quant]`) became `case @quant in :one then ""` in Sake; a Hash would also work but the `case` is more natural without Hash literals.

## brainfuck
- Interpreter bug: `Array.join` without the separator crashes inside the interpreter (exit 1 with a Ruby backtrace, not a Sake error).
  Repro: `p(Array.join(Array["a", "b"]))` -> `stdlib.rb:176:in 'block in Sake::Stdlib.install_array': undefined method 'map' for an instance of String (NoMethodError)`.
  `Array.join(a, "")` works. Workaround: always pass the separator.
- Ruby's `Array.new(tape_size, 0)` (Sake has no `Array.new`) is `Integer[]` filled with `Integer.times`.

## forth
- Sake's `String.chomp` takes no argument (`String.chomp(s, "\"")` -> "wrong number of arguments for String.chomp (given 2, expected 1)"); used `String.delete_suffix`, which Ruby also has.
- Loop frames are mutable Tuples `[index, limit, start]` updated with `frame[0] = frame[0] + 1` (Ruby: `frame[0] += 1` on an Array).
- Ruby's `when *BINARY` (splat of a constant list) is an alternation pattern `in "+" | "-" | ...` in Sake (no value constants, no `when`).

## symbolic_diff
- Ruby's `PREC = {...}` constant is a function `prec(op)` with `case/in` (no value constants).
- Dispatch over the AST node types is `case e in Num ... in Bin` in both versions (Ruby `case/when` on classes), so nothing had to be worked around beyond syntax.

## pratt_parser
- Ruby's `a == b` on values that may be Integer, true/false, or Array (false when the types differ) cannot be written directly: Sake's `==` raises TypeError for mixed types. The Sake version compares only when both sides are Integer or both are booleans (`(a in Integer) && (b in Integer)`), otherwise `false`.
- `while (op = peek)` (assignment in condition) is `while true` + `op = peek(ps)` + `break if op == nil`.
- Binding powers are a Hash of Tuples (`"^" => [16, 15]`) destructured by `lbp, rbp = table[op]` after a `Hash.key?` check.

## assembler
- Ruby's `mn, rest = src.split(/\s+/, 2)`: Sake's `String.split` takes no limit argument, so the mnemonic and the rest are taken with `String.match(src, /\A(\S+)\s*(.*)\z/)`.
- Docs: spec §8.3 lists `<=>` as not supported, but `3 <=> 4` runs (gives -1), so the Sake version uses it like Ruby.
- Ruby keeps the decoded word as a Hash read with `d[:op]`; Sake returns a Record and destructures it with `decode(w) => {op:, immediate:, dst:, src:, imm:, addr:}`.

## template_engine
- Ruby's `src.index("{{", pos)` (start offset): Sake's `String.index` takes no offset, so it searches `src[pos..]` and adds `pos` back.
- Ruby's `first, *rest = name.split(".")` (splat in multiple assignment) is `parts[0]` and `Array.drop(parts, 1)`.

## query_engine
- Ruby dispatches the comparison with `a.public_send(cond.op, b)`; Sake spells out each operator in `case op in "<" then a < b ...`.
- Both versions raise a QueryError when the column and literal types differ. In Ruby this guards `Integer < String` (ArgumentError); in Sake it also guards `==`/`!=`, which raise TypeError on mixed types.
- A column is either a String or an `Agg` struct, compared with `col == "*"`. Checked: `Agg.new(..) == "*"` is false (Struct equality), but the reverse order `"*" == Agg.new(..)` is a TypeError ("Kernel.==: no implementation for (String, A)"), so `==` is asymmetric across types.

## markdown
- `String.index` has no start offset; a helper `find_from(s, needle, from)` searches `s[from..]` (Ruby: `s.index(needle, from)`).
- `current&.kind == kind` (safe navigation) is `current != nil && Block.get_kind(current) == kind`.
- Assignment inside `elsif (m = String.match(...))` works in Sake as in Ruby.

## truth_table
- The AST is Records of three shapes (`{var:}`, `{neg:}`, `{op:, l:, r:}`), dispatched with Record patterns; Ruby uses Hashes with Symbol keys and the same `case/in` patterns, so the shapes match one-to-one.
- `variables(e, acc = Set.new)` (default argument) needs the accumulator passed explicitly in Sake.
- `!x` is written `x == false`, e.g. `in :imp then a == false || holds?(r, env)`.

## chem_formula
- `lhs, rhs = String.split(eq, "->")` fails at run time: "TypeError: multiple assignment needs a Tuple, got Array". Multiple assignment only takes Tuples, so the Sake version indexes the Array (`sides[0]`, `sides[1]`).
- `Hash.keys(a) + Hash.keys(b)` is not available (no `+` row for Arrays); used `Array.union` (Ruby: `a.keys | b.keys`).

## turing_machine
- Ruby's `case line when /re/ then ... $1` (regexp `when` and match globals) becomes an `if (m = String.match(...))` chain with `m[1]`; Sake has neither `case/when` nor `$1`.
- The rule table uses Tuple keys (`rules[[state, sym]]`), which Sake allows as Hash keys (value types).

## tiny_basic
- Ruby's constructor `Basic.new(text)` does the loading in `initialize`; Sake's `Struct.new` takes every field positionally, so a top-level `load(text)` builds the struct with all nine fields.
- Ruby's `v = @vars[name] += frame.step` (compound index assignment as an expression) is split into two statements in Sake.
- Performance: the first draft ran 20000 BASIC statements in the infinite-loop test and took about 14 s under Sake (Ruby: well under 1 s); the step limit was lowered to 3000 in both versions (Sake run now about 3 s).

## cmdline_parser
- Ruby prints options that differ from their defaults with `v != d[k]`, where values are Integer, String, true/false or Array. In Sake `!=` on two Arrays is a TypeError ("Kernel.!=: no implementation for (Array, Array)"), so the list option is compared with `Array.empty?` instead.
- `name, eq, inline = String.partition(body, "=")` works: `String.partition` returns a Tuple (unlike `String.split`, see chem_formula).

## type_checker
- The AST is tagged Tuples of different lengths (`[:lit, v]`, `[:bin, op, l, r]`, `[:let, name, value, body]`). Ruby destructures them with array patterns (`in [:bin, op, lhs, rhs]`); Sake has no array patterns, so it dispatches with `case e[0] in :bin` and reads positions as `e[2]`, `e[3]`.
- Ruby's `env.fetch(name) { raise ... }` (block default) is `env[name]` plus a nil check.
- Ruby evaluates operators with `a.public_send(op, b)`; Sake lists each operator in a `case`.

## indent_lexer
- Writing `(n - 1).times { ... }` by habit is a static error (method call on a value); it is `Integer.times(n - 1) { ... }`.
- Ruby's `each_line(chomp: true).with_index(1)` (keyword argument, enumerator chaining) is `Array.each_with_index(String.lines(src))` with `String.chomp` and `i + 1`.
