#!/usr/bin/env ruby

def main
  lines = STDIN.readlines

  invalid_lines = []
  matches = []
  teams = Set.new

  lines.each_with_index do |line, idx|
    line_num = idx + 1
    stripped = line.chomp

    # Skip blank lines
    next if stripped.strip.empty?

    parts = stripped.split

    # Must have exactly 3 tokens
    if parts.size != 3
      invalid_lines << [line_num, stripped]
      next
    end

    home, score, away = parts

    # Validate team names
    if !valid_team_name?(home) || !valid_team_name?(away)
      invalid_lines << [line_num, stripped]
      next
    end

    # Teams must be different
    if home == away
      invalid_lines << [line_num, stripped]
      next
    end

    # Validate score
    if score == "P-P"
      # Postponed match
      teams << home
      teams << away
      next
    elsif score.match?(/^\d{1,2}-\d{1,2}$/)
      h_goals, a_goals = score.split('-').map(&:to_i)
      matches << { home: home, away: away, h_goals: h_goals, a_goals: a_goals }
      teams << home
      teams << away
    else
      invalid_lines << [line_num, stripped]
      next
    end
  end

  # Print invalid lines
  invalid_lines.each { |line_num, text| puts "invalid line #{line_num}: #{text}" }

  # Check if there are any teams
  if teams.empty?
    puts "no teams"
    return
  end

  # Build standings
  standings = {}
  teams.each do |team|
    standings[team] = { played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0 }
  end

  matches.each do |match|
    home, away, h_goals, a_goals = match.values_at(:home, :away, :h_goals, :a_goals)

    standings[home][:played] += 1
    standings[away][:played] += 1
    standings[home][:gf] += h_goals
    standings[home][:ga] += a_goals
    standings[away][:gf] += a_goals
    standings[away][:ga] += h_goals

    if h_goals > a_goals
      standings[home][:won] += 1
      standings[home][:points] += 3
      standings[away][:lost] += 1
    elsif a_goals > h_goals
      standings[away][:won] += 1
      standings[away][:points] += 3
      standings[home][:lost] += 1
    else
      standings[home][:drawn] += 1
      standings[home][:points] += 1
      standings[away][:drawn] += 1
      standings[away][:points] += 1
    end
  end

  # Sort teams
  sorted_teams = teams.to_a.sort do |a, b|
    # 1. Points descending
    if standings[a][:points] != standings[b][:points]
      standings[b][:points] <=> standings[a][:points]
    else
      # 2. Goal difference descending
      gd_a = standings[a][:gf] - standings[a][:ga]
      gd_b = standings[b][:gf] - standings[b][:ga]

      if gd_a != gd_b
        gd_b <=> gd_a
      else
        # 3. Goals for descending
        if standings[a][:gf] != standings[b][:gf]
          standings[b][:gf] <=> standings[a][:gf]
        else
          # 4. Head-to-head points (simplified: find all teams with same points, GD, GF and calculate h2h)
          # 5. Name ascending
          a <=> b
        end
      end
    end
  end

  # Group teams for head-to-head calculation
  # Teams are equal on points, GD, GF if they have same values for these
  groups = []
  current_group = []
  sorted_teams.each_with_index do |team, idx|
    if idx == 0
      current_group << team
    else
      prev_team = sorted_teams[idx - 1]
      if standings[team][:points] == standings[prev_team][:points] &&
         (standings[team][:gf] - standings[team][:ga]) == (standings[prev_team][:gf] - standings[prev_team][:ga]) &&
         standings[team][:gf] == standings[prev_team][:gf]
        current_group << team
      else
        groups << current_group
        current_group = [team]
      end
    end
  end
  groups << current_group if !current_group.empty?

  # Re-sort within groups using head-to-head
  final_sorted = []
  groups.each do |group|
    if group.size == 1
      final_sorted.concat(group)
    else
      # Calculate head-to-head points for teams in this group
      h2h_points = {}
      group.each { |t| h2h_points[t] = 0 }

      matches.each do |match|
        home, away = match[:home], match[:away]
        h_goals, a_goals = match[:h_goals], match[:a_goals]

        if group.include?(home) && group.include?(away)
          if h_goals > a_goals
            h2h_points[home] += 3
          elsif a_goals > h_goals
            h2h_points[away] += 3
          else
            h2h_points[home] += 1
            h2h_points[away] += 1
          end
        end
      end

      sorted_group = group.sort do |a, b|
        if h2h_points[a] != h2h_points[b]
          h2h_points[b] <=> h2h_points[a]
        else
          a <=> b
        end
      end

      final_sorted.concat(sorted_group)
    end
  end

  # Print header
  printf("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s\n", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")

  # Print standings
  position = 1
  prev_points = nil
  prev_gd = nil
  prev_gf = nil

  final_sorted.each_with_index do |team, idx|
    stats = standings[team]
    gd = stats[:gf] - stats[:ga]
    gd_str = gd > 0 ? "+#{gd}" : "#{gd}"

    # Recalculate position based on points, GD, GF
    if idx == 0 || stats[:points] != prev_points || gd != prev_gd || stats[:gf] != prev_gf
      position = idx + 1
    end

    printf("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d\n",
           position, team, stats[:played], stats[:won], stats[:drawn], stats[:lost],
           stats[:gf], stats[:ga], gd_str, stats[:points])

    prev_points = stats[:points]
    prev_gd = gd
    prev_gf = stats[:gf]
  end
end

def valid_team_name?(name)
  # Must start with ASCII letter, followed by up to 11 ASCII letters, digits, or underscores
  name.match?(/^[A-Za-z][A-Za-z0-9_]{0,11}$/)
end

main
