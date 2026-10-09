# faker (Faker::Name, Internet, Lorem, Number, Address, Company, Boolean, Color)

`require "faker"` → `sakelib/faker.sake`. Test: `test/sakelib/faker.{sake,rb}` (identical output); the Ruby side is
`test/sakelib/ref/faker.rb`, a plain-Ruby twin with the same word lists and the same draws, because the gem's lists
are large and its output cannot be matched (the gem is not installed either).

The gem's nested modules are flattened to one module each: `Faker::Name.first_name` → `FakerName.first_name`,
`Faker::Internet.email` → `FakerInternet.email`, … (Sake has no nested names). Every module is `module_function`.
The word lists are functions returning `once { String[...] }`: Sake has no value constants, and `once` gives one
shared Array for the program.

**Determinism.** `Faker.seed(n)` is `Kernel.srand(n)`, and every pick is `Kernel.rand`. Sake's `rand` is Ruby's
(the interpreter is Ruby), so for one seed the Sake program and the Ruby twin draw the same numbers in the same
order; checked: `srand(42)` then `Array.new(5) { rand(100) }` gives `[51, 92, 14, 71, 60]` on both sides, and the
whole test output (names, addresses, Floats from `rand * (to - from)`) is identical. The twin's expressions are
written in the same order as the port's (`"#{building_number} #{street_name}"` draws left to right on both sides).
The gem's `Faker::Config.random = Random.new(n)` (a private generator) has no counterpart: Sake has no `Random`
type; seeding is global.

## API

