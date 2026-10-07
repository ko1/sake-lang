#!/usr/bin/env ruby

candidates_line = gets.chomp
candidates = candidates_line.split
if candidates.empty?
  puts "no candidates"
  exit
end

candidate_set = Set.new(candidates)

ballots = []
rejected = []
line_num = 1

while (line = gets)
  line_num += 1
  stripped = line.chomp
  next if stripped.match?(/^\s*$/)

  parts = stripped.split('>')
  ballot = parts.map { |p| p.strip }

  valid = true
  reason = nil

  ballot.each_with_index do |name, idx|
    if name.empty?
      valid = false
      reason = "empty rank"
      break
    end

    unless candidate_set.include?(name)
      valid = false
      reason = "unknown candidate #{name}"
      break
    end

    if ballot[0...idx].include?(name)
      valid = false
      reason = "duplicate #{name}"
      break
    end
  end

  if valid
    ballots << ballot
  else
    rejected << "rejected line #{line_num}: #{reason}"
  end
end

rejected.each { |r| puts r }
puts "ballots: #{ballots.size} valid, #{rejected.size} rejected"

if ballots.empty?
  exit
end

continuing = Set.new(candidates)
votes_per_round = []
round_num = 0

loop do
  round_num += 1
  puts "round #{round_num}"

  votes = {}
  continuing.each { |c| votes[c] = 0 }
  exhausted = 0

  ballots.each do |ballot|
    found = false
    ballot.each do |name|
      if continuing.include?(name)
        votes[name] += 1
        found = true
        break
      end
    end
    exhausted += 1 unless found
  end

  votes_per_round << votes.dup
  active = ballots.size - exhausted

  sorted = votes.select { |c, v| v > 0 }.sort_by { |c, v| [-v, c] }
  sorted.each do |candidate, count|
    pct = active > 0 ? (count * 100.0 / active) : 0.0
    pct_rounded = (pct * 2).round / 2.0
    puts "  #{candidate} #{count} #{format('%.1f', pct_rounded)}%"
  end

  puts "  exhausted #{exhausted}"

  if active == 0
    puts "no winner"
    break
  end

  winner = votes.find { |c, v| v * 2 > active }
  if winner
    puts "winner #{winner[0]}"
    break
  end

  min_votes = votes.values.select { |v| v > 0 }.min
  candidates_to_eliminate = votes.select { |c, v| v == min_votes && continuing.include?(c) }.map { |c, v| c }

  if candidates_to_eliminate.size > 1
    (votes_per_round.size - 2).downto(0) do |round_idx|
      round_votes = votes_per_round[round_idx]
      min_prev = candidates_to_eliminate.map { |c| round_votes[c] || 0 }.min
      candidates_to_eliminate.select! { |c| (round_votes[c] || 0) == min_prev }
      break if candidates_to_eliminate.size == 1
    end
  end

  if candidates_to_eliminate.size > 1
    candidates_to_eliminate.sort!
    eliminated = candidates_to_eliminate[-1]
  else
    eliminated = candidates_to_eliminate[0]
  end

  continuing.delete(eliminated)
  puts "  eliminated #{eliminated}"
end
