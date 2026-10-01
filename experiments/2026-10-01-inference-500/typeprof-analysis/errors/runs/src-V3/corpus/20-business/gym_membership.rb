class Member
  attr_reader :name, :plan, :expires, :visits
  attr_accessor :punches

  def initialize(name, plan, expires, punches, visits)
    @name = name
    @plan = plan
    @expires = expires
    @punches = punches
    @visits = visits
  end

  def check_in(day)
    case plan
    when :punch
      raise AccessDenied, "#{name}: no punches left" if punches == 0
      self.punches -= 1
    when :monthly, :annual
      raise AccessDenied, "#{name}: expired on day #{expires}" if day > expires
    end
    visits << day
  end
end

class AccessDenied < StandardError
end

def plan_fee(plan)
  case plan
  when :monthly then 49
  when :annual then 480
  when :punch then 90
  end
end

members = {
  "ann" => Member.new("Ann", :monthly, 30, 0, []),
  "raj" => Member.new("Raj", :annual, 365, 0, []),
  "sue" => Member.new("Sue", :punch, 0, 3, []),
  "tom" => Member.new("Tom", :monthly, 12, 0, []),
  "kim" => Member.new("Kim", :punch, 0, 10, [])
}

log = "1 ann,1 raj,2 sue,3 ann,4 tom,5 sue,8 raj,9 sue,10 ann,11 sue,13 tom,15 raj,16 ann,18 bob,20 raj,22 ann,25 raj,29 ann,31 ann"
denied = 0
log.split(",").each do |entry|
  day_s, who = entry.split(" ")
  m = members[who]
  if m.nil?
    puts "day #{day_s}: unknown card #{who}"
    next
  end
  begin
    m.check_in(day_s.to_i)
  rescue AccessDenied => e
    denied += 1
    puts "day #{day_s}: denied, #{e.message}"
  end
end

puts
today = 31
members.each_value do |m|
  last = m.visits.last
  idle = last ? today - last : today
  per_visit = m.visits.empty? ? "-" : format("%.2f", plan_fee(m.plan) * 1.0 / m.visits.size)
  flag = idle >= 14 ? "  <- at risk" : ""
  puts format("%-4s %-8s visits %2d  idle %2d  per visit %6s%s", m.name, m.plan, m.visits.size, idle, per_visit, flag)
end
puts
busiest = members.values.flat_map { |m| m.visits.map { |d| d % 7 } }.tally
day, n = busiest.max_by { |d, c| [c, -d] }
puts "Busiest weekday index: #{day} (#{n} visits); denied #{denied}"
