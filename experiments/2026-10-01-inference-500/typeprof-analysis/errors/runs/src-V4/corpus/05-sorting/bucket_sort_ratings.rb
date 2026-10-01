# Bucket sort of normalized product ratings in [0, 1), then nearest-neighbour
# lookups with binary search and a rank-to-percentile table.

class Rating
  attr_reader :product, :stars, :votes

  def initialize(product, stars, votes)
    @product = product
    @stars = stars
    @votes = votes
  end

  # Wilson-like lower bound, squeezed into [0, 1).
  def score
    mean = (stars - 1.0) / 4.0
    z = 1.5
    denom = 1.0 + z * z / votes
    centre = mean + z * z / (2.0 * votes)
    margin = z * Math.sqrt(mean * (1.0 - mean) / votes + z * z / (4.0 * votes * votes))
    v = (centre - margin) / denom
    v.clamp(0.0, 0.9999)
  end
end

def insertion_sort!(a)
  (1...a.size).each do |i|
    x = a[i]
    j = i - 1
    while j >= 0 && yield(a[j]) > yield(x)
      a[j + 1] = a[j]
      j -= 1
    end
    a[j + 1] = x
  end
  a
end

def bucket_sort(items, nbuckets, &key)
  buckets = Array.new(nbuckets) { [] }
  items.each do |x|
    buckets[(key.call(x) * nbuckets).floor] << x
  end
  sizes = buckets.map(&:size)
  out = buckets.flat_map { |b| insertion_sort!(b, &key) }
  [out, sizes]
end

def nearest(sorted, target)
  return nil if sorted.empty?
  lo = 0
  hi = sorted.size - 1
  while lo < hi
    mid = (lo + hi) / 2
    if sorted[mid] < target
      lo = mid + 1
    else
      hi = mid
    end
  end
  return sorted[lo] if lo == 0
  before = sorted[lo - 1]
  after = sorted[lo]
  target - before <= after - target ? before : after
end

ratings = [
  Rating.new("lamp", 4.6, 210), Rating.new("desk", 4.1, 35), Rating.new("chair", 3.2, 480),
  Rating.new("rug", 4.9, 8), Rating.new("shelf", 2.4, 60), Rating.new("sofa", 4.4, 1200),
  Rating.new("stool", 3.9, 15), Rating.new("bed", 4.7, 950), Rating.new("vase", 1.8, 22),
  Rating.new("clock", 3.6, 140), Rating.new("mirror", 4.0, 3), Rating.new("bench", 4.2, 77)
]

sorted, sizes = bucket_sort(ratings, 5, &:score)
puts "bucket sizes: #{sizes}"
sorted.reverse_each do |r|
  puts format("  %-7s %.1f stars %5d votes  score=%.4f", r.product, r.stars, r.votes, r.score)
end

scores = sorted.map(&:score)
puts "bucket order agrees with sort: #{scores == ratings.map(&:score).sort}"

[0.0, 0.5, 0.62, 0.95].each do |t|
  v = nearest(scores, t)
  owner = sorted.find { |r| r.score == v }
  puts format("nearest to %.2f: %s (%.4f)", t, owner.product, v) if owner
end
p nearest([], 0.5)

n = sorted.size
sorted.each_with_index do |r, i|
  pct = 100.0 * (i + 1) / n
  puts "#{r.product} is top #{(100.0 - pct + 100.0 / n).round(1)}%" if pct > 75.0
end
