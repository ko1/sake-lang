class Flight
  include Comparable
  attr_reader :callsign, :op, :scheduled, :heavy
  attr_accessor :fuel, :done_at, :emergency

  def initialize(callsign, op, scheduled, fuel, heavy)
    @callsign = callsign
    @op = op
    @scheduled = scheduled
    @fuel = fuel
    @heavy = heavy
    @done_at = nil
    @emergency = false
  end

  def urgency
    return 0 if @emergency
    @op == :land ? 1 : 2
  end

  def <=>(other)
    [urgency, @scheduled, @callsign] <=> [other.urgency, other.scheduled, other.callsign]
  end

  def to_s = "#{@callsign}(#{@op == :land ? "L" : "T"}#{@emergency ? "!" : ""})"
end

def separation(prev, cur)
  return 0 if !prev    
  base = prev.op == cur.op ? 2 : 1
  base += 2 if prev.heavy && !cur.heavy
  base
end

def simulate(flights, closed)
  waiting = []
  done = []
  diverted = []
  last = nil
  free_at = 0
  t = 0
  while done.size + diverted.size < flights.size && t < 200
    flights.each { |f| waiting << f if f.scheduled == t }
    waiting.each do |f|
      next unless f.op == :land
      f.fuel -= 1
      if f.fuel <= 5 && !f.emergency
        f.emergency = true
        puts format("t=%3d %s declares fuel emergency", t, f.callsign)
      end
    end
    out = waiting.select { |f| f.op == :land && f.fuel <= 0 }
    out.each do |f|
      diverted << f
      puts format("t=%3d %s diverts", t, f.callsign)
    end
    waiting -= out
    closed_now = closed.any? { |r| r.include?(t) }
    unless closed_now || waiting.empty?
      nxt = waiting.min
      ready = free_at + separation(last, nxt)
      if t >= ready
        waiting.delete(nxt)
        nxt.done_at = t
        done << nxt
        last = nxt
        free_at = t
      end
    end
    if t % 15 == 0 && !waiting.empty?
      puts format("t=%3d queue: %s", t, waiting.sort.map(&:to_s).join(" "))
    end
    t += 1
  end
  [done, diverted, t]
end

def schedule
  [
    ["BA12", :land, 0, 30, true], ["LH4", :take, 0, 0, false], ["AF77", :land, 1, 25, false],
    ["KL9", :take, 2, 0, true], ["UA90", :land, 3, 12, true], ["IB3", :take, 3, 0, false],
    ["SK5", :land, 5, 9, false], ["AY1", :take, 6, 0, false], ["EI8", :land, 8, 40, false],
    ["TP2", :take, 9, 0, false], ["LX6", :land, 10, 14, false], ["OS7", :take, 11, 0, true],
    ["AZ4", :land, 12, 20, false], ["SN3", :take, 14, 0, false], ["LO2", :land, 15, 8, false]
  ].map { |cs, op, at, fuel, heavy| Flight.new(cs, op, at, fuel, heavy) }
end

def report(title, closed)
  puts "== #{title}"
  flights = schedule
  done, diverted, finished = simulate(flights, closed)
  delays = done.map { |f| f.done_at - f.scheduled }
  puts "order: #{done.map(&:callsign).join(" ")}"
  [:land, :take].each do |op|
    group = done.select { |f| f.op == op }
    d = group.map { |f| f.done_at - f.scheduled }
    avg = d.empty? ? 0.0 : d.sum / d.size.to_f
    puts format("  %-4s %2d ops, avg delay %5.2f, max %2d", op, group.size, avg, d.max || 0)
  end
  worst = done.max_by { |f| f.done_at - f.scheduled }
  puts "  worst: #{worst} delayed #{worst.done_at - worst.scheduled}" if worst
  puts "  diverted: #{diverted.empty? ? "none" : diverted.map(&:to_s).join(", ")}"
  puts "  runway clear at t=#{finished}"
  delays.sum
end

a = report("normal operations", [])
b = report("runway inspection 6..20", [6..20])
c = report("two closures", [4..9, 18..26])
puts "total delay minutes: #{a} / #{b} / #{c}"
