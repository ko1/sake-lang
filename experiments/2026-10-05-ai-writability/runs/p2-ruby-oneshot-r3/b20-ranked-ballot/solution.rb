lines = $stdin.read.each_line.map { |l| l.chomp.chomp("\r") }
cands = (lines[0] || "").split.uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rejected = []
(1...lines.size).each do |i|
  l = lines[i]
  next if l =~ /\A *\z/
  seen = []
  reason = nil
  l.split(">", -1).each do |part|
    nm = part.strip
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
    rejected << "rejected line #{i + 1}: #{reason}"
  else
    valid << seen
  end
end
puts rejected
puts "ballots: #{valid.size} valid, #{rejected.size} rejected"
alive = cands.dup
hist = Hash.new { |h, k| h[k] = [] }
round = 0
loop do
  round += 1
  counts = alive.to_h { |c| [c, 0] }
  exhausted = 0
  valid.each do |b|
    top = b.find { |c| counts.key?(c) }
    if top
      counts[top] += 1
    else
      exhausted += 1
    end
  end
  active = valid.size - exhausted
  alive.each { |c| hist[c] << counts[c] }
  puts "round #{round}"
  counts.sort_by { |c, v| [-v, c] }.each do |c, v|
    pct = active == 0 ? 0 : (v * 2000 + active) / (2 * active)
    puts "  #{c} #{v} #{pct / 10}.#{pct % 10}%"
  end
  puts "  exhausted #{exhausted}"
  if active == 0
    puts "no winner"
    break
  end
  w = counts.find { |_, v| v * 2 > active }
  if w
    puts "winner #{w[0]}"
    break
  end
  tied = alive
  (0...round).reverse_each do |r|
    mn = tied.map { |c| hist[c][r] }.min
    tied = tied.select { |c| hist[c][r] == mn }
  end
  # round r=round-1 is current round; then earlier rounds
  out = tied.max
  puts "  eliminated #{out}"
  alive -= [out]
end
