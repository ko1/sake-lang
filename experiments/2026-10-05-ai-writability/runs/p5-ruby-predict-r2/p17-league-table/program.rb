Team = Struct.new(:name, :played, :won, :drawn, :lost, :gf, :ga) do
  def gd = gf - ga
  def pts = won * 3 + drawn
end

NAME = /\A[A-Za-z][A-Za-z0-9_]{0,11}\z/

teams = {}
matches = []
errors = []

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  toks = line.split
  next if toks.empty?
  home, score, away = toks
  ok = toks.size == 3 && NAME.match?(home) && NAME.match?(away) && home != away &&
       (score == "P-P" || score.match?(/\A\d{1,2}-\d{1,2}\z/))
  unless ok
    errors << "invalid line #{no}: #{line}"
    next
  end
  [home, away].each { |n| teams[n] ||= Team.new(n, 0, 0, 0, 0, 0, 0) }
  next if score == "P-P"
  hg, ag = score.split("-").map(&:to_i)
  matches << [home, hg, ag, away]
  h = teams[home]
  a = teams[away]
  h.played += 1
  a.played += 1
  h.gf += hg
  h.ga += ag
  a.gf += ag
  a.ga += hg
  if hg > ag
    h.won += 1
    a.lost += 1
  elsif hg < ag
    a.won += 1
    h.lost += 1
  else
    h.drawn += 1
    a.drawn += 1
  end
end

errors.each { |e| puts e }

if teams.empty?
  puts "no teams"
  exit
end

def h2h_points(group, matches)
  names = group.map(&:name)
  pts = Hash.new(0)
  matches.each do |home, hg, ag, away|
    next unless names.include?(home) && names.include?(away)
    if hg > ag
      pts[home] += 3
    elsif hg < ag
      pts[away] += 3
    else
      pts[home] += 1
      pts[away] += 1
    end
  end
  pts
end

rows = []
teams.values.group_by { |t| [t.pts, t.gd, t.gf] }.sort_by { |k, _| k.map(&:-@) }.each do |key, group|
  hp = h2h_points(group, matches)
  group.sort_by { |t| [-hp[t.name], t.name] }.each { |t| rows << [key, hp[t.name], t] }
end

FMT = "%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s"
puts format(FMT, "Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts")
pos = 0
prev = nil
rows.each_with_index do |(key, hp, t), i|
  rank_key = [key, hp]
  pos = i + 1 unless rank_key == prev
  prev = rank_key
  gd = t.gd > 0 ? "+#{t.gd}" : t.gd.to_s
  puts format(FMT, pos, t.name, t.played, t.won, t.drawn, t.lost, t.gf, t.ga, gd, t.pts)
end
