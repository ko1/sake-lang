def pct(count, active)
  return "0.0" if active == 0
  tenths = (Rational(count * 1000, active) + Rational(1, 2)).floor
  "#{tenths / 10}.#{tenths % 10}"
end

def vfmt(v)
  return v.numerator.to_s if v.denominator == 1
  c = (v * 100 + Rational(1, 2)).floor
  format("%d.%02d", c / 100, c % 100)
end

def check_ballot(line, names)
  ranks = line.split(">", -1).map(&:strip)
  seen = {}
  groups = []
  ranks.each do |rk|
    grp = []
    rk.split("=", -1).map(&:strip).each do |r|
      return [nil, "empty rank"] if r.empty?
      return [nil, "unknown candidate #{r}"] unless names.include?(r)
      return [nil, "duplicate #{r}"] if seen[r]
      seen[r] = true
      grp << r
    end
    groups << grp
  end
  [groups, nil]
end

lines = $stdin.readlines(chomp: true)
names = (lines.first || "").split
if names.empty?
  puts "no candidates"
  exit
end

ballots = []
rejected = 0
lines.each_with_index do |line, i|
  next if i == 0 || line.strip.empty?
  ranks, err = check_ballot(line, names)
  if err
    puts "rejected line #{i + 1}: #{err}"
    rejected += 1
  else
    ballots << ranks
  end
end
puts "ballots: #{ballots.size} valid, #{rejected} rejected"

continuing = names.dup
history = []
round = 0
loop do
  round += 1
  counts = continuing.to_h { [_1, Rational(0)] }
  exhausted = 0
  ballots.each do |b|
    top = b.map { |g| g.select { counts.key?(_1) } }.find { !_1.empty? }
    if top
      top.each { counts[_1] += Rational(1, top.size) }
    else
      exhausted += 1
    end
  end
  active = ballots.size - exhausted
  puts "round #{round}"
  continuing.sort_by { [-counts[_1], _1] }.each do |c|
    puts "  #{c} #{vfmt(counts[c])} #{pct(counts[c], active)}%"
  end
  puts "  exhausted #{exhausted}"
  history << counts
  if active == 0
    puts "no winner"
    break
  end
  leader = continuing.find { counts[_1] * 2 > active }
  if leader
    puts "winner #{leader}"
    break
  end
  # lowest now, then lowest in earlier rounds going back, then the name last in byte order
  past = ->(c) { history.reverse.map { _1[c] } }
  low = continuing.map(&past).min
  loser = continuing.select { past.(_1) == low }.max
  puts "  eliminated #{loser}"
  continuing.delete(loser)
end
