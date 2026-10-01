class Money
  include Comparable
  attr_reader :cents

  def initialize(cents)
    @cents = cents
  end

  def self.zero = new(0)

  def +(other) = Money.new(cents + other.cents)
  def -(other) = Money.new(cents - other.cents)
  def *(k) = Money.new((cents * k).round)
  def <=>(other) = cents <=> other.cents

  def to_s
    sign = cents < 0 ? "-" : ""
    c = cents.abs
    "#{sign}#{c / 100}.#{(c % 100).to_s.rjust(2, "0")}"
  end
end

class LineItem
  attr_reader :sku, :description, :qty, :unit_price

  def initialize(sku, description, qty, unit_price)
    @sku = sku
    @description = description
    @qty = qty
    @unit_price = unit_price
  end

  def total = unit_price * qty
end

class Invoice
  attr_reader :number, :customer, :region, :items, :coupon

  def initialize(number, customer, region, items, coupon)
    @number = number
    @customer = customer
    @region = region
    @items = items
    @coupon = coupon
  end
end

def tax_rate(region)
  rates = { "CA" => 0.0725, "NY" => 0.04, "TX" => 0.0625, "OR" => 0.0 }
  rates[region]
end

def volume_discount(subtotal)
  c = subtotal.cents
  if c >= 100_000 then 0.10
  elsif c >= 50_000 then 0.05
  else 0.0
  end
end

def coupon_value(code, subtotal)
  case code
  in nil then Money.zero
  in "FLAT20" then Money.new(2000)
  in "HALFSHIP" then Money.new(750)
  in String then subtotal * 0.0
  end
end

def invoices
  [
    Invoice.new("INV-001", "Northwind", "CA", [
      LineItem.new("KB-1", "Keyboard", 3, Money.new(4999)),
      LineItem.new("MS-2", "Mouse", 3, Money.new(1999)),
      LineItem.new("MN-7", "Monitor 27in", 2, Money.new(28900))
    ], nil),
    Invoice.new("INV-002", "Contoso", "NY", [
      LineItem.new("CB-9", "USB-C cable", 10, Money.new(899)),
      LineItem.new("HD-4", "Headset", 1, Money.new(7450))
    ], "FLAT20"),
    Invoice.new("INV-003", "Fabrikam", "OR", [
      LineItem.new("LT-3", "Laptop", 2, Money.new(129900)),
      LineItem.new("DK-1", "Dock", 2, Money.new(18900)),
      LineItem.new("CB-9", "USB-C cable", 4, Money.new(899))
    ], "BOGUS"),
    Invoice.new("INV-004", "Tailspin", "WA", [
      LineItem.new("MS-2", "Mouse", 1, Money.new(1999))
    ], "HALFSHIP")
  ]
end

def compute(inv)
  subtotal = inv.items.reduce(Money.zero) { |acc, it| acc + it.total }
  discount = subtotal * volume_discount(subtotal)
  coupon = coupon_value(inv.coupon, subtotal)
  coupon = subtotal - discount if coupon > subtotal - discount
  taxable = subtotal - discount - coupon
  rate = tax_rate(inv.region)
  tax = rate ? taxable * rate : Money.zero
  { subtotal: subtotal, discount: discount, coupon: coupon, tax: tax, total: taxable + tax, known_region: !!rate     }
end

def print_invoice(inv, r)
  puts "#{inv.number}  #{inv.customer} (#{inv.region})"
  inv.items.each do |it|
    puts format("  %-6s %-14s %3d x %9s %10s", it.sku, it.description, it.qty, it.unit_price, it.total)
  end
  puts format("  %38s %10s", "subtotal", r[:subtotal])
  puts format("  %38s %10s", "volume discount", Money.zero - r[:discount]) if r[:discount] > Money.zero
  code = inv.coupon
  puts format("  %38s %10s", "coupon #{code}", Money.zero - r[:coupon]) if code && r[:coupon] > Money.zero
  puts format("  %38s", "coupon #{code} not recognized") if code && r[:coupon] == Money.zero
  puts format("  %38s %10s", r[:known_region] ? "tax" : "tax (no rate on file)", r[:tax])
  puts format("  %38s %10s", "TOTAL", r[:total])
  puts
end

all = invoices
results = all.map { |inv| [inv, compute(inv)] }
results.each { |inv, r| print_invoice(inv, r) }

totals = results.map { |inv, r| r[:total] }
grand = totals.reduce(Money.zero) { |a, b| a + b }
largest = totals.max
puts "Invoices: #{all.size}  grand total: #{grand}  largest: #{largest}"
sku_qty = Hash.new(0)
all.each { |inv| inv.items.each { |it| sku_qty[it.sku] += it.qty } }
best = sku_qty.max_by { |sku, q| q }
if best
  sku, q = best
  puts "Most units: #{sku} (#{q})"
end
