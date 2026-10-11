# public_suffix (PublicSuffix)

`require "public_suffix"` → `sakelib/public_suffix.sake`. Test: `test/sakelib/public_suffix.{sake,rb}`
(identical output; the .rb uses the public_suffix 7.0.5 gem).

The rules come from the gem's own `data/list.txt`, read at run time on first use: the file named by
`PUBLIC_SUFFIX_LIST`, or else `../data/list.txt` next to what `gem which public_suffix` prints. Parsing the
~10,000 rules takes about 2 s of CPU in the interpreter (once per process, measured on a busy machine).

## API

| Ruby | Sake | |
|---|---|---|
| `PublicSuffix.parse(name)` | `PublicSuffix.parse(name)` | same |
| `PublicSuffix.parse(name, ignore_private: true, list: l)` | `PublicSuffix.parse(name, {ignore_private: true, list: l})` | differs: options Record |
| `PublicSuffix.parse(name, default_rule: r)` | — | missing: the default rule is always `*` |
| `PublicSuffix.valid?(name, **opts)` / `domain(name, **opts)` | `PublicSuffix.valid?(name, {...})` / `domain` | same, options Record |
| `PublicSuffix.decompose(name, rule)` / `normalize(name)` | same | same (`normalize` returns a DomainInvalid, as Ruby) |
| `Domain.new(tld, sld, trd)` | `PublicSuffix::Domain.new(tld, sld, trd)` | same (no block form) |
| `Domain.name_to_labels(s)` | same | same |
| `d.tld sld trd name to_s to_a domain subdomain domain? subdomain?` | `PublicSuffix::Domain.tld(d)` ... | same |
| `Rule.factory(s, private: true)` / `Rule.default` | `PublicSuffix::Rule.factory(s, {private: true})` / `Rule.default` | same, options Record |
| `Rule::Normal/Wildcard/Exception.new(value:, length:, private:)` / `.build(s)` | same | same |
| `rule.value length private rule parts match?(n) decompose(n)` | `PublicSuffix::Rule::Base.decompose(rule, n)` ... | differs: called through `Rule::Base` (see below) |
| `rule == other` | `==` | differs: compares value, length and private (Ruby: class and value) |
| `List.default` / `List.default = l` | `PublicSuffix::List.default` / `List.set_default(l)` | same / name |
| `List.parse(text, private_domains: false)` | `List.parse(text, {private_domains: false})` | same, options Record |
| `List.new`, `list.add(r)`, `list << r`, `size`, `empty?`, `clear`, `each`, `==`, `default_rule` | `PublicSuffix::List.add(l, r)`, `l << r`, ... | same (`each` without a block: use `Enum.map(l)` etc.) |
| `list.find(name, default: nil, ignore_private: true)` | `List.find(l, name, {default: nil, ignore_private: true})` | same, except `default:` can only be nil |
| `PublicSuffix::Error`, `DomainInvalid`, `DomainNotAllowed` | same names | differs: no hierarchy (see below) |
| `PublicSuffix::VERSION` | `PublicSuffix.VERSION` | function |

About 45 operations ported.

## What differs, and why

- **Rule classes.** Ruby's `Rule::Base` is the superclass of `Normal`, `Wildcard` and `Exception`, and
  `list.find` returns any of the three. In Sake `class B < A` copies, so `Base` is a mixin included by the
  three classes: `PublicSuffix::Rule::Base.decompose(rule, name)` dispatches on the rule's class, and its
  required functions (`value`, `length`, `private`, `parts`, `rule`) are each class's readers. A rule's
  class is tested with `rule in PublicSuffix::Rule::Exception`, as Ruby's `instance_of?`.
- **The List stores entries, not rules** (as Ruby: `Rule::Entry` of type, length, private), with the type as
  a Symbol instead of a class (classes are not values). `List.parse` builds entries straight from the lines
  without making a Rule for each (the gem makes one and throws it away); this cuts the load time by about a third.
- **Exceptions.** No exception hierarchy in Sake: `rescue PublicSuffix::Error` catches nothing raised here;
  write `rescue PublicSuffix::DomainInvalid, PublicSuffix::DomainNotAllowed` (and rescue
  `DomainNotAllowed` before or apart from `DomainInvalid`, which Ruby's subclassing makes optional).
- **Keyword options are a Record** (`{ignore_private: true}`), per the convention for Sake functions; read
  with `Record.to_h`. `default_rule:` is not taken; `find`'s `default:` can only be `nil` (a rule value
  would make the option Record's value type a union with the three rule classes).
- `List.default` is cached in a holder made by `once` (Ruby: a class instance variable), so `set_default`
  works as Ruby's `default=`.

## Built-ins Sake lacks

- A way to find an installed gem's files (`Gem::Specification`); this port runs `gem which` once.

## Friction

- `attr_reader :private` (Ruby's field name) → `write the field's name without ':'` → `attr_reader private`
  works, though `private` is also the visibility keyword.
- `PublicSuffix::Rule::Normal.private(rule)` on a rule that may be any of the three classes → `argument 1
  must be PublicSuffix::Rule::Normal, but can be PublicSuffix::Rule::Exception` → `Rule::Base.private(r)`,
  after declaring `def private(r) = raise(NotImplementedError)` in the mixin; readers of the includers then
  satisfy it. Without that declaration: `undefined function PublicSuffix::Rule::Base.private`.
- `l << rule` → `Bitwise.<<: PublicSuffix::List does not include Bitwise` → `include Bitwise` (the hint said
  exactly this).

## Size

Ruby: 287 code lines (1064 with comments) in public_suffix.rb and public_suffix/*.rb. Sake: 288 code
lines (367 with comments).
