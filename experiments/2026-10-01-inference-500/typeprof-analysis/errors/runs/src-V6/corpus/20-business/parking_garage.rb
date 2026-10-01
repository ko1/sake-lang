class Spot
  attr_reader :id, :level, :size
  attr_accessor :plate

  def initialize(id, level, size, plate)
    @id = id
    @level = level
    @size = size
    @plate = plate
  end
end

class Ticket
  attr_reader :number, :plate, :spot_id, :entered
  attr_accessor :charged_kwh

  def initialize(number, plate, spot_id, entered, charged_kwh)
    @number = number
    @plate = plate
    @spot_id = spot_id
    @entered = entered
    @charged_kwh = charged_kwh
  end
end

class GarageFull < StandardError
  attr_reader :plate

  def initialize(message, plate)
    super(message)
    @plate = plate
  end
end

class TicketError < StandardError
end

# smaller sizes fit fewer vehicles: a motorcycle fits anywhere, a van only in a large spot
SIZE_RANK = { moto: 0, compact: 1, regular: 2, large: 3 }
SIZE_CODES = { "m" => :moto, "c" => :compact, "r" => :regular, "L" => :large }

def minutes(hhmm)
  h, m = hhmm.split(":").map(&:to_i)
  h * 60 + m
end

def fee(mins, kwh, lost)
  return 2500 if lost
  billable = mins <= 30 ? 0 : mins.ceildiv(60)
  parking = [billable * 300, 2000].min
  parking + (kwh * 35.0).round
end

class Garage
  attr_reader :spots, :tickets

  def initialize(layout)
    @spots = []
    layout.each_with_index do |row, level|
      row.chars.each_with_index do |c, i|
        @spots << Spot.new("#{level}#{(i + 1).to_s.rjust(2, "0")}", level, SIZE_CODES.fetch(c), nil)
      end
    end
    @tickets = {}
    @seq = 100
  end

  def enter(plate, kind, at)
    raise TicketError, "#{plate} is already inside" if @spots.any? { |s| s.plate == plate }
    fits = @spots.select { |s| !s.plate     && SIZE_RANK[s.size] >= SIZE_RANK[kind] }
    raise GarageFull.new("no #{kind} spot", plate) if fits.empty?
    spot = fits.min_by { |s| [SIZE_RANK[s.size], s.level, @spots.index(s)] }
    spot.plate = plate
    @seq += 1
    t = Ticket.new(@seq, plate, spot.id, minutes(at), 0.0)
    @tickets[@seq] = t
    t
  end

  def charge(number, kwh)
    t = @tickets[number]
    raise TicketError, "unknown ticket #{number}" unless t
    t.charged_kwh += kwh
  end

  def leave(number, plate, at)
    t = number ? @tickets[number] : @tickets.values.find { |x| x.plate == plate }
    raise TicketError, "no car #{plate} inside" unless t
    spot = @spots.find { |s| s.id == t.spot_id }
    spot.plate = nil
    @tickets.delete(t.number)
    mins = minutes(at) - t.entered
    [mins, fee(mins, t.charged_kwh, !number    )]
  end

  def occupancy
    @spots.group_by(&:level).map { |level, ss| [level, ss.count(&:plate), ss.size] }
  end
end

garage = Garage.new(["mcrrL", "ccrr"])
tickets = {}
revenue = 0
events = [
  ["07:55", :in, "VAN-1", :large], ["08:02", :in, "CAR-1", :regular], ["08:05", :in, "MOTO-1", :moto],
  ["08:10", :in, "CAR-2", :compact], ["08:11", :in, "CAR-3", :regular], ["08:20", :in, "VAN-2", :large],
  ["08:30", :in, "CAR-4", :regular], ["08:31", :in, "CAR-5", :compact], ["08:40", :in, "CAR-6", :compact],
  ["09:00", :charge, "CAR-1", 18.5], ["09:15", :out, "MOTO-1", :ticket], ["09:20", :in, "CAR-6", :compact],
  ["11:47", :out, "CAR-1", :ticket], ["12:00", :out, "CAR-3", :lost], ["13:30", :out, "CAR-9", :lost],
  ["18:40", :out, "VAN-1", :ticket], ["19:05", :out, "CAR-2", :ticket]
]
events.each do |at, kind, plate, arg|
  case kind
  when :in
    t = garage.enter(plate, arg, at)
    tickets[plate] = t.number
    puts "#{at} #{plate} -> spot #{t.spot_id} (ticket #{t.number})"
  when :charge
    garage.charge(tickets.fetch(plate), arg)
    puts "#{at} #{plate} charged #{arg} kWh"
  when :out
    number = arg == :lost ? nil : tickets[plate]
    mins, cents = garage.leave(number, plate, at)
    revenue += cents
    puts format("%s %s leaves after %dh%02dm, pays $%.2f%s", at, plate, mins / 60, mins % 60, cents / 100.0, number ? "" : " (lost ticket)")
  end
rescue GarageFull => e
  puts "#{at} #{e.plate} turned away: #{e.message}"
rescue TicketError => e
  puts "#{at} error: #{e.message}"
end

puts
garage.occupancy.each do |level, used, total|
  puts "Level #{level}: #{used}/#{total} #{"#" * used}#{"." * (total - used)}"
end
puts format("Revenue: $%.2f", revenue / 100.0)
