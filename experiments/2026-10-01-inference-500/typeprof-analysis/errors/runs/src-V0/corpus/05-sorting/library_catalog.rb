# Library catalog lookups: books kept sorted by ISBN for binary search (with a
# retry after normalizing the query), an author/title ordering for shelf
# listings, and a sorted word index for title searches. Queries are Records.

class Book
  include Comparable
  attr_reader :isbn, :title, :author, :year, :copies

  def initialize(isbn, title, author, year, copies)
    @isbn = isbn
    @title = title
    @author = author
    @year = year
    @copies = copies
  end

  # shelf order: author surname, then title
  def <=>(other)
    c = surname <=> other.surname
    c == 0 ? title <=> other.title : c
  end

  def surname = author.split(" ").last
  def to_s = "#{title} (#{author}, #{year})"
end

class NotFound < StandardError
  attr_reader :query

  def initialize(message, query)
    super(message)
    @query = query
  end
end

def find_isbn(by_isbn, isbn)
  lo = 0
  hi = by_isbn.size - 1
  while lo <= hi
    mid = (lo + hi) / 2
    k = by_isbn[mid].isbn
    return by_isbn[mid] if k == isbn
    if k < isbn
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  raise NotFound.new("no book with ISBN #{isbn}", isbn)
end

def lookup(by_isbn, raw)
  query = raw
  begin
    find_isbn(by_isbn, query)
  rescue NotFound
    cleaned = query.strip.delete("- ")
    if cleaned != query
      query = cleaned
      retry
    end
    raise
  end
end

def build_index(books)
  pairs = []
  books.each do |b|
    b.title.downcase.split(/[^a-z]+/).uniq.each do |w|
      pairs << [w, b.isbn] if w.size > 2
    end
  end
  index = {}
  pairs.map(&:first).uniq.sort.each { |w| index[w] = [] }
  pairs.each { |w, isbn| index[w] << isbn }
  index
end

def words_with_prefix(words, prefix)
  lo = 0
  hi = words.size
  while lo < hi
    mid = (lo + hi) / 2
    if words[mid] < prefix
      lo = mid + 1
    else
      hi = mid
    end
  end
  words.drop(lo).take_while { |w| w.start_with?(prefix) }
end

def run_query(q, by_isbn, index, words)
  case q
  in {isbn:}
    b = lookup(by_isbn, isbn)
    "#{b} - #{b.copies} on shelf"
  in {word:}
    hits = words_with_prefix(words, word).flat_map { |w| index[w] }
    titles = hits.uniq.map { |i| find_isbn(by_isbn, i).title }
    titles.empty? ? "nothing matches #{word}*" : titles.sort.join("; ")
  in {before:}
    old = by_isbn.select { |b| b.year < before }
    "#{old.size} books before #{before}"
  end
end

books = [
  Book.new("9780262033848", "Introduction to Algorithms", "Thomas Cormen", 2009, 3),
  Book.new("9780201896831", "The Art of Computer Programming", "Donald Knuth", 1997, 1),
  Book.new("9780321573513", "Algorithms", "Robert Sedgewick", 2011, 2),
  Book.new("9781593279509", "Eloquent JavaScript", "Marijn Haverbeke", 2018, 4),
  Book.new("9780131103627", "The C Programming Language", "Brian Kernighan", 1988, 2),
  Book.new("9780134685991", "Effective Java", "Joshua Bloch", 2017, 1),
  Book.new("9781680500882", "Programming Elixir", "Dave Thomas", 2016, 0),
  Book.new("9780596516178", "The Ruby Programming Language", "David Flanagan", 2008, 2),
  Book.new("9780201633610", "Design Patterns", "Erich Gamma", 1994, 1)
]

by_isbn = books.sort_by(&:isbn)
index = build_index(books)
words = index.keys
puts "#{books.size} books, #{words.size} indexed words"
puts "shelf order:"
books.sort.each { |b| puts "  #{b.surname}: #{b.title}" }

queries = [{isbn: "9780321573513"}, {isbn: "978-0-13-468599-1"}, {isbn: "9999999999999"},
           {word: "prog"}, {word: "algo"}, {word: "haskell"}, {before: 2000}]
queries.each do |q|
  puts "#{q} => #{run_query(q, by_isbn, index, words)}"
rescue NotFound => e
  puts "#{q} => not found (#{e.query})"
end
out = books.select { |b| b.copies == 0 }
puts "checked out everywhere: #{out.join(", ")}"
