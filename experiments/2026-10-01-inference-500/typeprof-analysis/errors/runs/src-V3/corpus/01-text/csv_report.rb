class CsvError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

class Sale
  attr_reader :region, :rep, :product, :units, :price, :note

  def initialize(region, rep, product, units, price, note)
    @region = region
    @rep = rep
    @product = product
    @units = units
    @price = price
    @note = note
  end

  def amount = units * price
end

def parse_csv(text)
  rows = []
  row = []
  field = +""
  state = :start
  line = 1
  chars = text.chars
  i = 0
  while i < chars.size
    c = chars[i]
    if state == :quoted
      if c == "\""
        if chars[i + 1] == "\""
          field << "\""
          i += 1
        else
          state = :after_quote
        end
      else
        line += 1 if c == "\n"
        field << c
      end
    elsif c == ","
      row << field
      field = +""
      state = :start
    elsif c == "\n"
      row << field
      rows << row
      row = []
      field = +""
      state = :start
      line += 1
    elsif c == "\"" && state == :start
      state = :quoted
    elsif state == :after_quote
      raise CsvError.new("unexpected '#{c}' after closing quote", line)
    else
      field << c
      state = :plain
    end
    i += 1
  end
  raise CsvError.new("unterminated quoted field", line) if state == :quoted
  unless field.empty? && row.empty?
    row << field
    rows << row
  end
  rows
end

def to_sales(rows)
  header, *body = rows
  idx = header.each_with_index.to_h { |h, i| [h.strip.downcase, i] }
  body.map do |r|
    Sale.new(r[idx["region"]], r[idx["rep"]], r[idx["product"]],
             r[idx["units"]].to_i, r[idx["price"]].to_f, r[idx["note"]])
  end
end

def money(x)
  whole = (x * 100).round
  s = (whole / 100).to_s.gsub(/(\d)(?=(\d{3})+\z)/, "\\1,")
  format("%s.%02d", s, whole % 100)
end

def report(sales)
  by_region = sales.group_by(&:region)
  grand = 0.0
  by_region.keys.sort.each do |region|
    list = by_region[region]
    total = list.sum(&:amount)
    grand += total
    puts "#{region} (#{list.size} sales)"
    list.sort_by(&:rep).each do |s|
      note_text = s.note.nil? || s.note.empty? ? "" : "  # " + s.note.gsub("\n", " / ")
      puts format("  %-8s %-14s %4d x %8s = %10s%s", s.rep, s.product,
                  s.units, money(s.price), money(s.amount), note_text)
    end
    puts format("  %-38s %10s", "subtotal", money(total))
  end
  puts format("%-40s %10s", "GRAND TOTAL", money(grand))
  best = sales.max_by(&:amount)
  puts "largest sale: #{best.rep} / #{best.product}" if best
end

def data
  "Region,Rep,Product,Units,Price,Note\n" \
  "West,Ito,\"Desk, oak\",3,1250.00,\n" \
  "East,Brown,Chair,12,89.5,\"bulk order\"\n" \
  "West,Abe,Lamp,40,19.99,\"customer said \"\"rush\"\"\"\n" \
  "North,Chen,\"Shelf\",5,240,\"two lines:\nassemble on site\"\n" \
  "East,Adams,Desk,1,1300,\n" \
  "North,Baker,Chair,200,85.25,\"largest, by far\"\n"
end

begin
  rows = parse_csv(data)
  puts "parsed #{rows.size} rows, #{rows[0].size} columns"
  report(to_sales(rows))
rescue CsvError => e
  puts "csv error on line #{e.line}: #{e.message}"
end

["a,\"b\"x,c\n", "a,\"never closed\n", "x,y\n1,2"].each do |bad|
  rows = parse_csv(bad)
  puts "ok: #{rows.size} rows, last = #{rows.last.join("|")}"
rescue CsvError => e
  puts "csv error on line #{e.line}: #{e.message}"
end
