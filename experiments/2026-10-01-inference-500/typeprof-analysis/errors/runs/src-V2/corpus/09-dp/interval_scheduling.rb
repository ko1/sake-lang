class Clock
  include Comparable
  attr_reader :minutes

  def initialize(minutes)
    @minutes = minutes
  end

  def <=>(other) = @minutes <=> other.minutes

  def self.parse(text)
    m = text.match(/\A(\d\d):(\d\d)\z/)
    raise ArgumentError, "bad time #{text}" if m.nil?
    new(m[1].to_i * 60 + m[2].to_i)
  end

  def to_s = format("%02d:%02d", @minutes / 60, @minutes % 60)
end

class Booking
  attr_reader :client, :start, :finish, :fee

  def initialize(client, start, finish, fee)
    @client = client
    @start = start
    @finish = finish
    @fee = fee
  end

  def self.parse(line)
    client, span, fee = line.split(",")
    from, to = span.split("-")
    new(client, Clock.parse(from), Clock.parse(to), fee.to_i)
  end

  def hours = (@finish.minutes - @start.minutes) / 60.0
  def to_s = "#{@start}-#{@finish} #{@client.ljust(7)} $#{@fee}"
end

# latest booking (by index in finish order) that ends no later than booking i starts
def last_compatible(sorted, i)
  start = sorted[i].start
  lo = 0
  hi = i - 1
  found = nil
  while lo <= hi
    mid = (lo + hi) / 2
    if sorted[mid].finish <= start
      found = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  found
end

def schedule(bookings)
  sorted = bookings.sort_by { |b| b.finish.minutes }
  n = sorted.size
  p_of = (0...n).map { |i| last_compatible(sorted, i) }
  best = [0]
  n.times do |i|
    prior = p_of[i]
    take = sorted[i].fee + (prior.nil? ? 0 : best[prior + 1])
    best << [take, best[i]].max
  end
  chosen = []
  i = n - 1
  while i >= 0
    prior = p_of[i]
    take = sorted[i].fee + (prior.nil? ? 0 : best[prior + 1])
    if take >= best[i]
      chosen.unshift(sorted[i])
      i = prior.nil? ? -1 : prior
    else
      i -= 1
    end
  end
  [best[n], chosen]
end

requests = <<~CSV
  Avery,09:00-10:30,120
  Blake,09:30-11:00,200
  Casey,10:30-12:00,150
  Devon,11:00-11:45,90
  Emery,11:30-13:00,210
  Finley,12:00-12:30,40
  Gray,13:00-14:30,160
  Harper,12:45-15:00,260
  Indy,14:30-15:30,80
  Jules,15:00-17:00,180
  Kai,15:30-16:15,70
  Lane,16:15-17:30,110
CSV

bookings = requests.lines.map { |line| Booking.parse(line.strip) }
total, chosen = schedule(bookings)
puts "accepted bookings (revenue $#{total}):"
chosen.each { |b| puts "  #{b}" }
hours = chosen.sum(&:hours)
puts format("studio busy %.2f h, $%.2f per hour", hours, total / hours)
declined = bookings.reject { |b| chosen.include?(b) }
puts "declined: #{declined.map(&:client).join(", ")}"

earliest = bookings.min_by(&:start)
latest = bookings.map(&:finish).max
puts "day spans #{earliest.start} to #{latest}"

["Mo,08:00-09:00,50", "Ni,9:00-10:00,50"].each do |line|
  begin
    b = Booking.parse(line)
    bookings << b
    puts "added #{b}; revenue now $#{schedule(bookings)[0]}"
  rescue ArgumentError => e
    puts "rejected #{line.inspect}: #{e.message}"
  end
end
