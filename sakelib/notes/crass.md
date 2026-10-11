# crass

`require "crass"` → `sakelib/crass.sake`, after the crass gem 1.0.7 (CSS Syntax Module Level 3 tokenizer
and parser). Test: `test/sakelib/crass.{sake,rb}`, 160 identical lines (tokens of every kind, a stylesheet,
style attributes, comments, the IE hack, nesting depth, the Parser's instance methods, preprocessing).

The node tree is Ruby's: every token and node is a Hash with Symbol keys (`{node: :ident, pos: 0, raw:
"a", value: "a"}`), so `p(Crass.parse(css))` prints exactly what Ruby prints. The values are one recursive
union (Symbol, String, Integer, Float, true/false, an Array of nodes, a node), so a reader narrows:
`sel = node[:selector]; sel => Hash`. Ruby's code reads the same Hashes without the narrowing line.

## API

| Ruby | Sake | |
|---|---|---|
| `Crass.parse(css, opts = {})` | `Crass.parse(css, Hash[:preserve_comments => true])` | same; options are a Hash (no keyword arguments at call sites) |
| `Crass.parse_properties(css, opts)` | `Crass.parse_properties(css, opts)` | same |
| `Crass::Tokenizer.tokenize(css, opts)` | `Crass::Tokenizer.tokenize(css, opts)` | same |
| `Crass::Tokenizer.new(css, opts).tokenize` | `Crass::Tokenizer.run(Crass::Tokenizer.new(css, opts))` | differs: name (one name is one function; `tokenize` is the class method) |
| `Crass::Parser.parse_stylesheet` / `parse_rules` / `parse_properties` | same names | same |
| `Crass::Parser.stringify(nodes, exclude_comments: true)` | `Crass::Parser.stringify(nodes, Hash[:exclude_comments => true])` | same |
| `parser.parse_rule` / `parse_declaration` / `parse_component_value` / `parse_component_values` / `parse_declarations(input, strict: true)` | `Crass::Parser.parse_rule(parser, input = nil)` / ... | same; `input` nil means the parser's own tokens (Ruby's default `@tokens`), or a TokenScanner, or an Array of tokens |
| `parser.parse_properties(input)` | `Crass::Parser.properties(parser, input)` | differs: name (the class method has Ruby's name) |
| `parser.parse_value(nodes)`, `consume_*`, `create_node`, `create_selector`, `create_style_rule` | `Crass::Parser.parse_value(parser, nodes)`, ... | same (public in Ruby too) |
| `Crass::Scanner` (`consume peek mark marked reconsume scan scan_until consume_rest eos? reset current marker pos string`) | same, as operations | same; `scan` patterns must start with `\G` (see below) |
| `Crass::TokenScanner` (`collect consume peek reconsume reset current pos tokens`) | same | same |
| `Parser::DEFAULT_MAXIMUM_DEPTH`, `BLOCK_END_TOKENS`, `Tokenizer::RE_*` | `Parser.default_maximum_depth`, `block_end(sym)`, `Tokenizer.re_name`, ... | differs: no value constants in Sake, they are functions |
| `Crass::Parser.new(tokens)` with an Enumerable that is not an Array | — | missing (an Array of tokens works) |
| `Crass.parse(io)` (Scanner reads an IO) | — | missing: pass `IO.read(io)` |

About 31 operations (16 public entry points, 15 Scanner/TokenScanner operations).

## What differs and why

- **Options Hash.** Ruby's `options[:preserve_comments]` reads a keyword Hash; Sake takes a `Hash[Symbol =>
  true | Integer]` positionally (the brief's convention). An unknown key is ignored, as Ruby.
- **Scanner.** Ruby wraps a StringScanner and keeps byte and character positions; here positions are
  characters and `scan` is `Regexp.match(re, s, pos)` with patterns written `\G...` (Ruby's StringScanner
  anchors implicitly). `reconsume` steps one character back, which is what the tokenizer relies on.
- **convert_string_to_number** computes the spec's formula exactly with Rationals (`10r ** -d`), as Ruby's
  `10**-d` does (Ruby gives a Rational for a negative Integer power; Sake raises for `10 ** -2`).
  `Float::MAX_10_EXP` is written as 308.
- **Codepoints from escapes** are `Array.pack(Array[cp], "U")` (Ruby: `cp.chr(Encoding::UTF_8)`).
- **Preprocessing** does not re-encode invalid UTF-8 (`encode(..., invalid: :replace)`); Sake's Strings are
  valid UTF-8 already.
- `consume_component_value` returns nil at the end, as Ruby; where Ruby trusts that a value follows (the
  prelude, a declaration's value, a block's value), the port calls `component`, which asserts `=> Hash`,
  so the node Arrays do not hold nil in their type.

## Built-ins Sake lacks (requests)

- `Integer.chr(cp, "UTF-8")` (an encoding argument): `Integer.chr(9786)` raises RangeError.
- `Integer ** negative Integer` giving a Rational, as Ruby (Sake: ArgumentError with a hint to write `10r`).
- `Hash.fetch(h, k) { }` with a block (Ruby's lazy default).

## Friction (what I wrote → the message → what I wrote instead)

- `@maximum_depth = md in Integer ? md : 25` → `syntax error: unexpected '?'` with the hint `` `x in T` needs
  its own parentheses `` → `(md in Integer) ? md : ...`. The hint was exact.
- `module Crass` with `def parse` and no `module_function` → `Crass.parse is a mixin function, and no type
  includes Crass` (hint: mark it `module_function`) → added it. Exact.
- `def initialize(sc) ... reset(sc) end` setting the fields in `reset` → every later read was `the operands may
  be nil`, `Crass::Scanner.pos may be nil (nil is stored at line 142)` (line 142: the `Scanner.new` call that
  leaves the fields out) → wrote the assignments in `initialize` itself. A field set by a function that
  initialize calls is not seen as initialized.
- Pushing `consume_component_value(...)` (nil at the end) into node Arrays → errors far away in `node_s`:
  `Indexable.[]: the operands may be nil (nil | Hash@L530#42[...] | Hash@L530#43[...] | ...)`. The message
  lists ~40 Hash site types (one per `create_token` call) and is cut off; the nil itself was the point →
  `component(ps, input)` with `v => Hash`.
- `10 ** -d` → runtime `ArgumentError: Integer ** negative Integer ... write 10r ** -2` → `10r ** -d`. Clear,
  but only at run time, on the first CSS number with a fraction.
- `Integer.chr(codepoint)` → runtime `RangeError: Integer.chr: 9786 out of char range` →
  `Array.pack(Array[cp], "U")`.
- What went well: the whole tree as Symbol-keyed Hashes of a recursive union type-checked, and the test's
  first run printed Ruby's 160 lines, including the full `p` of a tree. `case char in "\"" | "'"` reads like
  Ruby's `case char.to_sym when`. The cost is the narrowing lines (`sel => Hash`) a reader writes.

## Size

Ruby: 1684 lines (lib/crass.rb + crass/*.rb; 1017 without comments and blank lines).
Sake: 1017 lines (889 without comments and blank lines).
