# erb

Ruby's ERB compiles a template into Ruby source and `eval`s it. Sake has no `eval` and no
`binding` (both are rejected by design: every call target is known before running), so Sake's ERB
is an **interpreter for a small template language whose syntax is a subset of Ruby's**: a template
written within the subset renders the same in Ruby (with `result_with_hash` and `include ERB::Util`)
and in Sake. `test/sakelib/erb.sake` and `erb.rb` render the same templates with the same data and
print identical output (including all three trim modes).

```ruby
require "erb"
erb = ERB.new("<% items.each do |it| %>- <%= h(it[:name]) %>\n<% end %>")
ERB.result_with_hash(erb, Hash[items: Array[Hash[name: "<a>"]]])   # "- &lt;a&gt;\n"
```

## What a template may contain

Tags: `<%= expr %>` (output, with `to_s`), `<% stmt %>`, `<%# comment %>`, `<%%` (a literal `<%`),
and `%%>` inside a tag (a literal `%>`). Trim modes: `"-"` (`<%-` drops the indentation before it
at the start of a line; `-%>` drops the newline after it), `">"` (every tag's following newline is
dropped), `"<>"` (the newline is dropped when the line started with a tag). Ruby's `"%"` mode
(`%`-lines) is missing.

Statements:

| Statement | Meaning |
|---|---|
| `if e`, `elsif e`, `else`, `end` | as Ruby (truthiness as Ruby: only nil and false are falsy) |
| `unless e` ... `else` ... `end` | as Ruby |
| `e.each do \|x\|` ... `end` | over an Array; over a Hash, `\|k, v\|`; with two names over an Array, each element (Tuple/Array) is taken apart, as Ruby's blocks do |
| `e.each_with_index do \|x, i\|` ... `end` | as Ruby |
| `e.each { \|x\| ... }` | `{ \|x\|` ... `}` works too |

Loop variables are visible only inside their loop, as Ruby's block parameters.

Expressions:

| Expression | Meaning |
|---|---|
| `name` | the value of `:name` in the Hash given to `result_with_hash` (or a loop variable) |
| `e[:sym]`, `e["str"]`, `e[3]`, `e[-1]` | Hash lookup, Array/String index |
| `e.size`, `length`, `count`, `empty?`, `any?`, `first`, `last`, `keys`, `values`, `join("sep")`, `upcase`, `downcase`, `capitalize`, `strip`, `reverse`, `sort`, `to_s`, `inspect`, `nil?` | the operation of the value's type (String, Array, Hash) |
| `h(e)`, `html_escape(e)`, `u(e)`, `url_encode(e)` (also with `ERB::Util.`) | ERB::Util's escaping |
| `"text"`, `'text'`, `42`, `-1`, `nil`, `true`, `false` | literals (no escapes or `#{}` inside strings) |
| `!e`, `a == b`, `!=`, `<`, `<=`, `>`, `>=`, `a && b`, `a \|\| b` | as Ruby; `<` and friends on two numbers or two Strings |

Anything else (assignments, other method calls, method calls with blocks other than `each`,
arithmetic, `case`, `while`, string interpolation, calling your own functions) is an `ERBError`
(`unsupported code in template: ...` / `unsupported expression in template: ...`). Compute such
values in the program and pass them in the Hash.

## API

| Ruby | Sake | |
|---|---|---|
| `ERB.new(str)` | `ERB.new(str)` | same |
| `ERB.new(str, trim_mode: "-")` (`">"`, `"<>"`) | `ERB.new(str, "-")` | differs: positional (Sake has no keyword arguments; the field has a default) |
| `erb.result_with_hash(hash)` | `ERB.result_with_hash(erb, hash)` | same for templates within the subset; keys are Symbols |
| `erb.result(binding)`, `erb.run` | — | missing: no `binding` in Sake (by design) |
| `erb.src` | `ERB.src(erb)` | differs: gives the template text (Ruby: the generated Ruby code) |
| — | `ERB.check(erb)` | Sake only: parses the template without rendering it (raises `ERBError`) |
| `ERB::Util.h(s)`, `html_escape` | `ERB.h(s)`, `ERB.html_escape(s)` | same output (no nested `ERB::Util` namespace) |
| `ERB::Util.u(s)`, `url_encode` | `ERB.u(s)`, `ERB.url_encode(s)` | same output |
| `erb.def_method`, `def_class`, `ERB::DefMethod`, `ERB.version`, `erb.filename=`, `lineno=`, `location=`, `encoding` | — | missing: they define Ruby methods from the compiled source |
| `NameError`, `NoMethodError`, `SyntaxError` from a template | `ERBError` | differs: one exception type with a message |

## Differences and why

- **No embedded code, only the subset above.** This is the one big difference, and it is forced
  by Sake's rules (no `eval`, no `send`, no reflection). The subset was chosen so that a template is
  still valid ERB: a Sake template renders the same in Ruby, so moving one way is free; moving from
  Ruby to Sake means rewriting any code that is outside the subset into values in the Hash.
- **Dispatch on values happens inside the library.** `<%= x.size %>` must find `size` at render
  time from the value's type; the library does it with `case v in String ... in Array ... in Hash`,
  and so the set of methods is closed (listed above). A Struct value in the data can be printed
  (`to_s`) but its fields cannot be read from the template (no reflection): pass a Hash instead.
- **Errors at render time.** As in Ruby, a broken template is reported when it is rendered (Ruby's
  `SyntaxError` comes from evaluating the generated code); Sake parses at every `result_with_hash`
  call, and `ERB.check` parses without rendering. Parsing is not cached: a field holding the parsed tree would make the
  ERB value's type depend on parsing, and the template is short.
- **Not type-checked.** Template expressions are text, so `--strict` checks nothing inside them;
  each is checked while rendering. This is the price of templates as data.

## Built-ins Sake lacks (requests)

- None strictly needed. A `String.index(s, t, pos)` with an offset, or `StringScanner` as a built-in,
  would make the tag scanner simpler; I split the template with a capturing Regexp instead.

## Friction

- `String[e, i, n]` for a substring (I meant `e[i, n]`) → `String[]: element 3 must be String, got
  Integer` (it is the typed-Array constructor) → `e[i, n]`. Easy to write by analogy with
  `String.size(e)`.
- `unless ((a in Integer) || (a in Float)) && ...` then `a < b` → `Comparable.<: the operands may
  be (true|false, ...)` (no narrowing through `||` of `in`, and the union was every type in the
  data) → nested `case a in Integer | Float ... case b in ...`.
- `a <=> b` then `c < 0` → `the operands may be nil`, with a hint that `ERB.trim_mode may be nil`
  (unrelated field) → `return _order(op, c) if c`.
- `String.to_s(m[2])` → level 3 `index-nil` report → `"#{m[2]}"`.
- In a test, `"... <%= x.join(", ") %> ..."` inside a double-quoted Sake string ends the string —
  my mistake, but templates are easiest as `<<~T` heredocs (which Sake supports).
- Splitting with a capturing Regexp gives `""` between adjacent tags (as in Ruby); the newline
  trimming first missed `-%>` followed by `\n` because of it → `Array.reject(...) { |t| t == "" }`.
