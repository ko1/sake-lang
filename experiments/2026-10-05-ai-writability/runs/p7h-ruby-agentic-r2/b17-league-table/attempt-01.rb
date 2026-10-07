#!/usr/bin/env ruby

TEAM_REGEX = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
SCORE_REGEX = /\A(\d{1,2})-(\d{1,2})\z/
POSTPONED_REGEX = /\AP-P\z/

teams = {}
matches = []
invalid_lines = []

STDIN.readlines.each_with_index do |line, idx|
  line_num = idx + 1
  stripped = line.strip
  next if stripped.empty?

  parts = stripped.split

  if parts.size != 3
    invalid_lines << "invalid line #{line_num}: #{line.chomp}"
    next
  end

  home, score, away = parts

  unless home.match?(TEAM_REGEX) && away.match?(TEAM_REGEX) && home != away
    invalid_lines << "invalid line #{line_num}: #{line.chomp}"
    next
  end

  if score == "P-P"
    # Postponed match - teams appear but no points
    teams[home] ||= {played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0}
    teams[away] ||= {played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0}
    next
  end

  match_data = score.match(SCORE_REGEX)
  unless match_data
    invalid_lines << "invalid line #{line_num}: #{line.chomp}"
    next
  end

  home_goals = match_data[1].to_i
  away_goals = match_data[2].to_i

  teams[home] ||= {played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0}
  teams[away] ||= {played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0}

  teams[home][:played] += 1
  teams[away][:played] += 1
  teams[home][:gf] += home_goals
  teams[home][:ga] += away_goals
  teams[away][:gf] += away_goals
  teams[away][:ga] += home_goals

  matches << {home: home, away: away, home_goals: home_goals, away_goals: away_goals}

  if home_goals > away_goals
    teams[home][:won] += 1
    teams[away][:lost] += 1
  elsif away_goals > home_goals
    teams[away][:won] += 1
    teams[home][:lost] += 1
  else
    teams[home][:drawn] += 1
    teams[away][:drawn] += 1
  end
end

invalid_lines.each { |msg| puts msg }

if teams.empty?
  puts "no teams"
  exit
end

# Add points to each team
teams.each do |name, stats|
  stats[:points] = stats[:won] * 3 + stats[:drawn]
  stats[:gd] = stats[:gf] - stats[:ga]
end

# Calculate head-to-head for tie-breaking
def calculate_h2h(team_names, matches)
  h2h = {}
  team_names.each { |t| h2h[t] = 0 }

  matches.each do |match|
    next unless team_names.include?(match[:home]) && team_names.include?(match[:away])

    if match[:home_goals] > match[:away_goals]
      h2h[match[:home]] += 3
    elsif match[:away_goals] > match[:home_goals]
      h2h[match[:away]] += 3
    else
      h2h[match[:home]] += 1
      h2h[match[:away]] += 1
    end
  end

  h2h
end

# Sort with complex tiebreaker
sorted_teams = teams.keys.sort do |a, b|
  stats_a = teams[a]
  stats_b = teams[b]

  cmp = stats_b[:points] <=> stats_a[:points]
  return cmp if cmp != 0

  cmp = stats_b[:gd] <=> stats_a[:gd]
  return cmp if cmp != 0

  cmp = stats_b[:gf] <=> stats_a[:gf]
  return cmp if cmp != 0

  # Head-to-head tiebreaker: need to check if in same tier
  # For now, calculate among all tied teams
  a <=> b
end

# Group teams by tier (points, GD, GF)
positions = []
current_pos = 1
prev_stats = nil

sorted_teams.each do |team|
  stats = teams[team]

  # Check if still in same tier
  if prev_stats.nil? ||
     stats[:points] != prev_stats[:points] ||
     stats[:gd] != prev_stats[:gd] ||
     stats[:gf] != prev_stats[:gf]
    # New tier
    current_pos = positions.size + 1
    # Re-sort current tier with h2h if needed
  end

  positions << {name: team, pos: current_pos, stats: stats}
  prev_stats = stats
end

# Now do proper h2h tie-breaking within tiers
final_positions = []
i = 0
while i < positions.size
  # Find all teams in this tier
  tier_start = i
  pos = positions[i][:pos]

  while i < positions.size && positions[i][:pos] == pos
    i += 1
  end

  tier_teams = positions[tier_start...i].map { |p| p[:name] }

  if tier_teams.size > 1
    # Calculate h2h for this tier
    h2h = calculate_h2h(tier_teams, matches)

    # Re-sort tier by h2h
    tier_teams.sort! do |a, b|
      cmp = h2h[b] <=> h2h[a]
      if cmp != 0
        cmp
      else
        a <=> b
      end
    end
  end

  tier_teams.each do |team|
    final_positions << {name: team, pos: pos, stats: teams[team]}
  end
end

# Print table
puts sprintf("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s",
             "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")

final_positions.each do |entry|
  team = entry[:name]
  stats = entry[:stats]
  pos = entry[:pos]
  gd_str = stats[:gd] >= 0 ? "+#{stats[:gd]}" : "#{stats[:gd]}"
  gd_str = "0" if stats[:gd] == 0

  puts sprintf("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d",
               pos, team, stats[:played], stats[:won], stats[:drawn],
               stats[:lost], stats[:gf], stats[:ga], gd_str, stats[:points])
end
