class NoItinerary < StandardError
  attr_reader :airport

  def initialize(message, airport)
    super(message)
    @airport = airport
  end
end

def parse_tickets(text)
  text.scan(/([A-Z]{3})-([A-Z]{3})/)
end

def degree_balance(tickets)
  bal = Hash.new(0)
  tickets.each do |from, to|
    bal[from] += 1
    bal[to] -= 1
  end
  bal
end

def pick_start(tickets)
  bal = degree_balance(tickets)
  starts = bal.keys.select { |k| bal[k] == 1 }
  ends = bal.keys.select { |k| bal[k] == -1 }
  odd = bal.keys.find { |k| bal[k].abs > 1 }
  raise NoItinerary.new("unbalanced airport", odd) if odd
  if starts.size > 1 || ends.size > 1
    raise NoItinerary.new("too many open ends", starts.sort.join("/"))
  end
  return starts[0] if starts.size == 1
  tickets.map { |from, to| from }.min
end

# Hierholzer's algorithm; destinations are kept sorted so the result is the smallest itinerary.
def itinerary(tickets, start)
  out = {}
  tickets.each do |from, to|
    (out[from] ||= []) << to
  end
  out = out.transform_values(&:sort)
  route = []
  stack = [start]
  until stack.empty?
    top = stack.last
    dests = out[top]
    if dests && !dests.empty?
      stack << dests.shift
    else
      route << stack.pop
    end
  end
  route.reverse
end

def plan(title, text)
  puts "== #{title}"
  tickets = parse_tickets(text)
  puts "#{tickets.size} tickets"
  start = pick_start(tickets)
  route = itinerary(tickets, start)
  raise NoItinerary.new("tickets are not connected", start) if route.size != tickets.size + 1
  puts "route: #{route.join(" ")}"
  hub, n = route.tally.max_by { |k, v| v }
  puts "busiest: #{hub} x#{n}"
rescue NoItinerary => e
  puts "cannot plan: #{e.message} (#{e.airport})"
end

plan("round trip", "JFK-SFO, JFK-ATL, SFO-ATL, ATL-JFK, ATL-SFO")
plan("one way", "MUC-LHR, JFK-MUC, SFO-SJC, LHR-SFO")
plan("loop with detour", "AMS-CDG CDG-FCO FCO-AMS AMS-BCN BCN-AMS CDG-AMS AMS-CDG")
plan("split", "AAA-BBB BBB-AAA CCC-DDD DDD-CCC")
plan("hub overload", "XXX-YYY XXX-ZZZ XXX-WWW")
plan("two chains", "AAA-BBB CCC-DDD")
