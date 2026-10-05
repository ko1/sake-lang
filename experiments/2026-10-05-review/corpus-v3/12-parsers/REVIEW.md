# REVIEW (12-parsers, corpus-v3)

All 25 programs run with `bin/sake --strict=0` and print exactly `NAME.out` (exit 0).

Note: the `.rb` / `TASKS.md` symlinks in this directory point to `../../corpus/12-parsers/...`, which
does not exist; the Ruby references were read from `experiments/2026-10-01-inference-500/corpus/12-parsers/`.

- assembler: `class AsmError < Exception` + `attr_reader line`; `Stmt` as `class` + `attr_reader`; opcode table and its inverse (`names`, was rebuilt per `disassemble` call) via `once`; `kind_of` as `case`/`in` with `|` alternatives (Ruby `case`/`when`); operand count from a Hash lookup as in Ruby; `String.split(src, /\s+/, 2)` (limit) replaces `String.partition`; `regs = Array[0] * 8`; `if (m = ...)`; `else mn` in `disassemble`; block-level `rescue` in the `do` block
- brainfuck: exception class; `Array.new(tape_size, 0)` replaces the `Integer.times` push loop; the `if`/`elsif` chain on the opcode is `case code[pc] in "+" then ...` (Ruby `case`/`when`); `programs` via `once`
- calc_rd: exception classes; `Calc` is `class` + `attr_reader src, env, pos = 0`, so `Calc.new(line, env)` as in Ruby (pos was passed as 0); `expr`/`term` loops and `call` use `case`/`in` (Ruby `case`/`when`) with `+=`/`*=`; `if (m = ...)`; `show` one line; block-level `rescue`
- chem_formula: exception class; `masses` via `once` (was rebuilt on every lookup); `parse_formula`/`side_counts` use `Array.each_with_object(..., Hash[])` as Ruby does; block-level `rescue`
- cmdline_parser: `Opt` class with `takes_value?` inside it (as in Ruby); exception class; `spec` via `once`; `defaults` is `Array.map { [k, v] }.Array.to_h` (Ruby `to_h { }`); `store` and `show` end in `else` like Ruby
- csv_parser: `class CsvError < Exception` + `attr_reader row`
- forth: exception class; `Forth` is `class` with `attr_reader stack = nil, dict = nil` / `attr_accessor out = "", loops = nil` and `initialize` creating the containers, so `Forth.new` takes no arguments (as Ruby); `find_matching` iterates `Range.each` (Ruby `(i+1...n).each`); `if (body = @dict[w])`; `push(f, case ... end)`; stack shown with `Array.join` directly; `session` via `once`
- indent_lexer: `Tok`, `Outline`, `IndentError` as classes; `Outline.new(header)` with `children` created in `initialize` (Ruby `@children = []`); `depth` moved into the class; `sources` via `once`
- ini_parser: `Section` (reader), `Entry` (accessor, as Ruby), `IniError` as classes; `convert` dispatches with `case type in :int` (Ruby `case`/`when`); `schema`, `files` via `once`; `&& last` instead of `last != nil`
- json_parser: exception class; `Json` is `class` + `attr_reader src, pos = 0`, `Json.new(text)`; escape handling as `case e in "n" ... in "\"" | "\\" | "/"`; `@src[@pos, 4]` (two-index slice) replaces a range; `quote` as a `.String.gsub` chain; `dump` uses `Array.none?` and `else Kernel.to_s(v)`; `lookup` is `Array.reduce` with `return` in the block, as Ruby; `Array.sum(books) { }`; block-level `rescue`
- lisp_interp: `LispError` class with `raise LispError, "msg"`; `Env` (`attr_reader parent, vars = nil` + `initialize`), `Lambda`, `Prim` classes, `Env.new(parent)` as in Ruby; `truthy?` is `v != false` and the `cond` test is `test == :else` (cross-type `==` now gives false); `define` returns from each branch; `eval_body` with `Array.reduce`; `apply` binds with `Array.zip`; `cons` is `Array[args[0], *args[1]]` (splat); `programs` via `once`
- markdown: `Block` class with `attr_reader kind, lines, level = 0` (Ruby's `level = 0` optional parameter), so `Block.new(kind, lines)`; the `find_from` helper is gone: `String.index(s, t, start)` as in Ruby; `if (close = String.index(...))`; `close = mid && String.index(...)`; `render` is `Array.map { case ... }.Array.join` (Ruby shape) instead of pushing into an Array; `escape_html` as a chain
- pratt_parser: classes for `Node`, `ParseError`, `EvalError` (`raise EvalError, "msg"`); `Parser` with `attr_reader tokens, pos = 0`; infix table via `once` (was rebuilt per `expr` call); `while (op = peek(ps))`; call node `Node[lhs, *list_until(...)]` (splat; was `Array.unshift`); `==`/`!=` as one line `op == "==" ? a == b : a != b` (cross-type `==` now false, the Integer/bool guard is gone); `size` with `Array.sum { }`; `bool!` checks `v == true || v == false`; `show` one line; block-level `rescue`
- query_engine: classes for `Query` (accessor, `where = nil, ..., desc = false, limit = nil` defaults, so `Query.new(columns, table)` as in Ruby), `Cmp`, `Logic`, `Agg` (with its own `label`), `Cursor` (`pos = 0`), `QueryError` (`raise QueryError, "msg"`); `Array.include?` for the aggregate names; result rows built with `Array.map { [k, v] }.Array.to_h`; `tables` via `once`
- regex_matcher: `Node` class (`attr_accessor`, as Ruby), exception class; `to_s` suffix and quantifier come from a Hash lookup as in Ruby; `expand_range` one line `Range.map { Integer.chr }`; escape node via `Array.push(nodes, case e ... end)`; `String.include?("*+?", c)`; `cases` via `once`; `result = if ... end`; block-level `rescue`
- rpn_calc: exception classes; `Calc` with `attr_reader stack = nil, regs = nil` + `initialize`, `Calc.new` without arguments; stack words as `case w in "neg" then ...` (Ruby `case`/`when`); block-level `rescue`
- shunting_yard: exception classes, `raise EvalError, "msg"`; operator table via `once`; `while (top = Array.last(stack)) && top != "("` as in Ruby (was `while true` + two `break`s); `apply` as `case`/`in`
- stack_vm: `Instr.to_s` is `Array.join(Array.compact([...]))` as Ruby; `Frame` (accessor) and `VMError` as classes; `if (m = ...)`; `Array.push(stack, case ... end)`; `Hash.sort_by(counts)` directly
- symbolic_diff: `Num`, `Var`, `Bin`, `Fn`, `ParseError` as classes; `Parser` with `pos = 0`, `Parser.new(tokens)`; `expr`/`term` as modifier `while` (Ruby form); precedence table via `once` Hash (Ruby `PREC`); block-level `rescue`
- template_engine: `Tag` class with `children` created in `initialize` (`Tag.new(kind, name)`, as Ruby); exception class; `String.index(src, t, pos)` replaces `src[pos..]` + offset arithmetic; `first, *rest = String.split(...)` with `Array.reduce` (Ruby shape); `escape` as a chain; `blank?` one line; `data`, `templates` via `once`
- tiny_basic: exception, `ForFrame`, `Toks` (`pos = 0`) as classes; `Basic.new(text)` parses the program in `initialize` (the `code` field holds the text, then the Hash), replacing the `load` function with 9 positional arguments; statement dispatch is `case Toks.peek(t) in "REM" ...` (Ruby `case`/`when`); `relops` via `once`
- tokenizer: `Token` class + `attr_reader`; `keywords`, `two_char_ops`, `sources` via `once`; modifier `while` for the comment skip; `Hash.sort_by` directly
- truth_table: exception class; `Reader` with `pos = 0`; `variables(e, acc = Set[])` (Ruby's optional parameter); operator symbols via a `once` Hash (Ruby `SYMBOLS`); `Range.map`; `filter_map` block `... if value`; `Integer.zero?`; block-level `rescue`
- turing_machine: `Rule`, `Machine`, `SpecError` as classes; `shown` as a ternary; `broken_specs` via `once`; block-level `rescue`
- type_checker: exception classes, `raise TypeErr, "msg"`; `Stream` with `pos = 0`; `expr` as `case peek(s) in "let" ... else compare(s)`; `compare` one line; `keywords`, `builtins` via `once`; block-level `rescue`

## Friction

- **Private instance variables.** Ruby keeps parser state private (`@src`, `@tokens`, `@pos` with no
  reader, or only `attr_reader :pos`). Sake has no field without an accessor, so each becomes
  `attr_reader` (calc_rd.sake:10, json_parser.sake:6, truth_table.sake:6, symbolic_diff.sake:22,
  pratt_parser.sake:24, type_checker.sake:11, query_engine.sake:23, tiny_basic.sake:10). Harmless, but the
  type's public surface grows.
- **`initialize` with fewer arguments than fields.** Ruby's `def initialize; @stack = []; @dict = {}`
  → Sake needs a literal default on every such field (`= nil`) so that `new` may omit it, then
  `initialize` overwrites it (forth.sake:6-7, rpn_calc.sake:10, lisp_interp.sake:5,
  indent_lexer.sake:6, template_engine.sake:2, tiny_basic.sake:30). `nil` is a placeholder that never
  survives `new`; a default that names an empty collection (or "set in initialize") is what one wants.
  tiny_basic.sake:30 also reuses the first field for the source text and replaces it by a Hash in
  `initialize`, because the constructor argument (`text`) is not a field in Ruby.
- **`case`/`in` has no implicit `else nil`.** Ruby's `case`/`when` without `else` gives nil; Sake raises
  `NoMatchingPatternError`. So turing_machine.sake:48-49 keeps `head += 1 if move == "R"` (Ruby:
  `case rule.move when "R" ... when "L" ...`, "N" falls through), regex_matcher.sake:88 keeps the `if
  kind == :bol` form (Ruby: `case node.kind when :bol ... when :eol ...`), assembler.sake:74 needs `in
  :none then nil`.
- **No regexp branches in `case`.** Ruby's `when /\A\d+\z/` cannot be written, so token dispatch that
  mixes literals and regexps stays an `if`/`elsif` chain (forth.sake:85, lisp_interp.sake:51,
  symbolic_diff.sake:73, type_checker.sake:79, rpn_calc.sake:47).
- **No `loop do`.** Every Ruby `loop do` became `while true` (12 places, e.g. json_parser.sake:57,
  calc_rd.sake:43, lisp_interp.sake:38).
- **`x in T` in a modifier inside a `case`/`in` branch is a Ruby parse trap.** `raise E, "m" unless
  args[0] in Array` followed by a statement, inside an `in "len"` branch, is parsed by Prism as a new
  `in Array` branch of the enclosing `case` (verified with `Prism.parse`; Ruby 4.0.2 behaves the same).
  pratt_parser.sake:145,148 needed parentheses `unless (args[0] in Array)`. Ruby code writes
  `is_a?(Array)` there and never meets it; Sake's `in` as the type test makes it common.
- **No array patterns.** type_checker.sake:119-146 still dispatches on `e[0]` and then destructures each
  branch with `_, name, value, body = e`; Ruby writes `in [:let, name, value, body]`.
- **No first-class functions / `public_send`.** Operator tables stay `case` chains: lisp_interp.sake:137
  (Ruby `PRIMITIVES` Hash of lambdas), query_engine.sake:124 (Ruby `a.public_send(op, b)`), rpn_calc.sake:55
  (Ruby `a.send(w, b)`).
- **`Array | Array` is not defined.** chem_formula.sake:71 keeps `Array.union(...)` for Ruby's
  `(left.keys | right.keys)` (`TypeError: Bitwise.|: no implementation for (Array, Array)`), although
  `Array + Array` and `Array - Array` work.
- **Smaller gaps:** no `&.` (`c&.match?` → `c != nil && String.match?`, truth_table.sake:56,
  tiny_basic.sake:124; `current&.kind == kind` → markdown.sake:85); `Array.to_h` takes no block
  (`map { [k, v] }.Array.to_h` in cmdline_parser, query_engine); `Set.merge` takes only a Set
  (turing_machine.sake:23 keeps `Array.each` + `Set.add`); `Array.all?`/`count` take no pattern argument
  (`values.all?(Integer)` → block with `in`).

## Ruby comparison

- Every field access is `T.get_x(v)` and every method is `T.f(v, ...)` with the receiver as an explicit
  first parameter (`def peek(ps) = @tokens[@pos]` where Ruby has `def peek = @tokens[@pos]`); in the
  parser classes this doubles the length of call-heavy lines (`Cursor.accept(c, "(")`,
  `Toks.peek(t)`).
- Tables are `def name = once { ... }` and are called, not referenced as constants (`operators[t]`,
  `opcodes[mn]`); exceptions are `class E < Exception` with `attr_reader` and positional `E.new(msg,
  field)`, no `super(message)`.
- `case`/`when` is `case`/`in` throughout; it reads the same for literal branches but differs where Ruby
  relies on `===` (regexps) or on a silent nil fall-through (see Friction).
- Collections are built with `Array[]` / `Hash[]` instead of `[]` / `{}`; `<<` is `Array.push`, and
  String building uses `+=` instead of `<<` on a mutable `+""`.
- Block-level `rescue` in `do ... end` (as Ruby 2.6+) now works, so the per-item error handling has the
  same shape as the Ruby versions.
