# Sudoku: parse, validate, and solve with constraint propagation plus backtracking.

class InvalidPuzzle < StandardError
  attr_reader :cell

  def initialize(message, cell)
    super(message)
    @cell = cell
  end
end

class Sudoku
  attr_accessor :cells, :guesses

  def initialize(cells, guesses)
    @cells = cells
    @guesses = guesses
  end

  def self.parse(text)
    digits = text.delete("\n").delete(" ")
    raise ArgumentError, "need 81 cells, got #{digits.size}" if digits.size != 81
    cells = []
    digits.each_char do |ch|
      cells.push(ch == "." ? 0 : ch.to_i)
    end
    Sudoku.new(cells, 0)
  end

  def self.peers(i)
    r, c = i.divmod(9)
    br = r / 3 * 3
    bc = c / 3 * 3
    result = Set[]
    9.times do |k|
      result.add(r * 9 + k)
      result.add(k * 9 + c)
      result.add((br + k / 3) * 9 + bc + k % 3)
    end
    result.delete(i)
    result
  end

  def candidates(i)
    used = Set[]
    Sudoku.peers(i).each { |j| used.add(@cells[j]) }
    (1..9).to_a.reject { |d| used.include?(d) }
  end

  def validate
    @cells.each_with_index do |v, i|
      next if v == 0
      clash = Sudoku.peers(i).find { |j| @cells[j] == v }
      if clash
        raise InvalidPuzzle.new("digit #{v} repeats at r#{clash / 9 + 1}c#{clash % 9 + 1}", i)
      end
    end
    self
  end

  def propagate(trail)
    changed = true
    while changed
      changed = false
      @cells.each_with_index do |v, i|
        next if v != 0
        cands = candidates(i)
        return false if cands.empty?
        if cands.size == 1
          @cells[i] = cands[0]
          trail.push(i)
          changed = true
        end
      end
    end
    true
  end

  def solve
    trail = []
    if propagate(trail)
      empties = (0...81).to_a.select { |i| @cells[i] == 0 }
      return true if empties.empty?
      best = empties.min_by { |i| candidates(i).size }
      candidates(best).each do |d|
        @guesses += 1
        @cells[best] = d
        return true if solve
        @cells[best] = 0
      end
    end
    trail.each { |i| @cells[i] = 0 }
    false
  end

  def to_s
    lines = []
    @cells.each_slice(9).each_with_index do |row, r|
      lines.push("------+-------+------") if r > 0 && r % 3 == 0
      groups = row.each_slice(3).map do |g|
        g.map { |v| v == 0 ? "." : v.to_s }.join(" ")
      end
      lines.push(groups.join(" | "))
    end
    lines.join("\n")
  end
end

def run(name, text)
  puts("== #{name} ==")
  s = Sudoku.parse(text).validate
  givens = s.cells.count { |v| v != 0 }
  puts("givens: #{givens}")
  if s.solve
    puts(s)
    puts("solved with #{s.guesses} guesses")
  else
    puts("no solution (#{s.guesses} guesses tried)")
  end
rescue InvalidPuzzle => e
  puts("invalid: #{e.message} (cell #{e.cell})")
rescue ArgumentError => e
  puts("bad input: #{e.message}")
ensure
  puts
end

run("easy", "53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79")
run("medium", "..9748...
7........
.2.1.9...
..7...24.
.64.1.59.
.98...3..
...8.3.2.
........6
...2759..")
run("duplicate", "53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
5...8..79")
run("short", "123456789")
run("stuck", "12345678.
........9
.........
.........
.........
.........
.........
.........
.........")
