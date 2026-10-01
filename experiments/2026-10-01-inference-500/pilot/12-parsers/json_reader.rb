class JSONError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class Reader
  attr_reader :src
  attr_accessor :pos

  def initialize(src, pos)
    @src = src
    @pos = pos
  end

  def peek = @src[@pos]

  def error(msg) = raise(JSONError.new(msg, @pos))

  def skip_ws
    @pos += 1 while peek != nil && " \n\t".include?(peek)
  end

  def expect(ch)
    skip_ws
    c = peek
    error("expected '#{ch}' but found #{c ? "'#{c}'" : "end of input"}") if c != ch
    @pos += 1
  end

  def parse_document
    v = parse_value
    skip_ws
    error("trailing characters") if peek != nil
    v
  end

  def parse_value
    skip_ws
    c = peek
    error("unexpected end of input") if c.nil?
    if c == "{"
      parse_object
    elsif c == "["
      parse_array
    elsif c == "\""
      parse_string
    elsif c.match?(/[-\d]/)
      parse_number
    else
      m = @src[@pos..].match(/\A(true|false|null)/)
      error("unexpected '#{c}'") if m.nil?
      word = m[1]
      @pos += word.size
      word == "null" ? nil : word == "true"
    end
  end

  def parse_object
    obj = {}
    expect("{")
    skip_ws
    if peek == "}"
      @pos += 1
      return obj
    end
    while true
      skip_ws
      error("object key must be a string") if peek != "\""
      key = parse_string
      expect(":")
      obj[key] = parse_value
      skip_ws
      break if peek == "}"
      expect(",")
    end
    @pos += 1
    obj
  end

  def parse_array
    items = []
    expect("[")
    skip_ws
    if peek == "]"
      @pos += 1
      return items
    end
    while true
      items << parse_value
      skip_ws
      break if peek == "]"
      expect(",")
    end
    @pos += 1
    items
  end

  def parse_string
    @pos += 1
    out = ""
    while true
      c = peek
      error("unterminated string") if c.nil?
      @pos += 1
      break if c == "\""
      if c == "\\"
        e = peek
        @pos += 1
        esc = { "n" => "\n", "t" => "\t", "\"" => "\"", "\\" => "\\", "/" => "/" }
        error("bad escape") if e.nil? || esc[e].nil?
        out += esc[e]
      else
        out += c
      end
    end
    out
  end

  def parse_number
    m = @src[@pos..].match(/\A-?\d+(\.\d+)?([eE][-+]?\d+)?/)
    error("bad number") if m.nil?
    text = m.to_s
    @pos += text.size
    m[1] || m[2] ? Float(text) : Integer(text)
  end
end

def quote(s) = "\"" + s.gsub("\\", "\\\\\\\\").gsub("\"", "\\\"").gsub("\n", "\\n") + "\""

def dump(v, indent)
  pad = "  " * indent
  case v
  when Hash
    return "{}" if v.empty?
    lines = v.map { |k, x| "#{pad}  #{quote(k)}: #{dump(x, indent + 1)}" }
    "{\n#{lines.join(",\n")}\n#{pad}}"
  when Array
    return "[]" if v.empty?
    lines = v.map { |x| "#{pad}  #{dump(x, indent + 1)}" }
    "[\n#{lines.join(",\n")}\n#{pad}]"
  when String then quote(v)
  when nil then "null"
  else v.to_s
  end
end

def query(v, path)
  path.split(".").each do |key|
    v = case v
        when Hash then v[key]
        when Array then key.match?(/\A\d+\z/) ? v[key.to_i] : nil
        else nil
        end
  end
  v
end

def numbers_in(v, acc)
  case v
  when Hash then v.each_value { |x| numbers_in(x, acc) }
  when Array then v.each { |x| numbers_in(x, acc) }
  when Integer, Float then acc.push(v)
  end
  acc
end

doc = "{\"store\": {\"name\": \"Corner \\\"Shop\\\"\", \"open\": true,\n \"items\": [{\"name\": \"tea\", \"price\": 3.5, \"qty\": 12},\n {\"name\": \"cake\", \"price\": 4, \"qty\": 0, \"tags\": [\"sweet\", \"fresh\"]}],\n \"owner\": null, \"rating\": -1.25e1, \"notes\": \"line1\\nline2\", \"empty\": {}, \"none\": []}}"
data = Reader.new(doc, 0).parse_document
puts dump(data, 0)
["store.name", "store.items.1.tags.0", "store.items.0.price", "store.owner",
 "store.items.5.name", "store.open.x", "store.items.1.qty"].each do |path|
  puts format("%-22s -> %s", path, dump(query(data, path), 0))
end
nums = numbers_in(data, [])
puts "numbers: #{nums.map { it.to_s }.join(", ")}  sum=#{nums.sum}"

["[1, 2,, 3]", "{\"a\": tru}", "{\"a\" 1}", "[\"open", "{1: 2}", "[1] x", "  ", "[\"bad \\q\"]"].each do |bad|
  begin
    Reader.new(bad, 0).parse_document
    puts "parsed?! #{bad}"
  rescue JSONError => e
    puts format("%-14s error at %d: %s", bad, e.pos, e.message)
  end
end
