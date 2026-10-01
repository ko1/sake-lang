# Parse application log lines, tolerate malformed ones up to a limit, and summarize errors per component.
class MalformedLine < StandardError
  attr_reader :lineno

  def initialize(message, lineno)
    super(message)
    @lineno = lineno
  end
end

class TooManyErrors < StandardError
  attr_reader :count

  def initialize(message, count)
    super(message)
    @count = count
  end
end

LOG_TEXT = "2026-09-30T10:00:01 INFO  api     request id=1 path=/users ms=12
2026-09-30T10:00:02 WARN  db      slow query ms=850
2026-09-30T10:00:02 ERROR api     upstream failed code=502 ms=3001
garbage line without structure
2026-09-30T10:00:03 INFO  api     request id=2 path=/orders ms=40
2026-09-30T10:00:04 ERROR db      deadlock detected code=40001
2026-09-30T10:00:05 DEBUG cache   miss key=user:7
2026-09-30T10:00:05 FATAL worker  out of memory
2026-09-30T10:00:06 ERROR api     upstream failed code=504 ms=5000
2026-09-30T10:00:07 INFO  api     request id=3 path=/users ms=9
2026-09-30 10:00:08 INFO api broken timestamp
2026-09-30T10:00:09 ERROR cache   connection reset
2026-09-30T10:00:10 NOTICE api    unknown level"

LEVELS = %w[DEBUG INFO WARN ERROR FATAL]

class Entry
  attr_reader :time, :level, :component, :message, :attrs

  def initialize(time, level, component, message, attrs)
    @time = time
    @level = level
    @component = component
    @message = message
    @attrs = attrs
  end
end

def parse_entry(line, lineno)
  m = line.match(/\A(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) +([A-Z]+) +([a-z]+) +(.*)\z/)
  raise MalformedLine.new("unparseable", lineno) unless m
  level = m[2]
  raise MalformedLine.new("unknown level #{level}", lineno) unless LEVELS.include?(level)
  attrs = m[4].scan(/(\w+)=(\S+)/).to_h
  text = m[4].gsub(/\w+=\S+/, "").strip
  Entry.new(m[1].split("T")[1], level, m[3], text, attrs)
end

def parse_all(text, max_bad)
  entries = []
  bad = []
  text.lines.each_with_index do |line, i|
    entries << parse_entry(line.chomp, i + 1)
  rescue MalformedLine => e
    bad << "line #{e.lineno}: #{e.message}"
    raise TooManyErrors.new("more than #{max_bad} malformed lines", bad.size) if bad.size > max_bad
  end
  [entries, bad]
end

def report(entries, bad)
  serious = entries.select { |e| LEVELS.index(e.level) >= 3 }
  puts "#{entries.size} entries, #{serious.size} error/fatal, #{bad.size} malformed"
  bad.each { |b| puts "  skipped #{b}" }
  by_comp = serious.group_by(&:component)
  by_comp.keys.sort.each do |comp|
    list = by_comp[comp]
    codes = list.filter_map { |e| e.attrs["code"] }
    worst = list.max_by { |e| LEVELS.index(e.level) }
    puts format("  %-7s %d  worst=%-5s codes=%s", comp, list.size, worst.level, codes.empty? ? "-" : codes.join(","))
  end
  slow = entries.select { |e| e.attrs["ms"] && e.attrs["ms"].to_i >= 1000 }
  slow.each { |e| puts "  slow: #{e.time} #{e.component} #{e.message} (#{e.attrs["ms"]}ms)" }
end

[5, 2].each do |limit|
  puts "== limit #{limit}"
  begin
    entries, bad = parse_all(LOG_TEXT, limit)
    report(entries, bad)
  rescue TooManyErrors => e
    puts "aborted: #{e.message} (#{e.count} seen)"
  end
end
