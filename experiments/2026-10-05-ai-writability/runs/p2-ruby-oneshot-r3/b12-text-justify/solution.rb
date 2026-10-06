lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop while !lines.empty? && lines.last.empty?
first = lines.shift
ws = first && first.strip
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
    if cur.nil?
      cur = []
      paras << cur
    end
    cur.concat(words)
  end
end

total_words = paras.sum(&:size)
out = []
nlines = 0
paras.each_with_index do |words, pi|
  out << "|#{' ' * w}|" if pi > 0
  pieces = []
  words.each do |wd|
    while wd.size > w
      pieces << wd[0, w - 1] + "-"
      wd = wd[(w - 1)..]
    end
    pieces << wd
  end
  rows = []
  curr = []
  len = 0
  pieces.each do |p|
    if curr.empty?
      curr = [p]
      len = p.size
    elsif len + 1 + p.size <= w
      curr << p
      len += 1 + p.size
    else
      rows << curr
      curr = [p]
      len = p.size
    end
  end
  rows << curr unless curr.empty?
  rows.each_with_index do |r, i|
    nlines += 1
    if i == rows.size - 1 || r.size == 1
      s = r.join(" ")
    else
      chars = r.sum(&:size)
      gaps = r.size - 1
      extra = w - chars
      base, rem = extra.divmod(gaps)
      s = +""
      r.each_with_index do |x, j|
        s << x
        s << " " * (base + (j < rem ? 1 : 0)) if j < gaps
      end
    end
    out << "|#{s.ljust(w)}|"
  end
end

border = "+#{'-' * w}+"
puts border
puts out
puts border
puts "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
