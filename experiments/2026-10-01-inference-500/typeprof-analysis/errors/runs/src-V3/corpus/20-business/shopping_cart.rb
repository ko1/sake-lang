class Money
  include Comparable
  attr_reader :cents

  def initialize(cents)
    @cents = cents
  end

  def self.zero = Money.new(0)
  def +(other) = Money.new(cents + other.cents)
  def -(other) = Money.new(cents - other.cents)
  def *(k) = Money.new((cents * k).round)
  def <=>(other) = cents <=> other.cents

  def to_s
    sign = cents < 0 ? "-" : ""
    c = cents.abs
    "#{sign}$#{c / 100}.#{(c % 100).to_s.rjust(2, "0")}"
  end
end

class Product
  attr_reader :sku, :name, :category, :price

  def initialize(sku, name, category, price)
    @sku = sku
    @name = name
    @category = category
    @price = price
  end
end

class Line
  attr_reader :product
  attr_accessor :qty

  def initialize(product, qty)
    @product = product
    @qty = qty
  end
end

class CartError < StandardError
  attr_reader :sku

  def initialize(message, sku)
    super(message)
    @sku = sku
  end
end

def tax_rate(category)
  case category
  when :food then 0.08
  when :books then 0.0
  else 0.1
  end
end

class Cart
  attr_reader :catalog, :lines
  attr_accessor :coupon

  def initialize(catalog)
    @catalog = catalog
    @lines = []
    @coupon = nil
  end

  def add(sku, qty)
    product = @catalog[sku]
    raise CartError.new("unknown product", sku) unless product
    raise CartError.new("quantity must be positive", sku) if qty <= 0
    line = @lines.find { |l| l.product.sku == sku }
    if line
      line.qty += qty
    else
      @lines << Line.new(product, qty)
    end
  end

  def remove(sku, qty)
    line = @lines.find { |l| l.product.sku == sku }
    raise CartError.new("not in cart", sku) unless line
    left = line.qty - qty
    if left > 0
      line.qty = left
    else
      @lines.delete(line)
    end
  end

  def subtotal
    @lines.reduce(Money.zero) { |sum, l| sum + l.product.price * l.qty }
  end

  # every third unit of a "3for2" product is free
  def discounts(promos)
    result = []
    @lines.each do |l|
      prod = l.product
      promo = promos[prod.sku]
      next unless promo
      case promo
      in {kind: :three_for_two}
        free = l.qty / 3
        result << ["3 for 2 #{prod.name}", prod.price * free] if free > 0
      in {kind: :percent, rate:}
        result << ["#{rate}% off #{prod.name}", prod.price * l.qty * (rate / 100.0)]
      end
    end
    result
  end
end

def coupon_value(code, amount)
  case code
  when "SAVE5"
    raise CartError.new("SAVE5 needs $30.00", code) if amount < Money.new(3000)
    Money.new(500)
  when "TENOFF"
    amount * 0.1
  when nil
    Money.zero
  else
    raise CartError.new("unknown coupon", code)
  end
end

def receipt(cart, promos)
  puts "Receipt"
  cart.lines.each do |l|
    prod = l.product
    total = prod.price * l.qty
    puts format("  %-18s %2d x %8s %9s", prod.name, l.qty, prod.price, total)
  end
  sub = cart.subtotal
  puts format("  %-32s %9s", "Subtotal", sub)
  disc = Money.zero
  cart.discounts(promos).each do |label, amount|
    puts format("  %-32s %9s", label, Money.zero - amount)
    disc += amount
  end
  after = sub - disc
  coupon = Money.zero
  begin
    coupon = coupon_value(cart.coupon, after)
    puts format("  %-32s %9s", "Coupon #{cart.coupon}", Money.zero - coupon) if coupon > Money.zero
  rescue CartError => e
    puts "  (coupon #{e.sku} rejected: #{e.message})"
  end
  # tax is computed on the discounted price of each line, proportionally
  ratio = sub.cents == 0 ? 0.0 : (after - coupon).cents * 1.0 / sub.cents
  tax = cart.lines.reduce(Money.zero) do |acc, l|
    acc + l.product.price * l.qty * (ratio * tax_rate(l.product.category))
  end
  puts format("  %-32s %9s", "Tax", tax)
  total = after - coupon + tax
  puts format("  %-32s %9s", "TOTAL", total)
  total
end

catalog = {}
[
  ["A100", "Coffee beans", :food, 1299],
  ["A200", "Green tea", :food, 650],
  ["B300", "Ruby book", :books, 3999],
  ["C400", "Mug", :kitchen, 899],
  ["C500", "Kettle", :kitchen, 4550]
].each do |sku, name, cat, cents|
  catalog[sku] = Product.new(sku, name, cat, Money.new(cents))
end
promos = { "A200" => {kind: :three_for_two}, "C500" => {kind: :percent, rate: 15} }

cart = Cart.new(catalog)
ops = [
  [:add, "A100", 2], [:add, "A200", 4], [:add, "Z999", 1], [:add, "C400", 0],
  [:add, "B300", 1], [:add, "C400", 2], [:remove, "C400", 1], [:add, "C500", 1],
  [:remove, "B300", 5], [:remove, "B300", 1], [:add, "A200", 2]
]
ops.each do |op, sku, qty|
  begin
    op == :add ? cart.add(sku, qty) : cart.remove(sku, qty)
  rescue CartError => e
    puts "! #{op} #{sku}: #{e.message}"
  end
end

totals = []
[nil, "SAVE5", "TENOFF", "BOGUS"].each do |code|
  cart.coupon = code
  totals << [code, receipt(cart, promos)]
  puts
end
best_code, best_total = totals.min_by { |_c, t| t.cents }
puts "Best coupon: #{best_code || "none"} (#{best_total})"
puts "Most expensive item: #{catalog.values.max_by(&:price).name}"
