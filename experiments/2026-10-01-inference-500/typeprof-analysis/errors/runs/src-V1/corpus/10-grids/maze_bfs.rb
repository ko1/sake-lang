class Maze
  attr_reader :grid, :start, :goal

  DIRS = [[0, 1], [1, 0], [0, -1], [-1, 0]].freeze

  def initialize(grid, start, goal)
    @grid = grid
    @start = start
    @goal = goal
  end

  def self.parse(text)
    grid = text.lines.map { |l| l.chomp.chars }
    start = nil
    goal = nil
    grid.each_with_index do |row, r|
      row.each_with_index do |ch, c|
        start = [r, c] if ch == "S"
        goal = [r, c] if ch == "E"
      end
    end
    raise ArgumentError, "maze has no start" unless start
    raise ArgumentError, "maze has no exit" unless goal
    new(grid, start, goal)
  end

  def open?(r, c)
    return false if r < 0 || c < 0
    row = @grid[r]
    return false unless row
    ch = row[c]
    !ch.nil? && ch != "#"
  end

  def solve
    parent = { @start => @start }
    queue = [@start]
    until queue.empty?
      cur = queue.shift
      break if cur == @goal
      r, c = cur
      DIRS.each do |dr, dc|
        nxt = [r + dr, c + dc]
        next unless open?(*nxt)
        next if parent.key?(nxt)
        parent[nxt] = cur
        queue << nxt
      end
    end
    return nil unless parent.key?(@goal)
    path = [@goal]
    node = @goal
    while node != @start
      node = parent[node]
      path.unshift(node)
    end
    path
  end

  def render(path)
    rows = @grid.map(&:dup)
    path.each do |r, c|
      rows[r][c] = "*" if rows[r][c] == "."
    end
    rows.map(&:join).join("\n")
  end

  def open_count = @grid.sum { |row| row.count { it != "#" } }
end

def report(name, text)
  puts "--- #{name} ---"
  maze = Maze.parse(text)
  path = maze.solve
  if path
    puts "shortest path: #{path.size - 1} steps"
    turns = 0
    path.each_cons(3) do |(ar, ac), (br, bc), (cr, cc)|
      turns += 1 if (br - ar) != (cr - br) || (bc - ac) != (cc - bc)
    end
    puts "turns: #{turns}"
    puts maze.render(path)
  else
    puts "no path (#{maze.open_count} open cells)"
  end
rescue ArgumentError => e
  puts "bad maze: #{e.message}"
end

report("small", "#######\n#S..#.#\n#.#.#.#\n#.#...#\n#.###.#\n#...#E#\n#######\n")
report("open room", "S.....\n......\n..##..\n......\n.....E\n")
report("walled off", "#####\n#S#.#\n###.#\n#..E#\n#####\n")
report("broken", "#####\n#...#\n#..E#\n#####\n")
report("winding", "S.#.......\n..#.####.#\n.##.#..#..\n....#.##.#\n#####.#..#\n#.....#.##\n#.#####..E\n")
