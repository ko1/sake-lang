class JsonError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class Json
  def self.parse(text)
    j = new(text)
    v = j.value
    j.skip_ws
    raise JsonError.new("trailing characters", j.pos) if j.pos < text.size
    v
  end

  attr_reader :pos

  def initialize(src)
    @src = src
    @pos = 0
  end

  def skip_ws
    @pos += 1 while @src[@pos] && " \t\n\r".include?(@src[@pos])
  end

  def error!(msg) = raise(JsonError.new(msg, @pos))

  def value
    skip_ws
    c = @src[@pos]
    if !c    
      error!("unexpected end of input")
    elsif c == "{"
      object
    elsif c == "["
      array
    elsif c == "\""
      string
    elsif c == "-" || c.match?(/\d/)
      number
    elsif @src[@pos..].start_with?("true")
      @pos += 4
      true
    elsif @src[@pos..].start_with?("false")
      @pos += 5
      false
    elsif @src[@pos..].start_with?("null")
      @pos += 4
      nil
    else
      error!("unexpected character '#{c}'")
    end
  end

  def object
    @pos += 1
    h = {}
    skip_ws
    if @src[@pos] == "}"
      @pos += 1
      return h
    end
    loop do
      skip_ws
      error!("expected string key") unless @src[@pos] == "\""
      key = string
      skip_ws
      error!("expected ':'") unless @src[@pos] == ":"
      @pos += 1
      h[key] = value
      skip_ws
      c = @src[@pos]
      @pos += 1
      return h if c == "}"
      error!("expected ',' or '}'") unless c == ","
    end
  end

  def array
    @pos += 1
    a = []
    skip_ws
    if @src[@pos] == "]"
      @pos += 1
      return a
    end
    loop do
      a << value
      skip_ws
      c = @src[@pos]
      @pos += 1
      return a if c == "]"
      error!("expected ',' or ']'") unless c == ","
    end
  end

  def string
    @pos += 1
    out = +""
    loop do
      c = @src[@pos]
      error!("unterminated string") if !c    
      @pos += 1
      return out if c == "\""
      if c == "\\"
        e = @src[@pos]
        @pos += 1
        case e
        when "n" then out << "\n"
        when "t" then out << "\t"
        when "u"
          out << @src[@pos, 4].hex.chr
          @pos += 4
        when "\"", "\\", "/" then out << e
        else error!("bad escape")
        end
      else
        out << c
      end
    end
  end

  def number
    m = @src[@pos..].match(/\A-?(0|[1-9]\d*)(\.\d+)?([eE][-+]?\d+)?/)
    error!("bad number") unless m
    text = m.to_s
    @pos += text.size
    m[2] || m[3] ? Float(text) : Integer(text)
  end
end

def quote(s) = "\"" + s.gsub("\\", "\\\\\\\\").gsub("\"", "\\\"").gsub("\n", "\\n") + "\""

def dump(v, indent)
  pad = "  " * indent
  case v
  when Hash
    return "{}" if v.empty?
    items = v.map { |k, x| "#{pad}  #{quote(k)}: #{dump(x, indent + 1)}" }
    "{\n#{items.join(",\n")}\n#{pad}}"
  when Array
    return "[]" if v.empty?
    if v.none? { |x| x.is_a?(Hash) || x.is_a?(Array) }
      "[#{v.map { |x| dump(x, 0) }.join(", ")}]"
    else
      items = v.map { |x| "#{pad}  #{dump(x, indent + 1)}" }
      "[\n#{items.join(",\n")}\n#{pad}]"
    end
  when String then quote(v)
  when nil then "null"
  else v.to_s
  end
end

def lookup(v, path)
  path.scan(/[^.\[\]]+|\[\d+\]/).reduce(v) do |cur, seg|
    if (m = seg.match(/\A\[(\d+)\]\z/))
      return nil unless cur.is_a?(Array)
      cur[m[1].to_i]
    else
      return nil unless cur.is_a?(Hash)
      cur[seg]
    end
  end
end

DOCUMENT = <<~JSON
  {
    "store": {
      "name": "Corner \\"Books\\"",
      "open": true,
      "rating": 4.5,
      "books": [
        {"title": "Dune", "price": 9.99, "tags": ["sf", "classic"], "stock": 3},
        {"title": "Emma", "price": 4, "tags": [], "stock": 0},
        {"title": "Neuromancer", "price": 7.5e0, "tags": ["sf", "cyber"], "stock": 12}
      ],
      "manager": null,
      "note": "line1\\nline2 \\u0041",
      "path": "C:\\\\tmp"
    },
    "version": -2
  }
JSON

doc = Json.parse(DOCUMENT)
puts dump(doc, 0)
["store.name", "store.books[2].title", "store.books[0].tags[1]", "store.books[5].title",
 "store.manager", "version", "store.rating.x"].each do |path|
  puts "#{path} -> #{dump(lookup(doc, path), 0)}"
end
books = lookup(doc, "store.books")
if books.is_a?(Array)
  total = books.sum { |b| b["price"] * b["stock"] }
  puts "inventory value: #{total.round(2)}"
  sf = books.select { |b| b["tags"].include?("sf") }
  puts "sf titles: #{sf.map { |b| b["title"] }.join(", ")}"
end

["[1, 2,]", "{\"a\" 1}", "[1, 2] x", "\"abc", "{\"k\": tru}", "[01]", "", "[[[]]]", "{\"e\": 1E3}"].each do |src|
  puts "#{src.inspect} => #{dump(Json.parse(src), 0)}"
rescue JsonError => e
  puts "#{src.inspect} => error at #{e.pos}: #{e.message}"
end
