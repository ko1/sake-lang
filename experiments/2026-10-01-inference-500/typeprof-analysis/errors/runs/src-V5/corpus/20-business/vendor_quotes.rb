class Quote
  attr_reader :vendor, :item, :currency, :tiers, :lead_days, :shipping

  def initialize(vendor, item, currency, tiers, lead_days, shipping)
    @vendor = vendor
    @item = item
    @currency = currency
    @tiers = tiers
    @lead_days = lead_days
    @shipping = shipping
  end

  # tiers: [[min_qty, unit_price], ...] in ascending min_qty
  def unit_price(qty)
    tier = tiers.select { |min, _price| qty >= min }.last
    return nil unless tier
    _min, price = tier
    price
  end

  def landed_cost(qty)
    price = unit_price(qty)
    return nil if !price    
    (price * qty + shipping) * FX.fetch(currency)
  end
end

class Need
  attr_reader :item, :qty, :by_day

  def initialize(item, qty, by_day)
    @item = item
    @qty = qty
    @by_day = by_day
  end
end

FX = { "USD" => 1.0, "EUR" => 1.08, "JPY" => 0.0067 }

def parse_tiers(s)
  s.split(" ").map do |t|
    min, price = t.split("@")
    [min.to_i, price.to_f]
  end
end

quotes = [
  ["Acme", "bolt-m8", "USD", "100@0.12 1000@0.09 10000@0.07", 5, 15.0],
  ["Bosch", "bolt-m8", "EUR", "500@0.10 5000@0.075", 9, 0.0],
  ["Chiyoda", "bolt-m8", "JPY", "1000@14 20000@10", 14, 3000.0],
  ["Acme", "washer-8", "USD", "100@0.03 1000@0.02", 5, 10.0],
  ["Chiyoda", "washer-8", "JPY", "500@3.5", 14, 1500.0],
  ["Bosch", "washer-8", "EUR", "100@0.025", 9, 12.0],
  ["Bosch", "bracket-l", "EUR", "10@4.20 100@3.65", 9, 25.0],
  ["Dynamo", "bracket-l", "USD", "50@3.90", 3, 40.0],
  ["Acme", "hinge-60", "USD", "20@6.50", 21, 12.0]
].map do |vendor, item, cur, tiers, lead, ship|
  Quote.new(vendor, item, cur, parse_tiers(tiers), lead, ship)
end

needs = [
  Need.new("bolt-m8", 4000, 10),
  Need.new("washer-8", 300, 15),
  Need.new("bracket-l", 60, 10),
  Need.new("hinge-60", 25, 14),
  Need.new("spring-3", 100, 30)
]

awards = {}
puts format("%-10s %6s  %-8s %10s  %s", "item", "qty", "vendor", "USD", "alternatives")
needs.each do |need|
  item = need.item
  qty = need.qty
  offers = quotes.select { |q| q.item == item }
  priced = offers.filter_map do |q|
    cost = q.landed_cost(qty)
    cost && q.lead_days <= need.by_day ? [q, cost] : nil
  end
  if priced.empty?
    reason = offers.empty? ? "no quotes" : "no vendor meets qty/deadline"
    puts format("%-10s %6d  %-8s %10s  (%s)", item, qty, "-", "-", reason)
    next
  end
  best, cost = priced.min_by { |_q, c| c }
  others = priced.reject { |q, _c| q == best }.map { |q, c| format("%s %.2f", q.vendor, c) }
  awards[item] = [best.vendor, cost]
  puts format("%-10s %6d  %-8s %10.2f  %s", item, qty, best.vendor, cost, others.join(", "))
end

puts
split_total = awards.sum { |_item, award| award[1] }
puts format("Split award total: %.2f across %d vendors", split_total, awards.values.map(&:first).uniq.size)

# could one vendor take everything that was awarded?
vendors = quotes.map(&:vendor).uniq
vendors.each do |v|
  costs = awards.keys.map do |item|
    need = needs.find { |n| n.item == item }
    q = quotes.find { |x| x.vendor == v && x.item == item }
    q ? q.landed_cost(need.qty) : nil
  end
  if costs.include?(nil)
    puts format("  %-8s cannot supply %d of %d items", v, costs.count(nil), costs.size)
  else
    total = costs.sum
    puts format("  %-8s single-vendor total %.2f (%+.1f%%)", v, total, (total - split_total) * 100 / split_total)
  end
end

top_vendor, won = awards.values.group_by(&:first).max_by { |_v, list| list.size }
puts "Vendor with most awards: #{top_vendor} (#{won.size})"
