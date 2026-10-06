lines = $stdin.each_line.map(&:chomp)
cands = (lines[0] || "").split(/ +/).reject(&:empty?).uniq
if cands.empty?
  puts "no candidates"
  exit
end

ballots = []
rejected = []
lines.each_with_index do |raw, i|
  next if i == 0
  next if raw.strip.empty?
  names = raw.split(">", -1).map(&:strip)
  reason = nil
  seen = {}
  names.each do |n|
    if n.empty? then reason = "empty rank"
    elsif !cands.include?(n) then reason = "unknown candidate #{n}"
    elsif seen[n] then reason = "duplicate #{n}"
    end
    break if reason
    seen[n] = true
  end
  if reason
    rejected << "rejected line #{i + 1}: #{reason}"
  else
    ballots << names
  end
end
puts rejected
puts "ballots: #{ballots.size} valid, #{rejected.size} rejected"

alive = cands.dup
hist = Hash.new { |h, k| h[k] = [] }
round = 0
loop do
  round += 1
  counts = alive.to_h { |c| [c, 0] }
  exhausted = 0
  ballots.each do |b|
    pick = b.find { |n| counts.key?(n) }
    pick ? counts[pick] += 1 : exhausted += 1
  end
  active = ballots.size - exhausted
  alive.each { |c| hist[c] << counts[c] }
  puts "round #{round}"
  counts.sort_by { |c, v| [-v, c.b] }.each do |c, v|
    t = active == 0 ? 0 : (v * 2000 + active) / (2 * active)
    puts "  #{c} #{v} #{t / 10}.#{t % 10}%"
  end
  puts "  exhausted #{exhausted}"
  if active == 0
    puts "no winner"
    break
  end
  if (w = counts.find { |_, v| v * 2 > active })
    puts "winner #{w[0]}"
    break
  end
  cand = counts.select { |_, v| v == counts.values.min }.keys
  r = round - 2
  while cand.size > 1 && r >= 0
    m = cand.map { |c| hist[c][r] }.min
    cand = cand.select { |c| hist[c][r] == m }
    r -= 1
  end
  out = cand.max_by(&:b)
  puts "  eliminated #{out}"
  alive.delete(out)
end
