class LogLine
  include Comparable
  attr_accessor :time, :host, :level, :text, :next

  def initialize(time, host, level, text, nxt)
    @time = time
    @host = host
    @level = level
    @text = text
    @next = nxt
  end

  def <=>(other)
    c = @time <=> other.time
    c == 0 ? @host <=> other.host : c
  end

  def to_s = format("%s %-5s %-5s %s", clock(@time), @host, @level, @text)
end

def clock(secs) = format("%02d:%02d:%02d", secs / 3600, secs / 60 % 60, secs % 60)

def parse_stream(host, text)
  head = nil
  tail = nil
  text.lines.each do |raw|
    line = raw.strip
    next if line.empty?
    m = line.match(/\A(\d+):(\d+):(\d+) (\w+) (.*)\z/)
    next unless m
    secs = m[1].to_i * 3600 + m[2].to_i * 60 + m[3].to_i
    node = LogLine.new(secs, host, m[4], m[5], nil)
    if tail
      tail.next = node
    else
      head = node
    end
    tail = node
  end
  head
end

def length(list)
  n = 0
  while list
    n += 1
    list = list.next
  end
  n
end

def merge(a, b)
  head = nil
  tail = nil
  while a && b
    if a <= b
      node = a
      a = a.next
    else
      node = b
      b = b.next
    end
    if tail
      tail.next = node
    else
      head = node
    end
    tail = node
  end
  rest = a || b
  return rest if !tail    
  tail.next = rest
  head
end

def split_half(list)
  slow = list
  fast = list.next
  while fast && fast.next
    slow = slow.next
    fast = fast.next.next
  end
  second = slow.next
  slow.next = nil
  second
end

def merge_sort(list)
  return list if !list     || !list.next    
  second = split_half(list)
  merge(merge_sort(list), merge_sort(second))
end

def merge_all(lists)
  while lists.size > 1
    lists = lists.each_slice(2).map { |pair| pair.size == 2 ? merge(pair[0], pair[1]) : pair[0] }
  end
  lists[0]
end

def each_line(list)
  while list
    yield list
    list = list.next
  end
end

web = parse_stream("web1", "09:00:01 INFO start\n09:00:05 INFO GET /\n09:01:10 WARN slow request\n09:03:00 ERROR 500 on /cart\n")
db = parse_stream("db", "08:59:59 INFO ready\n09:00:05 INFO query ok\n\n09:02:30 ERROR deadlock\n")
web2 = parse_stream("web2", "09:00:03 INFO start\n09:00:04 INFO GET /login\nbroken line\n09:02:59 WARN retry\n")
batch = parse_stream("batch", "09:05:00 INFO nightly\n09:00:00 INFO queued\n09:04:00 WARN late\n09:01:00 INFO picked\n")

puts "batch has #{length(batch)} lines, out of order; sorting"
batch = merge_sort(batch)
each_line(batch) { |l| puts "  #{l}" }

merged = merge_all([web, db, web2, batch])
puts "merged #{length(merged)} lines:"
counts = Hash.new(0)
first_error = nil
each_line(merged) do |l|
  puts l
  counts[l.level] += 1
  first_error ||= l if l.level == "ERROR"
end
puts counts.keys.sort.map { |k| "#{k}=#{counts[k]}" }.join(" ")
puts "first error: #{first_error}" if first_error

shuffled = parse_stream("x", "10:00:09 INFO i\n10:00:03 INFO c\n10:00:07 INFO g\n10:00:01 INFO a\n10:00:05 INFO e\n10:00:02 INFO b\n10:00:08 INFO h\n10:00:04 INFO d\n10:00:06 INFO f\n")
sorted = merge_sort(shuffled)
letters = []
each_line(sorted) { |l| letters << l.text }
puts letters.join
p merge_sort(nil)
