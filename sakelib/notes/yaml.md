# yaml

`sakelib/yaml.sake` is a useful subset of Ruby's YAML (Psych 5.4): `YAML.load`, `safe_load`,
`load_file`, `dump`. The test is compared with Ruby's own `yaml`: `test/sakelib/yaml.sake` prints the
same 172 lines as `yaml.rb` (loading 40 documents, 9 malformed ones, and dumping 70 kinds of String
through Psych's choice of quoting). 626 lines, 45 functions.

## API

| Ruby (Psych) | Sake | |
|---|---|---|
| `YAML.load(s)`, `(s, symbolize_names: true)` | `YAML.load(s)`, `(s, symbolize_names: true)` | same for the subset below |
| `YAML.safe_load(s, symbolize_names:)` | `YAML.safe_load(s, symbolize_names:)` | same (nothing is ever revived as an object) |
| `YAML.load_file(path, symbolize_names:)` | `YAML.load_file(path, symbolize_names:)` | same |
| `YAML.dump(obj)`, `YAML.dump(obj, io)` | `YAML.dump(obj)`, `YAML.dump(obj, io)` | same for nil, booleans, numbers, Strings, Symbols, Arrays, Hashes |
| `obj.to_yaml` | `Hash.to_yaml(h)`, `Array.to_yaml(a)` | differs (one per type, as json's `to_json`) |
| `Psych::SyntaxError` (`YAML::SyntaxError` too, YAML being Psych) | `YAML::SyntaxError` | same name (nested in `module YAML` since 2026-10-10; was `YAMLSyntaxError`); messages are this port's own, with the line |
| `permitted_classes:`, `aliases:`, `load_stream`, `parse` (AST), `YAML::Store`, `dump` options | | missing |

Loading: block mappings and sequences (including `key:` followed by `- item` at the same indentation,
`- key: v` items, `- - x`), flow `[...]` and `{...}` (also over several lines, `[k: v]`, `{a, b: 1}`),
plain scalars over several lines, single- and double-quoted scalars (all of YAML's escapes, folding of
line breaks), literal `|` and folded `>` block scalars with `-`/`+` chomping and an indentation
indicator, comments, `%` directives, `---` and `...`, `!!str`. Scalars resolve as Psych's
ScalarScanner does: `yes/no/on/off` booleans, `012` octal, `0x1F`, `0b101`, `1_000`, `1:20` (Psych's
sexagesimal, `1 * 3600 + 20 * 60`), `.inf/.nan`, `1.`, `.5`; `1e3`, `0o17` stay Strings.

Dumping follows Psych's `visit_String` and libyaml's check for plain scalars: `'123'`, `'true'`, `''`,
`"y"`, `"-1"`, `"#"`, `'a: b'`, `'x #'`, `"a\tb"`, `!!str '<<'`, `|-` / `|` / `|+` for multi-line text,
`[]`, `{}`, `:sym`, `.inf`, `1.0e+20`, and the indentation of nested sequences and mappings.

## What differs, and why

- Not supported: anchors and aliases (`&a`, `*a`), tags other than `!!str`, complex keys (`? `),
  several documents, dates (Psych makes a Date, or refuses one in `safe_load`; here a String), numbers
  with commas. Dumping objects other than the plain values raises `ArgumentError` (Psych dumps a Range
  as `!ruby/range`); a String longer than the line width is not folded; text whose only line breaks are
  trailing (`"x\n"`) and multi-line text with a leading space are quoted differently from Psych.
- Error messages are this port's own: libyaml's (`did not find expected ',' or ']' while parsing a flow
  sequence at line 1 column 4`) come from its state machine, which this line-based parser does not
  have. The test prints only that a `SyntaxError` was raised. libyaml accepts `[1, 2]]` (ignoring the
  extra `]`); this parser rejects it.
- `Psych::SyntaxError` → `YAML::SyntaxError`, as Ruby's alias spells it (nested since 2026-10-10; was `YAMLSyntaxError`). The parser is `YAML::Parser` (was `YAMLParser`).

## Frictions

1. `s, rest = quoted(yp, src)` after `while quoted(yp, src) == nil ... end` → `multiple assignment:
   argument 1 may be nil (nil | [String, String]) [nil]` (the loop condition is a call, not a local) →
   keep the result in `r`, loop `while r == nil`, then `r => Tuple`.
2. The `---` line: rewriting it as indented content broke block scalars on it (`--- |`); the
   document's first line is now the text after `---`, at indentation 0.
3. Psych's clip chomping keeps the last line break only when the source has one; splitting the source
   into lines lost that → a `final_newline` field.
4. No Psych quirk could be guessed: `1:20` is 4800, `-1:00:01` is -3599, `[1, 2]]` loads; each came from
   running Ruby.

## New language features used

- `T.new` with `initialize`: `YAML::Parser.new(lines, symbolize_names, final_newline)`; `initialize`
  checks `@lines => Array`. `private attr_accessor i = 0, fsrc = "", fpos = 0` for the cursor state.
- Keyword arguments `symbolize_names:` passed on with the `k:` shorthand (`load_file`, `safe_load`);
  optional positional `dump(v, io = nil)`.
- `once` for the boolean, escape and double-quote tables.
- `x => T`: `s => String` in `load` (Psych raises on a non-String), `r => Tuple` (friction 1).
- `*rest`, `**opts`, `block_given?`: not needed.

## Checker findings

- `--strict=1`: none.
- `--strict=2`: the `nil` report of friction 1.

## Types (`--types`)

- `YAML::Parser.lines`: three Array allocation sites of String (the field is replaced by
  `Array.first` when a document ends with `...`).
- The loaded value is the recursive union `true|false | Float | nil | Integer | String | Array[...] |
  Hash[...]`, with `Symbol` in Hash keys from `symbolize_names:`; one `partial` check remains, the
  test's `back => Hash`.
