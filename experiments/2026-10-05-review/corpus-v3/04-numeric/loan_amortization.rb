class Loan
  attr_reader :name, :principal, :annual_rate, :months

  def initialize(name, principal, annual_rate, months)
    @name = name
    @principal = principal
    @annual_rate = annual_rate
    @months = months
  end
end

class Row
  attr_reader :month, :payment, :interest, :principal, :balance

  def initialize(month, payment, interest, principal, balance)
    @month = month
    @payment = payment
    @interest = interest
    @principal = principal
    @balance = balance
  end
end

class NoSolution < StandardError
  attr_reader :low, :high

  def initialize(message, low, high)
    super(message)
    @low = low
    @high = high
  end
end

def round2(x) = x.round(2)

def payment_for(principal, monthly_rate, months)
  return principal / months if monthly_rate == 0.0
  principal * monthly_rate / (1.0 - (1.0 + monthly_rate) ** -months)
end

def schedule(loan, extras)
  r = loan.annual_rate / 12.0
  pay = round2(payment_for(loan.principal, r, loan.months))
  balance = loan.principal
  rows = []
  month = 0
  while balance > 0.005
    month += 1
    interest = round2(balance * r)
    amount = pay + extras.fetch(month, 0.0)
    amount = balance + interest if amount > balance + interest
    principal_part = round2(amount - interest)
    balance = round2(balance - principal_part)
    rows << Row.new(month, round2(amount), interest, principal_part, balance)
    break if month > 1000
  end
  rows
end

def by_year(rows)
  years = {}
  rows.each do |row|
    y = (row.month - 1) / 12 + 1
    paid, interest = years[y] || [0.0, 0.0]
    years[y] = [paid + row.payment, interest + row.interest]
  end
  years
end

# monthly rate that makes the payment stream worth the principal (bisection)
def implied_rate(principal, payment, months)
  lo = 0.0
  hi = 0.05
  pv = payment_for(principal, hi, months)
  raise NoSolution.new("payment too large for any rate below 60%/yr", lo, hi) if payment > pv
  raise NoSolution.new("payment does not cover the principal", lo, hi) if payment * months < principal
  100.times do
    mid = (lo + hi) / 2.0
    if payment_for(principal, mid, months) < payment
      lo = mid
    else
      hi = mid
    end
  end
  (lo + hi) / 2.0
end

def money(x) = format("%10.2f", x)

loans = [
  Loan.new("car", 18500.0, 0.069, 60),
  Loan.new("mortgage", 240000.0, 0.0425, 360),
  Loan.new("interest-free", 1200.0, 0.0, 12)
]

loans.each do |loan|
  rows = schedule(loan, {})
  total_interest = rows.map(&:interest).sum
  first = rows.first
  last = rows.last
  puts format("== %s: %.2f at %.2f%% over %d months", loan.name, loan.principal, loan.annual_rate * 100.0, loan.months)
  puts "  payment #{money(first.payment)}, total interest #{money(total_interest)}, final payment #{money(last.payment)} in month #{last.month}"
  if rows.size <= 72
    rows.each do |r|
      m = r.month
      next unless m <= 3 || m > rows.size - 2
      puts format("  %3d %s %s %s %s", m, money(r.payment), money(r.interest), money(r.principal), money(r.balance))
    end
  end
  years = by_year(rows)
  shown = years.keys.select { |y| y <= 2 || y == years.size }
  shown.each do |y|
    paid, interest = years[y]
    puts format("  year %2d paid %s of which interest %s", y, money(paid), money(interest))
  end
end

mortgage = loans[1]
base = schedule(mortgage, {})
extras = {}
(1..60).each { |m| extras[m] = 200.0 }
extras[12] = 5000.0
faster = schedule(mortgage, extras)
saved = base.map(&:interest).sum - faster.map(&:interest).sum
puts format("extra payments: paid off in %d months instead of %d, interest saved %.2f", faster.size, base.size, saved)
cross = faster.find { |r| r.balance < mortgage.principal / 2.0 }
puts "half the mortgage repaid by month #{cross.month}" if cross

offers = [[10000.0, 220.0, 60], [10000.0, 180.0, 60], [10000.0, 50000.0, 60], [5000.0, 95.0, 48]]
offers.each do |principal, pay, months|
  r = implied_rate(principal, pay, months)
  puts format("offer %.0f for %d x %.2f: APR %.3f%%", principal, months, pay, r * 1200.0)
rescue NoSolution => e
  puts format("offer %.0f for %d x %.2f: %s", principal, months, pay, e.message)
end
