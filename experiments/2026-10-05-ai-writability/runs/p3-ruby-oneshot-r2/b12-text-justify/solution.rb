lines = $stdin.read.to_s.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop while lines.last == "" && lines.size > 1
first = lines.shift
if first.nil? || first.strip !~ /\A\d+\z/ || !(2..80).cover?(first.strip.to_i)
  puts "invalid width"
  exit
end
w = first.strip.to_i
paras = []
cur = nil
lines.each do |l|
  words = l.split(/[ \t]+/).reject(&:empty?)
  if words.empty?
    cur = nil
  else
    if cur.nil?
      cur = []
      paras << cur
    end
    cur.concat(words)
  end
end
out = []
out << "+" + "-" * w + "+"
nlines = 0
nwords = 0
paras.each_with_index do |ws, i|
  nwords += ws.size
  out << "|" + " " * w + "|" if i > 0
  pieces = []
  ws.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  rows = []
  row = []
  len = 0
  pieces.each do |p|
    if row.empty?
      row = [p]
      len = p.size
    elsif len + 1 + p.size <= w
      row << p
      len += 1 + p.size
    else
      rows << row
      row = [p]
      len = p.size
    end
  end
  rows << row unless row.empty?
  rows.each_with_index do |r, j|
    if j < rows.size - 1 && r.size > 1
      gaps = r.size - 1
      total = w - r.sum(&:size)
      base, extra = total.divmod(gaps)
      s = +""
      r.each_with_index do |x, k|
        s << x
        s << " " * (base + (k < extra ? 1 : 0)) if k < gaps
      end
    else
      s = r.join(" ")
    end
    out << "|" + s.ljust(w) + "|"
    nlines += 1
  end
end
out << "+" + "-" * w + "+"
out << "paragraphs: #{paras.size}, lines: #{nlines}, words: #{nwords}"
puts out
