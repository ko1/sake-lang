# Recommend articles by tag overlap; ranking uses a Match type that is Comparable.

class Article
  attr_reader :id, :title, :tags

  def initialize(id, title, tags)
    @id = id
    @title = title
    @tags = tags
  end
end

class Match
  include Comparable
  attr_reader :article, :score, :shared

  def initialize(article, score, shared)
    @article = article
    @score = score
    @shared = shared
  end

  # higher score first, then lower id
  def <=>(other)
    c = other.score <=> @score
    c == 0 ? @article.id <=> other.article.id : c
  end

  def to_s = format("#%d %-24s %.2f [%s]", @article.id, @article.title, @score, @shared.sort.join(","))
end

def catalog
  rows = [
    [1, "Intro to Ruby", "ruby beginner programming"],
    [2, "Ruby Performance", "ruby performance vm"],
    [3, "Garbage Collectors", "vm gc memory performance"],
    [4, "Writing a Parser", "parsing compilers programming"],
    [5, "Type Inference 101", "types compilers inference"],
    [6, "Gradual Typing in Ruby", "ruby types inference"],
    [7, "Memory Profiling", "memory performance tools"],
    [8, "Your First Program", "beginner programming"],
    [9, "Static Analysis Tools", "tools types compilers"]
  ]
  rows.map { |id, title, tags| Article.new(id, title, tags.split(" ").to_set) }
end

def similarity(a, b)
  inter = (a.tags & b.tags).size
  inter == 0 ? 0.0 : inter / (a.tags | b.tags).size.to_f
end

def recommend(articles, target, n)
  matches = articles.filter_map do |a|
    next nil if a.id == target.id
    s = similarity(target, a)
    s > 0 ? Match.new(a, s, target.tags & a.tags) : nil
  end
  matches.sort.take(n)
end

def by_interest(articles, interests, read)
  pool = articles.reject { |a| read.include?(a.id) }
  scored = pool.map { |a| [a, (a.tags & interests).size] }
  scored.select { |a, n| n > 0 }.sort_by { |a, n| [-n, a.id] }.map(&:first)
end

articles = catalog
[1, 5, 7].each do |id|
  target = articles.find { |a| a.id == id }
  puts "Because you read \"#{target.title}\":"
  recommend(articles, target, 3).each { |m| puts "  #{m}" }
end

all_tags = articles.reduce(Set[]) { |acc, a| acc.merge(a.tags) }
puts "tags (#{all_tags.size}): #{all_tags.sort.join(" ")}"

pair_counts = Hash.new(0)
articles.each do |a|
  a.tags.sort.combination(2).each { |x, y| pair_counts[[x, y]] += 1 }
end
common_pairs = pair_counts.select { |k, n| n > 1 }.sort_by { |k, n| k }
puts "tags that go together:"
common_pairs.each { |(x, y), n| puts "  #{x} + #{y}: #{n}" }

tag_index = {}
articles.each do |a|
  a.tags.each { |t| (tag_index[t] ||= Set[]) << a.id }
end
puts "articles with both 'types' and 'ruby': #{(tag_index["types"] & tag_index["ruby"]).sort.join(",")}"
puts "'performance' but not 'ruby': #{(tag_index["performance"] - tag_index["ruby"]).sort.join(",")}"
lonely = tag_index.select { |t, ids| ids.size == 1 }.keys.sort
puts "single-use tags: #{lonely.join(" ")}"
p tag_index["haskell"]

puts "For a reader of 2 and 6 interested in types, memory:"
read = Set[2, 6]
interests = Set["types", "memory"]
by_interest(articles, interests, read).each { |a| puts "  #{a.id} #{a.title}" }
