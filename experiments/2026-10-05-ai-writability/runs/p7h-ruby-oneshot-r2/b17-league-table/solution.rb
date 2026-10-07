#!/usr/bin/env ruby

matches = []
teams = Set.new
errors = []

line_num = 0
ARGF.each_line do |line|
  line_num += 1
  line = line.chomp

  next if line.strip.empty?

  parts = line.split

  if parts.length != 3
    errors << "invalid line #{line_num}: #{line}"
    next
  end

  home, score, away = parts

  # Validate team names
  if !home.match?(/^[A-Za-z][A-Za-z0-9_]{0,11}$/) || !away.match?(/^[A-Za-z][A-Za-z0-9_]{0,11}$/)
    errors << "invalid line #{line_num}: #{line}"
    next
  end

  # Validate that teams are different
  if home == away
    errors << "invalid line #{line_num}: #{line}"
    next
  end

  # Parse score
  if score == "P-P"
    teams.add(home)
    teams.add(away)
    matches << { home: home, away: away, postponed: true }
  elsif score.match?(/^\d{1,2}-\d{1,2}$/)
    home_goals, away_goals = score.split("-").map(&:to_i)
    teams.add(home)
    teams.add(away)
    matches << { home: home, away: away, home_goals: home_goals, away_goals: away_goals, postponed: false }
  else
    errors << "invalid line #{line_num}: #{line}"
    next
  end
end

# Print errors
errors.each { |e| puts e }

if teams.empty?
  puts "no teams"
  exit
end

# Calculate standings
team_stats = {}
teams.each do |team|
  team_stats[team] = {
    played: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    gf: 0,
    ga: 0,
    points: 0
  }
end

# Process matches
matches.each do |match|
  next if match[:postponed]

  home = match[:home]
  away = match[:away]
  home_goals = match[:home_goals]
  away_goals = match[:away_goals]

  team_stats[home][:played] += 1
  team_stats[home][:gf] += home_goals
  team_stats[home][:ga] += away_goals

  team_stats[away][:played] += 1
  team_stats[away][:gf] += away_goals
  team_stats[away][:ga] += home_goals

  if home_goals > away_goals
    team_stats[home][:wins] += 1
    team_stats[home][:points] += 3
    team_stats[away][:losses] += 1
  elsif away_goals > home_goals
    team_stats[away][:wins] += 1
    team_stats[away][:points] += 3
    team_stats[home][:losses] += 1
  else
    team_stats[home][:draws] += 1
    team_stats[home][:points] += 1
    team_stats[away][:draws] += 1
    team_stats[away][:points] += 1
  end
end

# Sort teams
sorted_teams = teams.sort do |a, b|
  stats_a = team_stats[a]
  stats_b = team_stats[b]
  gd_a = stats_a[:gf] - stats_a[:ga]
  gd_b = stats_b[:gf] - stats_b[:ga]

  # 1. points
  if stats_a[:points] != stats_b[:points]
    stats_b[:points] <=> stats_a[:points]
  # 2. GD
  elsif gd_a != gd_b
    gd_b <=> gd_a
  # 3. GF
  elsif stats_a[:gf] != stats_b[:gf]
    stats_b[:gf] <=> stats_a[:gf]
  # 4. head-to-head
  else
    # Find h2h points for both teams
    h2h_a = 0
    h2h_b = 0

    matches.each do |match|
      next if match[:postponed]

      if (match[:home] == a && match[:away] == b) || (match[:home] == b && match[:away] == a)
        if match[:home] == a
          if match[:home_goals] > match[:away_goals]
            h2h_a += 3
          elsif match[:home_goals] == match[:away_goals]
            h2h_a += 1
          end
        else
          if match[:away_goals] > match[:home_goals]
            h2h_a += 3
          elsif match[:away_goals] == match[:home_goals]
            h2h_a += 1
          end
        end
      end
    end

    if h2h_a != h2h_b
      h2h_b <=> h2h_a
    else
      # 5. name
      a <=> b
    end
  end
end

# Calculate positions (handle ties)
positions = {}
current_pos = 1

sorted_teams.each_with_index do |team, idx|
  if idx == 0
    positions[team] = 1
  else
    prev_team = sorted_teams[idx - 1]
    stats = team_stats[team]
    prev_stats = team_stats[prev_team]
    gd = stats[:gf] - stats[:ga]
    prev_gd = prev_stats[:gf] - prev_stats[:ga]

    if stats[:points] != prev_stats[:points] || gd != prev_gd || stats[:gf] != prev_stats[:gf]
      positions[team] = idx + 1
    else
      positions[team] = positions[prev_team]
    end
  end
end

# Output
printf "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s\n", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts"

sorted_teams.each do |team|
  stats = team_stats[team]
  gd = stats[:gf] - stats[:ga]
  gd_str = gd > 0 ? "+#{gd}" : gd.to_s

  printf "%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d\n",
    positions[team], team, stats[:played], stats[:wins], stats[:draws], stats[:losses],
    stats[:gf], stats[:ga], gd_str, stats[:points]
end
