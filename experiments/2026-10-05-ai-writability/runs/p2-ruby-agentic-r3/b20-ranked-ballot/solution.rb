lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
cands = (lines[0] || "").split(" ").uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rejected = []
lines[1..].each_with_index do |ln, i|
  no = i + 2
  next if ln.strip.empty?
  names = ln.split(">", -1).map(&:strip)
  seen = []
  reason = nil
  names.each do |nm|
    if nm.empty?
      reason = "empty rank"
    elsif !cands.include?(nm)
      reason = "unknown candidate #{nm}"
    elsif seen.include?(nm)
      reason = "duplicate #{nm}"
    end
    break if reason
    seen << nm
  end
  if reason
    rejected << "rejected line #{no}: #{reason}"
  else
    valid << names
  end
end
puts rejected
puts "ballots: #{valid.size} valid, #{rejected.size} rejected"

alive = cands.dup
history = [] # per round: {name => votes}
round = 0
loop do
  round += 1
  counts = alive.to_h { |c| [c, 0] }
  exhausted = 0
  valid.each do |b|
    pick = b.find { |x| alive.include?(x) }
    if pick then counts[pick] += 1 else exhausted += 1 end
  end
  history << counts
  active = valid.size - exhausted
  puts "round #{round}"
  alive.sort_by { |c| [-counts[c], c.b] }.each do |c|
    t = active.zero? ? 0 : (counts[c] * 2000 + active) / (2 * active)
    puts "  #{c} #{counts[c]} #{t / 10}.#{t % 10}%"
  end
  puts "  exhausted #{exhausted}"
  if active.zero?
    puts "no winner"
    break
  end
  w = alive.find { |c| counts[c] * 2 > active }
  if w
    puts "winner #{w}"
    break
  end
  min = counts.values.min
  tied = alive.select { |c| counts[c] == min }
  (history.size - 2).downto(0) do |r|
    break if tied.size == 1
    m = tied.map { |c| history[r][c] }.min
    tied = tied.select { |c| history[r][c] == m }
  end
  out = tied.max_by(&:b)
  puts "  eliminated #{out}"
  alive.delete(out)
end
