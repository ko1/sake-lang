# ini

`sakelib/ini.sake` is an INI reader/writer after the inifile gem's `IniFile` (Ruby has no INI library
in its standard library, so the reference is `test/sakelib/ref/ini.rb`). `test/sakelib/ini.sake` prints
the same 72 lines as `ini.rb`. 151 lines, 19 functions.

## API

| Ruby (inifile) | Sake | |
|---|---|---|
| `IniFile.new(content: s, comment:, parameter:, default:, filename:)` | `IniFile.new(content: s, ...)` | same (keywords of `new`; `initialize` parses) |
| `IniFile.load(path, ...)` | `IniFile.load(path, ...)` | same (nil when the file is missing) |
| `ini["sec"]`, `ini["sec"]["k"] = v`, `ini["sec"] = h` | same | same (`include Indexable`) |
| `ini.sections`, `has_section?`, `delete_section`, `to_h`, `match(re)` | `IniFile.sections(ini)`, ... | same |
| `ini.each { \|s, k, v\| }`, `each_section { \|s\| }` | `IniFile.each(ini) { \|s, k, v\| }`, ... | same |
| `ini.merge(other)` | `IniFile.merge(ini, other)` | same |
| `ini.to_s`, `ini.write(filename:)`, `ini.filename=` | `IniFile.to_s(ini)`, `IniFile.write(ini, filename:)`, `IniFile.set_filename` | same |
| `IniFile::Error` | `IniFileError` | differs (no nested names) |
| `merge!`, `encoding:`, `escape:` option, `\` line continuations, `ini.each` without a block | | missing |

Values are typecast as the gem does: `true`/`false`, Integer, Float, otherwise a String; `"quoted"`
values stay Strings and take `\n \t \\ \"` escapes; an inline comment needs a space before `;`/`#`.

## What differs, and why

- `IniFile::Error` → `IniFileError` (no nested names).
- `ini["missing"]` creates and stores an empty section, as the gem's `Hash.new { }` default does; Sake has
  no block default, so `[]` does `@ini[section] ||= Hash[]`.

## Frictions

None cost much: the library and test passed `--strict=1` and `--strict=2` on the first run, and the
outputs were identical on the first run. One choice: Ruby's `Integer("010")` is octal, so both sides use
`String.to_i` for typecasting.

## New language features used

- `T.new` keywords + `initialize`: `IniFile.new(content: text, parameter: ":")`; `initialize` checks
  `@comment => String` and parses the content. Helped: it is exactly the gem's constructor.
- `private attr_reader content = nil, ..., ini = Hash[]`: internal state with expression defaults, each
  `new` gets its own Hash. Helped (no factory function).
- A keyword default reading a field: `def write(ini, filename: @filename)`. Worked as in Ruby.
- `once` for the unescape table; `x => T` for `[]` / `[]=` arguments (Ruby raises on a non-String too).
- `*rest`, `**opts`, `block_given?`, `&b`: not needed.

## Checker findings

`--strict=1 -c` and `--strict=2 -c`: none.

## Types (`--types`)

- `IniFile.filename`, `content`: `nil | String` (optional fields, by design).
- `IniFile.ini`: `Hash[String => Hash[String => true|false | Float | Integer | String]]` (four Hash
  allocation sites listed): the union is the typecast's result, as in the gem.
