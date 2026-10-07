#!/usr/bin/env ruby

def main
  lines = STDIN.readlines.map(&:chomp)

  if lines.empty?
    puts "no candidates"
    return
  end

  # Parse candidates from first line
  candidates = lines[0].split.select { |c| c && !c.empty? }

  if candidates.empty?
    puts "no candidates"
    return
  end

  candidate_set = Set.new(candidates)

  # Parse and validate ballots
  valid_ballots = []
  rejected_ballots = []

  lines[1..].each_with_index do |line, idx|
    line_num = idx + 2

    # Skip blank lines
    next if line.strip.empty?

    # Parse ballot - keep ranks even if empty
    ballot_raw = line.split(">").map { |name| name.strip }

    # Validate ballot
    valid = true
    reason = nil
    seen = Set.new
    ballot = []

    ballot_raw.each do |name|
      if name.empty?
        valid = false
        reason = "empty rank"
        break
      elsif !candidate_set.include?(name)
        valid = false
        reason = "unknown candidate #{name}"
        break
      elsif seen.include?(name)
        valid = false
        reason = "duplicate #{name}"
        break
      else
        seen.add(name)
        ballot << name
      end
    end

    if valid
      valid_ballots << ballot
    else
      rejected_ballots << [line_num, reason]
    end
  end

  # Print rejected ballots
  rejected_ballots.each { |line_num, reason| puts "rejected line #{line_num}: #{reason}" }

  # Print ballot summary
  puts "ballots: #{valid_ballots.size} valid, #{rejected_ballots.size} rejected"

  # Instant runoff voting
  continuing = Set.new(candidates)
  round_counts = {}
  candidates.each { |c| round_counts[c] = 0 }

  # Store vote counts for each round for tiebreaking
  round_history = []  # Array of { candidate => count }

  round = 1

  loop do
    # Count votes for this round
    counts = {}
    exhausted = 0
    continuing.each { |c| counts[c] = 0 }

    valid_ballots.each do |ballot|
      # Find the highest-ranked continuing candidate
      found = false
      ballot.each do |candidate|
        if continuing.include?(candidate)
          counts[candidate] += 1
          found = true
          break
        end
      end

      exhausted += 1 unless found
    end

    active = valid_ballots.size - exhausted
    round_history << counts.dup

    # Print round
    puts "round #{round}"

    # Print candidate counts
    sorted_candidates = continuing.to_a.sort do |a, b|
      if counts[a] != counts[b]
        counts[b] <=> counts[a]
      else
        a <=> b
      end
    end

    sorted_candidates.each do |candidate|
      count = counts[candidate]
      if active == 0
        percentage = 0.0
      else
        percentage = (count * 100.0) / active
      end
      percentage_rounded = (percentage * 10).round / 10.0
      puts "  #{candidate} #{count} #{percentage_rounded.round(1)}%"
    end

    puts "  exhausted #{exhausted}"

    # Check for winner
    if active == 0
      puts "no winner"
      break
    end

    winner = nil
    sorted_candidates.each do |candidate|
      if counts[candidate] * 2 > active
        winner = candidate
        break
      end
    end

    if winner
      puts "winner #{winner}"
      break
    end

    # Eliminate candidate with fewest votes
    min_count = sorted_candidates.map { |c| counts[c] }.min
    candidates_to_eliminate = sorted_candidates.select { |c| counts[c] == min_count }

    # Tiebreaker: check previous rounds
    if candidates_to_eliminate.size > 1
      (round_history.size - 2).downto(0) do |prev_round_idx|
        prev_counts = round_history[prev_round_idx]
        min_prev_count = candidates_to_eliminate.map { |c| prev_counts[c] || 0 }.min
        candidates_to_eliminate.select! { |c| (prev_counts[c] || 0) == min_prev_count }
        break if candidates_to_eliminate.size == 1
      end
    end

    # Final tiebreaker: alphabetical (last in byte order)
    if candidates_to_eliminate.size > 1
      candidates_to_eliminate.sort!
      to_eliminate = candidates_to_eliminate[-1]
    else
      to_eliminate = candidates_to_eliminate[0]
    end

    puts "  eliminated #{to_eliminate}"
    continuing.delete(to_eliminate)

    round += 1
  end
end

main
