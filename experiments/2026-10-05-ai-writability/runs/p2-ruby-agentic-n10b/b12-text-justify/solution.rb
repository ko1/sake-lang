lines = $stdin.each_line.map { |l| l.chomp }
w0 = lines.shift
ws = w0 && w0.gsub(/\A +| +\z/, "")
unless ws && ws =~ /\A\d+\z/ && (2..80).cover?(ws.to_i)
  puts "invalid width"
  exit
end
w = ws.to_i
paras = []
cur = nil
lines.each do |l|
  words = l.split(/[ \t]+/).reject(&:empty?)
  if words.empty?
    cur = nil
  else
    paras << (cur = []) unless cur
    cur.concat(words)
  end
end
total_words = paras.sum(&:size)
out = []
nlines = 0
paras.each_with_index do |ps, i|
  out << "|#{" " * w}|" if i > 0
  pieces = []
  ps.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  ls = []
  pieces.each do |x|
    if !ls.empty? && ls[-1].sum(&:size) + ls[-1].size - 1 + 1 + x.size <= w
      ls[-1] << x
    else
      ls << [x]
    end
  end
  ls.each_with_index do |ln, j|
    if j == ls.size - 1 || ln.size == 1
      s = ln.join(" ")
    else
      gaps = ln.size - 1
      extra = w - ln.sum(&:size)
      q, r = extra.divmod(gaps)
      s = +""
      ln.each_with_index do |x, k|
        s << x
        s << " " * (q + (k < r ? 1 : 0)) if k < gaps
      end
    end
    out << "|#{s.ljust(w)}|"
    nlines += 1
  end
end
border = "+#{"-" * w}+"
puts border, out, border
puts "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
