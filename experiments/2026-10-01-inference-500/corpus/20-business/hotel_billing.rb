class Stay
  attr_reader :guest, :room_type, :arrive, :nights, :adults, :company

  def initialize(guest, room_type, arrive, nights, adults, company)
    @guest = guest
    @room_type = room_type
    @arrive = arrive
    @nights = nights
    @adults = adults
    @company = company
  end
end

class Charge
  attr_reader :night, :category, :text, :amount, :payer

  def initialize(night, category, text, amount, payer)
    @night = night
    @category = category
    @text = text
    @amount = amount
    @payer = payer
  end
end

class BillingError < StandardError
  attr_reader :guest

  def initialize(message, guest)
    super(message)
    @guest = guest
  end
end

DAY_SECONDS = 86400
BASE_RATE = { single: 120.0, double: 160.0, suite: 340.0 }
CITY_TAX_PER_ADULT = 3.5

# season multiplier by month
def season(t)
  m = t.month
  if m == 7 || m == 8 then 1.35
  elsif m == 12 then 1.2
  elsif m <= 2 then 0.85
  else 1.0
  end
end

class Folio
  attr_reader :stay, :charges, :payments

  def initialize(stay)
    @stay = stay
    @charges = []
    @payments = []
  end

  # folio[:minibar] sums one category
  def [](category) = @charges.select { |c| c.category == category }.sum(&:amount)

  def post(night, category, text, amount)
    raise BillingError.new("night #{night} is outside the stay", @stay.guest) unless (1..@stay.nights).cover?(night)
    payer = category == :room && @stay.company ? @stay.company : @stay.guest
    @charges << Charge.new(night, category, text, amount.round(2), payer)
  end

  def post_rooms
    @stay.nights.times do |i|
      t = @stay.arrive + i * DAY_SECONDS
      rate = BASE_RATE.fetch(@stay.room_type) * season(t)
      rate *= 1.15 if t.friday? || t.saturday?
      post(i + 1, :room, "Room #{t.strftime("%a %b %d")}", rate)
      post(i + 1, :tax, "City tax", CITY_TAX_PER_ADULT * @stay.adults)
    end
  end

  def pay(who, amount) = @payments << [who, amount]

  def owed_by(who)
    charged = @charges.select { |c| c.payer == who }.sum(&:amount)
    paid = @payments.select { |w, _a| w == who }.sum { |_w, a| a }
    (charged - paid).round(2)
  end

  def payers = @charges.map(&:payer).uniq
end

def print_folio(f)
  s = f.stay
  depart = s.arrive + s.nights * DAY_SECONDS
  puts "Folio: #{s.guest} (#{s.room_type}, #{s.adults} adults) #{s.arrive.strftime("%Y-%m-%d")} to #{depart.strftime("%Y-%m-%d")}"
  f.charges.each do |c|
    next if c.category == :tax
    puts format("  n%-2d %-22s %8.2f  %s", c.night, c.text, c.amount, c.payer)
  end
  [:room, :tax, :minibar, :restaurant, :spa].each do |cat|
    total = f[cat]
    puts format("  %-27s %8.2f", "total #{cat}", total) if total > 0
  end
  f.payers.each do |who|
    owed = f.owed_by(who)
    status = owed > 0 ? format("owes %.2f", owed) : (owed < 0 ? format("refund %.2f", -owed) : "settled")
    puts "  #{who}: #{status}"
  end
end

stays = [
  Stay.new("M. Rossi", :double, Time.new(2026, 7, 30), 4, 2, "Acme GmbH"),
  Stay.new("K. Tanaka", :single, Time.new(2026, 2, 26), 3, 1, nil),
  Stay.new("L. Okafor", :suite, Time.new(2026, 12, 23), 2, 3, nil)
]
folios = {}
stays.each do |s|
  f = Folio.new(s)
  f.post_rooms
  folios[s.guest] = f
end

extras = [
  ["M. Rossi", 1, :minibar, "Minibar", 14.5], ["M. Rossi", 2, :restaurant, "Dinner", 86.0],
  ["M. Rossi", 4, :spa, "Massage", 95.0], ["M. Rossi", 6, :minibar, "Minibar", 7.0],
  ["K. Tanaka", 2, :restaurant, "Breakfast", 18.0], ["L. Okafor", 1, :restaurant, "Christmas dinner", 240.0],
  ["L. Okafor", 2, :minibar, "Champagne", 89.0], ["J. Doe", 1, :minibar, "Water", 3.0]
]
extras.each do |guest, night, cat, text, amount|
  f = folios[guest]
  if f.nil?
    puts "no folio for #{guest}"
    next
  end
  begin
    f.post(night, cat, text, amount)
  rescue BillingError => e
    puts "#{e.guest}: #{e.message}"
  end
end

folios.fetch("M. Rossi").pay("M. Rossi", 100.0)
folios.fetch("K. Tanaka").pay("K. Tanaka", 400.0)
folios.fetch("L. Okafor").pay("L. Okafor", 500.0)

folios.each_value do |f|
  puts
  print_folio(f)
end

puts
room_revenue = folios.values.sum { |f| f[:room] }
nights = stays.sum(&:nights)
puts format("Room nights %d, ADR %.2f, extras %.2f", nights, room_revenue / nights,
  folios.values.sum { |f| f[:minibar] + f[:restaurant] + f[:spa] })
