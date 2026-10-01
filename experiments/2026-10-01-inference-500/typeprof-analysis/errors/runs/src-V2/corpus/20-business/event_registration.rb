class TicketType
  attr_reader :name, :price, :early_price, :capacity
  attr_accessor :sold

  def initialize(name, price, early_price, capacity, sold)
    @name = name
    @price = price
    @early_price = early_price
    @capacity = capacity
    @sold = sold
  end

  def unit_price(date) = date <= EARLY_BIRD_ENDS ? early_price : price
end

class Registration
  attr_reader :order, :name, :company, :ticket, :paid, :diet

  def initialize(order, name, company, ticket, paid, diet)
    @order = order
    @name = name
    @company = company
    @ticket = ticket
    @paid = paid
    @diet = diet
  end

  def last_name = name.rpartition(" ")[2]

  def badge
    first, _sp, last = name.rpartition(" ")
    line1 = last.upcase + ", " + first
    line2 = company || "Independent"
    "[#{line1.center(22)}|#{line2.center(14)}|#{ticket.name.center(8)}]"
  end
end

class SoldOutError < StandardError
  attr_reader :ticket

  def initialize(message, ticket)
    super(message)
    @ticket = ticket
  end
end

EARLY_BIRD_ENDS = "2026-08-31"

types = {
  "full" => TicketType.new("full", 600, 450, 6, 0),
  "day" => TicketType.new("day", 250, 200, 3, 0),
  "vip" => TicketType.new("vip", 1500, 1500, 1, 0)
}

orders = [
  ["2026-08-20", "full", [["Grace Hopper", "Navy", "veg"], ["Alan Kay", nil, nil]]],
  ["2026-08-31", "day", [["Yukihiro Matsumoto", "Ruby Assn", nil]]],
  ["2026-09-03", "full", [["Barbara Liskov", "MIT", "gf"], ["John Backus", "IBM", nil], ["Frances Allen", "IBM", "veg"]]],
  ["2026-09-05", "vip", [["Ada Lovelace", nil, "veg"]]],
  ["2026-09-06", "vip", [["Charles Babbage", nil, nil]]],
  ["2026-09-07", "full", [["Edsger Dijkstra", "TU/e", nil]]],
  ["2026-09-09", "day", [["Donald Knuth", "Stanford", "veg"], ["Leslie Lamport", "MSR", nil]]]
]

regs = []
revenue = 0
orders.each_with_index do |(date, type_name, people), i|
  tt = types.fetch(type_name)
  n = people.size
  begin
    left = tt.capacity - tt.sold
    raise SoldOutError.new("only #{left} #{type_name} left, wanted #{n}", type_name) if n > left
    total = tt.unit_price(date) * n
    total = total * 90 / 100 if n >= 3
    tt.sold += n
    revenue += total
    people.each do |name, company, diet|
      regs << Registration.new(i + 1, name, company, tt, total / n, diet)
    end
    puts format("order %d %s: %d x %-4s %5d%s", i + 1, date, n, type_name, total, n >= 3 ? " (group -10%)" : "")
  rescue SoldOutError => e
    puts format("order %d %s: sold out (%s)", i + 1, date, e.message)
  end
end

puts
regs.sort_by { |r| r.last_name.downcase }.each { |r| puts r.badge }
puts
types.each_value do |tt|
  puts format("%-4s %d/%d sold", tt.name, tt.sold, tt.capacity)
end
diets = regs.filter_map(&:diet).tally
puts "Catering: #{regs.size} people, " + diets.map { |d, k| "#{k} #{d}" }.join(", ")
puts "Revenue: #{revenue}, average #{format("%.2f", revenue * 1.0 / regs.size)} per attendee"
companies = regs.select(&:company).group_by(&:company)
companies.select { |_c, rs| rs.size > 1 }.each { |c, rs| puts "#{c} sends #{rs.size}" }
