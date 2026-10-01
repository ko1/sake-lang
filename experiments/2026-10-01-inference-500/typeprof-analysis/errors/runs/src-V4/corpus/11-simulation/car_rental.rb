class CarClass
  include Comparable
  attr_reader :name, :rank, :daily

  def initialize(name, rank, daily)
    @name = name
    @rank = rank
    @daily = daily
  end

  def <=>(other) = @rank <=> other.rank
  def to_s = @name
end

CLASSES = {
  "economy" => CarClass.new("economy", 1, 39),
  "compact" => CarClass.new("compact", 2, 49),
  "suv" => CarClass.new("suv", 3, 79),
  "van" => CarClass.new("van", 4, 99)
}.freeze

class Booking
  attr_reader :id, :customer, :klass, :pickup, :dropoff, :days
  attr_accessor :car, :price, :upgraded

  def initialize(id, customer, klass, pickup, dropoff, days)
    @id = id
    @customer = customer
    @klass = klass
    @pickup = pickup
    @dropoff = dropoff
    @days = days
    @car = nil
    @price = 0
    @upgraded = false
  end
end

class NoCarAvailable < StandardError
  attr_reader :booking_id

  def initialize(message, booking_id)
    super(message)
    @booking_id = booking_id
  end
end

class Car
  attr_reader :plate, :klass, :branch, :bookings, :service_due
  attr_accessor :km

  def initialize(plate, klass, branch, km, service_due)
    @plate = plate
    @klass = klass
    @branch = branch
    @km = km
    @bookings = []
    @service_due = service_due
  end

  def free?(days) = @bookings.none? { |b| b.days.overlap?(days) }

  def located_at?(branch, day)
    last = @bookings.select { |b| b.days.end < day }.max_by { |b| b.days.end }
    where = last ? last.dropoff : @branch
    where == branch
  end
end

class Fleet
  attr_reader :cars, :log

  def initialize(cars)
    @cars = cars
    @log = []
  end

  def reserve(b)
    wanted = CLASSES[b.klass]
    days = b.days
    ranked = CLASSES.values.select { |k| k >= wanted }.sort
    ranked.each do |k|
      car = @cars.find do |c|
        c.klass == k.name && c.free?(days) && c.located_at?(b.pickup, days.begin) && c.service_due > c.km
      end
      next unless car
      b.car = car.plate
      b.upgraded = k > wanted
      fee = b.pickup == b.dropoff ? 0 : 60
      b.price = days.size * wanted.daily + fee
      car.bookings << b
      @log << "##{b.id} #{b.customer}: #{car.plate} (#{k})#{k > wanted ? " upgrade" : ""}"
      return car
    end
    raise NoCarAvailable.new("no #{wanted} or better at #{b.pickup} for days #{days}", b.id)
  end

  def complete(b, km)
    car = @cars.find { |c| c.plate == b.car }
    return unless car
    car.km += km
    @log << "#{car.plate} needs service at #{car.km} km" if car.km >= car.service_due
  end
end

cars = [
  Car.new("E-101", "economy", "airport", 14800, 15000),
  Car.new("E-102", "economy", "downtown", 3000, 15000),
  Car.new("C-201", "compact", "airport", 8000, 20000),
  Car.new("C-202", "compact", "downtown", 19500, 20000),
  Car.new("S-301", "suv", "airport", 500, 10000),
  Car.new("V-401", "van", "downtown", 2000, 10000)
]
fleet = Fleet.new(cars)

requests = [
  [1, "kim", "economy", "airport", "airport", 1..3, 420],
  [2, "lee", "economy", "airport", "downtown", 2..4, 180],
  [3, "max", "compact", "downtown", "downtown", 1..2, 650],
  [4, "nia", "suv", "airport", "airport", 3..6, 900],
  [5, "oli", "compact", "downtown", "airport", 5..7, 300],
  [6, "pam", "economy", "downtown", "downtown", 5..6, 120],
  [7, "quo", "van", "downtown", "downtown", 4..5, 210],
  [8, "ray", "economy", "airport", "airport", 8..9, 90],
  [9, "sue", "suv", "airport", "downtown", 7..8, 150],
  [10, "tom", "compact", "airport", "airport", 9..10, 200]
]

bookings = []
failed = []
requests.each do |id, who, klass, from, to, days, km|
  b = Booking.new(id, who, klass, from, to, days)
  begin
    fleet.reserve(b)
    bookings << b
    fleet.complete(b, km)
  rescue NoCarAvailable => e
    failed << e.booking_id
    fleet.log << "##{id} #{who}: refused (#{e.message})"
  end
end

fleet.log.each { |line| puts line }
puts "--- utilization over days 1..10"
cars.each do |c|
  used = c.bookings.sum { |b| b.days.size }
  strip = (1..10).map { |d| c.bookings.any? { |b| b.days.include?(d) } ? "#" : "." }.join
  puts format("%-6s %-8s %s %3d%% %6d km", c.plate, c.klass, strip, used * 10, c.km)
end
revenue = bookings.sum(&:price)
upgrades = bookings.count(&:upgraded)
puts "bookings #{bookings.size}, refused #{failed.inspect}, upgrades #{upgrades}, revenue $#{revenue}"
top = cars.reject { |c| c.bookings.empty? }.max_by { |c| c.bookings.size }
puts "busiest car: #{top.plate}" if top
