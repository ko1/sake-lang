# jmespath (JMESPath)

`require "jmespath"` → `sakelib/jmespath.sake` (ported from the jmespath gem 1.6.2). Test: `test/sakelib/jmespath.{sake,rb}`
(the same 150 expressions, identical output, including the error messages).

Data are plain JSON values as `JSON.parse` returns them. The lexer, the Pratt parser, every node type
and all 26 built-in functions are ported, with the gem's error classes and messages.

## API

| Ruby | Sake | |
|---|---|---|
| `JMESPath.search(expr, data)` | `JMESPath.search(expr, data)` | same |
| `JMESPath.search(expr, data, disable_visit_errors: true)` | `JMESPath.search(expr, data, Hash[disable_visit_errors: true])` | differs: the options are a Hash (Ruby's are a Hash too, passed as keywords) |
| `... cache_expressions: false` | `Hash[cache_expressions: false]` | same, as above |
| `JMESPath::Runtime.new(opts).search(e, d)` | `JMESPath::Runtime.search(JMESPath.runtime(opts), e, d)` | differs: the Runtime is made by `JMESPath.runtime(opts)` (its field is the parser) |
| `JMESPath::Parser.new.parse(e)` | `JMESPath::Parser.parse(JMESPath::Parser.new, e)` | same (returns a `Nodes::Node`) |
| `JMESPath::CachingParser` | `JMESPath::CachingParser.parse(cp, e)` | same (cache cleared at 1000 entries; no Mutex) |
| `JMESPath::Lexer.new.tokenize(e)` | `JMESPath::Lexer.tokenize(JMESPath::Lexer.new, e)` | same (Array of `Token`) |
| `node.visit(data)` / `node.optimize` | `JMESPath.visit(node, data)` / `JMESPath.optimize(node)` | differs: functions of the module, not of each node class |
| `JMESPath::Util.falsey?(v)` | `JMESPath::Util.falsey?(v)` | same for JSON values |
| `JMESPath::Errors::SyntaxError` & co. | same names | same, but no `Errors::Error` parent (see below) |
| `JMESPath.search(e, Pathname / IO)` | — | missing: data must already be parsed |
| Struct data (`value.respond_to?(@key)`) | — | missing: no reflection |

Functions: abs avg ceil contains floor length map max min type keys values join to_string to_number sum
not_null sort sort_by max_by min_by ends_with starts_with merge reverse to_array (all 26).

## What differs and why

- **Nodes are one class.** Ruby has ~25 node classes, each with `visit` and `optimize`. Here
  `Nodes::Node` has a `kind` (`:field`, `:subexpression`, `:array_projection`, ... named after Ruby's
  class) and fields `left right children key value name keys nums quiet`; `JMESPath.visit` is one
  `case` on the kind. Every node is made by `Nodes.node(kind, ...)`, so the checker sees a single Node
  type (each `Node.new` site would otherwise be its own type, and a tree mixes them).
- **Dispatch.** Ruby's parser calls `send("nud_#{type}")` / `send("led_#{type}")` and turns
  `method_missing` into "unexpected token X"; here `nud` and `led` are `case`s with that error in `else`.
  Function classes registered in `FUNCTIONS` become one `case` on the name in `Function.call`.
- **optimize.** Ruby's optimizer builds ChainedField, Chain, Fast*Projection and *Condition nodes that
  give the same results; only `Slice → SimpleSlice` changes a result (`a[5:9]` on a 3-element array is
  `nil`, not `[]`, because SimpleSlice uses `value[start, len]`). That rewrite alone is ported, so
  results match the gem.
- **Duck typing** (`respond_to?(:to_ary)`, `:to_hash`, `:to_str`, `Numeric ===`) is `case v in Array /
  Hash / String / Integer | Float`. Struct and other Enumerable data are not handled.
- **Comparisons** (`>`, `max`, `sort`) on values of a union type go through `greater?`, which narrows
  both sides with `=>`; `sort`/`sort_by` sort an index Array by `[key, i]` with the keys narrowed to
  String or number first, because `Array.sort_by` rejects keys that are not comparable with each other.
- **Error hierarchy.** `rescue JMESPath::Errors::Error` (the parent) is not possible: Sake's exception
  classes have no hierarchy; rescue the specific classes. `Errors::RuntimeError` (never raised by the gem)
  is left out.
- **TYPE constants.** `TypeChecker`'s integer constants appear in messages ("type mismatch in sequence: 4,
  6"); here `get_type` returns the type's name and `type_number` gives Ruby's number for those messages.

## Built-ins Sake lacks

- A class hierarchy for exceptions (to rescue `Errors::Error`).
- `Set.new(array)`: Ruby's spelling; Sake has `Array.to_set` / `Set[...]`, but the hint for `Set.new` lists
  every other `new` and not these.

## Friction

- `Set.new(String.chars("..."))` → `undefined function Set.new` (the hint lists 40 `new`s) →
  `Array.to_set(String.chars("..."))`.
- A `private` line before the private methods → `only def, include, ... are allowed in a class/module
  body` → removed it; the helper functions are public.
- `TokenStream#initialize` calls `next`, which sets `@token` → 12 errors `Token.type: argument 1 may be
  nil` at every `Token.type(TokenStream.token(stream))`, since a field not given to `new` is nil until
  `initialize` writes it, and the checker keeps that nil → a constructor function `TokenStream.start(e,
  tokens)` that passes `Token.null_token` to `new`.
- 13 `Token.new` sites listed in each message (`Token@L76#1 | Token@L80#1 | ...`) → one `Token.make`.
- What went well: the interpreter part (values are JSON values of a union type) passed the checker on
  the first run, and the test matched Ruby on the first full run. The only real cost is checking time:
  about 15 s of CPU for the test, nearly all in the checker.

## Size

The gem's Ruby: 2033 lines (lib, without comments and blank lines; ~90 of them the lexer's character
table). Sake: 925 lines (1072 with comments).
