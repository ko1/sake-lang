class Spot
  attr_reader :level, :number, :size
  attr_accessor :plate

  def initialize(level, number, size, plate)
    @level = level
    @number = number
    @size = size
    @plate = plate
  end
end

class Ticket
  attr_reader :plate, :spot, :entered, :kind

  def initialize(plate, spot, entered, kind)
    @plate = plate
    @spot = spot
    @entered = entered
    @kind = kind
  end
end

class GarageFull < StandardError
  attr_reader :plate, :kind

  def initialize(message, plate, kind)
    super(message)
    @plate = plate
    @kind = kind
  end
end

SIZE_RANK = { compact: 1, regular: 2, large: 3 }.freeze
NEEDED_SIZE = { motorcycle: :compact, car: :regular, van: :large, truck: :large }.freeze

class Garage
  attr_reader :spots, :tickets, :receipts

  def initialize(spots)
    @spots = spots
    @tickets = {}
    @receipts = []
  end

  def free_spots = @spots.select { |s| s.plate.nil? }

  def park(plate, kind, at)
    need = SIZE_RANK.fetch(NEEDED_SIZE.fetch(kind))
    fits = free_spots.select { |s| SIZE_RANK.fetch(s.size) >= need }
    spot = fits.min_by { |s| [SIZE_RANK.fetch(s.size), s.level, s.number] }
    raise GarageFull.new("no spot for #{plate}", plate, kind) if spot.nil?
    spot.plate = plate
    @tickets[plate] = Ticket.new(plate, spot, at, kind)
    spot
  end

  def leave(plate, at)
    ticket = @tickets.delete(plate)
    return nil if ticket.nil?
    spot = ticket.spot
    spot.plate = nil
    minutes = ((at - ticket.entered) / 60.0).to_i
    amount = fee(minutes, ticket.kind)
    @receipts << [plate, minutes, amount]
    [minutes, amount]
  end

  def occupancy
    levels = @spots.group_by(&:level)
    levels.keys.sort.map do |lv|
      list = levels[lv]
      used = list.count { |s| s.plate }
      "L#{lv}:#{used}/#{list.size}"
    end
  end
end

def fee(minutes, kind)
  return 0 if minutes <= 30
  hours = minutes.ceildiv(60)
  rate = case kind
         when :motorcycle then 100
         when :car then 250
         else 400
         end
  days, rest = hours.divmod(24)
  day_max = rate * 8
  partial = [rest * rate, day_max].min
  days * day_max + partial
end

def money(c) = format("$%d.%02d", c / 100, c % 100)

def build_spots
  layout = [[1, [:compact, :compact, :regular, :regular, :large]], [2, [:regular, :regular, :regular, :large]]]
  layout.flat_map do |e__0| level, sizes = e__0;
    sizes.each_with_index.map { |e__1| size, i = e__1; Spot.new(level, i + 1, size, nil) }
  end
end

g = Garage.new(build_spots)
base = Time.new(2026, 10, 1, 7, 0, 0)

events = [
  [0, :in, "MOTO-1", :motorcycle], [5, :in, "CAR-11", :car], [12, :in, "VAN-7", :van],
  [20, :in, "CAR-12", :car], [25, :in, "MOTO-2", :motorcycle], [31, :in, "TRK-3", :truck],
  [40, :in, "CAR-13", :car], [45, :out, "MOTO-1", :motorcycle], [50, :in, "CAR-14", :car],
  [52, :in, "TRK-4", :truck], [55, :in, "MOTO-3", :motorcycle], [90, :out, "CAR-11", :car],
  [95, :in, "TRK-4", :truck], [200, :out, "VAN-7", :van], [210, :out, "CAR-99", :car],
  [600, :out, "CAR-12", :car], [700, :out, "TRK-3", :truck], [1500, :out, "CAR-13", :car],
  [1990, :out, "MOTO-2", :motorcycle]
]

refused = []
events.each do |offset, action, plate, kind|
  at = base + offset * 60
  stamp = at.strftime("%d %H:%M")
  if action == :in
    begin
      spot = g.park(plate, kind, at)
      puts "#{stamp} #{plate.ljust(7)} in  -> L#{spot.level}-#{spot.number} (#{spot.size})"
    rescue GarageFull => e
      refused << e.plate
      puts "#{stamp} #{plate.ljust(7)} refused: full for #{e.kind}"
    end
  else
    result = g.leave(plate, at)
    if result
      minutes, amount = result
      puts "#{stamp} #{plate.ljust(7)} out after #{minutes} min, pays #{money(amount)}"
    else
      puts "#{stamp} #{plate.ljust(7)} out: no ticket"
    end
  end
  puts "  occupancy #{g.occupancy.join(" ")}" if offset % 50 == 0
end

puts "--- end of run"
puts "still parked: #{g.tickets.keys.sort.join(", ")}"
puts "refused: #{refused.join(", ")}"
puts "revenue: #{money(g.receipts.sum { |e__2| _p, _m, a = e__2; a })}"
longest = g.receipts.max_by { |e__3| _p, m, _a = e__3; m }
if longest
  plate, minutes, _amount = longest
  puts "longest stay: #{plate} #{minutes / 60}h#{minutes % 60}m"
end
