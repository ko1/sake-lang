class Maze
  attr_reader :rows, :width, :height

  def initialize(rows, width, height)
    @rows = rows
    @width = width
    @height = height
  end

  def self.parse(text)
    rows = text.lines.map { |l| l.chomp.chars }
    new(rows, rows.first.size, rows.size)
  end

  def find(ch)
    @rows.each_with_index do |row, y|
      x = row.index(ch)
      return [x, y] if x
    end
    nil
  end

  def open?(x, y)
    return false if x < 0 || y < 0 || x >= @width || y >= @height
    @rows[y][x] != "#"
  end

  def neighbors(pos)
    x, y = pos
    [[1, 0], [0, 1], [0, -1], [-1, 0]].filter_map do |dx, dy|
      nx = x + dx
      ny = y + dy
      [nx, ny] if open?(nx, ny)
    end
  end
end

def bfs(maze, start, goal)
  prev = { start => nil }
  queue = [start]
  until queue.empty?
    cur = queue.shift
    break if cur == goal
    maze.neighbors(cur).each do |nb|
      next if prev.key?(nb)
      prev[nb] = cur
      queue << nb
    end
  end
  return nil unless prev.key?(goal)
  path = []
  node = goal
  while node
    path.unshift(node)
    node = prev[node]
  end
  path
end

def render(maze, path)
  rows = maze.rows.map(&:dup)
  path.each do |x, y|
    rows[y][x] = "." if rows[y][x] == " "
  end
  rows.each { |r| puts r.join }
end

def solve(name, text)
  maze = Maze.parse(text)
  start = maze.find("S")
  goal = maze.find("G")
  puts "== #{name} (#{maze.width}x#{maze.height})"
  if start.nil? || goal.nil?
    puts "missing start or goal"
    return
  end
  path = bfs(maze, start, goal)
  if path
    puts "steps: #{path.size - 1}"
    render(maze, path)
  else
    puts "no path"
  end
end

maze1 = "##########\n" \
        "#S   #   #\n" \
        "# ## # # #\n" \
        "#  #   # #\n" \
        "## ##### #\n" \
        "#      #G#\n" \
        "# #### # #\n" \
        "#      # #\n" \
        "######   #\n" \
        "##########\n"
maze2 = "#######\n" \
        "#S#   #\n" \
        "# # # #\n" \
        "### #G#\n" \
        "#######\n"
maze3 = "#####\n#S  #\n#####\n"

solve("first", maze1)
solve("walled", maze2)
solve("no goal", maze3)
