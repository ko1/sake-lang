class Entry
  attr_reader :hour, :minute, :level, :component, :message

  def initialize(hour, minute, level, component, message)
    @hour = hour
    @minute = minute
    @level = level
    @component = component
    @message = message
  end
end

def raw_log
  "09:01 INFO  [auth] user 1042 logged in
09:03 INFO  [db] query took 12 ms
09:07 WARN  [db] query took 340 ms
09:15 ERROR [payment] card 4411 declined: insufficient funds
09:22 INFO  [auth] user 2001 logged in
garbage line without structure
10:02 ERROR [db] connection 7 reset by peer
10:05 INFO  [auth] user 1042 logged out
10:11 ERROR [payment] card 9902 declined: insufficient funds
10:30 WARN  [cache] miss rate 41 percent
10:45 ERROR [db] connection 3 reset by peer
11:00 INFO  [db] query took 8 ms
11:20 DEBUG [cache] evicted 120 keys
11:21 ERROR [payment] gateway timeout after 30 s
11:40 INFO  [auth] user 3333 logged in
11:59 WARN  [auth] 5 failed logins for user 3333
"
end

def parse_line(line)
  m = line.match(/^(\d\d):(\d\d) (\w+)\s+\[(\w+)\] (.*)$/)
  return nil unless m
  Entry.new(m[1].to_i, m[2].to_i, m[3], m[4], m[5])
end

def normalize(message) = message.gsub(/\d+/, "N")

def count_by(entries)
  counts = Hash.new(0)
  entries.each { |e| counts[yield(e)] += 1 }
  counts
end

def print_counts(title, counts)
  puts "#{title}:"
  counts.keys.sort.each { |k| puts format("  %-10s %3d", k, counts[k]) }
end

entries = []
malformed = 0
raw_log.lines.each do |line|
  e = parse_line(line.chomp)
  if e
    entries << e
  else
    malformed += 1
  end
end
puts "parsed #{entries.size} entries, #{malformed} malformed"

print_counts("by level", count_by(entries, &:level))
print_counts("by component", count_by(entries, &:component))

matrix = {}
entries.each do |e|
  row = matrix[e.component] ||= Hash.new(0)
  row[e.level] += 1
end
levels = ["DEBUG", "INFO", "WARN", "ERROR"]
puts "component  " + levels.map { |l| format("%6s", l) }.join
matrix.keys.sort.each do |comp|
  row = matrix[comp]
  puts format("%-10s ", comp) + levels.map { |l| format("%6d", row[l]) }.join
end

errors = entries.select { |e| e.level == "ERROR" }
patterns = errors.group_by { |e| normalize(e.message) }
puts "error patterns:"
patterns.keys.sort_by { |k| k }.each do |pat|
  times = patterns[pat].map { |e| format("%02d:%02d", e.hour, e.minute) }
  puts "  #{patterns[pat].size}x #{pat} [#{times.join(", ")}]"
end

per_hour = count_by(entries, &:hour)
puts "per hour:"
per_hour.each { |h, n| puts format("  %02d:00 %s %d", h, "#" * n, n) }

users = Hash.new(0)
entries.each do |e|
  m = e.message.match(/user (\d+)/)
  users[m[1]] += 1 if m
end
active = users.max_by { |_, n| n }
if active
  u, n = active
  puts "most mentioned user: #{u} (#{n} lines)"
end

slow = entries.filter_map do |e|
  m = e.message.match(/took (\d+) ms/)
  m ? m[1].to_i : nil
end
puts "query times: #{slow}, max #{slow.max} ms, mean #{slow.sum / slow.size} ms"
