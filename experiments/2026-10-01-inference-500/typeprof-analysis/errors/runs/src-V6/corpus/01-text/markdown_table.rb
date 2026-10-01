class Table
  attr_reader :headers, :aligns, :rows

  def initialize(headers, aligns, rows)
    @headers = headers
    @aligns = aligns
    @rows = rows
  end
end

class TableError < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

def split_row(line)
  s = line.strip
  s = s[1..] if s.start_with?("|")
  s = s[0...-1] if s.end_with?("|")
  s.split("|").map(&:strip)
end

def parse_align(spec)
  left = spec.start_with?(":")
  right = spec.end_with?(":")
  raise ArgumentError, "bad alignment spec '#{spec}'" unless spec.match?(/\A:?-+:?\z/)
  if left && right
    :center
  elsif right
    :right
  else
    :left
  end
end

def parse_table(text)
  lines = text.lines.reject { |l| l.strip.empty? }
  raise TableError.new("need a header and a separator", 0) if lines.size < 2
  headers = split_row(lines[0])
  aligns = split_row(lines[1]).map { |spec| parse_align(spec) }
  if aligns.size != headers.size
    raise TableError.new("separator has #{aligns.size} cells, header has #{headers.size}", 2)
  end
  rows = lines.drop(2).each_with_index.map do |l, i|
    cells = split_row(l)
    raise TableError.new("row has #{cells.size} cells", i + 3) if cells.size > headers.size
    cells << "" while cells.size < headers.size
    cells
  end
  Table.new(headers, aligns, rows)
end

def column_widths(t)
  ws = t.headers.map { |h| h.size.clamp(3, 100) }
  t.rows.each do |r|
    r.each_with_index { |c, i| ws[i] = c.size if c.size > ws[i] }
  end
  ws
end

def cell(text, width, align)
  case align
  when :left then text.ljust(width)
  when :right then text.rjust(width)
  when :center then text.center(width)
  end
end

def rule(width, align)
  case align
  when :left then ":" + "-" * (width - 1)
  when :right then "-" * (width - 1) + ":"
  when :center then ":" + "-" * (width - 2) + ":"
  end
end

def render_row(cells, ws, aligns)
  parts = cells.each_with_index.map { |c, i| cell(c, ws[i], aligns[i]) }
  "| " + parts.join(" | ") + " |"
end

def render(t)
  ws = column_widths(t)
  out = [render_row(t.headers, ws, t.aligns)]
  out << "| " + ws.zip(t.aligns).map { |w, a| rule(w, a) }.join(" | ") + " |"
  t.rows.each { |r| out << render_row(r, ws, t.aligns) }
  out.join("\n")
end

def sort_by_column(t, name)
  idx = t.headers.index(name)
  raise ArgumentError, "no column #{name}" if !idx    
  rows = t.rows.sort_by { |r| -r[idx].delete(",$").to_f }
  Table.new(t.headers, t.aligns, rows)
end

def inputs
  [
    "| Language | Year |Typing| Users ($k) |\n|:--|:-:|---|--:|\n|Ruby|1995|dynamic|1,200|\n| Sake | 2026 | per-operation | 3\n|OCaml|1996|static|  410 |\n",
    "|a|b|\n|---|:-:|\n|1|2|3|\n",
    "|x|y|\n|--|-|\n|only|\n",
    "|a|b|\n|---|\n",
    "|name|\n|=?=|\n|bad|\n",
    "just one line\n"
  ]
end

inputs.each_with_index do |text, i|
  puts "== input #{i + 1}"
  begin
    t = parse_table(text)
    puts render(t)
    if t.headers.include?("Users ($k)")
      puts "-- sorted by users"
      puts render(sort_by_column(t, "Users ($k)"))
    end
  rescue TableError => e
    puts "table error at line #{e.line_no}: #{e.message}"
  rescue ArgumentError => e
    puts "argument error: #{e.message}"
  end
end
