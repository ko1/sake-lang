lines = $stdin.each_line.map { |l| l.chomp("\n").chomp("\r") }
first = lines.shift
w = first && first.gsub(/\A +| +\z/, "")
unless w && w =~ /\A\d+\z/ && (2..80).cover?(w.to_i)
  puts "invalid width"
  exit
end
w = w.to_i
paras = [[]]
lines.each do |l|
  ws = l.split(/[ \t]+/).reject(&:empty?)
  if ws.empty?
    paras << [] unless paras.last.empty?
  else
    paras.last.concat(ws)
  end
end
paras.pop if paras.last.empty?
total = paras.sum(&:size)
out = []
nl = 0
paras.each_with_index do |ws, i|
  out << "|#{' ' * w}|" if i > 0
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
  len = 0
  pieces.each do |p|
    if cur.empty?
      cur = [p]; len = p.size
    elsif len + 1 + p.size <= w
      cur << p; len += 1 + p.size
    else
      rows << cur; cur = [p]; len = p.size
    end
  end
  rows << cur unless cur.empty?
  rows.each_with_index do |r, j|
    s = if j == rows.size - 1 || r.size == 1
      r.join(" ")
    else
      gaps = r.size - 1
      extra = w - r.sum(&:size)
      base, rem = extra.divmod(gaps)
      r[0..-2].each_with_index.map { |x, k| x + " " * (base + (k < rem ? 1 : 0)) }.join + r.last
    end
    out << "|#{s.ljust(w)}|"
    nl += 1
  end
end
bar = "+#{'-' * w}+"
puts bar, out, bar
puts "paragraphs: #{paras.size}, lines: #{nl}, words: #{total}"
