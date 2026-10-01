class Edit
  attr_reader :op, :old_no, :new_no, :text

  def initialize(op, old_no, new_no, text)
    @op = op
    @old_no = old_no
    @new_no = new_no
    @text = text
  end
end

def lcs_table(a, b)
  n = a.size
  m = b.size
  t = Array.new(n + 1) { Array.new(m + 1, 0) }
  (n - 1).downto(0) do |i|
    (m - 1).downto(0) do |j|
      t[i][j] = a[i] == b[j] ? t[i + 1][j + 1] + 1 : [t[i + 1][j], t[i][j + 1]].max
    end
  end
  t
end

def diff(a, b)
  t = lcs_table(a, b)
  edits = []
  i = 0
  j = 0
  while i < a.size || j < b.size
    if i < a.size && j < b.size && a[i] == b[j]
      edits << Edit.new(:same, i + 1, j + 1, a[i])
      i += 1
      j += 1
    elsif i < a.size && (j >= b.size || t[i + 1][j] >= t[i][j + 1])
      edits << Edit.new(:del, i + 1, nil, a[i])
      i += 1
    else
      edits << Edit.new(:add, nil, j + 1, b[j])
      j += 1
    end
  end
  edits
end

def hunks(edits, context)
  changed = (0...edits.size).select { |k| edits[k].op != :same }
  groups = []
  changed.each do |k|
    lo = (k - context).clamp(0, edits.size - 1)
    hi = (k + context).clamp(0, edits.size - 1)
    last = groups.last
    if last && lo <= last[1] + 1
      last[1] = hi
    else
      groups << [lo, hi]
    end
  end
  groups.map { |lo, hi| edits[lo..hi] }
end

def start_of(hunk, side)
  hunk.each do |e|
    n = side == :old ? e.old_no : e.new_no
    return n if n
  end
  0
end

def header(hunk)
  old_len = hunk.count { |e| e.op != :add }
  new_len = hunk.count { |e| e.op != :del }
  "@@ -#{start_of(hunk, :old)},#{old_len} +#{start_of(hunk, :new)},#{new_len} @@"
end

def prefix(op)
  case op
  when :same then " "
  when :add then "+"
  when :del then "-"
  end
end

def unified(name, a, b, context)
  edits = diff(a, b)
  puts "--- a/#{name}"
  puts "+++ b/#{name}"
  hs = hunks(edits, context)
  if hs.empty?
    puts "(no differences)"
    return
  end
  hs.each do |h|
    puts header(h)
    h.each { |e| puts prefix(e.op) + e.text }
  end
  stats = edits.map(&:op).tally
  puts "#{stats.fetch(:add, 0)} insertions(+), #{stats.fetch(:del, 0)} deletions(-)"
end

old_text = "# Config loader\ndef load(path)\n  text = File.read(path)\n  parse(text)\nend\n\ndef parse(text)\n  text.lines.map(&:strip)\nend\n\ndef unused\n  nil\nend\n# end of file"
new_text = "# Config loader\ndef load(path)\n  text = File.read(path)\n  raise \"empty\" if text.empty?\n  parse(text)\nend\n\ndef parse(text)\n  text.lines.map(&:chomp)\nend\n\n# end of file\n# (generated)"

unified("config.rb", old_text.split("\n"), new_text.split("\n"), 2)
puts
unified("same.txt", ["a", "b"], ["a", "b"], 3)
puts
unified("words.txt", "the cat sat on the mat".split(" "), "a cat sat on a hat today".split(" "), 1)
