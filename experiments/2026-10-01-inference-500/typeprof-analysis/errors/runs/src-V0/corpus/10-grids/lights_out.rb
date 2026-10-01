class Grid
  attr_reader :size, :bits

  def initialize(size, bits)
    @size = size
    @bits = bits
  end

  def self.parse(rows)
    bits = 0
    n = rows.size
    rows.each_with_index do |row, r|
      row.each_char.with_index do |ch, c|
        bits |= 1 << (r * n + c) if ch == "*"
      end
    end
    new(n, bits)
  end

  def bit(r, c) = 1 << (r * @size + c)

  def lit?(r, c) = (@bits & bit(r, c)) != 0

  def press_mask(r, c)
    mask = bit(r, c)
    mask |= bit(r - 1, c) if r > 0
    mask |= bit(r + 1, c) if r < @size - 1
    mask |= bit(r, c - 1) if c > 0
    mask |= bit(r, c + 1) if c < @size - 1
    mask
  end

  def press(r, c)
    @bits ^= press_mask(r, c)
    self
  end

  def dark? = @bits == 0

  def lit_count
    n = 0
    b = @bits
    while b != 0
      n += b & 1
      b >>= 1
    end
    n
  end

  def to_s
    (0...@size).map { |r| (0...@size).map { |c| lit?(r, c) ? "*" : "." }.join }.join("\n")
  end
end

# light chasing: choose the first row, then each press below clears the light above it
def solve(rows)
  start = Grid.parse(rows)
  n = start.size
  best = nil
  (1 << n).times do |first|
    g = Grid.new(n, start.bits)
    presses = []
    n.times do |c|
      if (first >> c) & 1 == 1
        g.press(0, c)
        presses << [0, c]
      end
    end
    (1...n).each do |r|
      n.times do |c|
        if g.lit?(r - 1, c)
          g.press(r, c)
          presses << [r, c]
        end
      end
    end
    next unless g.dark?
    best = presses if best.nil? || presses.size < best.size
  end
  best
end

def verify(rows, presses)
  g = Grid.parse(rows)
  presses.each { |r, c| g.press(r, c) }
  g.dark?
end

puzzles = [
  ["plus", [".....", "..*..", ".***.", "..*..", "....."]],
  ["corners", ["*...*", ".....", ".....", ".....", "*...*"]],
  ["row", ["*****", ".....", ".....", ".....", "....."]],
  ["single", ["*....", ".....", ".....", ".....", "....."]],
  ["three", ["*.*", ".*.", "*.*"]],
  ["four", ["*..*", ".**.", ".**.", "*..*"]],
]

puzzles.each do |name, rows|
  g = Grid.parse(rows)
  puts "#{name} (#{g.lit_count} lit):"
  puts g
  presses = solve(rows)
  if presses
    names = presses.map { |r, c| "#{(97 + c).chr}#{r + 1}" }
    puts "  #{presses.size} presses: #{names.join(" ")} (verified: #{verify(rows, presses)})"
  else
    puts "  no solution"
  end
end
