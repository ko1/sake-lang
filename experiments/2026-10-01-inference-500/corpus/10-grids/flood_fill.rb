require "set"

class Region
  attr_reader :color, :size, :top, :left

  def initialize(color, size, top, left)
    @color = color
    @size = size
    @top = top
    @left = left
  end

  def to_s = "#{@color}x#{@size}@(#{@top},#{@left})"
end

class Canvas
  attr_reader :pixels, :height, :width

  def initialize(pixels, height, width)
    @pixels = pixels
    @height = height
    @width = width
  end

  def self.parse(rows) = new(rows.map(&:chars), rows.size, rows[0].size)

  def inside?(r, c) = r >= 0 && r < @height && c >= 0 && c < @width

  def neighbours(r, c)
    [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]].select { |nr, nc| inside?(nr, nc) }
  end

  # paint bucket: returns how many pixels changed
  def fill(r, c, color)
    target = @pixels[r][c]
    return 0 if target == color
    stack = [[r, c]]
    changed = 0
    until stack.empty?
      cr, cc = stack.pop
      next if @pixels[cr][cc] != target
      @pixels[cr][cc] = color
      changed += 1
      stack.concat(neighbours(cr, cc))
    end
    changed
  end

  def regions
    seen = Set.new
    found = []
    @height.times do |r|
      @width.times do |c|
        next if seen.include?([r, c])
        color = @pixels[r][c]
        size = 0
        queue = [[r, c]]
        seen << [r, c]
        until queue.empty?
          cr, cc = queue.shift
          size += 1
          neighbours(cr, cc).each do |n|
            nr, nc = n
            if @pixels[nr][nc] == color && !seen.include?(n)
              seen << n
              queue << n
            end
          end
        end
        found << Region.new(color, size, r, c)
      end
    end
    found
  end

  def to_s = @pixels.map(&:join).join("\n")
end

def summarize(cv)
  regs = cv.regions
  by_color = regs.group_by(&:color)
  parts = by_color.keys.sort.map { |color| "#{color}:#{by_color[color].size}" }
  biggest = regs.max_by(&:size)
  puts "  regions #{regs.size} (#{parts.join(" ")}); largest #{biggest}"
  singles = regs.select { it.size == 1 }
  puts "  single-pixel regions: #{singles.join(", ")}" unless singles.empty?
end

canvas = Canvas.parse([
  "....##....",
  "...#..#...",
  "..#....#..",
  "..#....#..",
  "...#..#...",
  "....##....",
  "oo......oo",
  "o.o....o.o",
])

puts canvas
summarize(canvas)
ops = [[2, 4, "~"], [0, 0, "-"], [7, 1, "*"], [0, 4, "@"], [2, 4, "~"], [6, 0, "-"]]
ops.each do |r, c, color|
  n = canvas.fill(r, c, color)
  puts "fill (#{r},#{c}) with #{color}: #{n} pixels"
  summarize(canvas)
end
puts canvas
counts = Hash.new(0)
canvas.pixels.each { |row| row.each { |ch| counts[ch] += 1 } }
puts counts.sort_by { |ch, n| [-n, ch] }.map { |ch, n| "#{ch}=#{n}" }.join(" ")
