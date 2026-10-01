class Lot
  attr_reader :earned_day, :expires_day
  attr_accessor :points

  def initialize(points, earned_day, expires_day)
    @points = points
    @earned_day = earned_day
    @expires_day = expires_day
  end
end

class NotEnoughPoints < StandardError
  attr_reader :needed, :available

  def initialize(message, needed, available)
    super(message)
    @needed = needed
    @available = available
  end
end

TIERS = [[:gold, 2000], [:silver, 800], [:bronze, 0]]
MULTIPLIER = { gold: 2.0, silver: 1.5, bronze: 1.0 }
LIFETIME_DAYS = 180
REWARDS = { "coffee" => 150, "tote bag" => 900, "gift card" => 2500 }

class Customer
  attr_reader :id, :name, :tier, :spend, :lots, :history

  def initialize(id, name)
    @id = id
    @name = name
    @tier = :bronze
    @spend = 0.0
    @lots = []
    @history = []
  end

  def balance(today) = @lots.select { |l| l.expires_day >= today }.sum(&:points)

  def log(day, text) = @history << "day #{day.to_s.rjust(3)}: #{text}"

  def earn(day, amount)
    pts = (amount * MULTIPLIER.fetch(@tier)).floor
    @lots << Lot.new(pts, day, day + LIFETIME_DAYS)
    @spend += amount
    log(day, format("spent %.2f, +%d pts", amount, pts))
    name, _min = TIERS.find { |_t, min| @spend >= min }
    if name != @tier
      log(day, "tier #{@tier} -> #{name}")
      @tier = name
    end
    pts
  end

  # oldest points are used first
  def redeem(day, pts)
    avail = balance(day)
    raise NotEnoughPoints.new("#{@name} cannot redeem #{pts}", pts, avail) if pts > avail
    left = pts
    live = @lots.select { |l| l.expires_day >= day && l.points > 0 }.sort_by(&:earned_day)
    live.each do |lot|
      break if left == 0
      take = [left, lot.points].min
      lot.points -= take
      left -= take
    end
    log(day, "redeemed #{pts} pts")
    pts
  end

  def expire(day)
    gone = @lots.select { |l| l.expires_day < day && l.points > 0 }
    lost = gone.sum(&:points)
    gone.each { |l| l.points = 0 }
    log(day, "#{lost} pts expired") if lost > 0
    lost
  end
end

customers = {}
[[1, "Mia"], [2, "Noah"], [3, "Zoe"]].each do |id, name|
  customers[id] = Customer.new(id, name)
end

activity = [
  [3, 1, :buy, 120.0], [5, 2, :buy, 45.5], [10, 1, :buy, 760.0], [12, 3, :buy, 15.0],
  [20, 1, :redeem, "coffee"], [33, 2, :redeem, "coffee"], [40, 1, :buy, 1300.0], [41, 1, :redeem, "gift card"],
  [60, 2, :buy, 220.0], [61, 2, :redeem, "coffee"], [75, 3, :refer, 2], [200, 1, :buy, 50.0],
  [201, 1, :redeem, "tote bag"], [230, 2, :buy, 600.0], [231, 3, :redeem, "tote bag"]
]

activity.each do |day, id, kind, arg|
  c = customers.fetch(id)
  customers.each_value { |x| x.expire(day) }
  begin
    case kind
    when :buy then c.earn(day, arg)
    when :redeem then c.redeem(day, REWARDS.fetch(arg))
    when :refer
      c.lots << Lot.new(250, day, day + LIFETIME_DAYS)
      c.log(day, "+250 pts for referring #{customers.fetch(arg).name}")
    end
  rescue NotEnoughPoints => e
    c.log(day, "#{e.message}: has #{e.available}, needs #{e.needed}")
  end
end

today = 240
customers.each_value do |c|
  puts "#{c.name} (#{c.tier}, spent #{format("%.2f", c.spend)}, balance #{c.balance(today)})"
  c.history.each { |h| puts "  #{h}" }
end

puts
soon = customers.values.flat_map do |c|
  c.lots.filter_map do |l|
    left = l.expires_day - today
    [c.name, l.points, left] if l.points > 0 && left.between?(0, 30)
  end
end
soon.each { |name, pts, left| puts "#{name}: #{pts} pts expire in #{left} days" }
by_tier = customers.values.map(&:tier).tally
puts "Tiers: #{TIERS.map { |t, _min| "#{t}=#{by_tier[t] || 0}" }.join(" ")}"
