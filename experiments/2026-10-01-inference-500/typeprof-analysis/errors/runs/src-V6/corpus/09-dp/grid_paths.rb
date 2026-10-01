class Grid
  attr_reader :rows, :height, :width

  def initialize(rows, height, width)
    @rows = rows
    @height = height
    @width = width
  end

  def self.parse(text)
    rows = text.split("\n").map { |line| line.strip.chars }
    new(rows, rows.size, rows[0].size)
  end

  def cell(r, c) = @rows[r][c]
  def blocked?(r, c) = cell(r, c) == "#"
  def cost(r, c) = blocked?(r, c) ? nil : (cell(r, c) == "." ? 1 : cell(r, c).to_i)
end

def count_paths(g)
  h = g.height
  w = g.width
  ways = Array.new(h) { Array.new(w, 0) }
  h.times do |r|
    w.times do |c|
      next if g.blocked?(r, c)
      if r == 0 && c == 0
        ways[r][c] = 1
      else
        up = r > 0 ? ways[r - 1][c] : 0
        left = c > 0 ? ways[r][c - 1] : 0
        ways[r][c] = up + left
      end
    end
  end
  ways[h - 1][w - 1]
end

def cheapest_path(g)
  h = g.height
  w = g.width
  best = Array.new(h) { Array.new(w) }
  from = Array.new(h) { Array.new(w) }
  h.times do |r|
    w.times do |c|
      here = g.cost(r, c)
      next if !here    
      if r == 0 && c == 0
        best[r][c] = here
        next
      end
      up = r > 0 ? best[r - 1][c] : nil
      left = c > 0 ? best[r][c - 1] : nil
      if up && (!left     || up <= left)
        best[r][c] = up + here
        from[r][c] = :down
      elsif left
        best[r][c] = left + here
        from[r][c] = :right
      end
    end
  end
  total = best[h - 1][w - 1]
  return nil if !total    
  moves = []
  r = h - 1
  c = w - 1
  while r > 0 || c > 0
    dir = from[r][c]
    moves.unshift(dir)
    if dir == :down
      r -= 1
    else
      c -= 1
    end
  end
  [total, moves]
end

def render(g, moves)
  marks = g.rows.map(&:dup)
  r = 0
  c = 0
  marks[0][0] = "*"
  moves.each do |m|
    if m == :down
      r += 1
    else
      c += 1
    end
    marks[r][c] = "*"
  end
  marks.each { |row| puts "    " + row.join }
end

def compress(moves)
  moves.chunk_while { |a, b| a == b }.map { |run| "#{run.size}#{run[0] == :down ? "D" : "R"}" }.join(" ")
end

maps = {
  "open" => "....\n....\n....",
  "walls" => "..#..\n.#...\n...#.\n#....",
  "weighted" => "13.9\n.9.1\n52.1\n1191",
  "sealed" => "..#\n.#.\n#..",
  "maze" => ".2..#.\n.#.#..\n...7#.\n#9#...\n...#1."
}

maps.each do |name, text|
  g = Grid.parse(text)
  puts "#{name} (#{g.height}x#{g.width}): #{count_paths(g)} monotone paths"
  result = cheapest_path(g)
  if result
    total, moves = result
    puts "  cheapest: cost #{total}, moves #{compress(moves)}"
    render(g, moves)
  else
    puts "  no path to the corner"
  end
end

puts "lattice paths in an empty n x n grid:"
[2, 5, 10, 16].each do |n|
  text = (1..n).map { "." * n }.join("\n")
  puts format("  %2d: %d", n, count_paths(Grid.parse(text)))
end
