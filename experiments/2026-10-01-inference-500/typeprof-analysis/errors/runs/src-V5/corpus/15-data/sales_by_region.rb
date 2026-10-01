class Sale
  attr_reader :region, :rep, :product, :units, :unit_price

  def initialize(region, rep, product, units, unit_price)
    @region = region
    @rep = rep
    @product = product
    @units = units
    @unit_price = unit_price
  end

  def amount = units * unit_price
end

def raw_sales
  <<~CSV
    North,Alice,Widget,12,250
    North,Bob,Gadget,3,1200
    South,Carol,Widget,20,240
    East,Dave,Gizmo,7,560
    South,Carol,Gadget,1,1250
    North,Alice,Gizmo,4,575
    West,Erin,Widget,9,260
    East,Dave,Widget,15,245
    West,Frank,Gadget,2,1190
    South,Gina,Gizmo,6,550
    East,Hank,Gadget,5,1210
    West,Erin,Gizmo,3,580
  CSV
end

def parse_sales(text)
  text.lines.filter_map do |line|
    fields = line.chomp.split(",")
    next if fields.size != 5
    region, rep, product, units, price = fields
    Sale.new(region, rep, product, units.to_i, price.to_i)
  end
end

def money(cents)
  "$" + cents.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
end

def region_summary(sales)
  rows = sales.group_by(&:region).map do |region, list|
    {
      region: region,
      total: list.sum(&:amount),
      units: list.sum(&:units),
      count: list.size,
      best: list.max_by(&:amount)
    }
  end
  rows.sort_by { |r| -r[:total] }
end

def print_region_table(rows, grand)
  puts format("%-8s %6s %6s %12s %7s  %s", "Region", "Orders", "Units", "Revenue", "Share", "Top sale")
  puts "-" * 64
  rows.each do |r|
    share = r[:total] * 100.0 / grand
    best = r[:best]
    top = best ? "#{best.rep}/#{best.product}" : "-"
    puts format("%-8s %6d %6d %12s %6.1f%%  %s", r[:region], r[:count], r[:units], money(r[:total]), share, top)
  end
  puts "-" * 64
end

def rep_leaderboard(sales)
  totals = Hash.new(0)
  sales.each { |s| totals[s.rep] += s.amount }
  totals.sort_by { |rep, amt| [-amt, rep] }.first(3)
end

def product_mix(sales)
  mix = {}
  sales.each do |s|
    entry = (mix[s.product] ||= [0, 0])
    entry[0] += s.units
    entry[1] += s.amount
  end
  mix
end

sales = parse_sales(raw_sales)
grand = sales.sum(&:amount)
puts "Sales report (#{sales.size} orders)"
puts
print_region_table(region_summary(sales), grand)
puts format("%-8s %6d %6s %12s", "Total", sales.size, "", money(grand))
puts
puts "Top reps:"
rep_leaderboard(sales).each_with_index do |(rep, amt), i|
  puts format("  %d. %-6s %10s", i + 1, rep, money(amt))
end
puts
puts "Product mix:"
product_mix(sales).each do |product, (units, amt)|
  avg = amt / units
  puts format("  %-7s units=%3d revenue=%10s avg=%s", product, units, money(amt), money(avg))
end
