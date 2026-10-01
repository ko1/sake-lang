# Notes (pilot, 12-parsers)

No interpreter bugs found. All four tasks ran under `--strict=0` on the first try that was
syntactically complete; the only rework was for length and output formatting.

## expr_parser
- Unary minus in the *interpreted* language is parsed to `BinOp("-", Num(0), x)`, because Sake has
  no unary operators (the Ruby version does the same to keep the algorithm identical).
- Ruby uses `case node when Num`; Sake uses `case node in Num` (no `case/when`).

## stack_vm
- `Integer(s) rescue raise(AsmError.new(...))` works the same way in both languages.

## mini_lang
- The first version (with `while`) was 266 lines of Sake, over the 200-line limit. To fit, I
  dropped `while` from the interpreted language (loops are written as recursion in the sample
  programs), dropped `<=`/`>=`, and replaced the per-level parse functions with a precedence table.
  The Ruby version was changed the same way.
- Nodes dispatch through a mixin: `module Node` has a default `run` that raises, each node type does
  `include Node` and defines its own `run`, and callers write `Node.run(child, frame)`. The Ruby
  version uses ordinary methods (`child.run(frame)`) and `include Node` for the default.
- The Ruby record classes cost about 8 lines each (attr_reader + initialize), so the Ruby file is
  much longer than the Sake one (Sake uses `class Lit < {reader: [value]}`).

## json_reader
- Values are a union (Hash | Array | String | Integer | Float | true | false | nil); traversal uses
  `case v in Hash ... in Array ...`. `query` returns nil on a miss at any step.
- `String.gsub` with a String replacement interprets backslashes as Ruby does
  (`"\\\\\\\\"` to produce `\\`), so `quote` is identical in both.
