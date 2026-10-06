lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
lines = lines.map { |l| l.chomp("\r") }
cands = (lines[0] || "").split(" ").uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rejected = []
lines.each_with_index do |l, i|
  next if i == 0
  next if l =~ /\A *\z/
  names = l.split(">", -1).map(&:strip)
  seen = []
  reason = nil
  names.each do |n|
    if n.empty?
      reason = "empty rank"
    elsif !cands.include?(n)
      reason = "unknown candidate #{n}"
    elsif seen.include?(n)
      reason = "duplicate #{n}"
    end
    break if reason
    seen << n
  end
  if reason
    rejected << "rejected line #{i + 1}: #{reason}"
  else
    valid << names
  end
end
puts rejected
puts "ballots: #{valid.size} valid, #{rejected.size} rejected"
cont = cands.dup
hist = []
round = 0
loop do
  round += 1
  counts = cont.to_h { |c| [c, 0] }
  active = 0
  valid.each do |b|
    w = b.find { |n| counts.key?(n) }
    if w
      counts[w] += 1
      active += 1
    end
  end
  hist << counts
  puts "round #{round}"
  cont.sort_by { |c| [-counts[c], c] }.each do |c|
    p10 = active == 0 ? 0 : (counts[c] * 2000 + active) / (2 * active)
    puts "  #{c} #{counts[c]} #{p10 / 10}.#{p10 % 10}%"
  end
  puts "  exhausted #{valid.size - active}"
  if active == 0
    puts "no winner"
    break
  end
  win = cont.find { |c| counts[c] * 2 > active }
  if win
    puts "winner #{win}"
    break
  end
  tied = cont
  (hist.size - 1).downto(0) do |k|
    mn = tied.map { |c| hist[k][c] }.min
    tied = tied.select { |c| hist[k][c] == mn }
    break if tied.size == 1
  end
  el = tied.max
  puts "  eliminated #{el}"
  cont = cont - [el]
end
