class Client
  attr_reader :code, :name, :terms_days, :discount_pct, :rates

  def initialize(code, name, terms_days, discount_pct, rates)
    @code = code
    @name = name
    @terms_days = terms_days
    @discount_pct = discount_pct
    @rates = rates
  end
end

class Entry
  attr_reader :date, :client, :person, :hours, :note

  def initialize(date, client, person, hours, note)
    @date = date
    @client = client
    @person = person
    @hours = hours
    @note = note
  end
end

class Expense
  attr_reader :date, :client, :amount, :note

  def initialize(date, client, amount, note)
    @date = date
    @client = client
    @amount = amount
    @note = note
  end
end

class InvoiceLine
  attr_reader :text, :qty, :unit, :amount

  def initialize(text, qty, unit, amount)
    @text = text
    @qty = qty
    @unit = unit
    @amount = amount
  end
end

STAFF_ROLES = { "alice" => :senior, "bob" => :junior, "carol" => :senior, "dan" => :designer }
STANDARD_RATES = { senior: 150r, junior: 90r, designer: 110r }
TAX_RATE = 8.25r / 100

def cents(r) = (r * 100).round

def money(r)
  c = cents(r)
  whole = (c / 100).to_s
  grouped = whole.reverse.scan(/\d{1,3}/).join(",").reverse
  "$#{grouped}.#{format("%02d", c % 100)}"
end

def parse_date(s)
  Time.new(*s.split("-").map(&:to_i))
end

def rate_for(client, person)
  role = STAFF_ROLES.fetch(person)
  client.rates.fetch(role, STANDARD_RATES.fetch(role))
end

def build_lines(client, entries, expenses)
  lines = []
  mine = entries.select { |e| e.client == client.code }
  by_person = mine.group_by(&:person)
  by_person.keys.sort.each do |person|
    es = by_person.fetch(person)
    hours = es.sum(&:hours)
    rate = rate_for(client, person)
    notes = es.map(&:note).uniq.join("; ")
    lines << InvoiceLine.new("#{person.capitalize} - #{notes}", hours, rate, hours * rate)
  end
  expenses.select { |x| x.client == client.code }.each do |x|
    lines << InvoiceLine.new("Expense: #{x.note}", 1r, x.amount, x.amount)
  end
  lines
end

def print_invoice(number, client, lines, issued)
  due = issued + client.terms_days * 86400
  puts "INVOICE #{number}"
  puts "Bill to: #{client.name}"
  puts "Issued:  #{issued.strftime("%Y-%m-%d")}   Due: #{due.strftime("%Y-%m-%d (%a)")}"
  puts "-" * 64
  lines.each do |l|
    text = l.text
    text = text[0...37] + "..." if text.size > 40
    puts format("%-40s %5.2f %8s %10s", text, l.qty.to_f, money(l.unit), money(l.amount))
  end
  subtotal = lines.sum(&:amount)
  discount = subtotal * client.discount_pct / 100
  taxable = subtotal - discount
  tax = taxable * TAX_RATE
  total = taxable + tax
  puts "-" * 64
  puts format("%55s %8s", "Subtotal", money(subtotal))
  puts format("%55s %8s", "Discount #{client.discount_pct}%", money(discount)) if discount > 0
  puts format("%55s %8s", "Tax 8.25%", money(tax))
  puts format("%55s %8s", "TOTAL", money(total))
  puts
  cents(total)
end

clients = [
  Client.new("acme", "Acme Corp.", 30, 0, { senior: 140r }),
  Client.new("glob", "Globex Ltd.", 15, 5, {}),
  Client.new("init", "Initech", 45, 10, { junior: 85r, designer: 100r }),
  Client.new("hool", "Hooli", 30, 0, {})
]

timesheet = <<~TXT
  2026-09-01 acme alice 3.5 Architecture review
  2026-09-02 acme bob 6 API implementation
  2026-09-03 glob carol 2.25 Kickoff workshop
  2026-09-03 acme bob 7.5 API implementation
  2026-09-04 init dan 4 Logo concepts
  2026-09-08 init bob 3 Data migration scripts for the legacy billing system
  2026-09-09 acme alice 1.25 Code review
  2026-09-10 glob carol 5.5 Requirements document
  2026-09-11 init dan 2.5 Logo revisions
TXT

entries = timesheet.lines.map do |line|
  m = line.chomp.match(/\A(\S+) (\w+) (\w+) ([\d.]+) (.+)\z/)
  Entry.new(parse_date(m[1]), m[2], m[3], m[4].to_r, m[5])
end

expenses = [
  Expense.new(parse_date("2026-09-03"), "glob", 184.4r, "Train tickets"),
  Expense.new(parse_date("2026-09-12"), "acme", 1299r / 10, "Test devices"),
  Expense.new(parse_date("2026-09-15"), "glob", 36r, "Workshop supplies")
]

issued = parse_date("2026-09-30")
seq = 41
billed = {}
clients.each do |client|
  lines = build_lines(client, entries, expenses)
  if lines.empty?
    puts "(nothing to bill for #{client.name})"
    puts
    next
  end
  seq += 1
  number = "INV-#{issued.year}-#{seq.to_s.rjust(4, "0")}"
  billed[client.code] = print_invoice(number, client, lines, issued)
end

total_hours = entries.sum(&:hours)
puts "Billed hours: #{total_hours.to_f}"
grand = billed.sum { |_code, c| c }
puts "Grand total: #{money(Rational(grand, 100))}"
first = entries.min_by(&:date)
last = entries.max_by(&:date)
span = (last.date - first.date) / 86400
puts "Work period: #{first.date.strftime("%b %-d")} - #{last.date.strftime("%b %-d")} (#{span.to_i + 1} days)"
