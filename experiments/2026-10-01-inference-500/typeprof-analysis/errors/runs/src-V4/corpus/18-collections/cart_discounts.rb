# Shopping-cart pricing: a catalog Hash, promotion rules of different Record shapes matched with case/in,
# bundle detection with Set subset, and coupon lookups that may fail.

class UnknownItem < StandardError
  attr_reader :sku

  def initialize(message, sku)
    super(message)
    @sku = sku
  end
end

def catalog
  {
    "tea" => {name: "Green tea", cents: 450, cat: :drinks},
    "cof" => {name: "Coffee beans", cents: 1299, cat: :drinks},
    "mug" => {name: "Mug", cents: 800, cat: :kitchen},
    "pot" => {name: "Teapot", cents: 2500, cat: :kitchen},
    "bis" => {name: "Biscuits", cents: 325, cat: :snacks},
    "cho" => {name: "Chocolate", cents: 275, cat: :snacks}
  }
end

def promotions
  [
    {bogo: "bis"},
    {category: :drinks, pct: 10},
    {bundle: Set["tea", "pot", "mug"], cents: 3200},
    {min_total: 5000, off: 500}
  ]
end

def coupons = {"WELCOME" => 300, "SNACK50" => 150}

def money(c) = format("%s$%d.%02d", c < 0 ? "-" : "", c.abs / 100, c.abs % 100)

def price_lines(cart, cat)
  cart.map do |sku, qty|
    item = cat[sku]
    raise UnknownItem.new("unknown sku #{sku}", sku) unless item
    [sku, item[:name], qty, item[:cents] * qty]
  end
end

def apply(rule, cart, cat, subtotal)
  case rule
  in {bogo:}
    q = cart.fetch(bogo, 0)
    return nil if q < 2
    ["buy one get one: #{bogo}", (q / 2) * cat[bogo][:cents]]
  in {category:, pct:}
    base = cart.sum { |sku, qty| cat[sku][:cat] == category ? cat[sku][:cents] * qty : 0 }
    base > 0 ? ["#{pct}% off #{category}", base * pct / 100] : nil
  in {bundle:, cents:}
    if bundle.subset?(cart.keys.to_set)
      full = bundle.sum { |sku| cat[sku][:cents] }
      ["bundle #{bundle.sort.join("+")}", full - cents]
    end
  in {min_total:, off:}
    subtotal >= min_total ? ["spend #{money(min_total)}", off] : nil
  end
end

def checkout(label, cart, code)
  cat = catalog
  puts "== #{label} =="
  lines = price_lines(cart, cat)
  lines.each { |sku, name, qty, total| puts format("  %-13s x%d %9s", name, qty, money(total)) }
  subtotal = lines.sum { |l| l[3] }
  puts format("  %-16s %9s", "subtotal", money(subtotal))
  discounts = promotions.map { |r| apply(r, cart, cat, subtotal) }.compact
  if code
    amount = coupons[code]
    discounts << (amount ? ["coupon #{code}", amount] : ["coupon #{code} (invalid)", 0])
  end
  discounts.each { |what, c| puts format("  %-28s %9s", what, money(-c)) }
  total = (subtotal - discounts.sum { |d| d[1] }).clamp(0, subtotal)
  puts format("  %-16s %9s", "TOTAL", money(total))
  total
rescue UnknownItem => e
  puts "  cannot price cart: #{e.message}"
  nil
end

totals = [
  checkout("tea lover", {"tea" => 2, "pot" => 1, "mug" => 1}, "WELCOME"),
  checkout("snacks", {"bis" => 5, "cho" => 2}, "SNACK50"),
  checkout("coffee", {"cof" => 3, "mug" => 2}, "BOGUS"),
  checkout("typo", {"tea" => 1, "teh" => 1}, nil)
]
paid = totals.compact
puts "carts priced: #{paid.size}/#{totals.size}, revenue #{money(paid.sum)}"
cats = catalog.values.map { |i| i[:cat] }.uniq
puts "categories: #{cats.join(", ")}"
