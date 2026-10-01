# Subscription billing: monthly and yearly cycles anchored to the signup day
# (clamped at month ends), mid-cycle plan changes with day-based proration,
# cancellations, and the invoices issued up to a cut-off date.

class Plan
  attr_reader :code, :cents, :months

  def initialize(code, cents, months)
    @code = code
    @cents = cents
    @months = months
  end
end

class Subscription
  attr_reader :customer, :anchor, :plan, :changes, :cancelled

  def initialize(customer, anchor, plan, changes, cancelled)
    @customer = customer
    @anchor = anchor
    @plan = plan
    @changes = changes
    @cancelled = cancelled
  end
end

class Invoice
  attr_reader :customer, :date, :cents, :note

  def initialize(customer, date, cents, note)
    @customer = customer
    @date = date
    @cents = cents
    @note = note
  end
end

class BadAnchor < StandardError
  attr_reader :customer

  def initialize(message, customer)
    super(message)
    @customer = customer
  end
end

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def dim(y, m) = m == 2 ? (leap?(y) ? 29 : 28) : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]

def ymd(s)
  m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/)
  raise ArgumentError, "malformed date #{s}" if m.nil?
  m.captures.map(&:to_i)
end

def day_of(s) = days_from_civil(*ymd(s))

def iso(y, m, d) = format("%04d-%02d-%02d", y, m, d)

# The n-th cycle start after the anchor, keeping the anchor day where possible.
def cycle_start(anchor, n, months)
  y, m, d = ymd(anchor)
  total = m - 1 + n * months
  ny = y + total / 12
  nm = total % 12 + 1
  iso(ny, nm, [d, dim(ny, nm)].min)
end

def money(cents) = format("%s$%d.%02d", cents < 0 ? "-" : "", cents.abs / 100, cents.abs % 100)

PLANS = {
  "basic" => Plan.new("basic", 900, 1),
  "pro" => Plan.new("pro", 2900, 1),
  "pro-annual" => Plan.new("pro-annual", 29000, 12)
}

# Prorated amount for the unused/used part of a cycle, rounded half up.
def prorate(cents, days_used, days_total) = (cents * days_used * 2 + days_total) / (days_total * 2)

def bill(sub, cutoff)
  invoices = []
  plan = PLANS.fetch(sub.plan)
  anchor = sub.anchor
  ay, am, ad = ymd(anchor)
  raise BadAnchor.new("no such day #{anchor}", sub.customer) if ad > dim(ay, am)
  cancelled = sub.cancelled
  n = 0
  loop do
    start = cycle_start(anchor, n, plan.months)
    finish = cycle_start(anchor, n + 1, plan.months)
    break if day_of(start) > day_of(cutoff)
    break if cancelled && day_of(start) >= day_of(cancelled)
    invoices << Invoice.new(sub.customer, start, plan.cents, "#{plan.code} #{start}..#{finish}")
    total_days = day_of(finish) - day_of(start)
    change = sub.changes.find { |date, _code| day_of(date) > day_of(start) && day_of(date) < day_of(finish) }
    if change
      date, code = change
      left = day_of(finish) - day_of(date)
      credit = prorate(plan.cents, left, total_days)
      invoices << Invoice.new(sub.customer, date, -credit, "credit #{left}/#{total_days} days of #{plan.code}")
      plan = PLANS.fetch(code)
      anchor = date
      n = 0
      next
    end
    if cancelled && day_of(cancelled) < day_of(finish)
      left = day_of(finish) - day_of(cancelled)
      refund = prorate(plan.cents, left, total_days)
      invoices << Invoice.new(sub.customer, cancelled, -refund, "refund #{left}/#{total_days} days")
    end
    n += 1
  end
  invoices
end

subs = [
  Subscription.new("acme", "2026-01-31", "basic", [], nil),
  Subscription.new("bolt", "2026-03-15", "basic", [["2026-05-01", "pro"]], nil),
  Subscription.new("cora", "2026-02-29", "pro", [], nil),
  Subscription.new("dune", "2025-11-30", "pro-annual", [], "2026-06-15"),
  Subscription.new("echo", "2026-06-10", "pro", [["2026-08-20", "pro-annual"]], nil)
]

cutoff = "2026-10-01"
all = []
subs.each do |sub|
  all.concat(bill(sub, cutoff))
rescue BadAnchor => e
  puts "skip #{e.customer}: #{e.message}"
end

all.group_by(&:customer).each do |customer, invs|
  puts "#{customer}:"
  invs.each do |inv|
    puts format("  %s %10s  %s", inv.date, money(inv.cents), inv.note)
  end
  puts format("  %-10s %10s", "total", money(invs.sum(&:cents)))
end

puts
monthly = Hash.new(0)
all.each { |inv| monthly[inv.date[0...7]] += inv.cents }
monthly.keys.sort.each { |month| puts format("%s %10s", month, money(monthly[month])) }
credits = all.select { |inv| inv.cents < 0 }
puts "Credits and refunds: #{credits.size}, worth #{money(-credits.sum(&:cents))}"
puts "Anchor-day clamping for 01-31: #{(0..5).map { |n| cycle_start("2026-01-31", n, 1)[5..] }.join(" ")}"
