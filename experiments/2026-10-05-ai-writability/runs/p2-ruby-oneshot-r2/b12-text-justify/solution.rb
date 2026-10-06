lines = $stdin.read.split("\n", -1).map { |l| l.chomp("\r") }
lines.pop if lines.last == ""
first = lines[0]
width = nil
if first
  s = first.gsub(/\A +| +\z/, "")
  width = s.to_i if s =~ /\A\d+\z/
end
if width.nil? || width < 2 || width > 80
  puts "invalid width"
  exit
end
W = width
paras = []
cur = nil
(lines[1..] || []).each do |l|
  ws = l.split(/[ \t]+/).reject(&:empty?)
  if ws.empty?
    cur = nil
  else
    if cur.nil?
      cur = []
      paras << cur
    end
    cur.concat(ws)
  end
end
total_words = paras.sum(&:size)
out = []
out << "+#{'-' * W}+"
nlines = 0
paras.each_with_index do |words, pi|
  out << "|#{' ' * W}|" if pi > 0
  pieces = []
  words.each do |w|
    while w.size > W
      pieces << w[0, W - 1] + "-"
      w = w[(W - 1)..]
    end
    pieces << w
  end
  rows = []
  row = []
  len = 0
  pieces.each do |p|
    if row.empty?
      row = [p]
      len = p.size
    elsif len + 1 + p.size <= W
      row << p
      len += 1 + p.size
    else
      rows << row
      row = [p]
      len = p.size
    end
  end
  rows << row unless row.empty?
  rows.each_with_index do |r, ri|
    text =
      if ri == rows.size - 1 || r.size == 1
        r.join(" ")
      else
        gaps = r.size - 1
        spaces = W - r.sum(&:size)
        base, extra = spaces.divmod(gaps)
        s = +""
        r.each_with_index do |w, k|
          s << w
          s << " " * (base + (k < extra ? 1 : 0)) if k < gaps
        end
        s
      end
    out << "|#{text.ljust(W)}|"
    nlines += 1
  end
end
out << "+#{'-' * W}+"
out << "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
puts out
