class Txn
  attr_reader :account, :date, :currency, :amount

  def initialize(account, date, currency, amount)
    @account = account
    @date = date
    @currency = currency
    @amount = amount
  end
end

class RateMissing < StandardError
  attr_reader :currency, :date

  def initialize(message, currency, date)
    super(message)
    @currency = currency
    @date = date
  end
end

def rate_table
  <<~TXT
    2026-06-01 USD 0.9210 GBP 1.1680 JPY 0.005920 CHF 1.0330
    2026-06-02 USD 0.9198 GBP 1.1702 JPY 0.005911
    2026-06-03 USD 0.9225 GBP 1.1695 JPY 0.005934 CHF 1.0351
    2026-06-05 USD 0.9240 GBP 1.1710 JPY 0.005950 CHF 1.0362
  TXT
end

def transactions
  [
    Txn.new("ops", "2026-06-01", "USD", "1200.00"), Txn.new("ops", "2026-06-02", "EUR", "-310.50"),
    Txn.new("ops", "2026-06-02", "CHF", "450.00"), Txn.new("ops", "2026-06-04", "USD", "-99.99"),
    Txn.new("sales", "2026-06-01", "GBP", "2500.00"), Txn.new("sales", "2026-06-03", "JPY", "185000"),
    Txn.new("sales", "2026-06-05", "USD", "780.25"), Txn.new("sales", "2026-06-05", "SEK", "1000.00"),
    Txn.new("travel", "2026-06-03", "JPY", "-42000"), Txn.new("travel", "2026-05-30", "GBP", "-120.00"),
    Txn.new("travel", "2026-06-05", "EUR", "-64.20")
  ]
end

def parse_rates(text)
  text.lines.to_h do |line|
    date, *pairs = line.split
    [date, pairs.each_slice(2).to_h { |cur, r| [cur, Rational(r)] }]
  end
end

def lookup(rates, currency, date)
  return 1r if currency == "EUR"
  rates.keys.select { |d| d <= date }.sort.reverse.each do |d|
    r = rates.fetch(d)[currency]
    return r if r
  end
  raise RateMissing.new("no #{currency} rate on or before #{date}", currency, date)
end

def eur(r) = format("%12.2f", r.to_f)

rates = parse_rates(rate_table)
converted = []
failures = []
transactions.each do |t|
  amount = Rational(t.amount)
  begin
    rate = lookup(rates, t.currency, t.date)
    converted << [t, amount * rate, rate]
  rescue RateMissing => e
    failures << e
  end
end

puts "Converted to EUR:"
converted.each do |t, value, rate|
  stale = t.currency != "EUR" && rates.fetch(t.date, {})[t.currency].nil?
  puts format("  %-6s %s %3s %10s @ %-9s %s%s", t.account, t.date, t.currency,
              t.amount, rate.to_f, eur(value), stale ? "  (earlier rate)" : "")
end
puts

puts "Balances by account (EUR):"
by_account = converted.group_by { |t, v, r| t.account }
by_account.each do |account, rows|
  inflow = rows.select { |t, v, r| v > 0 }.sum { |t, v, r| v }
  outflow = rows.select { |t, v, r| v < 0 }.sum { |t, v, r| v }
  puts format("  %-6s in %s  out %s  net %s", account, eur(inflow), eur(outflow), eur(inflow + outflow))
end
total = converted.sum { |t, v, r| v }
puts format("  %-6s %s", "total", eur(total))
exact = converted.reduce(0r) { |acc, (t, v, r)| acc + v }
puts "  exact total: #{exact.numerator}/#{exact.denominator}"
puts

puts "Exposure by currency:"
by_cur = converted.group_by { |t, v, r| t.currency }
gross = converted.sum { |t, v, r| v.abs }
by_cur.sort_by { |cur, rows| -rows.sum { |t, v, r| v.abs.to_f } }.each do |cur, rows|
  g = rows.sum { |t, v, r| v.abs }
  puts format("  %s %s %5.1f%%", cur, eur(g), (g / gross * 100).to_f)
end
puts
puts "Not converted:"
failures.each { |e| puts "  #{e.currency} on #{e.date}: #{e.message}" }
