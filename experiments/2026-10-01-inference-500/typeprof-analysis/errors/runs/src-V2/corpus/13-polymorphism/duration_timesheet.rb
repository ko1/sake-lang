class ParseError < StandardError
  attr_reader :input
  def initialize(message, input)
    super(message)
    @input = input
  end
end

class Duration
  include Comparable
  attr_reader :secs

  def initialize(secs)
    @secs = secs
  end

  def self.zero = Duration.new(0)

  def self.parse(s)
    total = 0
    rest = s.strip
    raise ParseError.new("empty duration", s) if rest.empty?
    until rest.empty?
      m = rest.match(/\A(\d+)\s*(h|m|s)\s*/)
      raise ParseError.new("bad duration #{s.inspect}", s) unless m
      n = m[1].to_i
      total += case m[2]
               in "h" then n * 3600
               in "m" then n * 60
               in "s" then n
               end
      rest = m.post_match
    end
    Duration.new(total)
  end

  def +(b) = Duration.new(@secs + b.secs)
  def -(b) = Duration.new(@secs - b.secs)
  def *(k) = Duration.new((@secs * k * 1.0).round)

  def /(b)
    case b
    in Duration then @secs / (b.secs * 1.0)
    in Integer then Duration.new(@secs / b)
    end
  end

  def <=>(b) = @secs <=> b.secs
  def hours = @secs / 3600.0

  def to_s
    sign = @secs < 0 ? "-" : ""
    s = @secs.abs
    h, rem = s.divmod(3600)
    m, sec = rem.divmod(60)
    if h > 0
      format("%s%dh %02dm %02ds", sign, h, m, sec)
    elsif m > 0
      format("%s%dm %02ds", sign, m, sec)
    else
      format("%s%ds", sign, sec)
    end
  end
end

class Clock
  include Comparable
  attr_reader :mins

  def initialize(mins)
    @mins = mins
  end

  def self.at(text)
    h, m = text.split(":").map(&:to_i)
    Clock.new(h * 60 + m)
  end

  def +(d) = Clock.new((@mins + d.secs / 60) % 1440)

  def -(b)
    case b
    in Clock
      diff = @mins - b.mins
      diff += 1440 if diff < 0
      Duration.new(diff * 60)
    in Duration then Clock.new((@mins - b.secs / 60) % 1440)
    end
  end

  def <=>(b) = @mins <=> b.mins
  def to_s = format("%02d:%02d", @mins / 60, @mins % 60)
end

class Entry
  attr_accessor :who, :project, :start, :spent
  def initialize(who, project, start, spent)
    @who = who
    @project = project
    @start = start
    @spent = spent
  end
end

log = [
  ["ann", "billing", "09:00", "1h 30m"],
  ["ann", "infra", "10:45", "45m"],
  ["bob", "billing", "08:30", "2h"],
  ["bob", "billing", "13:00", "1h15m 30s"],
  ["cy", "docs", "22:30", "3h"],
  ["ann", "docs", "14:00", "50 m"],
  ["bob", "infra", "16:00", "ten minutes"],
  ["cy", "infra", "11:00", "25m 10s"],
  ["ann", "billing", "15:10", "2h 5m"],
  ["cy", "billing", "09:15", ""]
]

entries = []
log.each do |who, project, start, spent|
  begin
    entries << Entry.new(who, project, Clock.at(start), Duration.parse(spent))
  rescue ParseError => e
    puts "skipped #{who}/#{project}: #{e.message}"
  end
end

puts "== entries =="
entries.each do |e|
  start = e.start
  finish = start + e.spent
  puts format("%-4s %-8s %s-%s %12s", e.who, e.project, start, finish, e.spent)
end

total = entries.reduce(Duration.zero) { |acc, e| acc + e.spent }
puts "total: #{total} (#{format("%.2f", total.hours)} h)"

puts "== per project =="
by_project = Hash.new(Duration.zero)
entries.each { |e| by_project[e.project] += e.spent }
by_project.sort_by { |p, d| -d.secs }.each do |project, d|
  share = d / total
  puts format("%-8s %12s %5.1f%%", project, d, share * 100)
end

puts "== per person =="
people = entries.group_by(&:who)
budget = Duration.parse("4h")
people.each do |who, es|
  spent = es.reduce(Duration.zero) { |acc, e| acc + e.spent }
  avg = spent / es.size
  status = spent > budget ? "over by #{spent - budget}" : "#{budget - spent} left"
  puts format("%-4s %d entries, %s, avg %s, %s", who, es.size, spent, avg, status)
end

longest = entries.max_by { |e| e.spent.secs }
puts "longest: #{longest.who} on #{longest.project} (#{longest.spent})" if longest
earliest = entries.min_by { |e| e.start.mins }
puts "earliest start: #{earliest.start} by #{earliest.who}" if earliest

puts "== clock arithmetic =="
late = Clock.at("23:20")
puts "23:20 + 1h 5m = #{late + Duration.parse("1h 5m")}"
puts "00:10 - 30m = #{Clock.at("00:10") - Duration.parse("30m")}"
puts "from 22:30 to 01:15 = #{Clock.at("01:15") - Clock.at("22:30")}"
puts "09:00 < 17:30? #{Clock.at("09:00") < Clock.at("17:30")}"
standup = Duration.parse("15m")
puts "standups per week: #{standup * 5}, a third: #{standup / 3}, 1.5x: #{standup * 1.5}"
puts "sorted: #{entries.map(&:spent).sort.join(", ")}"
