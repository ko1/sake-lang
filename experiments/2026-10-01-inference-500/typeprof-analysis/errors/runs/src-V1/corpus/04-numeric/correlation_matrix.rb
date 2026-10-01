DATASET = {
  "hours" => [2.0, 4.5, 3.0, 6.0, 1.0, 5.5, 7.0, 3.5, 4.0, nil, 8.0, 2.5],
  "sleep" => [8.0, 7.0, 7.5, 6.0, 9.0, 6.5, 5.5, 7.0, nil, 8.5, 5.0, 8.0],
  "score" => [55.0, 71.0, 62.0, 85.0, 48.0, 80.0, 88.0, 66.0, 70.0, 52.0, 91.0, 58.0],
  "coffee" => [1.0, 2.0, 1.0, 3.0, 0.0, 3.0, 4.0, 2.0, 2.0, 0.0, 5.0, 1.0],
  "commute" => [30.0, 25.0, 40.0, 35.0, 20.0, 45.0, 30.0, 25.0, 50.0, 35.0, 40.0, 30.0]
}

def pairwise(xs, ys)
  pairs = xs.zip(ys).select { |x, y| x && y }
  [pairs.map(&:first), pairs.map(&:last)]
end

def pearson(xs, ys)
  n = xs.size
  return nil if n < 3
  mx = xs.sum / n
  my = ys.sum / n
  sxy = 0.0
  sxx = 0.0
  syy = 0.0
  xs.each_with_index do |x, i|
    dx = x - mx
    dy = ys[i] - my
    sxy += dx * dy
    sxx += dx * dx
    syy += dy * dy
  end
  return nil if sxx == 0.0 || syy == 0.0
  sxy / Math.sqrt(sxx * syy)
end

# average ranks, ties share the mean rank
def ranks(xs)
  order = (0...xs.size).sort_by { |i| xs[i] }
  result = Array.new(xs.size, 0.0)
  i = 0
  while i < order.size
    j = i
    j += 1 while j + 1 < order.size && xs[order[j + 1]] == xs[order[i]]
    avg = (i + j) / 2.0 + 1.0
    (i..j).each { |k| result[order[k]] = avg }
    i = j + 1
  end
  result
end

def spearman(xs, ys) = pearson(ranks(xs), ranks(ys))

def fmt_r(r) = r.nil? ? "     n/a" : format("%8.3f", r)

data = DATASET
names = data.keys
puts "missing values: " + names.map { |n| "#{n}=#{data[n].count(&:nil?)}" }.join(" ")

pearson_m = {}
spearman_m = {}
names.each do |a|
  names.each do |b|
    xs, ys = pairwise(data[a], data[b])
    pearson_m[[a, b]] = pearson(xs, ys)
    spearman_m[[a, b]] = spearman(xs, ys)
  end
end

[["Pearson", pearson_m], ["Spearman", spearman_m]].each do |title, m|
  puts "#{title}:"
  puts format("%-8s", "") + names.map { |n| format("%8s", n) }.join
  names.each do |a|
    puts format("%-8s", a) + names.map { |b| fmt_r(m[[a, b]]) }.join
  end
end

strongest = nil
names.each_with_index do |a, i|
  names.each_with_index do |b, j|
    next unless i < j
    r = pearson_m[[a, b]]
    next if r.nil?
    strongest = [a, b, r] if strongest.nil? || r.abs > strongest[2].abs
  end
end
if strongest
  a, b, r = strongest
  puts format("strongest pair: %s ~ %s (r=%.3f)", a, b, r)
end

# partial correlation of hours and score controlling for coffee
r_hs = pearson_m[["hours", "score"]]
r_hc = pearson_m[["hours", "coffee"]]
r_sc = pearson_m[["score", "coffee"]]
if r_hs && r_hc && r_sc
  partial = (r_hs - r_hc * r_sc) / Math.sqrt((1.0 - r_hc ** 2) * (1.0 - r_sc ** 2))
  puts format("partial r(hours, score | coffee) = %.3f", partial)
end

# Fisher z confidence interval for hours ~ score
hx, _sy = pairwise(data["hours"], data["score"])
n = hx.size
z = 0.5 * Math.log((1.0 + r_hs) / (1.0 - r_hs))
se = 1.0 / Math.sqrt(n - 3)
lo = z - 1.96 * se
hi = z + 1.96 * se
back_lo = (Math.exp(2.0 * lo) - 1.0) / (Math.exp(2.0 * lo) + 1.0)
back_hi = (Math.exp(2.0 * hi) - 1.0) / (Math.exp(2.0 * hi) + 1.0)
puts format("hours~score n=%d r=%.3f 95%% CI [%.3f, %.3f]", n, r_hs, back_lo, back_hi)

const = [3.0, 3.0, 3.0, 3.0]
p pearson(const, [1.0, 2.0, 3.0, 4.0])
puts "ranks with ties: #{ranks([10.0, 20.0, 10.0, 30.0, 20.0, 10.0])}"
weak = pearson_m.select { |key, r| r && r.abs < 0.2 }
puts "weak pairs: #{weak.size}"
