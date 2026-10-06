lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
cands = (lines[0] || "").split.uniq
if cands.empty?
  puts "no candidates"
  exit
end
ballots = []
rej = []
lines[1..].each_with_index do |raw, i|
  ln = raw.chomp
  next if ln.strip.empty?
  n = i + 2
  ranks = ln.split(">", -1).map(&:strip)
  seen = {}
  reason = nil
  ranks.each do |r|
    if r.empty?
      reason = "empty rank"
    elsif !cands.include?(r)
      reason = "unknown candidate #{r}"
    elsif seen[r]
      reason = "duplicate #{r}"
    end
    break if reason
    seen[r] = true
  end
  if reason
    rej << "rejected line #{n}: #{reason}"
  else
    ballots << ranks
  end
end
puts rej
puts "ballots: #{ballots.size} valid, #{rej.size} rejected"
cont = cands.dup
hist = []
round = 0
loop do
  round += 1
  cnt = {}
  cont.each { |c| cnt[c] = 0 }
  ballots.each do |b|
    w = b.find { |x| cont.include?(x) }
    cnt[w] += 1 if w
  end
  hist << cnt
  active = cnt.values.sum
  puts "round #{round}"
  cont.sort_by { |c| [-cnt[c], c] }.each do |c|
    p10 = active == 0 ? 0 : (cnt[c] * 2000 + active) / (2 * active)
    puts "  #{c} #{cnt[c]} #{p10 / 10}.#{p10 % 10}%"
  end
  puts "  exhausted #{ballots.size - active}"
  if active == 0
    puts "no winner"
    break
  end
  win = cont.find { |c| cnt[c] * 2 > active }
  if win
    puts "winner #{win}"
    break
  end
  cand = cont.select { |c| cnt[c] == cnt.values.min }
  (hist.size - 2).downto(0) do |r|
    break if cand.size == 1
    mn = cand.map { |c| hist[r][c] }.min
    cand = cand.select { |c| hist[r][c] == mn }
  end
  el = cand.max
  puts "  eliminated #{el}"
  cont.delete(el)
end
