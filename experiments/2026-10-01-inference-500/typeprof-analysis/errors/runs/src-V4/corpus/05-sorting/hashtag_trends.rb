# Trending hashtags: count tags per hour, rank them (count desc, then name),
# and report the top tags per hour and the biggest rank climbers.

class Tally
  include Comparable
  attr_reader :tag, :count

  def initialize(tag, count)
    @tag = tag
    @count = count
  end

  # "smaller" means ranked higher
  def <=>(other)
    c = other.count <=> count
    c == 0 ? tag <=> other.tag : c
  end

  def to_s = "#{tag}(#{count})"
end

def extract_tags(text)
  text.scan(/#[A-Za-z0-9_]+/).map(&:downcase)
end

def ranking(posts)
  counts = Hash.new(0)
  posts.each { |text| extract_tags(text).each { |t| counts[t] += 1 } }
  counts.map { |tag, n| Tally.new(tag, n) }.sort
end

def rank_of(ranked, tag)
  i = ranked.find_index { |t| t.tag == tag }
  i && i + 1
end

feed = [
  [9, "Morning! #coffee #monday"], [9, "Traffic again #commute #monday"],
  [9, "#Coffee first, then #code"], [9, "standup done #work #code"],
  [9, "#coffee #coffee break"], [10, "Ship it #release #code"],
  [10, "Release notes are up #release"], [10, "Bug found after #release #oncall"],
  [10, "#coffee refill"], [10, "Lunch plans? #food"],
  [11, "#oncall pager again #release"], [11, "Rollback #release #oncall"],
  [11, "#food truck day #food"], [11, "Postmortem at 3 #oncall #work"],
  [11, "#code review queue #work"], [11, "no hashtags here"]
]

by_hour = feed.group_by(&:first)
hours = by_hour.keys.sort
rankings = {}
hours.each do |h|
  ranked = ranking(by_hour[h].map(&:last))
  rankings[h] = ranked
  puts format("%02d:00 top 3: %s", h, ranked.take(3).join(", "))
end

overall = ranking(feed.map(&:last))
puts "overall: #{overall.join(" ")}"
puts "leader: #{overall.min}, least: #{overall.max}"

first = rankings[hours.first]
last = rankings[hours.last]
moves = last.map do |t|
  now = rank_of(last, t.tag)
  before = rank_of(first, t.tag)
  if !before    
    [t.tag, "new at ##{now}", 100]
  else
    [t.tag, "#{before} -> #{now}", before - now]
  end
end
climbers = moves.select { |_, _, d| d > 0 }.sort_by { |tag, _, d| [-d, tag] }
puts "climbers since #{hours.first}:00:"
climbers.each { |tag, desc, _| puts "  #{tag}: #{desc}" }
dropped = first.reject { |t| rank_of(last, t.tag) }
puts "dropped out: #{dropped.map(&:tag).join(", ")}"

untagged = feed.count { |_, text| extract_tags(text).empty? }
puts "posts without tags: #{untagged}"
