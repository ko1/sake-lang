#!/usr/bin/env ruby

TEAM_REGEX = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/
SCORE_REGEX = /\A(\d{1,2})-(\d{1,2})\z/

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

# Add points and goal difference to each team
teams.each do |name, stats|
  stats[:points] = stats[:won] * 3 + stats[:drawn]
  stats[:gd] = stats[:gf] - stats[:ga]
end

# Sort teams with all tiebreakers
team_list = teams.keys.sort do |a, b|
  # 1. Points
  cmp = teams[b][:points] <=> teams[a][:points]
  next cmp if cmp != 0

  # 2. Goal Difference
  cmp = teams[b][:gd] <=> teams[a][:gd]
  next cmp if cmp != 0

  # 3. Goals For
  cmp = teams[b][:gf] <=> teams[a][:gf]
  next cmp if cmp != 0

  # 4. Head-to-head (calculate among all teams for now, will refine)
  # For now, use alphabetical (will fix with proper h2h calculation)
  a <=> b
end

# For proper h2h, we need to identify groups and calculate h2h within each group
# First, mark groups by points/GD/GF
groups = []
i = 0
while i < team_list.size
  group = [team_list[i]]
  j = i + 1
  while j < team_list.size &&
        teams[team_list[j]][:points] == teams[team_list[i]][:points] &&
        teams[team_list[j]][:gd] == teams[team_list[i]][:gd] &&
        teams[team_list[j]][:gf] == teams[team_list[i]][:gf]
    group << team_list[j]
    j += 1
  end
  groups << group
  i = j
end

# Re-sort each group by h2h
def calculate_h2h(group_teams, matches)
  h2h = {}
  group_teams.each { |t| h2h[t] = 0 }

  matches.each do |match|
    if group_teams.include?(match[:home]) && group_teams.include?(match[:away])
      if match[:home_goals] > match[:away_goals]
        h2h[match[:home]] += 3
      elsif match[:away_goals] > match[:home_goals]
        h2h[match[:away]] += 3
      else
        h2h[match[:home]] += 1
        h2h[match[:away]] += 1
      end
    end
  end

  h2h
end

final_team_list = []
groups.each do |group|
  if group.size > 1
    h2h = calculate_h2h(group, matches)
    group.sort! do |a, b|
      cmp = h2h[b] <=> h2h[a]
      next cmp if cmp != 0
      a <=> b
    end
  end
  final_team_list.concat(group)
end

# Calculate h2h for all groups to determine positions
group_h2h = {}
groups.each do |group|
  if group.size > 1
    h2h = calculate_h2h(group, matches)
    h2h.each { |team, pts| group_h2h[team] = pts }
  else
    group_h2h[group[0]] = 0
  end
end

# Calculate positions based on all tiebreakers
positions = {}
pos = 1
prev_pts = nil
prev_gd = nil
prev_gf = nil
prev_h2h = nil

final_team_list.each_with_index do |team, idx|
  stats = teams[team]
  h2h_pts = group_h2h[team] || 0

  # Position only stays the same if ALL criteria are equal
  if prev_pts.nil? || prev_pts != stats[:points] || prev_gd != stats[:gd] || prev_gf != stats[:gf] || (prev_h2h != h2h_pts && prev_pts == stats[:points] && prev_gd == stats[:gd] && prev_gf == stats[:gf])
    pos = idx + 1
  end

  positions[team] = pos
  prev_pts = stats[:points]
  prev_gd = stats[:gd]
  prev_gf = stats[:gf]
  prev_h2h = h2h_pts
end

# Print table
puts sprintf("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s",
             "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")

final_team_list.each do |team|
  stats = teams[team]
  pos = positions[team]

  gd = stats[:gd]
  if gd > 0
    gd_str = "+#{gd}"
  elsif gd == 0
    gd_str = "0"
  else
    gd_str = "#{gd}"
  end

  puts sprintf("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d",
               pos, team, stats[:played], stats[:won], stats[:drawn],
               stats[:lost], stats[:gf], stats[:ga], gd_str, stats[:points])
end
