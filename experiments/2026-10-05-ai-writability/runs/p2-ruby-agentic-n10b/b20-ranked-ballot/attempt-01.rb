lines = $stdin.each_line.map(&:chomp)
cands = (lines[0] || "").split.uniq
if cands.empty?
  puts "no candidates"
  exit
end
rej = []
ballots = []
lines.each_with_index do |l, i|
  next if i == 0
  next if l.strip.empty?
  ranks = l.split(">", -1).map(&:strip)
  seen = {}
  reason = nil
  ranks.each do |r|
    if r.empty? then reason = "empty rank"
    elsif !cands.include?(r) then reason = "unknown candidate #{r}"
    elsif seen[r] then reason = "duplicate #{r}"
    end
    break if reason
    seen[r] = true
  end
  if reason
    rej << "rejected line #{i + 1}: #{reason}"
  else
    ballots << ranks
  end
end
puts rej
puts "ballots: #{ballots.size} valid, #{rej.size} rejected"
cont = cands.dup
hist = [] # per round {cand => votes}
k = 0
loop do
  k += 1
  counts = cont.to_h { |c| [c, 0] }
  active = 0
  ballots.each do |b|
    c = b.find { |x| cont.include?(x) }
    next unless c
    counts[c] += 1
    active += 1
  end
  hist << counts
  puts "round #{k}"
  cont.sort_by { |c| [-counts[c], c] }.each do |c|
    pct = active == 0 ? 0 : (counts[c] * 1000 * 2 + active) / (2 * active)
    puts "  #{c} #{counts[c]} #{pct / 10}.#{pct % 10}%"
  end
  puts "  exhausted #{ballots.size - active}"
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
  tied = tied.select { |c| counts[c] == counts.values.min }
  (hist.size - 2).downto(0) do |j|
    break if tied.size == 1
    mn = tied.map { |c| hist[j][c] }.min
    tied = tied.select { |c| hist[j][c] == mn }
  end
  e = tied.max
  puts "  eliminated #{e}"
  cont.delete(e)
end
