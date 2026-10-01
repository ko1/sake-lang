class Plan
  attr_reader :name, :per_seat, :min_seats

  def initialize(name, per_seat, min_seats)
    @name = name
    @per_seat = per_seat
    @min_seats = min_seats
  end
end

class Subscription
  attr_reader :customer
  attr_accessor :plan, :seats, :coupon_months, :status, :failures, :card_ok

  def initialize(customer, plan, seats, coupon_months, status, failures, card_ok)
    @customer = customer
    @plan = plan
    @seats = seats
    @coupon_months = coupon_months
    @status = status
    @failures = failures
    @card_ok = card_ok
  end

  def monthly = plan.per_seat * [seats, plan.min_seats].max
end

class PaymentDeclined < StandardError
  attr_reader :customer, :attempt

  def initialize(message, customer, attempt)
    super(message)
    @customer = customer
    @attempt = attempt
  end
end

PLANS = {
  "starter" => Plan.new("starter", 8r, 1),
  "team" => Plan.new("team", 15r, 3),
  "business" => Plan.new("business", 29r, 10)
}
DAYS_IN_MONTH = 30
COUPON_OFF = 20

def money(r) = format("%.2f", ((r * 100).round / 100r).to_f)

# switching plan or seats on `day`: credit the unused part of the old price, charge the new one
def change(sub, day, plan_name, seats)
  left = Rational(DAYS_IN_MONTH - day + 1, DAYS_IN_MONTH)
  before = sub.monthly
  sub.plan = PLANS.fetch(plan_name)
  sub.seats = seats
  (sub.monthly - before) * left
end

def charge_card(sub, amount, attempt)
  raise PaymentDeclined.new("card declined", sub.customer, attempt) unless sub.card_ok
  amount
end

def invoice(sub, adjustments)
  lines = [["#{sub.plan.name} x#{sub.seats}", sub.monthly]]
  lines.concat(adjustments)
  if sub.coupon_months > 0
    subtotal = lines.sum { |_t, amt| amt }
    lines << ["coupon -#{COUPON_OFF}%", -subtotal * COUPON_OFF / 100]
    sub.coupon_months -= 1
  end
  lines
end

subs = [
  Subscription.new("Northwind", PLANS.fetch("team"), 5, 2, :active, 0, true),
  Subscription.new("Contoso", PLANS.fetch("starter"), 2, 0, :active, 0, true),
  Subscription.new("Fabrikam", PLANS.fetch("business"), 12, 1, :active, 0, true),
  Subscription.new("Tailspin", PLANS.fetch("team"), 1, 0, :active, 0, true),
  Subscription.new("Globex", PLANS.fetch("starter"), 3, 0, :active, 0, true)
]
by_name = subs.to_h { |s| [s.customer, s] }

# events per month: [month, customer, kind, arg...]
events = [
  [1, "Contoso", :change, 16, "team", 4],
  [2, "Northwind", :change, 11, "team", 8],
  [2, "Tailspin", :card, false],
  [2, "Globex", :card, false],
  [3, "Fabrikam", :change, 21, "team", 6],
  [3, "Tailspin", :card, true],
  [4, "Contoso", :cancel]
]

revenue = Hash.new(0r)
(1..4).each do |month|
  puts "== Month #{month} =="
  pending = {}
  events.select { |e| e[0] == month }.each do |e|
    sub = by_name.fetch(e[1])
    case e[2]
    when :change
      _m, _c, _k, day, plan, seats = e
      delta = change(sub, day, plan, seats)
      pending[e[1]] = [["proration day #{day} -> #{plan} x#{seats}", delta]]
    when :card
      sub.card_ok = e[3]
    when :cancel
      sub.status = :canceled
    end
  end
  subs.each do |sub|
    name = sub.customer
    next if sub.status == :canceled
    lines = invoice(sub, pending[name] || [])
    total = lines.sum { |_t, amt| amt }
    begin
      paid = charge_card(sub, total, sub.failures + 1)
      revenue[month] += paid
      sub.failures = 0
      sub.status = :active
      puts "  #{name}: " + lines.map { |t, amt| "#{t} #{money(amt)}" }.join("; ") + " = #{money(total)}"
    rescue PaymentDeclined => e
      sub.failures = e.attempt
      sub.status = sub.failures >= 2 ? :suspended : :past_due
      puts "  #{name}: #{e.message} (attempt #{e.attempt}), now #{sub.status}"
    end
  end
end

puts
(1..4).each { |m| puts "Month #{m} collected #{money(revenue[m])}" }
active = subs.select { |s| s.status == :active }
mrr = active.sum(&:monthly)
puts "MRR #{money(mrr)} from #{active.size} active; " +
  subs.reject { |s| s.status == :active }.map { |s| "#{s.customer}=#{s.status}" }.join(", ")
seats = active.sum(&:seats)
puts "Average revenue per seat #{money(mrr / seats)}"
