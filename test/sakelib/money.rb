require_relative "ref/money"

puts("-- new, from_amount, fields")
m = Money.new(1234, "USD")
p(m)
puts(m)
p([m.cents, m.fractional, m.amount, m.to_d, m.to_i])
p(m.currency)
puts(m.currency)
p([m.currency.iso_code, m.currency.symbol, m.currency.id, m.currency_as_string])
p(Money.new(1234))
p(Money.new(1234, :eur))
p(Money.from_amount(12.34, "USD"))
p(Money.from_amount(12.345, "USD"))
p(Money.from_amount(12.355, "USD"))
p(Money.from_amount(1000, "JPY"))
p(Money.from_amount(10.5, "JPY"))
p(Money.from_amount(11.5, "JPY"))
p(Money.new(12.5, "USD"))
p(Money.new(13.5, "USD"))
p(Money.new(Rational(1, 3), "USD"))
p(Money.from_amount(1, "GBP"))
p([Money.us_dollar(100), Money.euro(100), Money.pound_sterling(100), Money.zero("JPY"), Money.from_cents(5, "EUR")])
begin
  Money.new(100, "XYZ")
rescue Money::Currency::UnknownCurrency => e
  puts("MoneyUnknownCurrency: #{e.message}")
end

puts("-- predicates")
[Money.new(100, "USD"), Money.new(0, "USD"), Money.new(-100, "USD")].each do |x|
  p([x.to_s, x.zero?, x.positive?, x.negative?, x.nonzero?, x.abs, -x])
end

puts("-- arithmetic")
a = Money.new(1000, "USD")
b = Money.new(250, "USD")
p(a + b)
p(a - b)
p(b - a)
p(a * 3)
p(a * 1.5)
p(a * 0.333)
p(a * Rational(1, 3))
p(a / 3)
p(a / 4.0)
p(a / b)
p(b / a)
p(a.div(7))
p(-(a + b))
p(+a)
begin
  a * b
rescue TypeError => e
  puts("TypeError: #{e.message}")
end
begin
  a / 0
rescue ZeroDivisionError => e
  puts("ZeroDivisionError: #{e.message}")
end
begin
  a + Money.new(1, "EUR")
rescue Money::Bank::UnknownRate => e
  puts("MoneyUnknownRate: #{e.message}")
end

puts("-- comparison")
p([a == Money.new(1000, "USD"), a == b, a != b, a > b, a < b, a >= Money.new(1000, "USD"), a <=> b, b <=> a, a <=> a])
p(Money.new(0, "USD") == Money.new(0, "JPY"))
p(Money.new(100, "USD") == Money.new(100, "EUR"))
p(Money.new(100, "USD") <=> Money.new(100, "EUR"))
p([a, b, Money.new(500, "USD"), Money.new(-5, "USD")].sort.map { |x| x.cents })
p([a, b].max.cents)
p(a.eql?(Money.new(1000, "USD")))

puts("-- allocate, split")
def cents_of(xs) = xs.map { |x| x.cents }
p(cents_of(Money.new(100, "USD").allocate([1, 1, 1])))
p(cents_of(Money.new(100, "USD").allocate([0.5, 0.25, 0.25])))
p(cents_of(Money.new(100, "USD").allocate([70, 30])))
p(cents_of(Money.new(5, "USD").allocate([3, 7])))
p(cents_of(Money.new(-100, "USD").allocate([1, 1, 1])))
p(cents_of(Money.new(100, "USD").allocate([0, 0])))
p(cents_of(Money.new(100, "USD").split(3)))
p(cents_of(Money.new(1000, "JPY").split(7)))
p(Money.new(100, "USD").split(2))
begin
  Money.new(100, "USD").allocate([])
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

