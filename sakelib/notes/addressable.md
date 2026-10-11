# addressable (Addressable::URI, Addressable::Template, Addressable::IDNA)

`require "addressable"` → `sakelib/addressable.sake` (it requires `public_suffix` for `tld`/`domain`).
Test: `test/sakelib/addressable.{sake,rb}` (identical output; the .rb uses the addressable 2.9.0 gem).

`Addressable::URI` is a class with the eight components as fields; every Ruby instance method is an
operation with the URI first, and every setter `x=` is `set_x` with Ruby's validation. Ruby's
constants (`CharacterClasses::UNRESERVED`, `Template::EXPRESSION`, ...) are functions of the same names
(`Addressable::URI::CharacterClasses.UNRESERVED`), since Sake constants hold only types.

## API

| Ruby | Sake | |
|---|---|---|
| `URI.parse(s)` / `URI.parse(uri)` | `Addressable::URI.parse(s)` | same (no `nil` → `nil`, no `to_str` objects) |
| `URI.heuristic_parse(s, hints)` | `URI.heuristic_parse(s, Hash[:scheme => "https"])` | same |
| `URI.convert_path(path)` | `URI.convert_path(path)` | same |
| `URI.join(*uris)` / `uri.join(other)` / `uri + other` | `URI.join(base, *uris)` / `base + other` | same; one function for both (see below) |
| `uri.join!(other)` | `URI.join!(u, other)` | same |
| `URI.new(scheme: .., host: .., ...)` | `URI.new(scheme: .., host: .., ...)` | same for the eight components; `authority:`, `userinfo:`, `query_values:` are not fields: use the setters |
| `scheme user password host port path query fragment` | `URI.scheme(u)` ... | same (`port` is Integer or nil) |
| `userinfo authority site origin hostname request_uri` | `URI.userinfo(u)` ... | same |
| `basename extname inferred_port default_port` | `URI.basename(u)` ... | same |
| `normalized_scheme/user/password/userinfo/host/port/authority/site/path/fragment` | `URI.normalized_host(u)` ... | same (recomputed; Ruby caches) |
| `normalized_query(*flags)` | `URI.normalized_query(u, :compacted, :sorted)` | same (Ruby caches the first call's result whatever the flags) |
| `x = v` for each component and `userinfo= authority= site= origin= hostname= request_uri=` | `URI.set_x(u, v)` | differs: name; `set_port` takes a String or an Integer |
| `query_values` / `query_values(Array)` | `URI.query_values(u)` / `URI.query_values_array(u)` | differs: no class values to pass |
| `query_values = hash_or_pairs` | `URI.set_query_values(u, Hash[...] / Array[[k, v]])` | same (Hash sorted by key, as Ruby) |
| `normalize` / `normalize!` | `URI.normalize(u)` / `normalize!` | same (IDN hosts to punycode) |
| `display_uri` | `URI.display_uri(u)` | same |
| `merge(hash)` / `merge!(hash)` | `URI.merge(u, Hash[:path => "/x"])` / `merge!` | same, including the ArgumentErrors and TypeError |
| `route_from(uri)` / `route_to(uri)` | `URI.route_from(u, other)` / `route_to` | same |
| `omit(*components)` / `omit!` | `URI.omit(u, :port, ...)` / `omit!` | same |
| `==` `eql?` `===` | `a == b`, `URI.eql?(a, b)`, `URI.===(a, b)` | same |
| `absolute? relative? ip_based? empty?` | `URI.absolute?(u)` ... | same |
| `to_s` / `to_str` / `to_hash` | `URI.to_s(u)` / `to_str` / `to_hash` | same |
| `dup` | `URI.dup(u)` | same |
| `inspect` | `Kernel.inspect(u)` | differs: no object id (`#<Addressable::URI URI:...>`) |
| `tld` / `tld=` / `domain` | `URI.tld(u)` / `URI.set_tld(u, s)` / `URI.domain(u)` | same (via sakelib/public_suffix) |
| `defer_validation { }` | `URI.defer_validation(u) { }` | same |
| `URI.encode_component(s, cc, upcase)` / `escape_component` | same names | same; `cc` is a Regexp or a class body String |
| `URI.unencode(s, return_type, leave)` / `unescape` / `unencode_component` / `unescape_component` | `URI.unencode(s, leave)` | differs: no `return_type` (always a String; `URI.parse` it) |
| `URI.normalize_component(s, cc, leave)` | same | same |
| `URI.encode(s, return_type)` / `escape` / `normalized_encode` | `URI.encode(s)` / ... | differs: no `return_type` (a String) |
| `URI.form_encode(h_or_pairs, sort)` / `form_unencode(s)` | same | same |
| `URI.port_mapping` / `URI.ip_based_schemes` | same | same |
| `encode_with` / `init_with` (YAML), `freeze`, `hash` | — | missing: no YAML coder, no freezing, no hash protocol |
| `Template.new(pattern)` | `Addressable::Template.new(pattern)` | same |
| `t.expand(mapping, processor, normalize)` | `Template.expand(t, mapping, normalize)` | differs: no processor |
| `t.partial_expand(mapping)` | `Template.partial_expand(t, mapping)` | same |
| `t.extract(uri)` / `t.match(uri)` | `Template.extract(t, uri)` / `match` | same, without processor |
| `t.pattern variables keys names variable_defaults` | `Template.variables(t)` ... | same |
| `t.to_regexp source named_captures` | same | same |
| `t == other`, `t.inspect` | `==`, `Kernel.inspect(t)` | same / no object id |
| `MatchData#uri template mapping variables keys names values captures to_a to_s string [] values_at pre_match post_match inspect` | `Addressable::Template::MatchData.values(md)`, `md["id"]`, `md[1, 2]` ... | same |
| `IDNA.to_ascii(s)` / `IDNA.to_unicode(s)` | same | same (pure-Ruby backend) |

About 95 operations ported (URI 70, Template 13 + MatchData 17, IDNA 2).

## What differs, and why

- **One function for `URI.join(*uris)` and `uri.join(other)`.** One name is one function in Sake; the
  class form with two arguments computes the same thing as the instance form, so `URI.join(base, *uris)`
  is both. `+` is `join` through `include Arithmetic`.
- **No `return_type` arguments** (`URI.unencode(s, URI)`, `query_values(Array)`): classes are not values.
  The Array form of `query_values` is `query_values_array`.
- **Mapping and option Hashes have one key type.** `Template.expand` takes `Hash["id" => 42]` or
  `Hash[:id => 42]` (both work, as in Ruby), but not keys of both types in one Hash. Values may be Strings,
  numbers, Symbols, booleans, nil, Arrays and Hashes, as in Ruby: the Hash's value type is their union.
- **No caching.** Ruby memoizes each normalized component and resets the cache in every setter; this port
  recomputes them, so there is no cache to invalidate. The only visible difference: Ruby's
  `normalized_query(:sorted)` after a plain `normalized_query` returns the cached unsorted value.
- **`path` is never nil.** Ruby's `@path` starts as `""`; here the field is private and `URI.path(u)` returns
  `@path || ""`, so callers need no nil check (a field written nil by `new` would otherwise make every
  reader `String | nil`).
- **IDNA** uses `String.downcase` where the gem uses its own Unicode lowercase table (4300 lines of
  data); both follow Unicode's simple lowercase mapping. The native (libidn) backend is not used by the gem
  here either. Punycode overflow checks are gone (Integers do not overflow).
- **Template processors** (objects answering `validate`, `transform`, `restore`, `match`) are not ported:
  Sake has no `respond_to?`. The third argument of `expand` is `normalize_values`.
- **`inspect`** has no object id, so the test prints Ruby's with the id removed.
- `TypeError`s for non-String arguments (`Can't convert X into String.`) mostly cannot happen: the checker
  rejects them. The one kept is `merge(Hash[:path => 1])`, whose value type is a union.

## Built-ins Sake lacks (requests)

- `String#[]=` (Ruby's `uri[offset[0]...offset[1]] = new_authority`): written with two slices and `+`.
- `String.[](s, /re/, 1)` is rejected (see bug below); `String.slice(s, /re/, 1)` does it.

## Bugs found

- `notes/addressable_bug_flatten_scan_groups.sake`: `Array.flatten(String.scan(s, re_with_groups))` stays
  nested (`[["ab", "cd"]]`); Ruby flattens. Worked around with `MatchData.captures`.
- `notes/addressable_bug_string_index_regexp.sake`: `String.[](s, /re/, 1)` (and `s[/re/, 1]`) is rejected
  as `Indexable.[]` with a non-Integer index, though Part 2 lists `String.[](x, Any, [Integer])`.

## Friction

- `def SCHEME = ALPHA + DIGIT + "..."` inside `module CharacterClasses` → `type ALPHA cannot be used as a
  value` → `CharacterClasses.ALPHA + CharacterClasses.DIGIT`. Every use of a Ruby constant turned function
  has to be qualified (`Template.EXPRESSION`, `URI.URIREGEX`), even inside its own class.
- `::MatchData.captures(md)` inside `Addressable::Template` (which defines its own `MatchData`) → `undefined
  function Addressable::Template::MatchData.captures` → a helper `URI.match_captures(md)` defined in `URI`,
  where `MatchData` still means the built-in. There is no way to name a shadowed top-level type.
- `def initialize(t) = @pattern => String` → `only def, include, ... are allowed in a class/module body`
  (the `=>` was taken as a statement of the class body) → a `def ... end` body.
- `b.times do |j|` → `method call on a value` → `Integer.times(b)` (habit from Ruby).
- `URI.new(scheme: normalized_scheme(u))` then the setters, as Ruby's `new(...)` → `Absolute URI missing
  hierarchical segment: 'http:'` at run time: Ruby's `new` defers validation over all its options, a Sake
  `new` with one keyword validates in `initialize` at once → an empty `URI.new` and the setters inside
  `defer_validation`.
- The checker found a real hole: `omit(:bogus)` reaches a `case` with no matching `in` (Ruby's version
  validates first and never gets there; the Sake case needs an `else`).

## Size

Ruby: uri.rb + template.rb 2031 code lines (3642 with comments), plus idna.rb and the punycode part of
idna/pure.rb ~320 (its other 4400 lines are Unicode data). Sake: 1363 code lines (1568 with comments).
