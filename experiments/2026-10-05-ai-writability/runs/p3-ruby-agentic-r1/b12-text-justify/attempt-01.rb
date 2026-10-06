lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop if lines.last == ""
first = lines.shift
ws = first && first.gsub(/\A +| +\z/, "")
unless ws && ws =~ /\A\d+\z/ && (2..80).cover?(ws.to_i)
  puts "invalid width"; exit
end
w = ws.to_i
paras = []
cur = nil
total = 0
lines.each do |l|
  words = l.split(/[ \t]+/).reject(&:empty?)
  if words.empty?
    cur = nil
  else
    paras << (cur = []) unless cur
    cur.concat(words)
    total += words.size
  end
end
out = []
nl = 0
paras.each_with_index do |ws_, i|
  out << "|" + " " * w + "|" if i > 0
  pieces = []
  ws_.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  rows = []
  pieces.each do |x|
    if rows.last && (rows.last.sum(&:size) + rows.last.size + x.size) <= w
      rows.last << x
    else
      rows << [x]
    end
  end
  rows.each_with_index do |r, j|
    if j == rows.size - 1 || r.size == 1
      s = r.join(" ")
    else
      g = r.size - 1
      extra = w - r.sum(&:size)
      s = +""
      r.each_with_index do |x, k|
        s << x
        s << " " * (extra / g + (k < extra % g ? 1 : 0)) if k < g
      end
    end
    out << "|" + s.ljust(w) + "|"
    nl += 1
  end
end
border = "+" + "-" * w + "+"
puts border, out, border
puts "paragraphs: #{paras.size}, lines: #{nl}, words: #{total}"
