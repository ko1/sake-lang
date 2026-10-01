class CurrencyMismatch < StandardError
  attr_reader :left, :right
  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

class UnknownRate < StandardError
  attr_reader :from, :to
  def initialize(message, from, to)
    super(message)
    @from = from
    @to = to
  end
end

class Money
  include Comparable
  attr_reader :cents, :currency

  def initialize(cents, currency)
    @cents = cents
    @currency = currency
  end

  def self.zero(cur) = Money.new(0, cur)

  def check_same(b)
    if @currency != b.currency
      raise CurrencyMismatch.new("cannot combine #{@currency} and #{b.currency}", @currency, b.currency)
    end
  end

  def +(b)
    check_same(b)
    Money.new(@cents + b.cents, @currency)
  end

  def -(b)
    check_same(b)
    Money.new(@cents - b.cents, @currency)
  end

  def *(k) = Money.new((@cents * k * 1.0).round, @currency)

  def <=>(b)
    check_same(b)
    @cents <=> b.cents
  end

  def negative? = @cents < 0

  def allocate(ratios)
    total = ratios.sum
    parts = ratios.map { |r| Money.new(@cents * r / total, @currency) }
    remainder = @cents - parts.sum(&:cents)
    i = 0
    while remainder > 0
      m = parts[i]
      parts[i] = Money.new(m.cents + 1, @currency)
      remainder -= 1
      i += 1
    end
    parts
  end

  def to_s
    sign = @cents < 0 ? "-" : ""
    abs = @cents.abs
    "#{sign}#{@currency} #{abs / 100}.#{(abs % 100).to_s.rjust(2, "0")}"
  end
end

RATES = { ["USD", "EUR"] => 0.92, ["EUR", "USD"] => 1.09, ["USD", "JPY"] => 149.5, ["GBP", "USD"] => 1.27 }

def convert(m, to)
  from = m.currency
  return m if from == to
  rate = RATES[[from, to]]
  raise UnknownRate.new("no rate #{from}->#{to}", from, to) if !rate    
  Money.new((m.cents * rate).round, to)
end

class Txn
  attr_accessor :who, :amount, :memo
  def initialize(who, amount, memo)
    @who = who
    @amount = amount
    @memo = memo
  end
end

txns = [
  Txn.new("alice", Money.new(12_500, "USD"), "consulting"),
  Txn.new("bob", Money.new(-3_250, "USD"), "hardware"),
  Txn.new("alice", Money.new(8_000, "EUR"), "workshop"),
  Txn.new("carol", Money.new(-1_999, "EUR"), "travel"),
  Txn.new("bob", Money.new(45_000, "JPY"), "license"),
  Txn.new("carol", Money.new(7_525, "USD"), "support"),
  Txn.new("alice", Money.new(-600, "GBP"), "fees")
]

puts "== ledger =="
txns.each { |t| puts format("%-6s %-12s %14s", t.who, t.memo, t.amount) }

puts "== balance per currency =="
by_cur = {}
txns.each do |t|
  m = t.amount
  cur = m.currency
  by_cur[cur] = (by_cur[cur] || Money.zero(cur)) + m
end
by_cur.each { |cur, m| puts "#{cur}: #{m}" }

puts "== mixing currencies =="
begin
  bad = txns[0].amount + txns[2].amount
  puts "unexpected: #{bad}"
rescue CurrencyMismatch => e
  puts "error: #{e.message} (#{e.left}/#{e.right})"
end

puts "== in USD =="
total_usd = Money.zero("USD")
txns.each do |t|
  begin
    usd = convert(t.amount, "USD")
    total_usd += usd
    puts format("%-12s %12s", t.memo, usd)
  rescue UnknownRate => e
    puts format("%-12s %12s", t.memo, "n/a (#{e.from})")
  end
end
puts "total: #{total_usd}"

puts "== per person (USD only) =="
usd_txns = txns.select { |t| t.amount.currency == "USD" }
people = usd_txns.group_by(&:who)
people.each do |who, ts|
  sum = ts.reduce(Money.zero("USD")) { |acc, t| acc + t.amount }
  flag = sum.negative? ? " (owes)" : ""
  puts "#{who}: #{sum}#{flag}"
end

usd_amounts = usd_txns.map(&:amount)
puts "largest USD: #{usd_amounts.max}"
puts "smallest USD: #{usd_amounts.min}"
puts "sorted: #{usd_amounts.sort.join(", ")}"

puts "== split 100.00 USD 1:1:1 and 50:30:20 =="
pot = Money.new(10_000, "USD")
puts pot.allocate([1, 1, 1]).join(" | ")
puts pot.allocate([50, 30, 20]).join(" | ")
puts "tip 15%: #{pot * 0.15}"
puts "triple: #{pot * 3}"
puts "equal? #{pot == Money.new(10_000, "USD")} bigger? #{pot > Money.new(9_999, "USD")}"
