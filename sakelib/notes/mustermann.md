# mustermann (Mustermann 3.1.1: the `sinatra` pattern type and `regular`)

`require "mustermann"` → `sakelib/mustermann.sake`. Test: `test/sakelib/mustermann.{sake,rb}` (identical output,
the Ruby side is the real gem): 19 pattern/path pairs (params and `===`), `names`, `match`, `peek_size`, parse
errors. Written for `sinatra.sake`, which compiles every route with it.

## API

| Ruby | Sake | |
|---|---|---|
| `Mustermann.new("/hello/:name")` | `Mustermann.new(s)` → `Mustermann::Sinatra` | same (only the sinatra type; `type:` and the other 15 types missing) |
| `Mustermann.new(%r{...})` | `Mustermann.new(re)` → `Mustermann::Regular` | same |
| `pattern.params(path)`, `match`, `===`, `=~`, `peek_size`, `names`, `to_s`, `to_regexp` | `Mustermann::Pattern.params(m, path)` … (dispatch on either type) | same results; `to_regexp` is a different but equivalent Regexp (no `(?:h\|%68)` alternatives) |
| syntax `:name`, `{name}`, `*`, `*name`, `(...)`, `\|` in a group, `?`, `\x` | same | same params (splat → Array, repeated names → Array, missing optional → nil, values %-unescaped) |
| look-ahead for `/:id(.:format)?` | same | same for an optional group starting with a literal (the common case) |
| percent-encoded literals (`/h%65llo` matches `/hello`) | — | missing: literals match as written |
| `Mustermann::Error` (parent), `CompileError`, `ParseError`, `ExpandError` | a module `Mustermann::Error` and three classes including it | same `rescue Mustermann::Error`; ParseError messages for unbalanced parentheses are Ruby's |
| `expand`, `to_templates`, `|`/`&`/`^` composites, `Mustermann::Router`, `Mapper`, `EqualityMap`, options (`capture:`, `except:`, `greedy:`, `space_matches_plus:`, `uri_decode:`) | — | missing |

## How

Ruby parses the pattern into an AST (`Mustermann::AST::Parser`), transforms it (look-ahead insertion) and
compiles it to a Regexp with named groups (`(?<splat>...)` twice for two splats). The port compiles in one pass
over the characters to a Regexp with positional groups and keeps the capture names in an Array in group order,
so repeated names (two splats) work without Ruby's duplicate named groups. 198 lines (155 code) for the 1012
code lines of the AST, sinatra and regular parts.

## Friction

- `Array.push(list, value) if value != nil || key == "splat"` → `Array.push: argument elem may be nil` — right
  (an optional splat is nil); `if value`.
- `def self.new(pattern)` (Ruby: `Mustermann.new`) → module functions; `module_function` goes after the nested
  classes and the `Pattern` mixin, since it applies to every `def` after it.
- Class names: Ruby's test prints `e.class`; Sake has no class value, so both print `e.inspect` (Sake's
  `Kernel.inspect` of an exception is Ruby's `#<Mustermann::ParseError: ...>`).