| Ruby (faker gem) | Sake | |
|---|---|---|
| `Faker::Config.random = Random.new(n)` | `Faker.seed(n)` | differs: the global generator (Kernel.srand) |
| `Faker::Base.numerify("##")`, `letterify("??")`, `bothify` | `Faker.numerify(s)`, `letterify`, `bothify` | same (letters are capitals, as the gem's) |
| `Faker::Base.sample(list)` / `shuffle` | `Faker.pick(list)` / `Faker.pick_distinct(list, n)` | differs: names; `pick_distinct` keeps list order |
| `Faker::Name.name` | `FakerName.name` | same formats (`First Last`, `Prefix First Last`, `First Last Suffix`), own lists |
| `Faker::Name.first_name`, `last_name`, `prefix`, `suffix`, `name_with_middle` | `FakerName.first_name`, … | same shape, own lists |
| `Faker::Name.initials(number: 3)` | `FakerName.initials(3)` | differs: positional argument |
| `Faker::Internet.username(specifier:, separators:)` | `FakerInternet.username(specifier = nil, seps)` | differs: positional; two name parts, not shuffled |
| `Faker::Internet.email(name:, domain:)`, `free_email` | `FakerInternet.email(name = nil, domain = nil)` | same shape |
| `Faker::Internet.domain_name`, `domain_word`, `domain_suffix` | `FakerInternet.domain_name`, … | same shape |
| `Faker::Internet.ip_v4_address`, `mac_address` | same names | ip octets are 1..254 (the gem checks reserved ranges) |
| `Faker::Internet.url(host:, path:, scheme:)` | `FakerInternet.url(host = nil, path = nil, scheme = "http")` | positional |
| `Faker::Internet.password(min_length:)` | `FakerInternet.password(min_length = 8)` | differs: letters and digits only, exactly min_length |
| `Faker::Internet.slug(words:, glue:)` | `FakerInternet.slug(words = nil, glue = nil)` | positional |
| `Faker::Lorem.word`, `words(number:)`, `sentence(word_count:, random_words_to_add:)`, `sentences`, `paragraph(sentence_count:, random_sentences_to_add:)`, `paragraphs`, `question`, `character(s)` | `FakerLorem.word`, `words(3)`, `sentence(4, 0)`, … | positional; 40 Latin words |
| `Faker::Number.number(digits:)`, `leading_zero_number`, `decimal(l_digits:, r_digits:)`, `between(from:, to:)`, `within(range:)`, `positive`, `negative`, `digit`, `non_zero_digit`, `hexadecimal`, `binary` | `FakerNumber.number(10)`, … | positional; `between` is Integer only; `within` needs a finite Range |
| `Faker::Address.city`, `street_name`, `street_address(include_secondary:)`, `secondary_address`, `building_number`, `zip_code`/`zip`/`postcode`, `state`, `state_abbr`, `country`, `full_address`, `latitude`, `longitude`, `city_prefix`, `city_suffix`, `street_suffix` | `FakerAddress.city`, … | same formats as the gem's en locale, own lists |
| `Faker::Company.name`, `suffix`, `industry`, `buzzword`, `bs`, `catch_phrase`, `ein` | `FakerCompany.name`, … | same formats, own lists |
| `Faker::Boolean.boolean(true_ratio:)` | `FakerBoolean.boolean(0.5)` | positional |
| `Faker::Color.color_name`, `hex_color`, `rgb_color` | `FakerColor.color_name`, … | same shape |
| `Faker::Date`, `Time`, `Commerce`, `Food`, every other generator; locales; `unique` | — | missing (see below) |

72 operations in 9 modules (plus the list functions).

## できたこと / できなかったこと

- **Done.** The generator shape: a module per gem module, lists as `once` data, formats as `case rand(n) in 0 ... in 1 ... else`
  (the gem picks a format String such as `"#{Name.first_name}#{city_suffix}"` and evaluates it with `parse`; here each
  format is a branch, since there is no eval and interpolation is not data). Seeding, numerify/letterify through
  `String.gsub` with a block (the gem's own idiom), the common calls of Name, Internet, Lorem, Number, Address,
  Company, Boolean, Color.
- **Not done, by rule.** `Faker::Config.random` (a private `Random`): no `Random` type, `Kernel.srand` only.
  `Faker::Base.unique` (an `Unique` generator with a seen-set per method): doable but needs a table keyed by
  generator; a generator cannot be passed (no blocks as values, no method references), so it would be
  `FakerUnique.name` per operation. Locales (`Faker::Config.locale`, YAML data files): the lists are code, not
  data files; a locale would be another `once` list per module. `Faker::Date.between` and `Time` generators: left
  out for the budget (Sake has Time; a port is straightforward). Keyword arguments in the gem (`words(number: 3)`)
  are positional here: the port's functions were written with optional positionals to read like the ref's, and
  Sake's keywords would have worked as well.
- **Not matched.** The gem's output: lists differ and the gem seeds a private generator; the Ruby twin is the port's
  own reference. The order of draws is part of the API: a format that evaluated its parts in another order would
  give different data for the same seed.

## 書き心地

- First write: `def within(range) = between(Range.begin(range), Range.exclude_end?(range) ? Range.end(range) - 1 : Range.end(range))` →
  `faker.sake:182:38: error: Arithmetic.+: the operands may be nil ([Integer | nil, Integer]) [nil]` /
  `hint: reached by the call at line 49 → faker.sake:185` → the ends of an endless Range are nil, which the
  gem would turn into `rand(nil)` noise; now `raise ArgumentError, "within needs a finite Range" if b == nil || e == nil`.
  A real mistake found before running, with the test line that reached it in the hint chain.
- The first run of the whole file otherwise passed `--strict`. Everything here is Strings, Integers and Arrays of
  Strings, and the typed `String[...]` lists made every `Faker.pick` result a String for the checker, so
  `String.downcase(Array.join(...))` and interpolations were never in doubt.
- `case rand(5) in 0 ... in 1 ... else ...` reads as Ruby's `case/when` with Integers; the `else` is required
  anyway (an Integer is open), which matches what the gem's formats need.
- Writing the Ruby twin at the same time as the port was the pleasant part: every function is one line in each,
  `Faker.pick(list)` ↔ `list.fetch(rand(list.size))`, and the diff of the two programs was empty on the second run.
- A habit caught in the test program: `FakerName.name.upcase` →
  `error: method call on a value ... is not allowed` / `hint: String.upcase(FakerName.name)`. The first hint is the
  right one; the second (`Symbol.upcase`) shows the checker does not yet know `name` returns a String here.

## Built-ins requested

- `Random.new(seed)` / `Random.rand(r, n)`: a private generator, so a library can be seeded without touching the
  program's `rand` (the gem's `Faker::Config.random`).
- `Array.sample(a, n)` with a count (Ruby's `sample(n)`): `pick_distinct` is written by hand.
