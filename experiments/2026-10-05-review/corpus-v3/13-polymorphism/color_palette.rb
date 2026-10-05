class BadColor < StandardError
  attr_reader :text
  def initialize(message, text)
    super(message)
    @text = text
  end
end

def clamp255(x) = x < 0 ? 0 : (x > 255 ? 255 : x)

class Color
  attr_reader :r, :g, :b

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end

  def self.rgb(r, g, b) = Color.new(clamp255((r * 1.0).round), clamp255((g * 1.0).round), clamp255((b * 1.0).round))

  def self.hex(s)
    m = s.downcase.match(/\A#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/)
    raise BadColor.new("bad color #{s}", s) unless m
    Color.new(m[1].hex, m[2].hex, m[3].hex)
  end

  def +(o) = Color.rgb(@r + o.r, @g + o.g, @b + o.b)
  def -(o) = Color.rgb(@r - o.r, @g - o.g, @b - o.b)
  def *(k)
    case k
    in Color then Color.rgb(@r * k.r / 255.0, @g * k.g / 255.0, @b * k.b / 255.0)
    in Integer | Float then Color.rgb(@r * k, @g * k, @b * k)
    end
  end

  def mix(o, t) = Color.rgb(@r + (o.r - @r) * t, @g + (o.g - @g) * t, @b + (o.b - @b) * t)

  def self.channel(c)
    s = c / 255.0
    s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
  end

  def luminance = 0.2126 * Color.channel(@r) + 0.7152 * Color.channel(@g) + 0.0722 * Color.channel(@b)

  def contrast(o)
    l1 = luminance
    l2 = o.luminance
    hi = l1 > l2 ? l1 : l2
    lo = l1 > l2 ? l2 : l1
    (hi + 0.05) / (lo + 0.05)
  end

  def hsl
    r = @r / 255.0
    g = @g / 255.0
    b = @b / 255.0
    mx = [r, g, b].max
    mn = [r, g, b].min
    l = (mx + mn) / 2
    return [0.0, 0.0, l] if mx == mn
    d = mx - mn
    s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
    h = if mx == r
      (g - b) / d + (g < b ? 6 : 0)
    elsif mx == g
      (b - r) / d + 2
    else
      (r - g) / d + 4
    end
    [h * 60, s, l]
  end

  def hue = hsl[0]

  def to_s = format("#%02x%02x%02x", @r, @g, @b)
end

def gradient(stops, steps)
  out = []
  steps.times do |i|
    t = i / (steps - 1.0) * (stops.size - 1)
    seg = [t.floor, stops.size - 2].min
    out << stops[seg].mix(stops[seg + 1], t - seg)
  end
  out
end

palette_src = ["#1e90ff", "#ff6347", "#2e8b57", "#ffd700", "#8a2be2", "zzz", "#ffffff", "#000000", "#808080", "#f0f"]
palette = []
palette_src.each do |s|
  begin
    palette << Color.hex(s)
  rescue BadColor => e
    puts "skip: #{e.message}"
  end
end

puts "== palette =="
palette.each do |c|
  h, s, l = c.hsl
  puts format("%s  h=%5.1f s=%.2f l=%.2f  lum=%.3f", c, h, s, l, c.luminance)
end

puts "== by hue (chromatic only) =="
chromatic = palette.select { |c| c.r != c.g || c.g != c.b }
puts chromatic.sort_by(&:hue).join(" ")
puts "darkest: #{palette.min_by(&:luminance)}, lightest: #{palette.max_by(&:luminance)}"

puts "== arithmetic =="
blue = Color.hex("#1e90ff")
red = Color.hex("#ff6347")
puts "blue + red = #{blue + red}"
puts "red - blue = #{red - blue}"
puts "blue * 0.5 = #{blue * 0.5}"
puts "blue * 2 = #{blue * 2}"
puts "red * blue (multiply) = #{red * blue}"
puts "mix 25% = #{blue.mix(red, 0.25)}"

puts "== gradient =="
stops = [Color.hex("#000080"), Color.hex("#00ffff"), Color.hex("#ffff00")]
puts gradient(stops, 9).join(" ")

puts "== text contrast =="
white = Color.hex("#ffffff")
black = Color.hex("#000000")
chromatic.each do |bg|
  cw = bg.contrast(white)
  cb = bg.contrast(black)
  best = cw >= cb ? "white" : "black"
  ratio = cw >= cb ? cw : cb
  grade = ratio >= 7 ? "AAA" : (ratio >= 4.5 ? "AA" : "fail")
  puts format("%s  vs white %5.2f  vs black %5.2f  -> %s text (%s)", bg, cw, cb, best, grade)
end
