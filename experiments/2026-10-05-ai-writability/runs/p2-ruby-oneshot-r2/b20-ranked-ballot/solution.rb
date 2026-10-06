lines = $stdin.readlines.map(&:chomp)
cands = (lines[0] || "").split.uniq
if cands.empty?
  puts "no candidates"
  exit
end

valid = []
rejected = []
(lines[1..] || []).each_with_index do |ln, i|
  num = i + 2
  next if ln.match?(/\A *\z/)
  seen = []
  reason = nil
  ln.split(">", -1).each do |raw|
    nm = raw.strip
    if nm.empty?
      reason = "empty rank"
    elsif !cands.include?(nm)
      reason = "unknown candidate #{nm}"
    elsif seen.include?(nm)
      reason = "duplicate #{nm}"
    else
      seen << nm
    end
    break if reason
  end
  if reason
    rejected << "rejected line #{num}: #{reason}"
  else
    valid << seen
  end
end
rejected.each { |s| puts s }
puts "ballots: #{valid.size} valid, #{rejected.size} rejected"

cont = cands.dup
hist = []
round = 0
loop do
  round += 1
  counts = cont.to_h { |c| [c, 0] }
  exhausted = 0
  valid.each do |b|
    w = b.find { |c| counts.key?(c) }
    if w
      counts[w] += 1
    else
      exhausted += 1
    end
  end
  active = valid.size - exhausted
  hist << counts
  puts "round #{round}"
  counts.sort_by { |c, v| [-v, c] }.each do |c, v|
    pct = if active == 0
            "0.0"
          else
            tn = (v * 2000 + active) / (2 * active)
            "#{tn / 10}.#{tn % 10}"
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
  mn = counts.values.min
  tied = counts.select { |_, v| v == mn }.keys
  (round - 2).downto(0) do |r|
    break if tied.size == 1
    m = tied.map { |c| hist[r][c] }.min
    tied = tied.select { |c| hist[r][c] == m }
  end
  el = tied.max
  puts "  eliminated #{el}"
  cont.delete(el)
end