puts("-- format")
[[123457, "USD"], [123457, "EUR"], [123457, "GBP"], [123457, "JPY"], [-123457, "USD"], [-123457, "EUR"], [0, "USD"], [5, "USD"], [100, "USD"], [1234567890, "USD"], [1234567, "JPY"], [100, "CHF"], [123456, "KRW"], [123456, "INR"], [123456, "CNY"], [123456, "AUD"], [123456, "CAD"]].each do |cents, cur|
  x = Money.new(cents, cur)
  puts("#{cur} #{cents}: #{x.format} | #{x.to_s} | #{x.format(symbol: false)} | #{x.format(with_currency: true)}")
end
x = Money.new(123457, "USD")
p(x.format(no_cents: true))
p(x.format(no_cents_if_whole: true))
p(Money.new(100, "USD").format(no_cents_if_whole: true))
p(x.format(thousands_separator: " ", decimal_mark: ","))
p(x.format(thousands_separator: ""))
p(x.format(symbol: "US$"))
p(x.format(symbol_position: :after))
p(Money.new(-123457, "USD").format(sign_before_symbol: false))
p(Money.new(-123457, "USD").format(sign_before_symbol: false, symbol_position: :after))
p(x.format(format: "%n %u"))
p(x.format(format: "%u %n", with_currency: true))
p(Money.new(-5, "EUR").format(format: "%n%u"))
p(Money.new(-5, "EUR").to_s)
p(Money.new(1, "JPY").to_s)
p(Money.new(100000, "JPY").to_s)

puts("-- currency")
p(Money::Currency.find("usd"))
p(Money::Currency.find("nope"))
c = Money::Currency.wrap("EUR")
p([c.iso_code, c.name, c.symbol, c.subunit_to_unit, c.decimal_mark, c.thousands_separator, c.symbol_first?, c.decimal_places, c.priority])
p([Money::Currency.wrap("JPY").decimal_places, Money::Currency.wrap(:usd).decimal_places])
p(Money::Currency.wrap(c) == c)
p(Money::Currency.wrap("USD") < Money::Currency.wrap("EUR"))
p(Money::Currency.all.map { |k| k.iso_code })
p([Money::Currency.wrap("JPY"), Money::Currency.wrap("USD"), Money::Currency.wrap("GBP")].sort.map { |k| k.to_s })

puts("-- exchange")
bank = Money::Bank::VariableExchange.new
p(bank.rates)
p(bank.add_rate("USD", "EUR", 0.9))
p(bank.set_rate("EUR", "USD", Rational(10, 9)))
p(bank.add_rate("USD", "JPY", 150))
p(bank.get_rate("USD", "EUR"))
p(bank.get_rate("EUR", "GBP"))
p(bank.rates)
p(Money.new(1000, "USD").exchange_to("EUR", bank))
p(Money.new(1000, "USD").exchange_to("JPY", bank))
p(Money.new(1234, "USD").exchange_to("JPY", bank))
p(Money.new(999, "EUR").exchange_to("USD", bank))
p(Money.new(1000, "USD").exchange_to("USD", bank))
p(bank.exchange_with(Money.new(5, "USD"), :eur))
begin
  Money.new(1000, "USD").exchange_to("GBP", bank)
rescue Money::Bank::UnknownRate => e
  puts("MoneyUnknownRate: #{e.message}")
end
p(Money.add_rate("USD", "EUR", 0.5))
Money.default_bank.add_rate("EUR", "USD", 2)
p(Money.new(1000, "USD").exchange_to("EUR"))
p(Money.new(1000, "USD") + Money.new(1000, "EUR"))
p(Money.new(1000, "EUR") - Money.new(1000, "USD"))
p(Money.new(500, "EUR") == Money.new(1000, "USD"))
p(Money.new(500, "EUR") > Money.new(999, "USD"))
p(Money.new(500, "EUR") / Money.new(1000, "USD"))
p(Money.new(1000, "USD").exchange_to("EUR") == Money.default_bank.exchange_with(Money.new(1000, "USD"), "EUR"))
puts("end")
