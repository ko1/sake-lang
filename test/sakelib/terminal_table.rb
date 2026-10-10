require_relative "ref/terminal_table"

rows = [["Alice", 30, "Tokyo"], ["Bob", 4, "Osaka"], ["Christopher", 125, "Kyoto"]]
t = Terminal::Table.new(headings: ["Name", "Age", "City"], rows: rows)
puts t
p t.number_of_columns

# a title, a separator, right-aligned numbers
t2 = Terminal::Table.new(title: "Population", headings: ["Name", "Age", "City"], rows: rows)
t2.add_separator
t2.add_row(["Total", 159, ""])
t2.align_column(1, :right)
puts t2
p rows.size

# unicode borders, centered, short rows and other values
t3 = Terminal::Table.new(rows: [[1, 2.5, nil], [:sym, true], ["日本"]], border: :unicode,
                       alignment: :center)
t3 << [[1, 2], [3, "x"]]
puts t3

# a title wider than the columns
puts Terminal::Table.new(title: "A rather long title", rows: [["a", "b"]])

# markdown
md = Terminal::Table.new(headings: ["Lib", "Lines", "Status"], border: :markdown)
md.add_row(["semver", 163, "ok"])
md.add_row(["text", 120, "ok"])
md.add_separator
md.align_column(1, :right)
md.align_column(2, :center)
puts md

# no headings; empty
puts Terminal::Table.new(rows: [["x"]])
p Terminal::Table.new.to_s
puts Terminal::Table.new(headings: ["only", "headings"])

# errors
begin
  Terminal::Table.new(border: :fancy)
rescue ArgumentError => e
  puts e.message
end
begin
  t.align_column(0, :justify)
rescue ArgumentError => e
  puts e.message
end
begin
  Terminal::Table.new(title: "T", border: :markdown)
rescue ArgumentError => e
  puts e.message
end
