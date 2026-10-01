# Sales roll-up: parse CSV-like rows into records, pivot region x month, and rank products.

def raw_sales
  <<~CSV
    region,month,product,units,unit_price
    north,2026-01,widget,12,2.50
    north,2026-01,gadget,3,10.00
    south,2026-01,widget,7,2.50
    east,2026-01,gizmo,4,6.75
    north,2026-02,widget,9,2.50
    south,2026-02,gadget,6,10.00
    south,2026-02,gizmo,2,6.75
    east,2026-02,widget,15,2.40
    east,2026-02,gadget,1,10.00
    north,2026-03,gizmo,5,6.75
    south,2026-03,widget,11,2.50
    east,2026-03,widget,8,2.40
    east,2026-03,gizmo,6,6.50
    west,2026-03,gadget,2,9.50
  CSV
end

def parse(text)
  lines = text.strip.lines
  header = lines.first.chomp.split(",").map(&:to_sym)
  rows = lines.drop(1).map do |line|
    cols = line.chomp.split(",")
    {region: cols[0], month: cols[1], product: cols[2], units: cols[3].to_i, price: cols[4].to_f}
  end
  [header, rows]
end

def revenue(r) = r[:units] * r[:price]

def pad_table(header, rows)
  widths = (0...header.size).map do |i|
    ([header] + rows).map { |row| row[i].size }.max
  end
  puts format_row(widths, header)
  puts widths.map { |w| "-" * w }.join("-+-")
  rows.each { |row| puts format_row(widths, row) }
end

def format_row(widths, cells)
  cells.each_with_index.map { |c, i| i == 0 ? c.ljust(widths[i]) : c.rjust(widths[i]) }.join(" | ")
end

header, sales = parse(raw_sales)
puts "columns: #{header.join(", ")}"
puts "rows: #{sales.size}"

months = sales.map { |r| r[:month] }.uniq.sort
regions = sales.map { |r| r[:region] }.uniq.sort

pivot = Hash.new(0.0)
sales.each do |r|
  pivot[[r[:region], r[:month]]] += revenue(r)
end

rows = regions.map do |reg|
  cells = months.map { |m| format("%.2f", pivot[[reg, m]]) }
  total = months.sum { |m| pivot[[reg, m]] }
  [reg, *cells, format("%.2f", total)]
end
month_totals = months.map { |m| regions.sum { |reg| pivot[[reg, m]] } }
grand = month_totals.sum
rows << ["total", *month_totals.map { |t| format("%.2f", t) }, format("%.2f", grand)]
pad_table(["region", *months, "total"], rows)

puts
stats = sales.group_by { |r| r[:product] }.transform_values do |rs|
  units = rs.sum { |r| r[:units] }
  rev = rs.sum { |r| revenue(r) }
  {units: units, revenue: rev, avg_price: rev / units}
end
ranked = stats.sort_by { |name, s| -s[:revenue] }
ranked.each_with_index do |(name, s), i|
  puts format("%d. %-7s units=%3d revenue=%7.2f avg=%.3f", i + 1, name, s[:units], s[:revenue], s[:avg_price])
end

puts
months.zip(month_totals).each_cons(2) do |(m1, t1), (m2, t2)|
  puts format("%s -> %s: %+.1f%%", m1, m2, (t2 - t1) / t1 * 100.0)
end
(region, month), v = pivot.max_by { |k, v| v }
puts "best cell: #{region} #{month} #{format("%.2f", v)}"
quiet = regions.product(months).reject { |key| pivot.key?(key) }
puts "no sales: #{quiet.map { |r, m| "#{r}/#{m}" }.join(", ")}"
