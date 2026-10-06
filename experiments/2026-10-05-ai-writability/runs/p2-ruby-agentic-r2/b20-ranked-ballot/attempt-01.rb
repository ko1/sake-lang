lines = STDIN.read.split("\n", -1)
lines.pop if lines.last == ""
cands = (lines[0] || "").split(" ").uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rej = []
(1...lines.size).each do |i|
  l = lines[i]
  next if l.delete(" ").empty?
  seen = []
  reason = nil
  l.split(">", -1).each do |r|
    nm = r.strip
    if nm.empty? then reason = "empty rank"
    elsif !cands.include?(nm) then reason = "unknown candidate #{nm}"
    elsif seen.include?(nm) then reason = "duplicate #{nm}"
    end
    break if reason
    seen << nm
  end
  if reason
    rej << "rejected line #{i + 1}: #{reason}"
  else
    valid << seen
  end
end
puts rej
puts "ballots: #{valid.size} valid, #{rej.size} rejected"
cont = cands.dup
history = []
round = 0
loop do
  round += 1
  counts = cont.to_h { |c| [c, 0] }
  active = 0
  valid.each do |b|
    c = b.find { |x| cont.include?(x) }
    next unless c
    counts[c] += 1
    active += 1
  end
  history << counts
  puts "round #{round}"
  cont.sort_by { |c| [-counts[c], c.b] }.each do |c|
    pct = active == 0 ? 0 : (counts[c] * 2000 + active) / (2 * active)
    puts "  #{c} #{counts[c]} #{pct / 10}.#{pct % 10}%"
  end
  puts "  exhausted #{valid.size - active}"
  if active == 0
    puts "no winner"
    break
  end
  w = cont.find { |c| counts[c] * 2 > active }
  if w
    puts "winner #{w}"
    break
  end
  tied = cont.dup
  (history.size - 1).downto(0) do |k|
    m = tied.map { |c| history[k][c] }.min
    tied = tied.select { |c| history[k][c] == m }
    break if tied.size == 1
  end
  e = tied.max_by(&:b)
  puts "  eliminated #{e}"
  cont.delete(e)
end
