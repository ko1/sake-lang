#!/usr/bin/env ruby

# Parse candidates
candidates_line = gets.chomp
candidates = candidates_line.split
if candidates.empty?
  puts "no candidates"
  exit
end

candidate_set = Set.new(candidates)

# Parse ballots
ballots = []
rejected = []

line_num = 1
while line = gets
  line_num += 1
  line = line.chomp
  next if line.strip.empty?

  # Parse ballot
  ranks = line.split(">").map(&:strip)

  # Validate ballot
  valid = true
  seen = Set.new

  ranks.each do |rank|
    if rank.empty?
      rejected << "rejected line #{line_num}: empty rank"
      valid = false
      break
    elsif !candidate_set.include?(rank)
      rejected << "rejected line #{line_num}: unknown candidate #{rank}"
      valid = false
      break
    elsif seen.include?(rank)
      rejected << "rejected line #{line_num}: duplicate #{rank}"
      valid = false
      break
    end
    seen.add(rank)
  end

  ballots << ranks if valid
end

# Print rejected ballots
rejected.each { |r| puts r }

# Print ballot summary
valid_count = ballots.length
rejected_count = rejected.length
puts "ballots: #{valid_count} valid, #{rejected_count} rejected"

if valid_count == 0
  exit
end

# Initialize tracking
continuing = Set.new(candidates)
history = []  # Array of vote counts for each candidate per round
current_round = 0

# Instant runoff voting
loop do
  current_round += 1
  puts "round #{current_round}"

  # Count votes
  votes = {}
  exhausted = 0

  candidates.each { |c| votes[c] = 0 }

  ballots.each do |ballot|
    # Find highest-ranked continuing candidate
    found = false
    ballot.each do |rank|
      if continuing.include?(rank)
        votes[rank] += 1
        found = true
        break
      end
    end
    exhausted += 1 unless found
  end

  # Record history for this round
  history << votes.dup

  # Output votes
  active = valid_count - exhausted

  continuing_with_votes = continuing.sort do |a, b|
    if votes[a] != votes[b]
      votes[b] <=> votes[a]  # descending
    else
      a <=> b  # ascending
    end
  end

  continuing_with_votes.each do |candidate|
    vote_count = votes[candidate]
    if active == 0
      percentage = "0.0%"
    else
      percentage_val = vote_count * 100.0 / active
      # Round half up
      rounded = (percentage_val * 2).round / 2.0
      percentage = sprintf("%.1f%%", rounded)
    end
    printf "  %s %d %s\n", candidate, vote_count, percentage
  end

  printf "  exhausted %d\n", exhausted

  # Check for winner
  if active == 0
    puts "no winner"
    break
  end

  if votes.any? { |c, v| c != "exhausted" && v * 2 > active }
    winner = votes.max_by { |c, v| v }[0]
    puts "winner #{winner}"
    break
  end

  # Eliminate candidate with fewest votes
  # Tiebreaker: previous round votes, then previous previous round votes, etc.
  min_votes = votes.values.select { |v| v > 0 }.min
  candidates_with_min = votes.select { |c, v| continuing.include?(c) && v == min_votes }.keys

  if candidates_with_min.length == 1
    eliminated = candidates_with_min[0]
  else
    # Tiebreaker using history: keep those with fewest votes in previous rounds
    to_eliminate = candidates_with_min
    (current_round - 2).downto(0) do |round|
      break if to_eliminate.length == 1
      min_in_round = to_eliminate.map { |c| history[round][c] }.min
      to_eliminate = to_eliminate.select { |c| history[round][c] == min_in_round }
    end

    # If still tied, eliminate the one whose name is last in byte order
    if to_eliminate.length == 1
      eliminated = to_eliminate[0]
    else
      eliminated = to_eliminate.sort.last
    end
  end

  continuing.delete(eliminated)
  puts "  eliminated #{eliminated}"
end
