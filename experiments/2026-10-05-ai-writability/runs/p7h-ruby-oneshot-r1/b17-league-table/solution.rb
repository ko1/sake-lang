#!/usr/bin/env ruby

teams = {}
games = []
invalid_lines = []

STDIN.each_line.with_index do |line, idx|
  line_num = idx + 1
  line = line.rstrip

  next if line.empty?

  parts = line.split(/\s+/)

  unless parts.size == 3
    invalid_lines << "invalid line #{line_num}: #{line}"
    next
  end

  home, score, away = parts

  # Validate team names
  unless home =~ /^[A-Za-z][A-Za-z0-9_]{0,11}$/ && away =~ /^[A-Za-z][A-Za-z0-9_]{0,11}$/
    invalid_lines << "invalid line #{line_num}: #{line}"
    next
  end

  # Validate score and parse
  if score == "P-P"
    # Postponed
    teams[home] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }
    teams[away] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }
  elsif score =~ /^(\d{1,2})-(\d{1,2})$/
    home_goals = $1.to_i
    away_goals = $2.to_i

    teams[home] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }
    teams[away] ||= { p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0 }

    teams[home][:p] += 1
    teams[away][:p] += 1
    teams[home][:gf] += home_goals
    teams[home][:ga] += away_goals
    teams[away][:gf] += away_goals
    teams[away][:ga] += home_goals

    if home_goals > away_goals
      teams[home][:w] += 1
      teams[home][:pts] += 3
      teams[away][:l] += 1
    elsif home_goals < away_goals
      teams[away][:w] += 1
      teams[away][:pts] += 3
      teams[home][:l] += 1
    else
      teams[home][:d] += 1
      teams[away][:d] += 1
      teams[home][:pts] += 1
      teams[away][:pts] += 1
    end

    games << { home: home, away: away, h_goals: home_goals, a_goals: away_goals }
  else
    invalid_lines << "invalid line #{line_num}: #{line}"
  end
end

invalid_lines.each { |msg| puts msg }

if teams.empty?
  puts "no teams"
  exit
end

# Sort teams
team_names = teams.keys.sort

# Function to compute GD for a team
def gd(team_stats)
  team_stats[:gf] - team_stats[:ga]
end

# Sort with complex rules
sorted = team_names.sort do |a, b|
  a_stats = teams[a]
  b_stats = teams[b]

  # 1. Points descending
  if a_stats[:pts] != b_stats[:pts]
    b_stats[:pts] <=> a_stats[:pts]
  else
    # 2. GD descending
    a_gd = gd(a_stats)
    b_gd = gd(b_stats)
    if a_gd != b_gd
      b_gd <=> a_gd
    else
      # 3. GF descending
      if a_stats[:gf] != b_stats[:gf]
        b_stats[:gf] <=> a_stats[:gf]
      else
        # 4. Head-to-head within group
        # Find all teams with same points, GD, GF as (a, b)
        group = team_names.select do |t|
          ts = teams[t]
          ts[:pts] == a_stats[:pts] &&
            gd(ts) == a_gd &&
            ts[:gf] == a_stats[:gf]
        end

        if group.size > 1
          # Compute head-to-head points
          h2h_a = 0
          h2h_b = 0
          games.each do |g|
            if group.include?(g[:home]) && group.include?(g[:away])
              if g[:home] == a
                if g[:h_goals] > g[:a_goals]
                  h2h_a += 3
                elsif g[:h_goals] == g[:a_goals]
                  h2h_a += 1
                end
              elsif g[:away] == a
                if g[:a_goals] > g[:h_goals]
                  h2h_a += 3
                elsif g[:a_goals] == g[:h_goals]
                  h2h_a += 1
                end
              end

              if g[:home] == b
                if g[:h_goals] > g[:a_goals]
                  h2h_b += 3
                elsif g[:h_goals] == g[:a_goals]
                  h2h_b += 1
                end
              elsif g[:away] == b
                if g[:a_goals] > g[:h_goals]
                  h2h_b += 3
                elsif g[:a_goals] == g[:h_goals]
                  h2h_b += 1
                end
              end
            end
          end

          if h2h_a != h2h_b
            h2h_b <=> h2h_a
          else
            # 5. Name ascending
            a <=> b
          end
        else
          # 5. Name ascending
          a <=> b
        end
      end
    end
  end
end

# Print header
printf("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s\n", "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")

# Print rows with positions
pos = 1
sorted.each_with_index do |team, idx|
  stats = teams[team]
  gd_val = gd(stats)
  gd_str = gd_val > 0 ? "+#{gd_val}" : "#{gd_val}"

  # Check if same as previous team for tie positions
  if idx > 0
    prev_team = sorted[idx - 1]
    prev_stats = teams[prev_team]

    if stats[:pts] == prev_stats[:pts] &&
       gd(stats) == gd(prev_stats) &&
       stats[:gf] == prev_stats[:gf]
      # Same position
    else
      pos = idx + 1
    end
  end

  printf("%3d %-12s%3d%3d%3d%3d%4d%4d%4s%4d\n",
         pos, team, stats[:p], stats[:w], stats[:d], stats[:l],
         stats[:gf], stats[:ga], gd_str, stats[:pts])
end
