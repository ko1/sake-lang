class Txn
  attr_reader :date, :merchant, :amount, :category

  def initialize(date, merchant, amount, category)
    @date = date
    @merchant = merchant
    @amount = amount
    @category = category
  end
end

class Rule
  attr_reader :pattern, :category

  def initialize(pattern, category)
    @pattern = pattern
    @category = category
  end
end

RULES = [
  Rule.new(/coffee|cafe|bakery/i, :meals),
  Rule.new(/air|hotel|taxi|uber|rail/i, :travel),
  Rule.new(/aws|github|slack|zoom/i, :software),
  Rule.new(/staples|office/i, :supplies),
  Rule.new(/restaurant|bistro|grill/i, :meals)
]

BUDGETS = { meals: 300.0, travel: 1200.0, software: 450.0, supplies: 150.0, other: 100.0 }

def categorize(merchant)
  rule = RULES.find { |r| r.pattern.match?(merchant) }
  rule ? rule.category : :other
end

def month_of(date) = date[0...7]

def parse(csv)
  txns = []
  bad = []
  csv.lines.each_with_index do |line, i|
    fields = line.chomp.split(",")
    if fields.size != 3 || !fields[0].match?(/\A\d{4}-\d\d-\d\d\z/)
      bad << i + 1
      next
    end
    date = fields[0]
    merchant = fields[1].strip
    amount = Float(fields[2]) rescue nil
    if !amount    
      bad << i + 1
      next
    end
    txns << Txn.new(date, merchant, amount, categorize(merchant))
  end
  [txns, bad]
end

csv = <<~CSV
  2026-07-02,Blue Bottle Coffee,6.50
  2026-07-03,AWS,212.40
  2026-07-05,United Air,489.00
  2026-07-05,Hotel Marlowe,612.30
  2026-07-09,Staples,48.99
  2026-07-15,GitHub,44.00
  2026-07-18,Corner Bakery,12.75
  2026-07-21,Uber,23.10
  2026-07-30,Nopa Restaurant,182.00
  2026-08-01,Blue Bottle Coffee,7.25
  2026-08-03,AWS,231.95
  2026-08-07,City Locksmith,95.00
  2026-08-11,Zoom,15.99
  2026-08-15,GitHub,44.00
  2026-08-16,Office Depot,129.50
  2026-08-16,Office Depot,-20.00
  2026-08-22,Amtrak Rail,96.00
  2026-08-29,Tartine Bakery,18.40
  2026-08-30,Bistro Jeanty,231.80
  oops this line is broken
  2026-09-01,AWS,240.10
  2026-09-02,Blue Bottle Coffee,six
  2026-09-04,Slack,87.50
  2026-09-10,United Air,1022.00
  2026-09-12,Marriott Hotel,418.00
  2026-09-15,GitHub,44.00
  2026-09-19,Staples,31.20
  2026-09-24,Uber,41.75
  2026-09-28,Plumber Bros,150.00
CSV


txns, bad = parse(csv)
puts "Parsed #{txns.size} transactions; bad lines: #{bad.join(", ")}"

by_month = txns.group_by { |t| month_of(t.date) }
months = by_month.keys.sort
cats = BUDGETS.keys

def row(label, cells) = format("%-9s", label) + cells.map { |c| c.rjust(10) }.join

totals = {}
months.each do |m|
  sums = Hash.new(0.0)
  by_month.fetch(m).each { |t| sums[t.category] += t.amount }
  totals[m] = sums
end

puts
puts row("category", months) + "budget".rjust(10)
cats.each do |c|
  cells = months.map { |m| format("%.2f", totals.fetch(m)[c]) }
  puts row(c.to_s, cells) + format("%10.2f", BUDGETS.fetch(c))
end
puts row("total", months.map { |m| format("%.2f", totals.fetch(m).values.sum) })

puts
puts "Over budget:"
months.each do |m|
  cats.each do |c|
    spent = totals.fetch(m)[c]
    limit = BUDGETS.fetch(c)
    next if spent <= limit
    puts format("  %s %-8s %8.2f over (%3.0f%%)", m, c, spent - limit, spent * 100 / limit)
  end
end

# a merchant seen in every month is treated as a subscription
puts
puts "Recurring:"
txns.group_by(&:merchant).each do |merchant, ts|
  seen = ts.map { |t| month_of(t.date) }.uniq
  next if seen.size < months.size
  lo, hi = ts.map(&:amount).minmax
  kind = hi - lo < 0.01 ? "fixed" : format("varies %.2f-%.2f", lo, hi)
  puts format("  %-20s %s", merchant, kind)
end

puts
uncategorized = txns.select { |t| t.category == :other }
puts "Uncategorized: #{uncategorized.map(&:merchant).uniq.join(", ")}"
txns.select { |t| t.amount < 0 }.each { |t| puts format("Refund %s %s %.2f", t.date, t.merchant, t.amount) }
biggest = txns.max_by(&:amount)
puts format("Largest: %s %s %.2f", biggest.date, biggest.merchant, biggest.amount)
first_total = totals.fetch(months.first).values.sum
last_total = totals.fetch(months.last).values.sum
puts format("Change %s -> %s: %+.1f%%", months.first, months.last, (last_total - first_total) * 100 / first_total)
