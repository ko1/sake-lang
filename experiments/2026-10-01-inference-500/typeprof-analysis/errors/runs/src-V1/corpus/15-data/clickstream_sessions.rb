class Event
  attr_reader :user, :at, :kind, :page

  def initialize(user, at, kind, page)
    @user = user
    @at = at
    @kind = kind
    @page = page
  end
end

class Session
  attr_reader :user, :events

  def initialize(user, events)
    @user = user
    @events = events
  end

  def start = events.fetch(0).at
  def finish = events.fetch(events.size - 1).at
  def duration = finish - start
  def bounce? = events.size == 1
  def reached?(kind) = events.any? { |e| e.kind == kind }
end

def raw_events
  <<~TXT
    09:00:05 u1 view /home
    09:01:10 u1 view /tea/sencha
    09:02:30 u2 view /home
    09:03:00 u1 cart /tea/sencha
    09:05:45 u1 checkout /checkout
    09:06:00 u3 view /tea/matcha
    09:10:12 u2 view /ware/kyusu
    09:12:40 u2 cart /ware/kyusu
    09:15:00 u4 view /home
    09:41:00 u2 view /home
    09:42:15 u2 checkout /checkout
    10:20:00 u1 view /home
    10:21:30 u3 view /tea/matcha
    10:22:00 u3 cart /tea/matcha
    10:40:05 u5 view /ware/cups
    10:41:00 u5 view /ware/kyusu
    10:44:20 u5 cart /ware/cups
    10:44:50 u5 cart /ware/kyusu
    bad line here
    11:30:00 u4 view /tea/sencha
  TXT
end

def seconds(hms)
  h, m, s = hms.split(":").map(&:to_i)
  h * 3600 + m * 60 + s
end

def clock(sec) = format("%02d:%02d", sec / 3600, sec % 3600 / 60)

def parse(text)
  events = []
  skipped = 0
  text.each_line do |line|
    m = line.match(/\A(\d\d:\d\d:\d\d) (\w+) (view|cart|checkout) (\S+)\s*\z/)
    if m
      events << Event.new(m[2], seconds(m[1]), m[3].to_sym, m[4])
    else
      skipped += 1
    end
  end
  [events, skipped]
end

def sessionize(events, gap)
  sessions = []
  events.sort_by(&:at).group_by(&:user).each do |user, list|
    current = nil
    list.each do |e|
      if current.nil? || e.at - current.finish > gap
        current = Session.new(user, [])
        sessions << current
      end
      current.events << e
    end
  end
  sessions.sort_by(&:start)
end

def step_code(kind)
  case kind
  in :view then "v"
  in :cart then "c"
  in :checkout then "$"
  else "?"
  end
end

def pct(n, d) = d == 0 ? "n/a" : format("%.0f%%", n * 100.0 / d)

events, skipped = parse(raw_events)
sessions = sessionize(events, 30 * 60)
puts "#{events.size} events (#{skipped} skipped), #{sessions.size} sessions"
puts
sessions.each do |s|
  path = s.events.map { |e| step_code(e.kind) }.join
  mins = s.duration / 60.0
  puts format("  %-3s %s-%s %5.1f min %2d events %-6s%s", s.user, clock(s.start), clock(s.finish),
              mins, s.events.size, path, s.bounce? ? "  bounce" : "")
end
puts

total = sessions.size
carted = sessions.count { |s| s.reached?(:cart) }
bought = sessions.count { |s| s.reached?(:checkout) }
puts "Funnel (sessions):"
puts format("  %-9s %3d %5s", "view", total, "100%")
puts format("  %-9s %3d %5s", "cart", carted, pct(carted, total))
puts format("  %-9s %3d %5s  (%s of carts)", "checkout", bought, pct(bought, total), pct(bought, carted))
bounces = sessions.count(&:bounce?)
puts format("Bounce rate: %s", pct(bounces, total))
long = sessions.reject(&:bounce?)
avg = long.empty? ? 0.0 : long.sum(&:duration) / 60.0 / long.size
puts format("Average non-bounce session: %.1f min", avg)
puts

abandoned = sessions.select { |s| s.reached?(:cart) && !s.reached?(:checkout) }
puts "Abandoned carts:"
abandoned.each do |s|
  items = s.events.filter_map { |e| e.page if e.kind == :cart }.uniq
  puts "  #{s.user} at #{clock(s.finish)}: #{items.join(", ")}"
end
pages = events.filter_map { |e| e.page if e.kind == :view }.tally
top = pages.sort_by { |page, n| [-n, page] }.first(3)
puts "Top viewed: #{top.map { |page, n| "#{page} (#{n})" }.join(", ")}"
