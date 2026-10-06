lines = $stdin.each_line.map { |l| l.chomp }
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

total_words = paras.sum(&:size)
out = ["+" + "-" * w + "+"]
nlines = 0
paras.each_with_index do |words, pi|
  out << "|" + " " * w + "|" if pi > 0
  pieces = []
  words.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  rows = []
  cur = []
  len = 0
  pieces.each do |x|
    if cur.empty?
      cur = [x]; len = x.size
    elsif len + 1 + x.size <= w
      cur << x; len += 1 + x.size
    else
      rows << cur
      cur = [x]; len = x.size
    end
  end
  rows << cur unless cur.empty?
  rows.each_with_index do |r, i|
    nlines += 1
    s =
      if i == rows.size - 1 || r.size == 1
        r.join(" ")
      else
        gaps = r.size - 1
        extra = w - r.sum(&:size)
        base, rem = extra.divmod(gaps)
        r.each_with_index.map { |x, j| j < gaps ? x + " " * (base + (j < rem ? 1 : 0)) : x }.join
      end
    out << "|" + s.ljust(w) + "|"
  end
end
out << "+" + "-" * w + "+"
out << "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
puts out
