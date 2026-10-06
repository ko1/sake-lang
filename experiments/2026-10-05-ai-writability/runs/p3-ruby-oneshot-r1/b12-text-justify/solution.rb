lines = STDIN.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop while lines.last == ''
first = lines.shift
w = first && first.gsub(/\A +| +\z/, '')
unless w && w =~ /\A\d+\z/ && (2..80).cover?(w.to_i)
  puts "invalid width"
  exit
end
w = w.to_i
paras = []
cur = nil
total_words = 0
lines.each do |l|
  ws = l.split(/[ \t]+/).reject(&:empty?)
  if ws.empty?
    cur = nil
  else
    if cur.nil?
      cur = []
      paras << cur
    end
    cur.concat(ws)
    total_words += ws.size
  end
end

out = []
nlines = 0
paras.each_with_index do |ws, i|
  out << "|#{' ' * w}|" if i > 0
  pieces = []
  ws.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + '-'
      x = x[(w - 1)..]
    end
    pieces << x
  end
  ls = []
  curl = []
  pieces.each do |x|
    if curl.empty?
      curl = [x]
    elsif (curl.sum(&:size) + curl.size - 1) + 1 + x.size <= w
      curl << x
    else
      ls << curl
      curl = [x]
    end
  end
  ls << curl unless curl.empty?
  ls.each_with_index do |l, j|
    if j == ls.size - 1 || l.size == 1
      s = l.join(' ')
    else
      gaps = l.size - 1
      spaces = w - l.sum(&:size)
      base, rem = spaces.divmod(gaps)
      s = +''
      l.each_with_index do |x, k|
        s << x
        s << ' ' * (base + (k < rem ? 1 : 0)) if k < gaps
      end
    end
    out << "|#{s.ljust(w)}|"
    nlines += 1
  end
end
border = "+#{'-' * w}+"
puts border
puts out
puts border
puts "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
