require "set"

class Post
  attr_reader :title, :slug, :words_dropped

  def initialize(title, slug, words_dropped)
    @title = title
    @slug = slug
    @words_dropped = words_dropped
  end
end

def transliterations
  { "á" => "a", "à" => "a", "ä" => "ae", "â" => "a", "é" => "e", "è" => "e", "ê" => "e",
    "í" => "i", "ó" => "o", "ö" => "oe", "ô" => "o", "ú" => "u", "û" => "u", "ü" => "ue", "ñ" => "n",
    "ç" => "c", "ß" => "ss", "ø" => "o", "å" => "a", "&" => " and ", "@" => " at ", "+" => " plus " }
end

def drop_words = Set["a", "an", "the", "of", "in", "on", "to", "for"]

def transliterate(s)
  table = transliterations
  s.downcase.each_char.map { |c| table.fetch(c, c) }.join
end

def words_of(s)
  transliterate(s).gsub(/[^a-z0-9]+/, " ").strip.split(" ")
end

def shorten(words, max_len)
  kept = []
  len = 0
  words.each do |w|
    extra = kept.empty? ? w.size : w.size + 1
    break if len + extra > max_len
    kept << w
    len += extra
  end
  kept = [words.first[0...max_len]] if kept.empty? && words.first
  kept
end

def slugify(title, max_len)
  all = words_of(title)
  meaningful = all.reject { |w| drop_words.include?(w) }
  meaningful = all if meaningful.empty?
  kept = shorten(meaningful, max_len)
  [kept.join("-"), all.size - kept.size]
end

def unique_slug(base, taken)
  return base unless taken.include?(base)
  n = 2
  n += 1 while taken.include?("#{base}-#{n}")
  "#{base}-#{n}"
end

def publish(titles, max_len)
  taken = Set[]
  titles.map do |t|
    base, dropped = slugify(t, max_len)
    base = "untitled" if base.empty?
    slug = unique_slug(base, taken)
    taken.add(slug)
    Post.new(t, slug, dropped)
  end
end

def titles
  [
    "Hello, World!",
    "The Quick Brown Fox & the Lazy Dog",
    "Crème Brûlée: A Café Classic",
    "Über-fast Straße Rendering in Ruby 4.0",
    "hello world",
    "Hello  --  World???",
    "Ten Tips for Writing Better Commit Messages (and Why They Matter to Your Team)",
    "!!!",
    "C++ @ Scale",
    "Año Nuevo en Málaga",
    "The The"
  ]
end

posts = publish(titles, 32)
width = posts.map { |p| p.slug.size }.max
posts.each do |p|
  note = p.words_dropped > 0 ? " (-#{p.words_dropped} words)" : ""
  puts "#{p.slug.ljust(width)}  <- #{p.title}#{note}"
end
collisions = posts.count { |p| p.slug.match?(/-\d+\z/) }
puts "#{posts.size} posts, #{collisions} renamed to avoid collisions"
lengths = posts.map { |p| p.slug.size }
puts "slug length: min #{lengths.min}, max #{lengths.max}, mean #{format("%.1f", lengths.sum.to_f / lengths.size)}"
