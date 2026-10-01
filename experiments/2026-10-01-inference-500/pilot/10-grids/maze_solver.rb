# Solve text mazes by breadth-first search, draw the path, and count the walled-off pockets.

class Maze
  attr_accessor :name, :grid, :rows, :cols

  def initialize(name, grid, rows, cols)
    @name = name
    @grid = grid
    @rows = rows
    @cols = cols
  end

  def self.parse(name, text)
    grid = text.lines.map { |l| l.chomp.chars }
    Maze.new(name, grid, grid.size, grid[0].size)
  end

  def at(pos)
    r, c = pos
    return nil if r < 0 || c < 0 || r >= @rows || c >= @cols
    @grid[r][c]
  end

  def find_char(ch)
    @grid.each_with_index do |row, r|
      c = row.index(ch)
      return [r, c] if c
    end
    nil
  end

  def open?(pos)
    ch = at(pos)
    ch != nil && ch != "#"
  end

  def neighbors(pos)
    r, c = pos
    cand = [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]
    cand.select { |p| open?(p) }
  end

  def shortest_path(start, goal)
    parent = { start => nil }
    queue = [start]
    until queue.empty?
      cur = queue.shift
      break if cur == goal
      neighbors(cur).each do |nb|
        next if parent.key?(nb)
        parent[nb] = cur
        queue.push(nb)
      end
    end
    return nil unless parent.key?(goal)
    path = []
    node = goal
    while node
      path.unshift(node)
      node = parent[node]
    end
    path
  end

  def flood(start, seen)
    stack = [start]
    seen.add(start)
    size = 0
    while (cur = stack.pop)
      size += 1
      neighbors(cur).each do |nb|
        stack.push(nb) if seen.add?(nb)
      end
    end
    size
  end

  def pockets(start)
    seen = Set[]
    flood(start, seen)
    sizes = []
    @rows.times do |r|
      @cols.times do |c|
        pos = [r, c]
        next unless open?(pos)
        next if seen.include?(pos)
        sizes.push(flood(pos, seen))
      end
    end
    sizes
  end

  def draw(path)
    on_path = Set[]
    path.each { |p| on_path.add(p) }
    @grid.each_with_index do |row, r|
      line = (0...@cols).map do |c|
        ch = row[c]
        ch == " " && on_path.include?([r, c]) ? "*" : ch
      end
      puts(line.join(""))
    end
  end
end

def solve(text, name)
  m = Maze.parse(name, text)
  start = m.find_char("S")
  goal = m.find_char("G")
  puts("== #{m.name} (#{m.rows}x#{m.cols}) ==")
  if start == nil || goal == nil
    puts("missing start or goal")
    return
  end
  path = m.shortest_path(start, goal)
  if path
    puts("shortest path: #{path.size - 1} steps")
    m.draw(path)
    turns = 0
    path.each_cons(3) do |a, b, c|
      ar, ac = a
      br, bc = b
      cr, cc = c
      turns += 1 if br - ar != cr - br || bc - ac != cc - bc
    end
    puts("turns: #{turns}")
  else
    puts("no path from #{start} to #{goal}")
  end
  sizes = m.pockets(start)
  if sizes.empty?
    puts("every open cell is reachable")
  else
    puts("unreachable pockets: #{sizes.size}, sizes #{sizes.sort}")
  end
  puts
end

solve("##########\n#S   #   #\n# ## # # #\n#  #   # #\n## ##### #\n#      #G#\n# #### # #\n#    #   #\n##########", "winding")
solve("#########\n#S      #\n### # # #\n#   # #G#\n##### ###\n#   #   #\n#########", "pockets")
solve("#######\n#S #  #\n#  # G#\n#######", "walled")
solve("#####\n#S  #\n#####", "no goal")
