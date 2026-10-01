class Terrain
  attr_reader :cells, :w, :h

  def initialize(cells, w, h)
    @cells = cells
    @w = w
    @h = h
  end

  def self.parse(rows) = new(rows.map(&:chars), rows[0].size, rows.size)

  def [](pos)
    x, y = pos
    return nil if x < 0 || y < 0 || x >= @w || y >= @h
    @cells[y][x]
  end

  def []=(pos, ch)
    x, y = pos
    @cells[y][x] = ch
  end

  def cost(pos)
    case self[pos]
    in "." | "S" | "G" then 1
    in "~" then 5
    in "^" then 3
    else nil
    end
  end

  def locate(ch)
    @h.times do |y|
      @w.times do |x|
        return [x, y] if @cells[y][x] == ch
      end
    end
    nil
  end
end

class Node
  include Comparable
  attr_reader :f, :g, :x, :y

  def initialize(f, g, x, y)
    @f = f
    @g = g
    @x = x
    @y = y
  end

  def <=>(other)
    c = f <=> other.f
    c == 0 ? other.g <=> g : c
  end
end

def heuristic(x, y, gx, gy) = (x - gx).abs + (y - gy).abs

def astar(t, start, goal)
  gx, gy = goal
  sx, sy = start
  open = [Node.new(heuristic(sx, sy, gx, gy), 0, sx, sy)]
  best = { start => 0 }
  came = {}
  expanded = 0
  until open.empty?
    pick = 0
    open.each_with_index { |n, i| pick = i if n < open[pick] }
    cur = open.delete_at(pick)
    x = cur.x
    y = cur.y
    g = cur.g
    next if g > best.fetch([x, y], g)
    expanded += 1
    return [g, came, expanded] if x == gx && y == gy
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      nb = [x + dx, y + dy]
      step = t.cost(nb)
      next unless step
      ng = g + step
      old = best[nb]
      next if old && old <= ng
      best[nb] = ng
      came[nb] = [x, y]
      nx, ny = nb
      open << Node.new(ng + heuristic(nx, ny, gx, gy), ng, nx, ny)
    end
  end
  [nil, came, expanded]
end

def mark_path(t, came, start, goal)
  cur = came[goal]
  steps = 1
  while cur
    break if cur == start
    t[cur] = "*"
    steps += 1
    cur = came[cur]
  end
  steps
end

def solve(title, rows)
  puts "== #{title}"
  t = Terrain.parse(rows)
  start = t.locate("S")
  goal = t.locate("G")
  cost, came, expanded = astar(t, start, goal)
  if !cost    
    puts "unreachable (expanded #{expanded})"
    return
  end
  steps = mark_path(t, came, start, goal)
  puts "cost #{cost}, #{steps} steps, expanded #{expanded}"
  t.cells.each { |r| puts r.join }
end

solve("valley", [
  "S..~~~....",
  ".#.~~~.##.",
  ".#..^^.#..",
  ".####..#.#",
  "...~~..#..",
  ".#.~~###..",
  ".#......^G"
])
solve("river", [
  "S.~~..",
  "..~~..",
  "..~~.G"
])
solve("sealed", [
  "S.#...",
  "..#.G.",
  "###..."
])
