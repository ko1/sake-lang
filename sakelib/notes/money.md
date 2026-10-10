# money

`sakelib/money.sake`: the core of the money gem (6.x; not installed, so the reference is
`test/sakelib/ref/money.rb`, plain Ruby written from the gem's documented behavior). `Money.new(cents, currency)`,
`from_amount`, arithmetic, Comparable, `allocate` / `split`, `format` with the gem's per-currency defaults,
`Money::Currency` (10 currencies), `Money::Bank::VariableExchange` and `exchange_to`. 36 Money operations,
11 Currency operations (+ 8 readers), 5 Bank operations; the test prints 128 lines, identical to the reference.
Names (2026-10-10): the gem's nested names are kept, declared inside `class Money`: `Money::Currency`,
`Money::Currency::UnknownCurrency`, `Money::Bank::VariableExchange` (the rate table; `Money::Bank` is its namespace,
a module as in the gem) and `Money::Bank::UnknownRate`. Before namespaces nested they were `Currency`, `Bank`,
`MoneyUnknownCurrency`, `MoneyUnknownRate`.

## API

| Ruby (money) | Sake | |
|---|---|---|
| `Money.new(cents, "USD")`, `Money.new(cents)` (default currency) | `Money.new(cents, "USD")`, `Money.new(cents)` | same (default USD, no deprecation warning) |
| `Money.from_amount(12.34, "USD")`, `from_cents`, `Money.zero(cur)` | same | same |
| `Money.us_dollar(c)`, `euro(c)`, `pound_sterling(c)` | same | same |
| `m.cents`, `m.fractional`, `m.currency`, `m.currency_as_string` | `Money.cents(m)`, … | same |
| `m.amount` (BigDecimal), `m.to_d`, `m.to_f`, `m.to_i` | `Money.amount(m)` (Float), `to_d` (Rational), `to_f`, `to_i` | differs: number types |
| `m.zero?`, `positive?`, `negative?`, `nonzero?`, `abs`, `-m`, `+m` | same | same |
| `m + n`, `m - n` (exchanged via the default bank when currencies differ) | same | same |
| `m * 2`, `m * 1.5`, `m / 3`, `m / n` (ratio), `m.div(x)` | same | same (`m / n` a Float, Ruby a BigDecimal) |
| `2 * m` (Ruby's `coerce`) | — | missing: `Arithmetic.*: the operands are (Integer, Money)` before running |
| `m <=> n`, `<`, `==`, `sort`, `max`; zero == zero across currencies; no rate → `nil` / `false` | same | same |
| `m.eql?(n)`, `m.hash` | `Money.eql?(a, b)`; — | hash missing (a Money cannot be a Hash key: it defines `<=>`) |
| `m.allocate([1, 1, 1])`, `allocate(3)`, `m.split(3)` | same | same (Money::Allocation's algorithm, remainders to the first parts) |
| `m.format(**rules)` | `Money.format(m, symbol:, no_cents:, no_cents_if_whole:, with_currency:, thousands_separator:, decimal_mark:, sign_before_symbol:, symbol_position:, format:)` | same for these 9 rules; missing: `disambiguate`, `symbol_space`, `html_wrap`, `drop_trailing_zeros`, `rounded_infinite_precision`, `translate_symbol`, `Money.default_formatting_rules`, I18n |
| `m.to_s` (currency's decimal mark, no symbol), `inspect` | same | same |
| `m.exchange_to("EUR")`, `exchange_to("EUR", bank)` | `Money.exchange_to(m, "EUR", [bank])` | same |
| `Money.default_bank`, `Money.add_rate(from, to, rate)` | `Money.default_bank` (a `once` value), `Money.add_rate` | same |
| `Money::Bank::VariableExchange.new`, `add_rate`, `set_rate`, `get_rate`, `exchange_with`, `rates` | `Money::Bank::VariableExchange.new`, `Money::Bank::VariableExchange.add_rate(b, …)`, … | same name (nested since 2026-10-10); `export_rates` / `import_rates` missing |
| `Money::Currency.find`, `wrap`, `all`, `iso_code`, `name`, `symbol`, `subunit_to_unit`, `decimal_mark`, `thousands_separator`, `symbol_first?`, `decimal_places`, `priority`, `id`, `code`, `<=>`, `to_s` | `Currency.find`, … | same (10 currencies: USD EUR GBP AUD CAD JPY CHF CNY INR KRW; the gem's ~170 and `register` missing) |
| `Money::Bank::UnknownRate`, `Money::Currency::UnknownCurrency` | `Money::Bank::UnknownRate`, `Money::Currency::UnknownCurrency` | same names and messages (nested since 2026-10-10) |
| `Money.rounding_mode`, `infinite_precision`, `Money.locale_backend`, `round`, `round_to_nearest_cash_value`, `divmod`, `modulo`, `remainder` | — | missing |

## できたこと / できなかったこと

- Amounts are exact without BigDecimal: `Money.to_r(x)` reads a Float with `Float.rationalize` (0.9 → 9/10,
  12.345 → 2469/200, what `BigDecimal(12.345.to_s)` gives), and `round_half_even` on a Rational is the gem's
  default `ROUND_HALF_EVEN`: `Money.from_amount(12.345)` → 1234, `12.355` → 1236, `Money.new(12.5)` → 12,
  `13.5` → 14. Exchange is `from_amount(to_d(m) * rate, to)`, the gem's amount-based conversion (handles
  JPY's subunit of 1: 12.34 USD at 150 → 1851 JPY).
- `include Arithmetic` + `+ - * / -@ +@`, `include Comparable` + `<=>`: `a + b`, `a * 1.5`, `-(a + b)`,
  `Array.sort(Money[...])`, `Array.max` all read as the gem's. `Money * Money` raises `TypeError` (Sake lets a
  library raise the built-in `TypeError` with the gem's message).
- `Money.default_bank` is `once { Bank::VariableExchange.new(Hash[]) }`: class-level mutable state (the gem's `@@default_bank`) as a
  shared value computed once. `Money::Bank::VariableExchange.add_rate(Money.default_bank, "USD", "EUR", 0.5)` then
  `Money.new(1000, "USD") + Money.new(1000, "EUR")` works as in the gem.
- Not done: `2 * money`. An operator dispatches on its left operand, and Integer's `*` is a closed table, so
  there is no `coerce` to join (the checker says so before running, see below). `Money` cannot be a Hash key
  (a Struct with `<=>` is refused as a key, §12.1), so the gem's `hash`/`eql?` for Hash use is out; `eql?` exists.
  Currency data is a table of ten; the gem loads ~170 from JSON. Formatting is the legacy (non-I18n) backend:
  thousands separator and decimal mark from the Currency (`€1.234,57`), symbol before, sign before the symbol.
- The reference `ref/money.rb` reproduces the gem's documented results as I remember them; the gem itself was
  not available to compare, so `format`'s defaults for CHF (`CHF1.00`) and the exact `Currency#inspect` text
  are the port's, not verified against the gem.

## 書き心地

- First `--strict` run of library and test: no report; outputs matched the reference on the first diff (the
  reference itself had a Ruby bug: a `TABLE` constant built above `initialize`).
- Wrote the test with `2 * a` expecting a rescue → `Arithmetic.*: the operands are (Integer, M), which the
  left operand's type does not support [type]` **before running**. Ruby raises `TypeError: Money can't be
  coerced into Integer` at run time unless `coerce` is defined; Sake names the real cause (the left operand
  decides) at the line. Removed the case; it is in the API table as missing.
- Wrote `Arithmetic.round(x)` for the gem's rounding → probe showed `Arithmetic.round(2.5r)` is 3 (half up),
  the gem's default is half even → `round_half_even(r)` in 6 lines on Rationals (`Rational.floor`, `r - fl`,
  `Integer.even?`). A `half:` keyword on `round` would delete it.
- `allocate`: `part = Array.pop(ps)` is `Integer | Float | nil` under `--strict`, so `remaining * part / sum` needs
  `part != nil` even though the loop condition `!Array.empty?(ps)` makes it impossible; the gem's Ruby has no
  such line. The rest of the algorithm is the gem's line for line (`Arithmetic.truncate(remaining * part / sum)`,
  Integer division floors as Ruby's; `-100` → `[-33, -33, -34]` in both).
- `def format(m, symbol: true, no_cents: false, ..., format: nil)`: the gem's `**rules` Hash became 9 named
  keywords, so `Money.format(x, no_cent: true)` is a static error naming the misspelling, where the gem silently
  ignores an unknown rule. The keyword `format:` shadows `Kernel.format` inside the function without trouble.
- `case symbol in true then ... in false | nil then "" in String then symbol`: a `true | false | nil | String`
  option taken apart with literal patterns; reads better than the gem's `if rules[:symbol] == false`.
- `initialize` as the converter: `@fractional = round_half_even(to_r(f))` and `@currency = Currency.wrap(c == nil ?
  default_currency : c)` give every Money an Integer and a Currency, and the checker then takes
  `Money.fractional(m)` as Integer everywhere (`Integer.abs(@fractional)`, `Integer.divmod` pass without a check).
- `Currency` with `include Comparable` and `<=>` on `[@priority, @iso_code]` (a Tuple comparison): `Money.currency(b)
  == @currency` then compares by `<=>`, as the gem's `Currency#==` compares ids. Rates are keyed by the String
  `"USD_TO_EUR"`, as the gem does, which also sidesteps Currency not being allowed as a Hash key.
- `once { Bank::VariableExchange.new(Hash[]) }` for the default bank: a one-liner where the gem has a class variable, a reader and
  a writer. `Money.default_bank.Money::Bank::VariableExchange.exchange_with(m, "EUR")` (a chain) reads like
  `Money.default_bank.exchange_with`, if longer since the names nest.

## Built-ins requested

- `Arithmetic.round(x, digits, half: :even)` (Ruby's `round(half: :even | :up | :down)`): bankers' rounding is the
  default of money, BigDecimal and most finance code; written by hand here.
- `Rational.divmod` / `Rational.truncate(r, digits)`: `Integer.divmod` and `Float.divmod` exist, Rational's does not.
- (Language) a way for a Struct type to take part in `Integer * T` (`coerce`, or a right-operand row): the one
  gem idiom that cannot be written.
- (Language) a Struct type with `<=>` as a Hash key when it also defines `eql?`/`hash`: `Hash[money => count]`
  is a common pattern (grouping by amount).
