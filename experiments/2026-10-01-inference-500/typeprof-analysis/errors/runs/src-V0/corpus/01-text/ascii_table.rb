class Column
  attr_reader :title, :align, :max_width
  attr_accessor :width

  def initialize(title, align, max_width, width)
    @title = title
    @align = align
    @max_width = max_width
    @width = width
  end
end

def format_cell(value)
  case value
  when nil then "-"
  when Integer then group_digits(value)
  when Float then format("%.2f", value)
  when String then value
  when true then "yes"
  when false then "no"
  end
end

def group_digits(n)
  sign = n < 0 ? "-" : ""
  digits = n.abs.to_s.reverse
  sign + digits.chars.each_slice(3).map(&:join).join(",").reverse
end

def default_align(values)
  numeric = values.all? { |v| v.nil? || v.is_a?(Numeric) }
  numeric ? :right : :left
end

def truncate(s, width)
  return s if s.size <= width
  return s[0...width] if width < 4
  s[0...(width - 3)] + "..."
end

def pad(s, width, align)
  case align
  when :left then s.ljust(width)
  when :right then s.rjust(width)
  when :center then s.center(width)
  end
end

def build_columns(titles, rows, limits)
  titles.each_with_index.map do |t, i|
    values = rows.map { |r| r[i] }
    Column.new(t, default_align(values), limits[t], 0)
  end
end

def measure(cols, cells)
  cols.each_with_index do |c, i|
    w = ([c.title.size] + cells.map { |row| row[i].size }).max
    w = c.max_width if c.max_width && w > c.max_width
    c.width = w
  end
end

def separator(cols, ch)
  "+" + cols.map { |c| ch * (c.width + 2) }.join("+") + "+"
end

def row_line(cols, cells, header)
  parts = cols.each_with_index.map do |c, i|
    align = header ? :center : c.align
    text = truncate(cells[i], c.width)
    " " + pad(text, c.width, align) + " "
  end
  "|" + parts.join("|") + "|"
end

def totals(titles, rows)
  titles.each_index.map do |i|
    nums = rows.map { |r| r[i] }.select { |v| v.is_a?(Numeric) }
    if i == 0
      "TOTAL"
    elsif nums.empty? || nums.size < rows.size / 2
      ""
    else
      format_cell(nums.sum)
    end
  end
end

def print_table(titles, rows, limits)
  cols = build_columns(titles, rows, limits)
  cells = rows.map { |r| r.map { |v| format_cell(v) } }
  footer = totals(titles, rows)
  measure(cols, cells + [footer])
  puts separator(cols, "=")
  puts row_line(cols, titles, true)
  puts separator(cols, "=")
  cells.each { |r| puts row_line(cols, r, false) }
  puts separator(cols, "-")
  puts row_line(cols, footer, false)
  puts separator(cols, "=")
end

titles = ["City", "Country", "Population", "Area km2", "Capital", "Density"]
rows = [
  ["Tokyo", "Japan", 13_960_000, 2194.07, true, nil],
  ["Osaka", "Japan", 2_750_000, 225.21, false, nil],
  ["Sao Paulo", "Brazil", 12_330_000, 1521.11, false, nil],
  ["Llanfairpwllgwyngyll", "United Kingdom of Great Britain", 3_107, 7.0, false, nil],
  ["Reykjavik", "Iceland", 131_136, 273.0, true, nil],
  ["Nowhere", nil, nil, nil, false, nil]
]
rows.each do |r|
  pop = r[2]
  area = r[3]
  r[5] = (pop / area).round(1) if pop && area
end
print_table(titles, rows, { "City" => 12, "Country" => 14 })
puts
print_table(["Code", "Count"], [["a1", 5], ["b22", -12_345], ["c333", 1_000_000]], {})
