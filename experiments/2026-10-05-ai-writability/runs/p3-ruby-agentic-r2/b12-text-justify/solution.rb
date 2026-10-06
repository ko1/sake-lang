lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
wl = lines[0] && lines[0].gsub(/\A +| +\z/, "")
unless wl && wl =~ /\A\d+\z/ && (2..80).cover?(wl.to_i)
  puts "invalid width"
  exit
end
w = wl.to_i
paras = [[]]
lines[1..].each do |l|
  ws = l.split(/[ \t]+/).reject(&:empty?)
  if ws.empty?
    paras << [] unless paras.last.empty?
  else
    paras.last.concat(ws)
  end
end
paras.pop if paras.last.empty?
total = paras.sum(&:size)
out = ["+" + "-" * w + "+"]
nl = 0
paras.each_with_index do |ws, pi|
  out << "|" + " " * w + "|" if pi > 0
  pieces = []
  ws.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  rows = []
  cur = []
  pieces.each do |x|
    if cur.empty? || (cur + [x]).join(" ").size <= w
      cur << x
    else
      rows << cur
      cur = [x]
    end
  end
  rows << cur
  rows.each_with_index do |r, i|
    nl += 1
    if i < rows.size - 1 && r.size > 1
      gaps = r.size - 1
      sp = w - r.sum(&:size)
      s = r[0]
      (1..gaps).each do |g|
        s += " " * (sp / gaps + (g <= sp % gaps ? 1 : 0)) + r[g]
      end
    else
      s = r.join(" ")
    end
    out << "|" + s.ljust(w) + "|"
  end
end
out << "+" + "-" * w + "+"
out << "paragraphs: #{paras.size}, lines: #{nl}, words: #{total}"
puts out
