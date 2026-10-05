class PayrollError < StandardError
  attr_reader :employee_id

  def initialize(message, employee_id)
    super(message)
    @employee_id = employee_id
  end
end

# yearly brackets: [upper limit, rate]; nil limit is the top bracket
BRACKETS = [[10000, 0.0], [40000, 0.12], [90000, 0.22], [nil, 0.3]]
HEALTH_PREMIUM = 85.0
PERIODS_PER_YEAR = 26

# shared by both kinds of employee
module Employee
  def label = "#{id} #{name}"
  def gross_pay(hours) = raise("gross_pay is not defined for #{name}")
end

class Hourly
  include Employee
  attr_reader :id, :name, :rate, :retirement_pct

  def initialize(id, name, rate, retirement_pct)
    @id = id
    @name = name
    @rate = rate
    @retirement_pct = retirement_pct
  end

  def gross_pay(hours)
    raise PayrollError.new("no timecard", id) if hours.nil?
    raise PayrollError.new("impossible hours #{hours}", id) if hours > 100 || hours < 0
    regular = [hours, 80.0].min
    overtime = hours - regular
    rate * regular + rate * 1.5 * overtime
  end
end

class Salaried
  include Employee
  attr_reader :id, :name, :annual, :retirement_pct

  def initialize(id, name, annual, retirement_pct)
    @id = id
    @name = name
    @annual = annual
    @retirement_pct = retirement_pct
  end

  def gross_pay(_hours) = annual / PERIODS_PER_YEAR
end

class Stub
  attr_reader :employee, :gross, :pretax, :tax, :health, :net

  def initialize(employee, gross, pretax, tax, health, net)
    @employee = employee
    @gross = gross
    @pretax = pretax
    @tax = tax
    @health = health
    @net = net
  end
end

# tax on one period: annualize, apply the brackets, divide back
def period_tax(taxable)
  yearly = taxable * PERIODS_PER_YEAR
  tax = 0.0
  lower = 0
  BRACKETS.each do |limit, rate|
    top = limit || yearly
    tax += ([yearly, top].min - lower) * rate if yearly > lower
    lower = top
  end
  (tax / PERIODS_PER_YEAR).round(2)
end

def run_period(employees, timecards)
  stubs = []
  errors = []
  employees.each do |e|
    gross = e.gross_pay(timecards[e.id]).round(2)
    pretax = (gross * e.retirement_pct / 100.0).round(2)
    tax = period_tax(gross - pretax)
    net = (gross - pretax - tax - HEALTH_PREMIUM).round(2)
    stubs << Stub.new(e, gross, pretax, tax, HEALTH_PREMIUM, net)
  rescue PayrollError => err
    errors << "#{e.label}: #{err.message}"
  end
  [stubs, errors]
end

employees = [
  Hourly.new(101, "Rosa", 22.5, 3),
  Hourly.new(102, "Tomas", 18.0, 0),
  Salaried.new(201, "Ingrid", 78000.0, 6),
  Hourly.new(103, "Wei", 31.0, 5),
  Salaried.new(202, "Omar", 132000.0, 10),
  Hourly.new(104, "Lena", 16.75, 2)
]

periods = [
  ["Sep 1-14", { 101 => 80.0, 102 => 86.5, 103 => 72.0, 104 => 40.0 }],
  ["Sep 15-28", { 101 => 91.0, 102 => 80.0, 103 => 120.0 }]
]

ytd = Hash.new(0.0)
periods.each do |label, cards|
  stubs, errors = run_period(employees, cards)
  puts "== Pay period #{label} =="
  puts format("%-7s %9s %8s %8s %7s %9s", "name", "gross", "401k", "tax", "health", "net")
  stubs.each do |s|
    e = s.employee
    puts format("%-7s %9.2f %8.2f %8.2f %7.2f %9.2f", e.name, s.gross, s.pretax, s.tax, s.health, s.net)
    ytd[e.name] += s.gross
  end
  errors.each { |m| puts "  skipped #{m}" }
  total_gross = stubs.sum(&:gross)
  total_tax = stubs.sum(&:tax)
  puts format("%-7s %9.2f %8s %8.2f", "total", total_gross, "", total_tax)
  hourly_cost = stubs.select { |s| s.employee.is_a?(Hourly) }.sum(&:gross)
  puts format("hourly share %.1f%%", hourly_cost * 100 / total_gross)
  puts
end

puts "Year to date:"
ytd.sort_by { |_n, g| -g }.each do |n, g|
  puts format("  %-7s %10.2f", n, g)
end
top_name, _top_gross = ytd.max_by { |_n, g| g }
puts "Highest paid: #{top_name}"
effective = [30000, 60000, 100000, 150000].map do |income|
  t = period_tax(income * 1.0 / PERIODS_PER_YEAR) * PERIODS_PER_YEAR
  format("%d: %.1f%%", income, t * 100 / income)
end
puts "Effective rates: #{effective.join(", ")}"
