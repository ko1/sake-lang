# Import CSV product rows against a column schema; collect cell-level errors as Records.
CSV_DATA = "sku,name,price,qty,category,released
A-100,Desk lamp,19.99,12,home,2025-03-14
A-101,,4.50,3,home,2025-13-01
B-200,USB cable,abc,40,electronics,2024-11-30
B-201,Charger,24.00,-5,electronics,2024-02-30
C-300,Notebook,3.25,100,stationery
C-301,Pen set,7.80,25,office,2023-07-07
A-1x2,Mug,8.00,7,home,2025-01-20
D-400,Headphones,89.90,4,electronics,2025-06-01"

CATEGORIES = ["home", "electronics", "stationery"]

def days_in_month(y, m)
  return 29 if m == 2 && (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
end

def check_cell(column, raw)
  case column
  when "sku"
    return "bad SKU format" unless raw.match?(/\A[A-Z]-\d{3}\z/)
  when "name"
    return "required" if raw.empty?
  when "price"
    return "not a decimal" unless raw.match?(/\A\d+\.\d{2}\z/)
  when "qty"
    n = Integer(raw, exception: false)
    return "not an integer" if !n    
    return "negative" if n < 0
  when "category"
    return "unknown category #{raw}" unless CATEGORIES.include?(raw)
  when "released"
    m = raw.match(/\A(\d{4})-(\d{2})-(\d{2})\z/)
    return "not a date" unless m
    y, mo, d = m.captures.map(&:to_i)
    return "month #{mo} out of range" unless (1..12).cover?(mo)
    return "day #{d} out of range" unless d.between?(1, days_in_month(y, mo))
  else
    return "unexpected column"
  end
  nil
end

def import(text)
  lines = text.lines
  header = lines[0].chomp.split(",")
  good = []
  errors = []
  lines.drop(1).each_with_index do |line, i|
    row_no = i + 2
    cells = line.chomp.split(",")
    if cells.size != header.size
      errors << { row: row_no, column: "*", message: "expected #{header.size} cells, got #{cells.size}" }
      next
    end
    row_errors = 0
    header.each_with_index do |col, j|
      if (msg = check_cell(col, cells[j])) && msg
        row_errors += 1
        errors << { row: row_no, column: col, message: msg }
      end
    end
    good << cells if row_errors.zero?
  end
  [good, errors]
end

good, errors = import(CSV_DATA)
puts "imported #{good.size} row(s):"
good.each do |cells|
  value = Float(cells[2]) * Integer(cells[3])
  puts format("  %-6s %-11s %8.2f", cells[0], cells[1], value)
end
puts "rejected cells: #{errors.size}"
errors.each do |err|
  puts "  row #{err[:row]} [#{err[:column]}] #{err[:message]}"
end
rows_with_errors = errors.map { |err| err[:row] }.uniq
puts "rows with errors: #{rows_with_errors.join(" ")}"
