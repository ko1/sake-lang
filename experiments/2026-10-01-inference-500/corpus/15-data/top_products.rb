class Product
  attr_reader :sku, :title, :category

  def initialize(sku, title, category)
    @sku = sku
    @title = title
    @category = category
  end
end

class Review
  attr_reader :sku, :stars

  def initialize(sku, stars)
    @sku = sku
    @stars = stars
  end
end

class Score
  include Comparable
  attr_reader :rating, :votes, :title

  def initialize(rating, votes, title)
    @rating = rating
    @votes = votes
    @title = title
  end

  def <=>(other)
    c = other.rating <=> rating
    c = other.votes <=> votes if c == 0
    c = title <=> other.title if c == 0
    c
  end
end

def catalog
  [
    Product.new("b1", "Dune", :books), Product.new("b2", "Neuromancer", :books),
    Product.new("b3", "Hyperion", :books), Product.new("b4", "Solaris", :books),
    Product.new("k1", "Chef knife", :kitchen), Product.new("k2", "Cast iron pan", :kitchen),
    Product.new("k3", "Peeler", :kitchen), Product.new("g1", "Trail tent", :garden),
    Product.new("t1", "Desk lamp", :tools), Product.new("t2", "Cordless drill", :tools)
  ]
end

def reviews
  stars = {
    "b1" => [5, 5, 4, 5, 4, 5], "b2" => [4, 3, 5], "b3" => [5],
    "b4" => [4, 4, 3, 5, 4], "k1" => [5, 4, 5, 5], "k2" => [5, 5, 5, 4, 5, 5, 4],
    "k3" => [2, 3], "t1" => [3, 4, 4], "t2" => [5, 4], "x9" => [1, 1]
  }
  stars.flat_map { |sku, list| list.map { |s| Review.new(sku, s) } }
end

def bayesian(sum, n, prior_mean, prior_weight) = (sum + prior_mean * prior_weight) / (n + prior_weight)

products = catalog
by_sku = products.to_h { |p| [p.sku, p] }
all_reviews = reviews
global_mean = all_reviews.sum(&:stars) * 1.0 / all_reviews.size
grouped = all_reviews.group_by(&:sku)

orphans = grouped.keys.reject { |sku| by_sku.key?(sku) }
puts format("%d reviews, global mean %.2f", all_reviews.size, global_mean)
puts "reviews for unknown products: #{orphans.join(", ")}" unless orphans.empty?
puts

scored = products.map do |p|
  rs = grouped[p.sku] || []
  total = rs.sum(&:stars)
  rating = bayesian(total, rs.size, global_mean, 3)
  [p, Score.new(rating.round(3), rs.size, p.title)]
end

by_cat = scored.group_by { |p, s| p.category }
by_cat.keys.sort_by(&:to_s).each do |cat|
  entries = by_cat.fetch(cat)
  rated = entries.select { |p, s| s.votes > 0 }
  puts "#{cat.upcase} (#{entries.size} products, #{rated.size} rated)"
  if rated.size < 2
    puts "  not enough data"
    next
  end
  top = rated.sort_by { |p, s| s }.first(3)
  top.each_with_index do |(p, s), i|
    puts format("  %d. %-15s %.2f  (%d votes)", i + 1, p.title, s.rating, s.votes)
  end
end

puts
unrated = scored.select { |p, s| s.votes == 0 }
puts "No reviews yet: #{unrated.map { |p, s| p.title }.join(", ")}"
best_pair = scored.min_by { |p, s| s }
if best_pair
  bp, bs = best_pair
  puts format("Best overall: %s (%.2f)", bp.title, bs.rating)
end
