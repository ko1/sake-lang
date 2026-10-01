# cells: 1 = filled, 0 = empty, nil = unknown
def clue(line)
  line.chunk_while { |a, b| a == b }.select { |run| run[0] == 1 }.map(&:size)
end

def arrangements(clues, length)
  return [Array.new(length, 0)] if clues.empty?
  first, *rest = clues
  min_rest = rest.sum + rest.size
  out = []
  (0..(length - first - min_rest)).each do |start|
    head = Array.new(start, 0) + Array.new(first, 1)
    if rest.empty?
      out << head + Array.new(length - start - first, 0)
    else
      head << 0
      arrangements(rest, length - head.size).each { |tail| out << head + tail }
    end
  end
  out
end

def fits?(candidate, known)
  candidate.zip(known).all? { |c, k| !k     || k == c }
end

# returns the line with every cell that all consistent arrangements agree on
def refine(clues, known)
  options = arrangements(clues, known.size).select { |a| fits?(a, known) }
  return nil if options.empty?
  (0...known.size).map do |i|
    values = options.map { |a| a[i] }.uniq
    values.size == 1 ? values[0] : nil
  end
end

class Puzzle
  attr_reader :row_clues, :col_clues, :grid

  def initialize(row_clues, col_clues, grid)
    @row_clues = row_clues
    @col_clues = col_clues
    @grid = grid
  end

  def self.from_picture(lines)
    pic = lines.map { |l| l.chars.map { it == "#" ? 1 : 0 } }
    grid = pic.map { |row| row.map { nil } }
    new(pic.map { clue(it) }, pic.transpose.map { clue(it) }, grid)
  end

  def column(c) = @grid.map { |row| row[c] }

  def unknowns = @grid.sum { |row| row.count(nil) }

  # one sweep over rows then columns; returns false on a contradiction
  def sweep
    @row_clues.each_with_index do |clues, r|
      line = refine(clues, @grid[r])
      return false unless line
      @grid[r] = line
    end
    @col_clues.each_with_index do |clues, c|
      line = refine(clues, column(c))
      return false unless line
      line.each_with_index { |v, r| @grid[r][c] = v }
    end
    true
  end

  def solve
    passes = 0
    while unknowns > 0
      before = unknowns
      passes += 1
      return [:contradiction, passes] unless sweep
      return [:stuck, passes] if unknowns == before
    end
    [:solved, passes]
  end

  def to_s
    @grid.map do |row|
      row.map { |v| !v     ? "?" : (v == 1 ? "#" : ".") }.join
    end.join("\n")
  end
end

def clue_text(clues) = clues.map { |c| c.empty? ? "0" : c.join(".") }.join(" ")

def run(name, lines)
  pz = Puzzle.from_picture(lines)
  puts "#{name}: rows #{clue_text(pz.row_clues)} | cols #{clue_text(pz.col_clues)}"
  status, passes = pz.solve
  puts "  #{status} after #{passes} passes, #{pz.unknowns} unknown"
  puts pz
  if status == :solved
    same = pz.grid.map { |row| row.map { it == 1 ? "#" : "." }.join } == lines
    puts "  matches picture: #{same}"
  end
end

run("heart", [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."])
run("arrow", ["..#...", "..##..", "######", "######", "..##..", "..#..."])
run("checker", ["#.#.", ".#.#", "#.#.", ".#.#"])
run("empty corner", ["###", "#..", "#.."])
