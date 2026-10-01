class CsvError < StandardError
  attr_reader :line, :col

  def initialize(message, line, col)
    super(message)
    @line = line
    @col = col
  end
end

def parse_csv(text)
  rows = []
  row = []
  field = +""
  state = :field_start
  line = 1
  col = 0
  (text + "\n").each_char do |c|
    col += 1
    case state
    in :field_start
      if c == "\""
        state = :quoted
      elsif c == ","
        row << field
        field = +""
      elsif c == "\n"
        row << field
        rows << row unless row.size == 1 && field == ""
        row = []
        field = +""
        line += 1
        col = 0
      elsif c != "\r"
        field << c
        state = :unquoted
      end
    in :unquoted
      if c == ","
        row << field
        field = +""
        state = :field_start
      elsif c == "\n"
        row << field
        rows << row
        row = []
        field = +""
        state = :field_start
        line += 1
        col = 0
      elsif c == "\""
        raise CsvError.new("quote inside unquoted field", line, col)
      elsif c != "\r"
        field << c
      end
    in :quoted
      if c == "\""
        state = :quote_seen
      else
        field << c
        if c == "\n"
          line += 1
          col = 0
        end
      end
    in :quote_seen
      if c == "\""
        field << "\""
        state = :quoted
      elsif c == ","
        row << field
        field = +""
        state = :field_start
      elsif c == "\n"
        row << field
        rows << row
        row = []
        field = +""
        state = :field_start
        line += 1
        col = 0
      elsif c != "\r"
        raise CsvError.new("garbage after closing quote", line, col)
      end
    end
  end
  raise CsvError.new("unterminated quoted field", line, col) if state == :quoted
  rows
end

def flat(f) = f.gsub("\n", "|")

def report(name, text)
  puts "== #{name}"
  rows = parse_csv(text)
  header = rows.first
  body = rows.drop(1)
  widths = header.map(&:size)
  bad, good = body.partition { it.size != header.size }
  good.each do |r|
    r.each_with_index { |f, i| widths[i] = [widths[i], flat(f).size].max }
  end
  ([header] + good).each do |r|
    puts r.zip(widths).map { |f, w| flat(f).ljust(w) }.join(" | ")
  end
  puts "#{good.size} rows, #{bad.size} with wrong field count"
  amount_col = header.index("amount")
  if amount_col
    total = good.sum { |r| r[amount_col].to_f }
    puts format("amount total: %.2f", total)
  end
rescue CsvError => e
  puts "parse error at line #{e.line}, col #{e.col}: #{e.message}"
end

report("orders", "id,customer,amount,note\r\n1,Alice,12.50,\r\n2,\"Bob, Jr.\",7.25,\"said \"\"hi\"\"\"\r\n3,Cy,100,\"two\nlines\"\r\n4,Dee,3\r\n")
report("empty fields", "a,b,c\n,,\n1,,3\n\n")
report("bad quote", "name,amount\nab\"c,1\n")
report("garbage", "name,amount\n\"x\"y,2\n")
report("unterminated", "name,amount\n\"open,5\n")
