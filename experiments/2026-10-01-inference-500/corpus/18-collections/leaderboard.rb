# Tournament leaderboard: merge per-round score Hashes, competition ranking with ties, movers, streaks.

def rounds
  [
    {"ana" => 12, "bo" => 9, "cy" => 15, "dee" => 9},
    {"ana" => 8, "bo" => 14, "cy" => 7, "eli" => 20},
    {"ana" => 10, "bo" => 10, "cy" => 13, "dee" => 18, "eli" => 2},
    {"bo" => 11, "cy" => 9, "dee" => 4, "eli" => 12, "fay" => 25}
  ]
end

def add_scores(total, round)
  total.merge(round) { |name, a, b| a + b }
end

# competition ranking: equal scores share a rank, the next rank skips
def ranking(totals)
  sorted = totals.sort_by { |name, pts| [-pts, name] }
  prev = nil
  rank = 0
  sorted.each_with_index.map do |(name, pts), i|
    rank = i + 1 if prev.nil? || pts != prev
    prev = pts
    [rank, name, pts]
  end
end

def rank_of(ranks, name)
  row = ranks.find { |r, n, p| n == name }
  row ? row[0] : nil
end

totals = {}
history = []
rounds.each_with_index do |round, i|
  totals = add_scores(totals, round)
  history << ranking(totals)
  winner = round.max_by { |n, p| p }
  puts "round #{i + 1}: #{round.size} players, best #{winner[0]} (#{winner[1]})"
end

puts "== Final standings =="
final = history.last
final.each do |rank, name, pts|
  played = rounds.count { |r| r.key?(name) }
  avg = pts / played.to_f
  puts format("%2d. %-4s %3d  (%d rounds, %.1f avg)", rank, name, pts, played, avg)
end
ties = final.group_by { |r, n, p| r }.select { |r, rows| rows.size > 1 }
ties.each { |r, rows| puts "tied at #{r}: #{rows.map { |x, n, p| n }.join(", ")}" }

puts "== Movers (last round) =="
before = history[-2]
final.each do |rank, name, pts|
  old = rank_of(before, name)
  move = old.nil? ? "new" : (old == rank ? "=" : format("%+d", old - rank))
  puts format("  %-4s %s", name, move)
end

puts "== Streaks =="
everyone = rounds.reduce(Set[]) { |acc, r| acc | r.keys.to_set }
everyone.sort.each do |name|
  flags = rounds.map { |r| r.key?(name) }
  longest = flags.chunk_while { |a, b| a == b }.select(&:first).map(&:size).max
  missed = flags.each_with_index.filter_map { |f, i| f ? nil : i + 1 }
  puts format("  %-4s played %s longest run %d%s", name, flags.map { |f| f ? "x" : "." }.join, longest || 0, missed.empty? ? "" : " missed #{missed.join(",")}")
end
always = rounds.map { |r| r.keys.to_set }.reduce(:&)
puts "played every round: #{always.sort.join(", ")}"
round_best = rounds.map { |r| r.values.max }
puts "best single round: #{round_best.max} in round #{round_best.index(round_best.max) + 1}"
