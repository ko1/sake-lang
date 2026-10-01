BRACKETS = [[100_000, 0.0], [300_000, 0.1], [600_000, 0.2], [nil, 0.3]]

def cents(c) = format("%d.%02d", c / 100, c % 100)

module Payable
  def gross(period) = raise("gross not implemented")
  def kind = "employee"
  def taxable? = true
  def benefits = 0

  def withholding(period)
    return 0 unless taxable?
    income = gross(period)
    tax = 0.0
    lower = 0
    BRACKETS.each do |limit, rate|
      top = !limit     ? income : [income, limit].min
      tax += (top - lower) * rate if top > lower
      break if !limit     || income <= limit
      lower = limit
    end
    tax.round
  end

  def net(period) = gross(period) - withholding(period) - benefits

  def stub(period)
    g = gross(period)
    format("%-6s %-12s gross %10s tax %9s benefits %7s net %10s",
           name, kind, cents(g), cents(withholding(period)), cents(benefits), cents(net(period)))
  end
end

class Salaried
  include Payable
  attr_reader :name, :dept, :annual
  def initialize(name, dept, annual)
    @name = name
    @dept = dept
    @annual = annual
  end
  def kind = "salaried"
  def gross(period) = @annual / 12
  def benefits = 25_000
end

class Hourly
  include Payable
  attr_reader :name, :dept, :rate
  def initialize(name, dept, rate)
    @name = name
    @dept = dept
    @rate = rate
  end
  def kind = "hourly"
  def gross(period)
    hours = period[@name] || 0
    regular = [hours, 160].min
    overtime = hours - regular
    (regular * @rate + overtime * @rate * 1.5).round
  end
  def benefits = 8_000
end

class Commissioned
  include Payable
  attr_reader :name, :dept, :base, :pct
  def initialize(name, dept, base, pct)
    @name = name
    @dept = dept
    @base = base
    @pct = pct
  end
  def kind = "commission"
  def gross(period)
    sales = period["sales:#{@name}"] || 0
    @base + (sales * @pct).round
  end
  def benefits = 15_000
end

class Contractor
  include Payable
  attr_reader :name, :dept, :invoice
  def initialize(name, dept, invoice)
    @name = name
    @dept = dept
    @invoice = invoice
  end
  def kind = "contractor"
  def gross(period) = @invoice
  def taxable? = false
end

staff = [
  Salaried.new("alice", "eng", 9_600_000),
  Salaried.new("bruno", "ops", 5_400_000),
  Hourly.new("chen", "ops", 2_850),
  Hourly.new("dana", "eng", 4_200),
  Commissioned.new("eli", "sales", 200_000, 0.08),
  Commissioned.new("fay", "sales", 250_000, 0.05),
  Contractor.new("gus", "eng", 720_000),
  Hourly.new("hana", "support", 2_400)
]

months = [
  ["2026-08", { "chen" => 172, "dana" => 150, "sales:eli" => 4_500_000, "sales:fay" => 9_100_000, "hana" => 0 }],
  ["2026-09", { "chen" => 160, "dana" => 181, "sales:eli" => 2_800_000, "hana" => 96 }]
]

ytd = Hash.new(0)
months.each do |label, period|
  puts "== payroll #{label} =="
  staff.each { |e| puts e.stub(period) }
  total_gross = staff.sum { |e| e.gross(period) }
  total_tax = staff.sum { |e| e.withholding(period) }
  puts "total gross #{cents(total_gross)}, withheld #{cents(total_tax)}"
  staff.each { |e| ytd[e.name] += e.net(period) }

  by_dept = Hash.new(0)
  staff.each do |e|
    by_dept[e.dept] += e.gross(period)
  end
  by_dept.keys.sort.each { |d| puts format("  %-8s %12s", d, cents(by_dept[d])) }

  top = staff.max_by { |e| e.net(period) }
  puts "top earner: #{top.name}" if top
  idle = staff.select { |e| e.gross(period) == 0 }
  puts "no pay this month: #{idle.map(&:name).join(", ")}" unless idle.empty?
end

puts "== year to date (net) =="
ytd.sort_by { |name, amount| -amount }.each do |name, amount|
  puts format("%-6s %12s", name, cents(amount))
end
kinds = staff.map(&:kind).tally
puts "headcount: #{kinds.map { |k, n| "#{k}=#{n}" }.join(" ")}"
