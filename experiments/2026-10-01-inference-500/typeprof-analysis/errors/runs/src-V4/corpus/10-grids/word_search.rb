class Hit
  attr_reader :word, :row, :col, :dir

  def initialize(word, row, col, dir)
    @word = word
    @row = row
    @col = col
    @dir = dir
  end
end

DIRECTIONS = [
  { name: "E", dr: 0, dc: 1 }, { name: "W", dr: 0, dc: -1 },
  { name: "S", dr: 1, dc: 0 }, { name: "N", dr: -1, dc: 0 },
  { name: "SE", dr: 1, dc: 1 }, { name: "NW", dr: -1, dc: -1 },
  { name: "NE", dr: -1, dc: 1 }, { name: "SW", dr: 1, dc: -1 },
].freeze

class Puzzle
  attr_reader :letters, :used

  def initialize(letters, used)
    @letters = letters
    @used = used
  end

  def self.parse(rows)
    letters = rows.map { |row| row.delete(" ").upcase.chars }
    new(letters, letters.map { |row| row.map { false } })
  end

  def letter(r, c)
    return nil if r < 0 || c < 0
    @letters[r]&.[](c)
  end

  def matches?(word, r, c, dr, dc)
    word.chars.each_with_index.all? { |ch, i| letter(r + dr * i, c + dc * i) == ch }
  end

  def find(word)
    target = word.upcase
    @letters.each_with_index do |row, r|
      row.each_with_index do |ch, c|
        next if ch != target[0]
        DIRECTIONS.each do |d|
          d => { name:, dr:, dc: }
          return Hit.new(target, r, c, name) if matches?(target, r, c, dr, dc)
        end
      end
    end
    nil
  end

  def mark(hit)
    d = DIRECTIONS.find { |x| x[:name] == hit.dir }
    return unless d
    hit.word.size.times do |i|
      @used[hit.row + d[:dr] * i][hit.col + d[:dc] * i] = true
    end
  end

  def leftovers
    out = []
    @letters.each_with_index do |row, r|
      row.each_with_index { |ch, c| out << ch unless @used[r][c] }
    end
    out.join
  end

  def render
    @letters.zip(@used).map do |letters, used|
      letters.zip(used).map { |ch, u| u ? ch : ch.downcase }.join(" ")
    end.join("\n")
  end
end

grid = [
  "R U B Y T K O H N",
  "A S T R I N G E L",
  "N H S E T N I O O",
  "G E A R R A Y P O",
  "E K H S A H S P E",
  "W L U P O R C A K",
  "M A P T U P L E A",
  "B L O C K S I T S",
]
words = %w[ruby string array hash range block tuple loop map shell sake yield keys set]

pz = Puzzle.parse(grid)
found = []
missing = []
words.each do |w|
  if (hit = pz.find(w))
    found << hit
    pz.mark(hit)
  else
    missing << w
  end
end

found.sort_by(&:word).each do |h|
  puts format("%-7s at (%d,%d) going %s", h.word, h.row, h.col, h.dir)
end
puts "not found: #{missing.join(", ")}"
by_dir = found.map(&:dir).tally
puts "directions: #{by_dir.keys.sort.map { |k| "#{k}=#{by_dir[k]}" }.join(" ")}"
puts pz.render
puts "leftover letters: #{pz.leftovers}"
