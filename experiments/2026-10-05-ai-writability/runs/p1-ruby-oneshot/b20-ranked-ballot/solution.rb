lines = $stdin.read.to_s.b.split("\n", -1)
lines.pop if lines.last == ""
cands = (lines[0] || "").chomp("\r").split(" ").uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rejected = []
lines.each_with_index do |raw, i|
  next if i == 0
  line = raw.chomp("\r")
  next if line.match?(/\A *\z/n)
  names = line.split(">", -1).map { |x| x.gsub(/\A +| +\z/, "") }
  seen = {}
  reason = nil
  names.each do |nm|
    if nm.empty?
      reason = "empty rank"
    elsif !cands.include?(nm)
      reason = "unknown candidate #{nm}"
    elsif seen[nm]
      reason = "duplicate #{nm}"
    end
    break if reason
    seen[nm] = true
  end
  if reason
    rejected << "rejected line #{i + 1}: #{reason}"
  else
    valid << names
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
    w = b.find { |x| counts.key?(x) }
    if w
      counts[w] += 1
    else
      exhausted += 1
    end
  end
  active = valid.size - exhausted
  counts.each { |c, v| hist[c] << v }
  puts "round #{round}"
  counts.sort_by { |c, v| [-v, c] }.each do |c, v|
    pct = active == 0 ? "0.0" : begin
      t = (v * 2000 + active) / (2 * active)
      "#{t / 10}.#{t % 10}"
    end
    puts "  #{c} #{v} #{pct}%"
  end
  puts "  exhausted #{exhausted}"
  if active == 0
    puts "no winner"
    break
  end
  win = counts.find { |_, v| v * 2 > active }
  if win
    puts "winner #{win[0]}"
    break
  end
  pool = alive.dup
  k = round - 1
  pool = pool.select { |c| hist[c][round - 1] == pool.map { |x| hist[x][round - 1] }.min }
  k -= 1
  while pool.size > 1 && k >= 0
    mn = pool.map { |x| hist[x][k] }.min
    pool = pool.select { |c| hist[c][k] == mn }
    k -= 1
  end
  out = pool.max
  puts "  eliminated #{out}"
  alive.delete(out)
end
