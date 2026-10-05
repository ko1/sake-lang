DAY_SECS = 86400
BASE_RATE = { single: 80, double: 120, suite: 260 }.freeze

class BookingError < StandardError
  attr_reader :ref

  def initialize(message, ref)
    super(message)
    @ref = ref
  end
end

class Stay
  attr_reader :ref, :guest, :first_night, :nights, :rate_total
  attr_accessor :status

  def initialize(ref, guest, first_night, nights, rate_total)
    @ref = ref
    @guest = guest
    @first_night = first_night
    @nights = nights
    @rate_total = rate_total
    @status = :booked
  end

  def night_list = (0...@nights).map { |i| @first_night + i * DAY_SECS }
end

def season_factor(t)
  weekend = t.friday? || t.saturday?
  mult = t.month == 12 && t.day >= 20 ? 150 : 100
  weekend ? mult + 25 : mult
end

class Room
  attr_reader :number, :kind, :floor, :stays

  def initialize(number, kind, floor)
    @number = number
    @kind = kind
    @floor = floor
    @stays = []
  end

  def free?(first, nights)
    wanted = (0...nights).map { |i| first + i * DAY_SECS }
    @stays.none? { |s| s.status == :booked && s.night_list.any? { |n| wanted.include?(n) } }
  end
end

class Hotel
  attr_reader :rooms, :waitlist, :ledger

  def initialize(rooms)
    @rooms = rooms
    @waitlist = []
    @ledger = []
    @next_ref = 0
  end

  def price(kind, first, nights)
    (0...nights).sum { |i| BASE_RATE[kind] * season_factor(first + i * DAY_SECS) / 100 }
  end

  def book(guest, kind, first, nights)
    raise BookingError.new("#{guest}: stay must be 1..14 nights", "") unless (1..14).cover?(nights)
    room = @rooms.find { |r| r.kind == kind && r.free?(first, nights) }
    if room.nil?
      @waitlist << [guest, kind, first, nights]
      raise BookingError.new("#{guest}: no #{kind} free from #{first.strftime("%b %d")}, waitlisted", "")
    end
    @next_ref += 1
    ref = "R#{@next_ref}"
    stay = Stay.new(ref, guest, first, nights, price(kind, first, nights))
    room.stays << stay
    @ledger << [ref, "charge", stay.rate_total]
    "#{ref} #{guest} room #{room.number} #{first.strftime("%b %d")} x#{nights} = #{stay.rate_total}"
  end

  def find_stay(ref)
    @rooms.each do |r|
      s = r.stays.find { |st| st.ref == ref }
      return [r, s] if s
    end
    nil
  end

  def cancel(ref, today)
    found = find_stay(ref)
    raise BookingError.new("unknown booking #{ref}", ref) if found.nil?
    room, stay = found
    raise BookingError.new("#{ref} already #{stay.status}", ref) if stay.status != :booked
    stay.status = :cancelled
    days_before = ((stay.first_night - today) / DAY_SECS).to_i
    penalty = if days_before >= 7
                0
              elsif days_before >= 2
                stay.rate_total / 4
              else
                stay.rate_total / 2
              end
    @ledger << [ref, "refund", penalty - stay.rate_total]
    msg = "#{ref} cancelled #{days_before} days ahead, penalty #{penalty}"
    promoted = promote(room.kind)
    promoted ? "#{msg}; #{promoted}" : msg
  end

  def promote(kind)
    idx = @waitlist.find_index do |_guest, k, first, nights|
      k == kind && @rooms.any? { |r| r.kind == kind && r.free?(first, nights) }
    end
    return nil if idx.nil?
    guest, k, first, nights = @waitlist.delete_at(idx)
    "from waitlist: #{book(guest, k, first, nights)}"
  end
end

rooms = [
  Room.new(101, :single, 1), Room.new(102, :double, 1),
  Room.new(201, :double, 2), Room.new(301, :suite, 3)
]
hotel = Hotel.new(rooms)
d = Time.new(2026, 12, 15)

requests = [
  [0, :book, "ito", :double, 3, 4], [0, :book, "kay", :double, 4, 3], [1, :book, "lin", :double, 5, 2],
  [1, :book, "moe", :suite, 7, 5], [2, :book, "nat", :single, 6, 20], [2, :book, "ola", :single, 2, 3],
  [3, :cancel, "R2", :none, 0, 0], [4, :book, "pia", :suite, 9, 2], [5, :cancel, "R9", :none, 0, 0],
  [6, :cancel, "R4", :none, 0, 0], [6, :cancel, "R4", :none, 0, 0], [7, :book, "quy", :single, 9, 1]
]

requests.each do |today_off, action, who, kind, off, nights|
  today = d + today_off * DAY_SECS
  stamp = today.strftime("%m-%d")
  begin
    msg = action == :book ? hotel.book(who, kind, d + off * DAY_SECS, nights) : hotel.cancel(who, today)
    puts "#{stamp} #{msg}"
  rescue BookingError => e
    puts "#{stamp} ! #{e.message}"
  end
end

puts "--- occupancy"
(0..12).each do |i|
  night = d + i * DAY_SECS
  marks = rooms.map do |r|
    s = r.stays.find { |st| st.status == :booked && st.night_list.include?(night) }
    s ? s.guest[0] : "."
  end
  puts "#{night.strftime("%a %m-%d")} #{marks.join(" ")}  x#{season_factor(night)}"
end
net = hotel.ledger.sum { |_ref, _kind, amount| amount }
puts "ledger entries #{hotel.ledger.size}, net revenue #{net}"
puts "still waitlisted: #{hotel.waitlist.map { |g, k, _f, _n| "#{g}(#{k})" }.join(", ")}"
