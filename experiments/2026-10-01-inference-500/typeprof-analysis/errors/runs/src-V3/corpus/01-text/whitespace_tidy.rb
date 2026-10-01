class Change
  attr_reader :kind, :line_no, :detail

  def initialize(kind, line_no, detail)
    @kind = kind
    @line_no = line_no
    @detail = detail
  end
end

def expand_tabs(line, tab)
  out = +""
  line.each_char do |c|
    if c == "\t"
      out << " " * (tab - out.size % tab)
    else
      out << c
    end
  end
  out
end

def leading(line) = line.size - line.lstrip.size

def blank?(line) = line.strip.empty?

def dedent(lines)
  cut = lines.reject { |l| blank?(l) }.map { |l| leading(l) }.min || 0
  [lines.map { |l| blank?(l) ? "" : l[cut..] }, cut]
end

def guess_unit(lines)
  steps = Hash.new(0)
  prev = 0
  lines.each do |l|
    next if blank?(l)
    ind = leading(l)
    steps[ind - prev] += 1 if ind > prev
    prev = ind
  end
  return 0 if steps.empty?
  steps.max_by { |step, count| count * 100 - step }[0]
end

def reindent(lines, from_unit, to_unit)
  return lines if from_unit == 0
  lines.map do |l|
    level, extra = leading(l).divmod(from_unit)
    " " * (level * to_unit + extra) + l.lstrip
  end
end

def collapse_blank_runs(lines)
  out = []
  lines.each do |l|
    next if l.empty? && (out.empty? || out.last == "")
    out << l
  end
  out.pop while !out.empty? && out.last == ""
  out
end

def tidy(text, tab, to_unit)
  changes = []
  expanded = text.split("\n").each_with_index.map do |l, i|
    e = expand_tabs(l, tab)
    changes << Change.new(:tabs, i + 1, "#{l.count("\t")} tab(s)") if e != l
    stripped = e.rstrip
    if stripped != e && !blank?(e)
      changes << Change.new(:trailing, i + 1, "#{e.size - stripped.size} space(s)")
    end
    stripped
  end
  lines, cut = dedent(expanded)
  changes << Change.new(:dedent, 0, "removed #{cut} columns") if cut > 0
  unit = guess_unit(lines)
  lines = reindent(lines, unit, to_unit)
  changes << Change.new(:reindent, 0, "#{unit} -> #{to_unit}") if unit != to_unit && unit > 0
  before = lines.size
  lines = collapse_blank_runs(lines)
  removed = before - lines.size
  changes << Change.new(:blank, 0, "dropped #{removed} blank line(s)") if removed > 0
  [lines, changes]
end

def samples
  [
    "        def greet(name)\n            if name   \n\t\tputs \"hi \" + name\n            end\n\n\n\n        end\n\n",
    "\tlist:\n\t\t- one\n\t\t- two  \n\t\t\t- two.a\n",
    "already\n  tidy\n    text\n"
  ]
end

samples.each_with_index do |text, i|
  lines, changes = tidy(text, 8, 2)
  puts "=== sample #{i + 1}: #{text.split("\n").size} -> #{lines.size} lines"
  lines.each { |l| puts "  |" + l }
  if changes.empty?
    puts "  (no changes)"
  else
    changes.each do |c|
      where = c.line_no > 0 ? "line #{c.line_no}" : "file"
      puts "  * #{c.kind.to_s.ljust(9)} #{where.ljust(8)} #{c.detail}"
    end
  end
  counts = changes.map(&:kind).tally
  puts "  summary: " + counts.map { |k, v| "#{k}=#{v}" }.join(" ")
end
