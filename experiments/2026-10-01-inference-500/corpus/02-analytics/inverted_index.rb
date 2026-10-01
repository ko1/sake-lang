require "set"

class Doc
  attr_reader :id, :title, :body

  def initialize(id, title, body)
    @id = id
    @title = title
    @body = body
  end
end

class QueryError < StandardError
  attr_reader :query

  def initialize(message, query)
    super(message)
    @query = query
  end
end

def documents
  [
    Doc.new(1, "Intro to Ruby", "Ruby is a dynamic language. Ruby code is concise and readable."),
    Doc.new(2, "Static types", "A static type checker reads code before it runs and reports type errors."),
    Doc.new(3, "Type inference", "Type inference finds the type of each expression without annotations."),
    Doc.new(4, "Hash tables", "A hash table maps keys to values. Ruby hashes keep insertion order."),
    Doc.new(5, "Search engines", "An inverted index maps each word to the documents that contain the word.")
  ]
end

def tokens(text) = text.downcase.split(/[^a-z]+/).reject(&:empty?)

def build_index(docs)
  index = {}
  docs.each do |d|
    tokens(d.body).each_with_index do |w, pos|
      index[w] ||= {}
      postings = index[w]
      postings[d.id] ||= []
      postings[d.id] << pos
    end
  end
  index
end

def doc_ids(index, word)
  postings = index[word]
  postings ? postings.keys.to_set : Set[]
end

def all_ids(docs) = docs.map(&:id).to_set

def search(index, docs, query)
  words = query.downcase.split(" ")
  raise QueryError.new("empty query", query) if words.empty?
  result = nil
  mode = :and
  words.each do |w|
    if w == "or"
      mode = :or
    elsif w == "not"
      mode = :not
    else
      ids = doc_ids(index, w)
      if result.nil?
        result = mode == :not ? all_ids(docs) - ids : ids
      elsif mode == :or
        result |= ids
      elsif mode == :not
        result -= ids
      else
        result &= ids
      end
      mode = :and
    end
  end
  raise QueryError.new("query has no terms", query) if result.nil?
  result.to_a.sort
end

def phrase_at?(index, words, id, start)
  words.each_with_index.all? do |w, offset|
    positions = index[w]&.[](id)
    positions && positions.include?(start + offset)
  end
end

def phrase_search(index, phrase)
  words = phrase.downcase.split(" ")
  first = index[words[0]]
  return [] unless first
  hits = []
  first.each do |id, positions|
    hits << id if positions.any? { |start| phrase_at?(index, words, id, start) }
  end
  hits.sort
end

def titles(docs, ids)
  ids.map do |id|
    d = docs.find { |x| x.id == id }
    d ? d.title : "?"
  end
end

docs = documents
index = build_index(docs)
puts "vocabulary: #{index.size} words"

common = index.keys.sort_by { |w| -index[w].size }
top = common.select { |w| index[w].size >= 2 }
top.sort.each do |w|
  postings = index[w]
  desc = postings.keys.sort.map { |id| "#{id}:#{postings[id].join(",")}" }
  puts "  #{w} -> #{desc.join(" ")}"
end

queries = ["ruby", "type code", "ruby or type", "maps not ruby", "not ruby", "zebra", "", "or"]
queries.each do |q|
  begin
    ids = search(index, docs, q)
    puts "[#{q}] => #{ids} #{titles(docs, ids).join(" | ")}"
  rescue QueryError => e
    puts "[#{q}] error: #{e.message} (#{e.query.inspect})"
  end
end

["type inference", "the word", "ruby code", "static code"].each do |ph|
  puts "\"#{ph}\" => #{phrase_search(index, ph)}"
end
