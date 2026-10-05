# Prints `cal`-style month grids, three months side by side, with marked days.

require "set"

MONTH_NAMES = ["January", "February", "March", "April", "May", "June", "July",
               "August", "September", "October", "November", "December"]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def days_in_month(y, m)
  return 29 if m == 2 && leap?(y)
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
end

def weekday(y, m, d)
  t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
  y -= 1 if m < 3
  (y + y / 4 - y / 100 + y / 400 + t[m - 1] + d) % 7
end

class MonthGrid
  attr_reader :year, :month, :weeks

  def initialize(year, month, weeks)
    @year = year
    @month = month
    @weeks = weeks
  end

  def self.build(y, m)
    weeks = []
    week = Array.new(7)
    col = weekday(y, m, 1)
    (1..days_in_month(y, m)).each do |d|
      week[col] = d
      col += 1
      if col == 7
        weeks << week
        week = Array.new(7)
        col = 0
      end
    end
    weeks << week if col > 0
    new(y, m, weeks)
  end

  def title = "#{MONTH_NAMES[@month - 1]} #{@year}"

  def lines(marks)
    out = [title.center(21), "Su Mo Tu We Th Fr Sa "]
    @weeks.each do |week|
      cells = week.map do |d|
        if d.nil?
          "   "
        elsif marks.include?([@year, @month, d])
          d.to_s.rjust(2) + "*"
        else
          d.to_s.rjust(2) + " "
        end
      end
      out << cells.join
    end
    out << "" while out.size < 8
    out
  end
end

def side_by_side(grids, marks)
  columns = grids.map { |g| g.lines(marks) }
  (0..7).each do |i|
    row = columns.map { |c| c[i].ljust(21) }
    puts row.join("  ").rstrip
  end
end

def next_month(y, m) = m == 12 ? [y + 1, 1] : [y, m + 1]

marks = Set[[2026, 10, 1], [2026, 10, 31], [2026, 11, 26], [2026, 12, 25], [2027, 1, 1], [2027, 2, 14]]

y = 2026
m = 9
2.times do
  grids = []
  3.times do
    grids << MonthGrid.build(y, m)
    y, m = next_month(y, m)
  end
  side_by_side(grids, marks)
  puts
end

feb = MonthGrid.build(2028, 2)
aug = MonthGrid.build(2026, 8)
side_by_side([feb, aug], Set[])
puts
[feb, aug].each do |g|
  rows = g.weeks.size
  first_full = g.weeks.find_index { |w| w.all? { |d| !d.nil? } }
  puts "#{g.title}: #{rows} rows, first full week is row #{first_full ? first_full + 1 : "none"}"
end
