class Obs
  attr_reader :site, :temp, :yield_kg

  def initialize(site, temp, yield_kg)
    @site = site
    @temp = temp
    @yield_kg = yield_kg
  end
end

class Fit
  attr_reader :slope, :intercept, :r2, :se_slope, :n

  def initialize(slope, intercept, r2, se_slope, n)
    @slope = slope
    @intercept = intercept
    @r2 = r2
    @se_slope = se_slope
    @n = n
  end

  def predict(x) = @intercept + @slope * x
  def to_s = format("y = %.4f + %.4f x  (r^2=%.4f, se=%.4f, n=%d)", @intercept, @slope, @r2, @se_slope, @n)
end

def least_squares(xs, ys)
  n = xs.size
  return nil if n < 3
  mx = xs.sum / n
  my = ys.sum / n
  sxx = 0.0
  sxy = 0.0
  syy = 0.0
  xs.zip(ys).each do |x, y|
    sxx += (x - mx) ** 2
    sxy += (x - mx) * (y - my)
    syy += (y - my) ** 2
  end
  return nil if sxx == 0.0
  slope = sxy / sxx
  intercept = my - slope * mx
  sse = xs.zip(ys).map { |x, y| (y - intercept - slope * x) ** 2 }.sum
  r2 = 1.0 - sse / syy
  se = Math.sqrt(sse / (n - 2) / sxx)
  Fit.new(slope, intercept, r2, se, n)
end

def weighted_fit(xs, ys, ws)
  sw = ws.sum
  mx = xs.zip(ws).map { |x, w| x * w }.sum / sw
  my = ys.zip(ws).map { |y, w| y * w }.sum / sw
  num = 0.0
  den = 0.0
  xs.each_with_index do |x, i|
    num += ws[i] * (x - mx) * (ys[i] - my)
    den += ws[i] * (x - mx) ** 2
  end
  slope = num / den
  [slope, my - slope * mx]
end

data = [
  Obs.new("north", 14.2, 310.0), Obs.new("north", 15.8, 342.5), Obs.new("north", 17.1, 360.2),
  Obs.new("north", 18.4, 391.0), Obs.new("north", 19.9, 405.8), Obs.new("north", 21.3, 441.1),
  Obs.new("south", 22.5, 512.4), Obs.new("south", 24.1, 530.0), Obs.new("south", 25.0, 548.9),
  Obs.new("south", 26.7, 551.3), Obs.new("south", 28.2, 590.6), Obs.new("south", 29.0, 588.1),
  Obs.new("south", 30.4, 499.7),
  Obs.new("valley", 19.0, 400.0), Obs.new("valley", 19.0, 410.0),
  Obs.new("coast", 18.0, 380.0), Obs.new("coast", 18.0, 375.0), Obs.new("coast", 18.0, 390.0)
]

groups = data.group_by(&:site)
fits = {}
groups.each do |site, obs|
  xs = obs.map(&:temp)
  ys = obs.map(&:yield_kg)
  f = least_squares(xs, ys)
  if f
    fits[site] = f
    puts "#{site}: #{f}"
    worst = obs.max_by { |o| (o.yield_kg - f.predict(o.temp)).abs }
    puts format("  largest residual at %.1f C: %+.2f", worst.temp, worst.yield_kg - f.predict(worst.temp))
  else
    puts "#{site}: not enough spread to fit (#{obs.size} points)"
  end
end

pooled = least_squares(data.map(&:temp), data.map(&:yield_kg))
puts "pooled: #{pooled}" if pooled

# down-weight the suspicious last south reading and refit
south = groups["south"]
if south
  ws = south.map { |o| o.temp > 30.0 ? 0.1 : 1.0 }
  slope, intercept = weighted_fit(south.map(&:temp), south.map(&:yield_kg), ws)
  puts format("south weighted: y = %.4f + %.4f x", intercept, slope)
end

puts "predictions at 23.0 C:"
fits.sort_by { |site, f| -f.predict(23.0) }.each do |site, f|
  puts format("  %-6s %8.2f", site, f.predict(23.0))
end

best = fits.max_by { |site, f| f.r2 }
if best
  site, f = best
  puts "best linear fit: #{site}"
end
missing = ["north", "south", "valley", "coast", "east"].reject { |s| fits.key?(s) }
puts "no fit for: #{missing.join(", ")}"
