class Car
  attr_reader :plate, :klass, :bookings
  attr_accessor :branch, :odometer

  def initialize(plate, klass, branch, odometer, bookings)
    @plate = plate
    @klass = klass
    @branch = branch
    @odometer = odometer
    @bookings = bookings
  end
end

class Rental
  attr_reader :id, :customer, :car, :from_day, :to_day, :pickup, :dropoff, :upgraded

  def initialize(id, customer, car, from_day, to_day, pickup, dropoff, upgraded)
    @id = id
    @customer = customer
    @car = car
    @from_day = from_day
    @to_day = to_day
    @pickup = pickup
    @dropoff = dropoff
    @upgraded = upgraded
  end
end

class NoCarAvailable < StandardError
  attr_reader :klass

  def initialize(message, klass)
    super(message)
    @klass = klass
  end
end

CLASSES = [:economy, :compact, :suv, :van]
DAILY_RATE = { economy: 39, compact: 49, suv: 79, van: 95 }
INCLUDED_KM_PER_DAY = 200
EXTRA_KM_CENTS = 25
ONE_WAY_FEE = 60

def weekend?(day) = day % 7 == 5 || day % 7 == 6

def price(klass, from_day, to_day, one_way)
  days = to_day - from_day
  weeks, rest = days.divmod(7)
  base = weeks * 6 * DAILY_RATE.fetch(klass) + [rest, 6].min * DAILY_RATE.fetch(klass)
  weekend_days = (from_day...to_day).count { |d| weekend?(d) }
  surcharge = weeks > 0 ? 0 : weekend_days * 10
  base + surcharge + (one_way ? ONE_WAY_FEE : 0)
end

class Fleet
  attr_reader :cars, :rentals

  def initialize(cars)
    @cars = cars
    @rentals = []
    @next_id = 1000
  end

  def free?(car, from_day, to_day)
    car.bookings.none? { |b| b.overlap?(from_day...to_day) }
  end

  # the requested class first, then one class up at the same price
  def reserve(customer, klass, branch, from_day, to_day, dropoff)
    start = CLASSES.index(klass)
    CLASSES.drop(start).each do |k|
      car = @cars.find { |c| c.klass == k && c.branch == branch && free?(c, from_day, to_day) }
      next unless car
      next if k != klass && CLASSES.index(k) > start + 1
      car.bookings << (from_day...to_day)
      @next_id += 1
      r = Rental.new(@next_id, customer, car, from_day, to_day, branch, dropoff, k != klass)
      @rentals << r
      return r
    end
    raise NoCarAvailable.new("no #{klass} at #{branch} for days #{from_day}-#{to_day}", klass)
  end

  def return_car(r, km)
    car = r.car
    days = r.to_day - r.from_day
    klass = r.upgraded ? CLASSES[CLASSES.index(car.klass) - 1] : car.klass
    charge = price(klass, r.from_day, r.to_day, r.pickup != r.dropoff)
    extra_km = [0, km - days * INCLUDED_KM_PER_DAY].max
    car.odometer += km
    car.branch = r.dropoff
    [charge, extra_km * EXTRA_KM_CENTS / 100.0]
  end
end

fleet = Fleet.new([
  Car.new("E-101", :economy, "airport", 41200, []),
  Car.new("E-102", :economy, "downtown", 18050, []),
  Car.new("C-201", :compact, "airport", 30020, []),
  Car.new("S-301", :suv, "airport", 9900, []),
  Car.new("S-302", :suv, "downtown", 61000, []),
  Car.new("V-401", :van, "downtown", 22000, [])
])

requests = [
  ["Ono", :economy, "airport", 1, 4, "airport"],
  ["Lam", :economy, "airport", 2, 5, "downtown"],
  ["Ruiz", :economy, "airport", 3, 6, "airport"],
  ["Kaur", :suv, "downtown", 4, 15, "downtown"],
  ["Berg", :compact, "downtown", 5, 7, "downtown"],
  ["Sato", :van, "airport", 1, 3, "airport"],
  ["Ngo", :economy, "airport", 4, 6, "airport"]
]

rentals = []
requests.each do |customer, klass, branch, from_day, to_day, dropoff|
  r = fleet.reserve(customer, klass, branch, from_day, to_day, dropoff)
  up = r.upgraded ? " (upgrade)" : ""
  puts "##{r.id} #{customer}: #{r.car.plate} #{r.car.klass}#{up}, days #{from_day}-#{to_day}"
  rentals << r
rescue NoCarAvailable => e
  puts "#{customer}: #{e.message}"
end

puts
distances = { "Ono" => 450, "Lam" => 700, "Kaur" => 2900, "Berg" => 310, "Ruiz" => 120 }
income = 0.0
rentals.each do |r|
  km = distances.fetch(r.customer, 0)
  charge, extra = fleet.return_car(r, km)
  total = charge + extra
  income += total
  puts format("%-5s %4d km  rental %4d  extra km %6.2f  total %7.2f", r.customer, km, charge, extra, total)
end
puts format("Income: %.2f", income)

puts
fleet.cars.sort_by(&:plate).each do |c|
  booked = c.bookings.sum(&:size)
  puts format("%-6s %-8s %-9s %6d km  booked %2d days", c.plate, c.klass, c.branch, c.odometer, booked)
end
idle = fleet.cars.select { |c| c.bookings.empty? }
puts "Idle: #{idle.map(&:plate).join(", ")}"
