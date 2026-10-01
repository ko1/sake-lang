class Team
  include Comparable
  attr_accessor :name, :played, :won, :drawn, :lost, :goals_for, :goals_against, :form

  def initialize(name, played, won, drawn, lost, goals_for, goals_against, form)
    @name = name
    @played = played
    @won = won
    @drawn = drawn
    @lost = lost
    @goals_for = goals_for
    @goals_against = goals_against
    @form = form
  end

  def points = won * 3 + drawn
  def goal_diff = goals_for - goals_against

  def <=>(other)
    c = other.points <=> points
    c = other.goal_diff <=> goal_diff if c == 0
    c = other.goals_for <=> goals_for if c == 0
    c = name <=> other.name if c == 0
    c
  end

  def record!(scored, conceded)
    self.played += 1
    self.goals_for += scored
    self.goals_against += conceded
    if scored > conceded
      self.won += 1
      form << "W"
    elsif scored == conceded
      self.drawn += 1
      form << "D"
    else
      self.lost += 1
      form << "L"
    end
  end
end

def results
  <<~TXT
    1: Lions 2-1 Tigers, Bears 0-0 Wolves, Eagles 3-1 Sharks
    2: Tigers 1-1 Bears, Wolves 2-0 Eagles, Sharks 1-4 Lions
    3: Lions 0-2 Wolves, Eagles 2-2 Tigers, Bears 3-1 Sharks
    4: Wolves 1-1 Tigers, Sharks 0-1 Eagles, Lions 1-0 Bears
    5: Tigers 3-0 Sharks, Bears 2-2 Eagles, Wolves 1-3 Lions
  TXT
end

def standings(table) = table.values.sort

def ranks(table)
  standings(table).each_with_index.to_h { |t, i| [t.name, i + 1] }
end

table = {}
previous = nil
history = {}
results.each_line do |line|
  _round, games = line.chomp.split(": ")
  previous = ranks(table) unless table.empty?
  games.split(", ").each do |g|
    m = g.match(/\A(\w+) (\d+)-(\d+) (\w+)\z/)
    next unless m
    home = table[m[1]] ||= Team.new(m[1], 0, 0, 0, 0, 0, 0, [])
    away = table[m[4]] ||= Team.new(m[4], 0, 0, 0, 0, 0, 0, [])
    hs = m[2].to_i
    as = m[3].to_i
    home.record!(hs, as)
    away.record!(as, hs)
  end
  ranks(table).each { |name, r| (history[name] ||= []) << r }
end

puts format("%-3s %-7s %2s %2s %2s %2s %5s %4s %3s  %-6s %s", "#", "team", "P", "W", "D", "L", "goals", "GD", "Pts", "form", "move")
standings(table).each_with_index do |t, i|
  before = previous ? previous[t.name] : nil
  move = if before.nil? then "new"
         elsif before > i + 1 then "+#{before - i - 1}"
         elsif before < i + 1 then "-#{i + 1 - before}"
         else "="
         end
  form = t.form.last(5).join
  puts format("%-3d %-7s %2d %2d %2d %2d %2d:%-2d %+4d %3d  %-6s %s", i + 1, t.name, t.played, t.won,
              t.drawn, t.lost, t.goals_for, t.goals_against, t.goal_diff, t.points, form, move)
end

puts
puts "Rank by round:"
history.each { |name, rs| puts format("  %-7s %s", name, rs.join(" ")) }
leader = standings(table).first
puts
puts "Leader: #{leader.name} with #{leader.points} points" if leader
unbeaten = table.values.select { |t| t.lost == 0 }
puts "Unbeaten: #{unbeaten.empty? ? "none" : unbeaten.map(&:name).join(", ")}"
best_attack = table.values.max_by(&:goals_for)
puts "Best attack: #{best_attack.name} (#{best_attack.goals_for} goals)" if best_attack
