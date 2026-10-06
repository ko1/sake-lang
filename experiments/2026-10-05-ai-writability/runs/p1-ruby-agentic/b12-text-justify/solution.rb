lines = $stdin.each_line.map { |l| l.chomp.delete("\r") }
w0 = lines.shift
w0 = w0&.gsub(/\A +| +\z/, "")
unless w0 && w0.match?(/\A\d+\z/) && (2..80).cover?(w0.to_i)
  puts "invalid width"
  exit
end
w = w0.to_i
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
out = []
nlines = 0
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
  pieces.each do |x|
    if cur.empty? || cur.sum(&:size) + cur.size + x.size <= w
      cur << x
    else
      rows << cur
      cur = [x]
    end
  end
  rows << cur unless cur.empty?
  rows.each_with_index do |r, j|
    nlines += 1
    s =
      if j == rows.size - 1 || r.size == 1
        r.join(" ")
      else
        gaps = r.size - 1
        extra = w - r.sum(&:size)
        base, rem = extra.divmod(gaps)
        r.each_with_index.map { |x, k| k < gaps ? x + " " * (base + (k < rem ? 1 : 0)) : x }.join
      end
    out << "|#{s.ljust(w)}|"
  end
end
border = "+#{'-' * w}+"
puts border, out, border
puts "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
