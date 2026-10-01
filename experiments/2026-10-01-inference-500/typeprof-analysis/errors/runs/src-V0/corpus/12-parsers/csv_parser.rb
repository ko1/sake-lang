class CsvError < StandardError
  attr_reader :row

  def initialize(message, row)
    super(message)
    @row = row
  end
end

def parse_csv(text, sep)
  rows = []
  row = []
  field = +""
  state = :start
  text.each_char do |c|
    case state
    when :start, :field
      if c == "\"" && state == :start
        state = :quoted
      elsif c == sep
        row << field
        field = +""
        state = :start
      elsif c == "\n"
        row << field
        rows << row
        row = []
        field = +""
        state = :start
      elsif c != "\r"
        field << c
        state = :field
      end
    when :quoted
      if c == "\""
        state = :quote_in_quoted
      else
        field << c
      end
    when :quote_in_quoted
      if c == "\""
        field << "\""
        state = :quoted
      elsif c == sep
        row << field
        field = +""
        state = :start
      elsif c == "\n"
        row << field
        rows << row
        row = []
        field = +""
        state = :start
      else
        raise CsvError.new("unexpected '#{c}' after closing quote", rows.size + 1)
      end
    end
  end
  raise CsvError.new("unterminated quoted field", rows.size + 1) if state == :quoted
  unless field.empty? && row.empty?
    row << field
    rows << row
  end
  rows
end

def to_records(rows)
  header = rows.shift
  records = []
  bad = []
  rows.each_with_index do |row, i|
    if row.size != header.size
      bad << "row #{i + 2}: expected #{header.size} fields, got #{row.size}"
    else
      records << header.zip(row).to_h
    end
  end
  [records, bad]
end

SALES_CSV = "region,product,amount,note\n" \
            "north,widget,12.50,\n" \
            "south,\"gadget, large\",30.00,\"said \"\"rush\"\"\"\n" \
            "north,gizmo,7.25,\"two\nlines\"\n" \
            "east,widget,abc,typo\n" \
            "south,widget,5\n" \
            "east,gadget,19.99,ok\n" \
            "north,widget,3.75,last"

rows = parse_csv(SALES_CSV, ",")
puts "parsed #{rows.size} rows"
rows.each { |r| puts "  #{r.size}: #{r.map(&:inspect).join(" | ")}" }

records, bad = to_records(rows)
bad.each { |b| puts "skip #{b}" }

totals = Hash.new(0.0)
counts = Hash.new(0)
records.each do |rec|
  amount = rec["amount"]
  unless amount.match?(/\A\d+(\.\d+)?\z/)
    puts "bad amount #{amount.inspect} for #{rec["product"]}"
    next
  end
  totals[rec["region"]] += amount.to_f
  counts[rec["product"]] += 1
end
totals.keys.sort.each { |r| puts format("%-6s %8.2f", r, totals[r]) }
puts "products: #{counts.sort_by { |k, _| k }.map { |k, v| "#{k}x#{v}" }.join(", ")}"

["a;b;c\n1;\"x;y\";3\n", "a,b\n\"open,1\n", "a,b\n\"x\"y,2\n"].each do |text|
  sep = text.include?(";") ? ";" : ","
  begin
    puts "ok: #{parse_csv(text, sep).inspect}"
  rescue CsvError => e
    puts "error on row #{e.row}: #{e.message}"
  end
end
