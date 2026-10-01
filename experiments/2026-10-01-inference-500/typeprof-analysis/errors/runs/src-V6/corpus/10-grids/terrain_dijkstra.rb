require "set"

class Terrain
  attr_reader :tiles, :rows, :cols

  def initialize(tiles, rows, cols)
    @tiles = tiles
    @rows = rows
    @cols = cols
  end

  def self.parse(lines) = new(lines.map(&:chars), lines.size, lines[0].size)

  def cost_at(r, c)
    return nil if r < 0 || r >= @rows || c < 0 || c >= @cols
    tile_cost(@tiles[r][c])
  end

  def find(ch)
    @tiles.each_with_index do |row, r|
      c = row.index(ch)
      return [r, c] if c
    end
    nil
  end

  def cheapest(from, to)
    dist = { from => 0.0 }
    prev = {}
    done = Set.new
    frontier = [from]
    until frontier.empty?
      best_i = frontier.each_index.min_by { |i| dist[frontier[i]] }
      cur = frontier.delete_at(best_i)
      next if done.include?(cur)
      done << cur
      break if cur == to
      r, c = cur
      [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]].each do |nxt|
        step = cost_at(*nxt)
        next unless step
        nd = dist[cur] + step
        old = dist[nxt]
        if !old     || nd < old
          dist[nxt] = nd
          prev[nxt] = cur
          frontier << nxt
        end
      end
    end
    total = dist[to]
    return nil unless total
    cells = [to]
    cells.unshift(prev[cells.first]) while prev[cells.first]
    Route.new(total, cells)
  end

  def draw(route)
    canvas = @tiles.map(&:dup)
    route.cells.each do |r, c|
      canvas[r][c] = "*" unless %w[S G].include?(canvas[r][c])
    end
    canvas.map(&:join).join("\n")
  end
end

class Route
  attr_reader :cost, :cells

  def initialize(cost, cells)
    @cost = cost
    @cells = cells
  end
end

def tile_cost(ch)
  case ch
  when ".", "S", "G" then 1.0
  when "=" then 0.5
  when "~" then 3.5
  when "^" then 5.0
  end
end

def describe(t, route)
  kinds = route.cells.drop(1).map { |r, c| t.tiles[r][c] }.tally
  kinds.keys.sort.map { |k| "#{k}x#{kinds[k]}" }.join(" ")
end

def survey(name, lines)
  puts "== #{name} =="
  t = Terrain.parse(lines)
  s = t.find("S")
  g = t.find("G")
  unless s && g
    puts "map needs S and G"
    return
  end
  route = t.cheapest(s, g)
  if route
    puts format("cost %.1f over %d steps (%s)", route.cost, route.cells.size - 1, describe(t, route))
    puts t.draw(route)
  else
    puts "G is unreachable from S"
  end
end

TILES_LEGEND = "S/G=1.0 .=1.0 ==0.5 ~=3.5 ^=5.0 #=wall"

puts "legend: #{TILES_LEGEND}"
survey("river crossing", [
  "S...~~~....",
  "....~~~.^^.",
  ".##.~~~.^^.",
  ".#..===....",
  ".#..~~~..#G",
])
survey("mountain pass", [
  "S^^^^^^",
  ".^^.^^.",
  ".^....^",
  "...^^.G",
])
survey("blocked", [
  "S.#..",
  "..#..",
  "###.G",
])
survey("no goal", ["S...."])
