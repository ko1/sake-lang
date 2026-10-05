class RowError < StandardError
  attr_reader :line, :column

  def initialize(message, line, column)
    super(message)
    @line = line
    @column = column
  end
end

class Order
  attr_reader :id, :customer, :date, :qty, :price, :note

  def initialize(id, customer, date, qty, price, note)
    @id = id
    @customer = customer
    @date = date
    @qty = qty
    @price = price
    @note = note
  end
end

def input
  <<~CSV
    id,customer,date,qty,price,note
    1001,"Acme, Inc.",2026-03-01,4,19.99,
    1002,Globex,2026-03-02,10,4.50,"rush, gift wrap"
    1003,Initech,2026-13-02,1,99.00,
    1004,"Umbrella ""Corp""",2026-03-04,two,5.00,
    1005,Hooli,2026-03-05,3,,missing price
    1006,Acme, Inc.,2026-03-06,1,1.00,
    1007,Globex,2026-03-07,0,12.00,
    1008,Stark,2026-03-08,7,3.25,"said ""thanks"""
    1001,Wayne,2026-03-09,2,8.00,duplicate id
  CSV
end

def split_csv_line(line)
  fields = []
  cur = +""
  quoted = false
  chars = line.chars
  i = 0
  while i < chars.size
    c = chars[i]
    if quoted
      if c == "\"" && chars[i + 1] == "\""
        cur << "\""
        i += 1
      elsif c == "\""
        quoted = false
      else
        cur << c
      end
    elsif c == "\""
      quoted = true
    elsif c == ","
      fields << cur
      cur = +""
    else
      cur << c
    end
    i += 1
  end
  fields << cur
  fields
end

def parse_int(s, line, col)
  raise RowError.new("#{col} is not an integer: #{s.inspect}", line, col) unless s.match?(/\A\d+\z/)
  s.to_i
end

def parse_date(s, line)
  m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/)
  raise RowError.new("bad date #{s}", line, "date") if m.nil?
  month = m[2].to_i
  day = m[3].to_i
  raise RowError.new("month out of range in #{s}", line, "date") unless month.between?(1, 12)
  raise RowError.new("day out of range in #{s}", line, "date") unless day.between?(1, 31)
  s
end

def parse_row(fields, header, line)
  if fields.size != header.size
    raise RowError.new("expected #{header.size} fields, got #{fields.size}", line, "*")
  end
  row = header.zip(fields).to_h
  id = parse_int(row.fetch("id"), line, "id")
  qty = parse_int(row.fetch("qty"), line, "qty")
  raise RowError.new("qty must be positive", line, "qty") if qty == 0
  price_s = row.fetch("price")
  raise RowError.new("price is empty", line, "price") if price_s.empty?
  price = Float(price_s)
  note = row.fetch("note")
  Order.new(id, row.fetch("customer"), parse_date(row.fetch("date"), line), qty, price, note.empty? ? nil : note)
end

lines = input.lines
header = split_csv_line(lines.fetch(0).chomp)
orders = []
errors = []
seen_ids = {}
lines.drop(1).each_with_index do |raw, i|
  line_no = i + 2
  begin
    order = parse_row(split_csv_line(raw.chomp), header, line_no)
    first = seen_ids[order.id]
    raise RowError.new("duplicate id #{order.id} (first on line #{first})", line_no, "id") if first
    seen_ids[order.id] = line_no
    orders << order
  rescue RowError => e
    errors << e
  end
end

puts "Imported #{orders.size} of #{lines.size - 1} rows"
orders.each do |o|
  total = o.qty * o.price
  puts format("  #%d %-18s %s %3d x %6.2f = %8.2f%s", o.id, o.customer, o.date,
              o.qty, o.price, total, o.note ? "  [#{o.note}]" : "")
end
puts format("  total value: %.2f", orders.sum { |o| o.qty * o.price })
puts
puts "Rejected #{errors.size} rows:"
errors.each do |e|
  puts "  line #{e.line} [#{e.column}]: #{e.message}"
end
by_col = errors.map(&:column).tally
puts "Errors by column: " + by_col.sort_by { |c, n| c }.map { |c, n| "#{c}=#{n}" }.join(", ")
