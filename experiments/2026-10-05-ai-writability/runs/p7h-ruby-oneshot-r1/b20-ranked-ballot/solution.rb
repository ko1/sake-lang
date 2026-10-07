#!/usr/bin/env ruby

# Parse candidates
candidates_line = gets.strip
candidates = candidates_line.split(/\s+/)

if candidates.empty?
  puts "no candidates"
  exit
end

candidate_set = Set.new(candidates)

# Parse ballots
ballots = []
rejected = []

STDIN.each_line.with_index do |line, idx|
  line_num = idx + 2
  line = line.strip

  next if line.empty?

  # Parse ballot: names separated by >
  ranks = line.split('>').map { |s| s.strip }

  # Validate ballot
  seen = Set.new
  valid = true
  final_ranks = []

  ranks.each do |name|
    if name.empty?
      rejected << "rejected line #{line_num}: empty rank"
      valid = false
      break
    elsif !candidate_set.include?(name)
      rejected << "rejected line #{line_num}: unknown candidate #{name}"
      valid = false
      break
    elsif seen.include?(name)
      rejected << "rejected line #{line_num}: duplicate #{name}"
      valid = false
      break
    else
      seen << name
      final_ranks << name
    end
  end

  if valid
    ballots << final_ranks
  end
end

rejected.each { |msg| puts msg }

puts "ballots: #{ballots.size} valid, #{rejected.size} rejected"

if ballots.empty?
  exit
end

# Instant runoff voting
continuing = Set.new(candidates)
round = 0
vote_history = {}  # candidate => [votes per round]

loop do
  round += 1
  puts "round #{round}"

  # Count votes
  votes = {}
  exhausted = 0

  continuing.each { |c| votes[c] = 0 }

  ballots.each do |ballot|
    # Find first continuing candidate in ballot
    voted = false
    ballot.each do |candidate|
      if continuing.include?(candidate)
        votes[candidate] += 1
        voted = true
        break
      end
    end
    exhausted += 1 unless voted
  end

  # Record vote history
  continuing.each do |c|
    vote_history[c] ||= []
    vote_history[c] << votes[c]
  end

  active = ballots.size - exhausted

  # Print round results
  sorted = continuing.sort do |a, b|
    if votes[a] != votes[b]
      votes[b] <=> votes[a]
    else
      a <=> b
    end
  end

  sorted.each do |candidate|
    count = votes[candidate]
    if active == 0
      pct = 0.0
    else
      pct = (count.to_f / active) * 100
    end
    # Round half up
    pct_rounded = ((pct + 0.05) * 10).floor / 10.0
    printf("  %s %d %.1f%%\n", candidate, count, pct_rounded)
  end

  printf("  exhausted %d\n", exhausted)

  # Check for winner
  winner = nil
  continuing.each do |candidate|
    if votes[candidate] * 2 > active
      winner = candidate
      break
    end
  end

  if winner
    puts "winner #{winner}"
    exit
  end

  # Check if no active ballots
  if active == 0
    puts "no winner"
    exit
  end

  # Eliminate candidate with fewest votes
  min_votes = votes.values.min
  candidates_to_eliminate = votes.select { |c, v| v == min_votes }.keys

  # Tie-breaker: look at previous rounds
  if candidates_to_eliminate.size > 1
    (round - 2).downto(0) do |r|
      min_prev = nil
      candidates_to_eliminate.each do |c|
        votes_prev = vote_history[c][r] || 0
        if min_prev.nil? || votes_prev < min_prev
          min_prev = votes_prev
        end
      end

      new_candidates = candidates_to_eliminate.select { |c| (vote_history[c][r] || 0) == min_prev }
      if new_candidates.size < candidates_to_eliminate.size
        candidates_to_eliminate = new_candidates
      end
    end
  end

  # If still tied, eliminate by name (last in byte order)
  eliminated = candidates_to_eliminate.sort.last

  continuing.delete(eliminated)
  puts "  eliminated #{eliminated}"
end
