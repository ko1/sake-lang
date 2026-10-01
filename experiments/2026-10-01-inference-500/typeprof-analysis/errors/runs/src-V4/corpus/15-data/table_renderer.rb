class Column
  attr_reader :key, :title, :align, :kind, :width

  def initialize(key, title, align, kind, width)
    @key = key
    @title = title
    @align = align
    @kind = kind
    @width = width
  end
end

def columns
  [
    Column.new(:city, "City", :left, :text, 0),
    Column.new(:country, "Country", :center, :text, 0),
    Column.new(:population, "Population", :right, :int, 0),
    Column.new(:area, "Area km2", :right, :float1, 0),
    Column.new(:density, "Density", :right, :float1, 0),
    Column.new(:notes, "Notes", :left, :wrap, 18)
  ]
end

def cities
  [
    { city: "Tokyo", country: "JP", population: 13_960_000, area: 2194.07, notes: "capital; largest metro economy" },
    { city: "Osaka", country: "JP", population: 2_750_000, area: 225.21, notes: nil },
    { city: "Lagos", country: "NG", population: 15_388_000, area: 1171.28, notes: "fast growth" },
    { city: "Zurich", country: "CH", population: 421_878, area: 87.88, notes: "finance" },
    { city: "Reykjavik", country: "IS", population: 139_875, area: 273.0, notes: "northernmost capital of a sovereign state" },
    { city: "Montevideo", country: "UY", population: 1_319_108, area: 201.0, notes: "" }
  ]
end

def group_digits(n)
  out = n.abs.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
  n < 0 ? "-" + out : out
end

def wrap(text, width)
  lines = []
  current = ""
  text.split(" ").each do |word|
    if current.empty?
      current = word
    elsif current.size + 1 + word.size <= width
      current = current + " " + word
    else
      lines << current
      current = word
    end
  end
  lines << current unless current.empty?
  lines.empty? ? [""] : lines
end

def render_cell(col, value)
  return ["-"] if !value     || value == ""
  case col.kind
  in :int then [group_digits(value)]
  in :float1 then [format("%.1f", value)]
  in :text then [value.to_s]
  in :wrap then wrap(value, col.width)
  end
end

def pad(text, width, align)
  case align
  in :left then text.ljust(width)
  in :right then text.rjust(width)
  in :center then text.center(width)
  end
end

def render(cols, rows, totals)
  body = rows.map { |r| cols.map { |c| render_cell(c, r[c.key]) } }
  all_cells = body + [cols.map { |c| render_cell(c, totals[c.key]) }]
  widths = cols.each_with_index.map do |c, i|
    longest = all_cells.flat_map { |row| row.fetch(i) }.map(&:size).max || 0
    [longest, c.title.size].max
  end
  sep = "+" + widths.map { |w| "-" * (w + 2) }.join("+") + "+"
  out = [sep]
  header = cols.each_with_index.map { |c, i| " " + pad(c.title, widths.fetch(i), :center) + " " }
  out.push("|" + header.join("|") + "|", sep.tr("-", "="))
  all_cells.each do |row|
    height = row.map(&:size).max || 1
    height.times do |k|
      parts = cols.each_with_index.map do |c, i|
        text = row.fetch(i)[k] || ""
        " " + pad(text, widths.fetch(i), c.align) + " "
      end
      out << "|" + parts.join("|") + "|"
    end
    out << sep
  end
  out
end

rows = cities
rows.each { |r| r[:density] = r[:population] / r[:area] }
pop = rows.sum { |r| r[:population] }
area = rows.sum { |r| r[:area] }
totals = { city: "TOTAL", country: "#{rows.map { |r| r[:country] }.uniq.size} countries", population: pop, area: area, density: pop / area, notes: nil }
sorted = rows.sort_by { |r| -r[:density] }
puts render(columns, sorted, totals)
