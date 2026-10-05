class Sale
  attr_reader :region, :product, :quarter, :units, :price

  def initialize(region, product, quarter, units, price)
    @region = region
    @product = product
    @quarter = quarter
    @units = units
    @price = price
  end

  def revenue = @units * @price
end

class RowError < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

def csv_text
  "region,product,quarter,units,price
north,widget,Q1,120,2.50
north,gadget,Q1,40,10.00
south,widget,Q1,80,2.50
south,gadget,Q2,55,9.50
east,widget,Q2,200,2.25
north,widget,Q2,130,2.50
west,gizmo,Q2,abc,4.00
east,gadget,Q3,60,10.00
south,widget,Q3,95,2.40
north,gizmo,Q3,15,4.00
west,widget,Q4,70,2.60
east,gizmo
south,gadget,Q4,65,9.75
north,widget,Q4,150,2.45
"
end

def parse_row(header, line, line_no)
  cells = line.split(",")
  if cells.size != header.size
    raise RowError.new("expected #{header.size} fields, got #{cells.size}", line_no)
  end
  row = {}
  header.each_with_index { |h, i| row[h] = cells[i] }
  units = row["units"]
  unless units.match?(/^\d+$/)
    raise RowError.new("units is not a number: #{units}", line_no)
  end
  Sale.new(row["region"], row["product"], row["quarter"], units.to_i, row["price"].to_f)
end

def pivot(sales)
  table = Hash.new(0.0)
  sales.each do |s|
    table[[s.region, s.quarter]] += s.revenue
  end
  table
end

def print_pivot(table, rows, cols)
  puts format("%-8s", "") + cols.map { |c| format("%9s", c) }.join + format("%10s", "total")
  col_totals = Hash.new(0.0)
  rows.each do |r|
    line = format("%-8s", r)
    row_total = 0.0
    cols.each do |c|
      v = table[[r, c]]
      row_total += v
      col_totals[c] += v
      line += format("%9.2f", v)
    end
    puts line + format("%10.2f", row_total)
  end
  grand = col_totals.values.sum
  puts format("%-8s", "total") + cols.map { |c| format("%9.2f", col_totals[c]) }.join + format("%10.2f", grand)
end

lines = csv_text.lines
header = lines[0].chomp.split(",")
sales = []
errors = []
lines.drop(1).each_with_index do |raw, i|
  begin
    sales << parse_row(header, raw.chomp, i + 2)
  rescue RowError => e
    errors << "line #{e.line_no}: #{e.message}"
  end
end
puts "rows: #{sales.size} ok, #{errors.size} rejected"
errors.each { |msg| puts "  #{msg}" }

regions = sales.map(&:region).uniq.sort
quarters = sales.map(&:quarter).uniq.sort
print_pivot(pivot(sales), regions, quarters)

by_product = sales.group_by(&:product)
puts "by product:"
by_product.keys.sort.each do |prod|
  group = by_product[prod]
  units = group.sum(&:units)
  rev = group.sum(&:revenue)
  puts format("  %-7s units=%4d revenue=%8.2f avg price=%5.2f", prod, units, rev, rev / units)
end

best = sales.max_by(&:revenue)
if best
  puts format("largest sale: %s %s %s %.2f", best.region, best.product, best.quarter, best.revenue)
end
