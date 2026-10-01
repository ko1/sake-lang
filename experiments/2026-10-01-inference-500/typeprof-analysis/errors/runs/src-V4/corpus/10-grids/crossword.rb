require "set"

class Conflict < StandardError
  attr_reader :row, :col

  def initialize(message, row, col)
    super(message)
    @row = row
    @col = col
  end
end

class Entry
  attr_reader :number, :direction, :row, :col, :length

  def initialize(number, direction, row, col, length)
    @number = number
    @direction = direction
    @row = row
    @col = col
    @length = length
  end

  def cells
    (0...@length).map { |i| @direction == :across ? [@row, @col + i] : [@row + i, @col] }
  end

  def label = "#{@number}#{@direction == :across ? "A" : "D"}"
end

class Crossword
  attr_reader :blocks, :rows, :cols, :entries, :letters

  def initialize(blocks, rows, cols, entries, letters)
    @blocks = blocks
    @rows = rows
    @cols = cols
    @entries = entries
    @letters = letters
  end

  def self.parse(lines)
    blocks = Set.new
    lines.each_with_index do |line, r|
      line.each_char.with_index { |ch, c| blocks << [r, c] if ch == "#" }
    end
    cw = new(blocks, lines.size, lines[0].size, [], {})
    cw.number
    cw
  end

  def open?(r, c) = r >= 0 && r < @rows && c >= 0 && c < @cols && !@blocks.include?([r, c])

  def run_length(r, c, dr, dc)
    n = 0
    n += 1 while open?(r + dr * n, c + dc * n)
    n
  end

  def number
    n = 0
    @rows.times do |r|
      @cols.times do |c|
        next unless open?(r, c)
        across = !open?(r, c - 1) && run_length(r, c, 0, 1) >= 2
        down = !open?(r - 1, c) && run_length(r, c, 1, 0) >= 2
        next unless across || down
        n += 1
        @entries << Entry.new(n, :across, r, c, run_length(r, c, 0, 1)) if across
        @entries << Entry.new(n, :down, r, c, run_length(r, c, 1, 0)) if down
      end
    end
  end

  def entry(label) = @entries.find { it.label == label }

  def fill(label, word)
    e = entry(label)
    raise ArgumentError, "no entry #{label}" unless e
    raise ArgumentError, "#{label} needs #{e.length} letters, got #{word}" if word.size != e.length
    cells = e.cells
    cells.each_with_index do |cell, i|
      have = @letters[cell]
      want = word[i]
      raise Conflict.new("#{label} puts #{want} where #{have} is", *cell) if have && have != want
    end
    cells.each_with_index { |cell, i| @letters[cell] = word[i] }
    e
  end

  def pattern(e) = e.cells.map { |cell| @letters[cell] || "_" }.join

  def to_s
    (0...@rows).map do |r|
      (0...@cols).map { |c| open?(r, c) ? (@letters[[r, c]] || ".") : "#" }.join
    end.join("\n")
  end
end

cw = Crossword.parse([
  "...#....",
  "...#....",
  "........",
  "##...###",
  "....#...",
  "....#...",
])

[:across, :down].each do |dir|
  list = cw.entries.select { it.direction == dir }
  puts "#{dir}: #{list.map { |e| "#{e.label}(#{e.length})" }.join(" ")}"
end

answers = [
  ["1A", "CAT"], ["1D", "COW"], ["4A", "RUBY"], ["2D", "AXE"], ["9A", "WEST"], ["9D", "WINE"],
  ["4D", "ROPE"], ["3D", "TEN"], ["5D", "UNIT"], ["7A", "ERA"], ["12A", "IDLE"], ["2D", "ACE"], ["6A", "SAKE"],
  ["3D", "TENANT"], ["10A", "WENTOVER"], ["10A", "WEREWOLF"],
]
answers.each do |label, word|
  cw.fill(label, word)
  puts "#{label} = #{word}"
rescue Conflict => err
  puts "#{label} = #{word}: conflict at (#{err.row},#{err.col}): #{err.message}"
rescue ArgumentError => err
  puts "#{label} = #{word}: #{err.message}"
end

puts cw
open_entries = cw.entries.select { |e| cw.pattern(e).include?("_") }
puts "still open: #{open_entries.map { |e| "#{e.label} #{cw.pattern(e)}" }.join(", ")}"
filled = cw.letters.size
total = cw.rows * cw.cols - cw.blocks.size
puts "filled #{filled}/#{total} cells"
