# uri

`require "uri"` loads `sakelib/uri.sake`. Parsing follows Ruby's `URI::RFC3986_Parser` (its regular
expressions are copied), reference resolution follows `URI::Generic#merge` (Ruby's RFC 2396-style
`merge_path`, kept as is so that results are the same, including the RFC 3986 §5.4 examples), and
form encoding follows `uri/common.rb`. Test: `test/sakelib/uri.sake` / `uri.rb` (identical output,
including all 41 RFC 3986 §5.4 references).

## The type

Ruby's `URI::Generic`, `URI::HTTP`, `URI::HTTPS`, `URI::FTP`, `URI::File`, `URI::MailTo`, `URI::WS`,
... are one Sake type, `URI`:

```ruby
class URI
  attr_reader scheme, userinfo, opaque
  attr_accessor host, port, path, query, fragment
```

The scheme decides the default port (http/ws 80, https/wss 443, ftp 21, ldap 389, ldaps 636) and the
class name that `inspect` prints (`#<URI::HTTP http://...>`, as Ruby). Sake has no subclasses, and
the differences between Ruby's classes are small enough to be a `case` on the scheme.
Field order for `URI.new` is scheme, userinfo, opaque, host, port, path, query, fragment (use
`URI.parse` instead).

## API

| Ruby | Sake | |
|---|---|---|
| `URI.parse(s)` | `URI.parse(s)` | same (scheme lower-cased; port Integer, the default when absent or empty; `path` nil only for an opaque URI) |
| `URI(s)` | — | missing: a function cannot be named like a type |
| `URI::InvalidURIError` | `InvalidURIError` | differs: no nested names; same messages (`bad URI (is not URI?): "..."`, `URI must be ascii only "..."` with Ruby's `dump` form) |
| `URI::BadURIError` | `BadURIError` | differs: name (`both URI are relative`) |
| `u.scheme`, `userinfo`, `user`, `password`, `host`, `hostname`, `port`, `path`, `opaque`, `query`, `fragment` | `URI.scheme(u)` ... (also `URI.get_x(u)`) | same |
| `u.host = v`, `port=`, `path=`, `query=`, `fragment=` | `URI.set_host(u, v)` ... | differs: no validation of the new value (Ruby checks it against the grammar); `port` must be an Integer |
| `u.scheme=`, `userinfo=`, `user=`, `password=`, `opaque=` | — | missing (reader fields) |
| `u.to_s`, `"#{u}"`, `puts u` | `URI.to_s(u)`, `"#{u}"`, `puts(u)` | same (default port omitted) |
| `u.inspect`, `p u` | `URI.inspect(u)`, `p(u)` | same |
| `u.absolute?`, `u.relative?` | `URI.absolute?(u)`, `URI.relative?(u)` | same |
| `u.request_uri` | `URI.request_uri(u)` | differs: available for every scheme (Ruby: HTTP/HTTPS only) |
| `u.default_port` | `URI.default_port(u)` | same |
| `u.merge(ref)`, `u + ref` | `URI.merge(u, ref)`, `u + ref` | same; `ref` is a String or a URI |
| `URI.join(base, ref, ...)` | `URI.join(base, ref, ...)` | same for one base and up to three references (optional parameters; Sake has no rest parameters); nest for more (`base` may be a URI) |
| `u.normalize` | `URI.normalize(u)` | same (host lower-cased, empty path → "/") |
| `u == v` | `u == v` | differs: Sake compares the fields as they are; Ruby compares normalized forms (so `http://H` == `http://h/` in Ruby only) |
| `u.dup` | `URI.dup(u)` | same |
| `URI.split(s)` | `URI.split(s)` | same (9 elements, Strings or nil; a Tuple instead of an Array) |
| `URI.encode_www_form(enum)` | `URI.encode_www_form(form)` | same; `form` is a Hash or an Array of `[k, v]`; nil value → key alone; Array value → repeated key (a nil inside it gives an empty part, as Ruby) |
| `URI.decode_www_form(s)`, `decode_www_form(s, enc)` | same | same, but returns an Array of `[k, v]` Tuples; invalid UTF-8 is not scrubbed (see requests); `enc` is an encoding name |
| `URI.encode_www_form_component(s)` | same | same (`*-._` and alphanumerics kept, space → `+`) |
| `URI.decode_www_form_component(s)`, `(s, enc)` | same | same (`ArgumentError: invalid %-encoding (s)`); `enc` is an encoding name (default `"UTF-8"`) |
| `URI.encode_uri_component(s)`, `decode_uri_component(s)`, `(s, enc)` | same | same (space ↔ `%20`) |
| `encode_www_form(enum, enc)`, `encode_www_form_component(s, enc)` | — | missing: converting to another encoding (Sake has no `String#encode`) |
| `decode_www_form(s, enc, separator: ";")` | `URI.decode_www_form(s, enc, separator: ";")` | same |
| `decode_www_form(s, enc, use__charset_:, isindex:)` | — | missing |
| `URI::HTTP.build(host: ..., path: ...)` | — | missing: Ruby's argument is a Hash (not keywords), and `URI::HTTP` cannot be named; use `URI.parse("http://#{host}#{path}")` |
| `u.route_to`, `route_from`, `URI.extract`, `URI.regexp`, `URI.open`, `URI.for`, `URI.register_scheme`, `find_proxy`, `hierarchical?`, `select`, `component` | — | missing (rarely used; `register_scheme` needs classes as values) |
| `URI::MailTo#to`, `headers`; `URI::FTP#typecode`; `URI::LDAP#dn` ...; `URI::File` host rules | — | missing: scheme-specific parts. FTP's path drops its leading "/" as Ruby's does. MailTo is not validated (Ruby raises `InvalidComponentError` for a bad address) |

Helpers whose names start with `_` (`URI._new`, `URI._merge_path`, ...) are internal; Sake has no
private functions.

## Differences and why

- **One type for all schemes**: no inheritance in Sake; `inspect` reproduces Ruby's class names.
- **Exceptions are not nested** (`InvalidURIError`): Sake rejects `A::B`.
- **Setters do not validate**; Ruby's check each component against the grammar. Easy to add later
  (one function per field with the regex), skipped for time.
- **Equality** is Struct equality, not normalized equality: defining `==` on URI would also forbid
  URIs as Hash keys (spec §12.1), which seemed the worse trade.

## Built-ins Sake lacks (requests)

- `String.dump(s)`: Ruby's error message for a non-ASCII URI uses it; `URI._dump` builds it as
  `inspect` plus a `gsub` block for non-ASCII characters (UTF-8 only).
- `String.scrub(s)`: `decode_www_form` scrubs invalid bytes in Ruby; not done here.
- Rest parameters (`def join(*refs)`), for Ruby's `URI.join(*str)`.

## Friction

- Adjacent literals with interpolation: `"(?<a>#{x})" "(?<b>...)"` (Ruby's implicit
  concatenation across lines with `\`) → `unsupported part of an interpolated literal` → joined
  with `+`. Adjacent plain literals work.
- Field order: I wrote `class URI < {reader: [scheme, userinfo, opaque], accessor: [host, ...]}` and
  called `URI.new(scheme, userinfo, host, port, path, opaque, ...)` (Ruby's order). Fields are
  ordered by first appearance across `reader:`/`accessor:`, so `opaque` came third. The checker
  caught it, but as distant reports (`Array.push: an element must be String, but can be Integer`
  in `to_s`, `Integer.to_s: argument 1 must be Integer, but can be String`) → reordered every
  `URI.new` call and wrote the order down. A static check that a struct's field gets values of
  several unrelated types at `new` sites, or naming fields at `new`, would point at the cause.
- `rel = other` then `rel = parse(other) if other in String` → `URI.get_scheme: argument 1 must be
  URI, but can be String` (the reassigned local keeps the union) → a helper with `case x in String
  then parse(x) in URI then x end`.
- `while !Array.empty?(tmp)` + `x = Array.shift(tmp)` → nil report on `x` (plus hints naming all
  eight URI fields as "may be nil", which were unrelated) → `x = Array.shift(tmp); while x ... end`.
- Absolute `require "/path/x"` is joined to the requiring file's directory unless that file is in
  the current directory (`bin/sake dir/f.sake` → `cannot read dir/path/x.sake`). Repro: `sakelib/notes/uri_bug_absolute_require.sake`.

## Phase 2

- `URI.join(base, r1 = nil, r2 = nil, r3 = nil)`: Ruby's several references, up to three (the test
  now calls `URI.join(a, b, c)` and `URI.join(a, b, c, d)` as `uri.rb` does, and `URI.join(a)`).
- Restored the optional encoding: `decode_www_form_component(s, enc = "UTF-8")`,
  `decode_uri_component(s, enc = "UTF-8")`, `decode_www_form(s, enc = "UTF-8")`; tested with
  `"ASCII-8BIT"`.
- Tables with `once`: the two RFC 3986 Regexps (`_absolute_re`, `_relative_re`) were built with
  `Regexp.new` from strings on every parse; now once. Ruby's `TBLENCWWWCOMP_` / `TBLENCURICOMP_`
  (256 entries each) are built once and used with `String.gsub(String.b(s), re, table)`, as
  `uri/common.rb` does; decoding is a `gsub` block over runs of `%XX`. `_dump` is a `gsub` block
  instead of a loop over characters. The test gained `http://h/😀\u0085` for it.
- Speed (`phase2/bench_uri.sake`: parse + merge + to_s of 300 URIs, encode/decode a 300-pair form;
  CPU s of the whole `bin/sake --strict` run, 3 runs, load about 37 on 16 cores): before
  2.58 / 2.64 / 2.58, after 1.57 / 1.51 / 1.64.

## Keyword arguments

- `decode_www_form(s, enc = "UTF-8", separator: "&")` takes Ruby's `separator:` keyword after the
  optional encoding. New test cases: `separator: ";"` (empty pairs and a trailing separator, as
  Ruby), `"&"` not splitting under `";"`, and `enc` with `separator:` together. A misspelled
  keyword is a static error: `URI.decode_www_form(s, sep: ";")` → `error: URI.decode_www_form has
  no keyword parameter `sep``.
