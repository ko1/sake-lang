require "set"

class Islands
  attr_reader :width, :height, :count

  def initialize(w, h)
    @width = w
    @height = h
    @parent = {}
    @size = {}
    @count = 0
  end

  def key(x, y) = y * @width + x

  def land?(x, y)
    x >= 0 && y >= 0 && x < @width && y < @height && @parent.key?(key(x, y))
  end

  def root(k)
    while @parent[k] != k
      @parent[k] = @parent[@parent[k]]
      k = @parent[k]
    end
    k
  end

  def join(a, b)
    ra = root(a)
    rb = root(b)
    return if ra == rb
    ra, rb = rb, ra if @size[ra] < @size[rb]
    @parent[rb] = ra
    @size[ra] += @size[rb]
    @size.delete(rb)
    @count -= 1
  end

  def raise_land(x, y)
    k = key(x, y)
    return false if @parent.key?(k)
    @parent[k] = k
    @size[k] = 1
    @count += 1
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      nx = x + dx
      ny = y + dy
      join(k, key(nx, ny)) if land?(nx, ny)
    end
    true
  end

  def largest = @size.values.max || 0

  def draw
    labels = {}
    @height.times do |y|
      row = +""
      @width.times do |x|
        if land?(x, y)
          r = root(key(x, y))
          labels[r] ||= (97 + labels.size).chr
          row << labels[r]
        else
          row << "~"
        end
      end
      puts "  #{row}"
    end
  end
end

def flood_count(m)
  seen = Set.new
  count = 0
  m.height.times do |y|
    m.width.times do |x|
      next unless m.land?(x, y)
      next if seen.include?([x, y])
      count += 1
      stack = [[x, y]]
      seen << [x, y]
      until stack.empty?
        cx, cy = stack.pop
        [[cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]].each do |px, py|
          next unless m.land?(px, py)
          stack << [px, py] if seen.add?([px, py])
        end
      end
    end
  end
  count
end

volcano = [
  [1, 1], [2, 1], [5, 1], [6, 1], [1, 2], [6, 2], [3, 4], [8, 4], [8, 3], [8, 5],
  [2, 2], [4, 4], [4, 3], [5, 2], [4, 2], [3, 2], [0, 6], [9, 0], [2, 1], [7, 4]
]
m = Islands.new(10, 7)
history = []
volcano.each_with_index do |(x, y), step|
  fresh = m.raise_land(x, y)
  history << m.count
  note = fresh ? "" : " (already land)"
  puts format("%2d: (%d,%d) islands=%d largest=%d%s", step + 1, x, y, m.count, m.largest, note)
end
m.draw
puts "peak islands: #{history.max} after step #{history.index(history.max) + 1}"
drops = history.each_cons(2).count { |a, b| b < a }
puts "steps that merged islands: #{drops}"
puts "flood fill agrees: #{flood_count(m) == m.count}"
