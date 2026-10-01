class InvalidPuzzle < StandardError
  attr_reader :row, :col

  def initialize(message, row, col)
    super(message)
    @row = row
    @col = col
  end
end

class Sudoku
  attr_reader :cells, :guesses

  def initialize(cells, guesses)
    @cells = cells
    @guesses = guesses
  end

  def self.parse(rows)
    cells = rows.flat_map { |line| line.chars.map { |ch| ch == "." ? 0 : ch.to_i } }
    raise ArgumentError, "expected 81 cells, got #{cells.size}" if cells.size != 81
    new(cells, 0)
  end

  def self.peers(i)
    r, c = i.divmod(9)
    br = r / 3 * 3
    bc = c / 3 * 3
    out = []
    9.times do |k|
      out.push(r * 9 + k, k * 9 + c, (br + k / 3) * 9 + bc + k % 3)
    end
    out.uniq.reject { it == i }
  end

  PEERS = (0...81).map { |i| peers(i) }

  def candidates(i)
    used = PEERS[i].map { |j| @cells[j] }.to_set
    (1..9).reject { |d| used.include?(d) }
  end

  def validate!
    @cells.each_with_index do |v, i|
      next if v == 0
      PEERS[i].each do |j|
        raise InvalidPuzzle.new("digit #{v} repeated", i / 9 + 1, i % 9 + 1) if @cells[j] == v
      end
    end
    self
  end

  def solve
    best = nil
    best_cands = nil
    @cells.each_with_index do |v, i|
      next if v != 0
      cands = candidates(i)
      if !best_cands     || cands.size < best_cands.size
        best = i
        best_cands = cands
      end
    end
    return true if !best    
    best_cands.each do |d|
      @guesses += 1
      @cells[best] = d
      return true if solve
    end
    @cells[best] = 0
    false
  end

  def to_s
    lines = []
    9.times do |r|
      lines << "------+-------+------" if r == 3 || r == 6
      lines << @cells[r * 9, 9].each_slice(3).map { |g| g.join(" ") }.join(" | ")
    end
    lines.join("\n")
  end
end

def run(name, rows)
  puts "## #{name}"
  s = Sudoku.parse(rows).validate!
  givens = s.cells.count { it != 0 }
  if s.solve
    puts "solved (#{givens} givens, #{s.guesses} placements)"
    puts s
  else
    puts "no solution after #{s.guesses} placements"
  end
rescue InvalidPuzzle => e
  puts "invalid: #{e.message} at r#{e.row}c#{e.col}"
rescue ArgumentError => e
  puts "unreadable: #{e.message}"
end

run("easy", ["53..7....", "6..195...", ".98....6.", "8...6...3", "4..8.3..1", "7...2...6", ".6....28.", "...419..5", "....8..79"])
run("nearly done", ["5.4678912", "672195.48", "19834256.", "8.9761423", "4268537.1", "71392485.", "9615.7284", "287419635", "34528617."])
run("duplicate", ["55..7....", "6..195...", ".98....6.", "8...6...3", "4..8.3..1", "7...2...6", ".6....28.", "...419..5", "....8..79"])
run("short", ["123", "456"])
