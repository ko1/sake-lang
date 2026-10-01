class Pivot
  attr_reader :cells, :rows, :cols

  def initialize
    @cells = Hash.new(0)
    @rows = []
    @cols = []
  end

  def [](key) = cells[key]

  def []=(key, v)
    row, col = key
    rows << row unless rows.include?(row)
    cols << col unless cols.include?(col)
    cells[key] = v
  end

  def row_total(row) = cols.sum { |c| cells[[row, c]] }
  def col_total(col) = rows.sum { |r| cells[[r, col]] }
  def grand_total = rows.sum { |r| row_total(r) }
end

def expenses
  [
    ["2026-01-04", "travel", 412.50], ["2026-01-09", "meals", 86.20],
    ["2026-01-15", "software", 299.00], ["2026-01-21", "meals", 41.75],
    ["2026-02-02", "travel", 1290.00], ["2026-02-11", "office", 64.99],
    ["2026-02-14", "meals", 152.40], ["2026-02-27", "software", 299.00],
    ["2026-03-03", "office", 210.10], ["2026-03-08", "travel", 388.00],
    ["2026-03-19", "meals", 73.30], ["2026-03-22", "training", 950.00],
    ["2026-03-30", "software", 49.00], ["2026-04-01", "meals", 18.90],
    ["2026-04-12", "travel", 702.25], ["2026-04-18", "office", 33.15]
  ]
end

def month_name(ym)
  names = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
  idx = ym[5, 2].to_i - 1
  names[idx] || ym
end

def cell(v) = v == 0 ? format("%9s", "-") : format("%9.2f", v)

pv = Pivot.new
expenses.each do |date, category, amount|
  month = date[0, 7]
  pv[[category, month]] += amount
end

categories = pv.rows.sort
months = pv.cols.sort
grand = pv.grand_total

header = format("%-10s", "category") + months.map { |m| format("%9s", month_name(m)) }.join + format("%10s %6s", "total", "share")
puts header
puts "=" * header.size
categories.sort_by { |c| -pv.row_total(c) }.each do |cat|
  line = format("%-10s", cat)
  months.each { |m| line += cell(pv[[cat, m]]) }
  total = pv.row_total(cat)
  line += format("%10.2f %5.1f%%", total, total / grand * 100)
  puts line
end
puts "-" * header.size
footer = format("%-10s", "total")
months.each { |m| footer += format("%9.2f", pv.col_total(m)) }
puts footer + format("%10.2f %5.1f%%", grand, 100.0)

puts
month_totals = months.map { |m| [m, pv.col_total(m)] }
peak = month_totals.max_by { |m, t| t }
low = month_totals.min_by { |m, t| t }
if peak && low
  peak_m, peak_t = peak
  low_m, low_t = low
  puts format("Busiest month: %s (%.2f)", month_name(peak_m), peak_t)
  puts format("Quietest month: %s (%.2f)", month_name(low_m), low_t)
end
month_totals.each_cons(2) do |(am, at), (bm, bt)|
  change = (bt - at) / at * 100
  puts format("%s -> %s: %+7.1f%%", month_name(am), month_name(bm), change)
end
recurring = categories.select { |c| months.all? { |m| pv[[c, m]] > 0 } }
puts "Every month: #{recurring.join(", ")}"
