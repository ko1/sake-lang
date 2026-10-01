# Merge per-server log files (each already sorted by time) into one timeline
# with a heap of cursors, then do sorted-list set operations on user ids.

class Entry
  attr_reader :ts, :server, :text

  def initialize(ts, server, text)
    @ts = ts
    @server = server
    @text = text
  end
end

class Cursor
  include Comparable
  attr_accessor :entries, :pos

  def initialize(entries, pos)
    @entries = entries
    @pos = pos
  end

  def head = entries.fetch(pos)
  def done? = pos >= entries.size

  def <=>(other)
    x = head
    y = other.head
    c = x.ts <=> y.ts
    c == 0 ? x.server <=> y.server : c
  end
end

def parse_line(server, line)
  ts, text = line.split(" ", 2)
  Entry.new(ts.to_i, server, text)
end

def sift_up(h, i)
  while i > 0
    parent = (i - 1) / 2
    break if h[parent] <= h[i]
    h[parent], h[i] = h[i], h[parent]
    i = parent
  end
end

def sift_down(h, i)
  n = h.size
  loop do
    smallest = i
    [2 * i + 1, 2 * i + 2].each do |c|
      smallest = c if c < n && h[c] < h[smallest]
    end
    break if smallest == i
    h[smallest], h[i] = h[i], h[smallest]
    i = smallest
  end
end

def kway_merge(sources)
  heap = []
  sources.each do |server, lines|
    entries = lines.map { |l| parse_line(server, l) }
    next if entries.empty?
    heap << Cursor.new(entries, 0)
    sift_up(heap, heap.size - 1)
  end
  out = []
  until heap.empty?
    c = heap[0]
    out << c.head
    c.pos += 1
    if c.done?
      last = heap.pop
      next if heap.empty?
      heap[0] = last
    end
    sift_down(heap, 0)
  end
  out
end

def sorted_intersection(a, b)
  i = 0
  j = 0
  out = []
  while i < a.size && j < b.size
    if a[i] == b[j]
      out << a[i]
      i += 1
      j += 1
    elsif a[i] < b[j]
      i += 1
    else
      j += 1
    end
  end
  out
end

def sorted_union(a, b)
  i = 0
  j = 0
  out = []
  while i < a.size || j < b.size
    if j >= b.size || (i < a.size && a[i] < b[j])
      x = a[i]
      i += 1
    elsif i >= a.size || b[j] < a[i]
      x = b[j]
      j += 1
    else
      x = a[i]
      i += 1
      j += 1
    end
    out << x if out.empty? || out.last != x
  end
  out
end

logs = {
  "web1" => ["100 GET / u17", "104 GET /cart u3", "110 POST /pay u3", "131 GET / u42"],
  "web2" => ["101 GET / u8", "104 GET /help u17", "125 GET /cart u8"],
  "web3" => [],
  "api" => ["99 auth u3", "104 auth u8", "106 auth u17", "140 auth u99", "141 auth u42"]
}

timeline = kway_merge(logs)
timeline.each do |e|
  puts format("%4d %-5s %s", e.ts, e.server, e.text)
end

def users_of(timeline, server)
  ids = timeline.select { |e| e.server == server }.map do |e|
    e.text.split(" ").last.delete_prefix("u").to_i
  end
  ids.sort.uniq
end

web = sorted_union(users_of(timeline, "web1"), users_of(timeline, "web2"))
api = users_of(timeline, "api")
puts "web users:  #{web}"
puts "api users:  #{api}"
puts "both:       #{sorted_intersection(web, api)}"
puts "api only:   #{api.reject { |u| web.bsearch { |w| w >= u } == u }}"
by_second = timeline.group_by(&:ts)
busy = by_second.select { |_, es| es.size > 1 }
busy.each { |ts, es| puts "t=#{ts}: #{es.map(&:server).join("+")}" }
