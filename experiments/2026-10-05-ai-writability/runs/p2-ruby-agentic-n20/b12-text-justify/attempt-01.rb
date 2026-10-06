lines = $stdin.each_line.map { |l| l.chomp("\n").chomp("\r") }
w0 = (lines[0] || "").strip
unless w0 =~ /\A\d+\z/ && (2..80).cover?(w0.to_i)
  puts "invalid width"
  exit
end
w = w0.to_i

paras = []
cur = nil
total_words = 0
lines[1..].each do |l|
  words = l.split(/[ \t]+/).reject(&:empty?)
  if words.empty?
    cur = nil
  else
    if cur.nil?
      cur = []
      paras << cur
    end
    cur.concat(words)
    total_words += words.size
  end
end

out = []
nlines = 0
paras.each_with_index do |words, pi|
  out << "|#{' ' * w}|" if pi > 0
  pieces = []
  words.each do |x|
    while x.size > w
      pieces << x[0, w - 1] + "-"
      x = x[(w - 1)..]
    end
    pieces << x
  end
  rows = []
  row = []
  pieces.each do |x|
    if row.empty? || (row.sum(&:size) + row.size + x.size) <= w
      row << x
    else
      rows << row
      row = [x]
    end
  end
  rows << row unless row.empty?
  rows.each_with_index do |r, i|
    text =
      if i == rows.size - 1 || r.size == 1
        r.join(" ")
      else
        gaps = r.size - 1
        extra = w - r.sum(&:size)
        base, rem = extra.divmod(gaps)
        s = +""
        r.each_with_index do |x, j|
          s << x
          s << " " * (base + (j < rem ? 1 : 0)) if j < gaps
        end
        s
      end
    out << "|#{text.ljust(w)}|"
    nlines += 1
  end
end

border = "+#{'-' * w}+"
puts border
puts out
puts border
puts "paragraphs: #{paras.size}, lines: #{nlines}, words: #{total_words}"
