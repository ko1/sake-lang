class Sale
  attr_reader :date, :region, :rep, :product, :units, :unit_price

  def initialize(date, region, rep, product, units, unit_price)
    @date = date
    @region = region
    @rep = rep
    @product = product
    @units = units
    @unit_price = unit_price
  end

  def revenue = units * unit_price
  def month = date.split("-")[1].to_i
  def quarter = (month - 1) / 3 + 1
end

def parse_sales(text)
  rows = text.strip.lines.map { |l| l.strip.split("|") }
  header = rows.shift.map { |h| h.strip.to_sym }
  rows.map do |cells|
    rec = header.zip(cells.map(&:strip)).to_h
    Sale.new(rec[:date], rec[:region], rec[:rep], rec[:product], rec[:units].to_i, rec[:price].to_f)
  end
end

# commission: 3% up to 20k, 5% up to 50k, 8% above, per rep for the period
def commission(total)
  bands = [[20000.0, 0.03], [50000.0, 0.05], [nil, 0.08]]
  paid = 0.0
  floor = 0.0
  bands.each do |cap, rate|
    top = cap ? [total, cap].min : total
    paid += (top - floor) * rate if top > floor
    floor = cap || total
  end
  paid
end

def bar(value, max, width) = "*" * (value / max * width).round

data = <<~TXT
  date       | region | rep    | product  | units | price
  2026-01-14 | North  | Hana   | Widget   | 120   | 25.00
  2026-01-20 | South  | Omar   | Gadget   | 15    | 310.00
  2026-02-03 | North  | Hana   | Gadget   | 22    | 295.00
  2026-02-17 | West   | Luis   | Widget   | 300   | 24.50
  2026-02-28 | South  | Omar   | Gizmo    | 40    | 99.90
  2026-03-09 | West   | Luis   | Gadget   | 31    | 300.00
  2026-03-22 | North  | Pia    | Gizmo    | 75    | 95.00
  2026-04-02 | South  | Omar   | Widget   | 210   | 25.00
  2026-04-15 | North  | Hana   | Gadget   | 48    | 290.00
  2026-05-06 | West   | Luis   | Gizmo    | 60    | 97.50
  2026-05-19 | North  | Pia    | Widget   | 500   | 23.75
  2026-05-30 | South  | Omar   | Gadget   | 12    | 315.00
  2026-06-11 | West   | Luis   | Widget   | 150   | 25.00
  2026-06-25 | North  | Hana   | Gizmo    | 90    | 96.00
TXT


sales = parse_sales(data)
puts "#{sales.size} sales, total #{format("%.2f", sales.sum(&:revenue))}"
puts

# pivot: region x quarter
cells = Hash.new(0.0)
sales.each { |s| cells[[s.region, s.quarter]] += s.revenue }
regions = sales.map(&:region).uniq.sort
quarters = sales.map(&:quarter).uniq.sort
puts format("%-7s", "") + quarters.map { |q| format("%12s", "Q#{q}") }.join + format("%12s", "growth")
regions.each do |r|
  vals = quarters.map { |q| cells[[r, q]] }
  growth = (vals.last - vals.first) / vals.first * 100
  puts format("%-7s", r) + vals.map { |v| format("%12.2f", v) }.join + format("%+11.1f%%", growth)
end

puts
puts "Revenue by product:"
by_product = sales.group_by(&:product).transform_values { |ss| ss.sum(&:revenue) }
top = by_product.values.max
by_product.sort_by { |_p, v| -v }.each do |p, v|
  puts format("  %-7s %10.2f %s", p, v, bar(v, top, 30))
end

puts
puts "Commissions (H1):"
rows = sales.group_by(&:rep).map do |rep, ss|
  total = ss.sum(&:revenue)
  best = ss.max_by(&:revenue)
  [rep, total, commission(total), "#{best.product} #{best.date}"]
end
rows.sort_by { |_rep, total, _c, _b| -total }.each do |rep, total, c, best|
  puts format("  %-5s sold %10.2f  commission %8.2f  best deal %s", rep, total, c, best)
end

puts
avg_price = sales.group_by(&:product).transform_values do |ss|
  ss.sum(&:revenue) / ss.sum(&:units)
end
avg_price.each do |p, avg|
  below = sales.select { |s| s.product == p && s.unit_price < avg * 0.98 }
  next if below.empty?
  puts "#{p}: discounted deals by #{below.map(&:rep).uniq.join(", ")} (avg #{format("%.2f", avg)})"
end
