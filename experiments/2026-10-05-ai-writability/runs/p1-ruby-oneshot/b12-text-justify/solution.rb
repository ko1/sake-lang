lines = $stdin.each_line.map { |l| l.chomp.chomp("\r") }
first = lines.shift
if first.nil? || (ws = first.gsub(/\A +| +\z/, "")) !~ /\A\d+\z/ || !(2..80).cover?(ws.to_i)
  puts "invalid width"
  exit
end
w = ws.to_i

paras = []
cur = nil
total_words = 0
lines.each do |l|
  words = l.split(/[ \t]+/).reject(&:empty?)
  if words.empty?
    cur = nil
  else
    if cur.nil?
      cur = []
      paras << cur
    end
    total_words += words.size
    cur.concat(words)
  end
end

out = []
nlines = 0
out << "+#{"-" * w}+"
paras.each_with_index do |words, pi|
  out << "|#{" " * w}|" if pi > 0
  pieces = []
  words.each do |wd|
    while wd.size > w
      pieces << wd[0, w - 1] + "-"
      wd = wd[(w - 1)..]
    end
    pieces << wd
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
  rows.each_with_index do |r, i|
    text =
      if i < rows.size - 1 && r.size > 1
        gaps = r.size - 1
        extra = w - r.sum(&:size)
        base, rem = extra.divmod(gaps)
        s = +""
        r.each_with_index do |x, j|
          s << x
          s << " " * (base + (j < rem ? 1 : 0)) if j < gaps
        end
        s
      else
        r.join(" ")
      end
    out << "|#{text.ljust(w)}|"
    nlines += 1
  end
end
out << "+#{"-" * w}+"
out << "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
puts out
