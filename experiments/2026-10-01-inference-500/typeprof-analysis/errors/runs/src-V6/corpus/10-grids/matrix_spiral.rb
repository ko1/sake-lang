require "set"

class Matrix
  attr_reader :height, :width, :data

  def initialize(height, width, data)
    @height = height
    @width = width
    @data = data
  end

  def self.filled(h, w, v) = new(h, w, Array.new(h * w, v))

  def self.from_rows(rows) = new(rows.size, rows[0].size, rows.flatten)

  def [](r, c) = @data[r * @width + c]

  def []=(r, c, v)
    @data[r * @width + c] = v
  end

  def row(r) = @data[r * @width, @width]

  def transpose
    out = Matrix.filled(@width, @height, 0)
    @height.times do |r|
      @width.times { |c| out[c, r] = self[r, c] }
    end
    out
  end

  def rotate
    out = Matrix.filled(@width, @height, 0)
    @height.times do |r|
      @width.times { |c| out[c, @height - 1 - r] = self[r, c] }
    end
    out
  end

  def symmetric?
    return false if @height != @width
    (0...@height).all? { |r| (0...r).all? { |c| self[r, c] == self[c, r] } }
  end

  def to_s
    cell_width = @data.map { it.to_s.size }.max || 1
    (0...@height).map { |r| row(r).map { it.to_s.rjust(cell_width) }.join(" ") }.join("\n")
  end
end

def spiral(h, w)
  m = Matrix.filled(h, w, 0)
  top = 0
  left = 0
  bottom = h - 1
  right = w - 1
  n = 1
  while top <= bottom && left <= right
    left.upto(right) { |c| m[top, c] = n; n += 1 }
    top += 1
    top.upto(bottom) { |r| m[r, right] = n; n += 1 }
    right -= 1
    if top <= bottom
      right.downto(left) { |c| m[bottom, c] = n; n += 1 }
      bottom -= 1
    end
    if left <= right
      bottom.downto(top) { |r| m[r, left] = n; n += 1 }
      left += 1
    end
  end
  m
end

def spiral_order(m)
  out = []
  seen = Set.new
  dirs = [[0, 1], [1, 0], [0, -1], [-1, 0]]
  r = 0
  c = 0
  d = 0
  while out.size < m.height * m.width
    out << m[r, c]
    seen << [r, c]
    dr, dc = dirs[d]
    nr = r + dr
    nc = c + dc
    if nr < 0 || nr >= m.height || nc < 0 || nc >= m.width || seen.include?([nr, nc])
      d = (d + 1) % 4
      dr, dc = dirs[d]
      nr = r + dr
      nc = c + dc
    end
    r = nr
    c = nc
  end
  out
end

[[4, 4], [3, 5], [1, 4], [5, 2]].each do |h, w|
  m = spiral(h, w)
  puts "spiral #{h}x#{w}:"
  puts m
  order = spiral_order(m)
  puts "reads back in order: #{order == (1..(h * w)).to_a}"
  puts "rotated:"
  puts m.rotate
end

sym = Matrix.from_rows([[1, 7, 3], [7, 4, 5], [3, 5, 0]])
puts "symmetric: #{sym.symmetric?} / #{spiral(3, 3).symmetric?}"
t = spiral(2, 3).transpose
puts "transpose of 2x3 spiral is #{t.height}x#{t.width}:"
puts t
puts "trace: #{(0...3).sum { |i| sym[i, i] }}"
