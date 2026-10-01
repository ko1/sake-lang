class JsonError < StandardError
  attr_reader :pos

  def initialize(message, pos)
    super(message)
    @pos = pos
  end
end

class Parser
  attr_reader :pos

  def initialize(src, pos)
    @src = src
    @pos = pos
  end

  def peek = @src[@pos]

  def skip_ws
    @pos += 1 while @pos < @src.size && " \t\n\r".include?(@src[@pos])
  end

  def expect(ch)
    skip_ws
    raise JsonError.new("expected '#{ch}'", @pos) if peek != ch
    @pos += 1
  end

  def parse_value
    skip_ws
    c = peek
    raise JsonError.new("unexpected end of input", @pos) if !c    
    case c
    when "{" then parse_object
    when "[" then parse_array
    when "\"" then parse_string
    when /[-0-9]/ then parse_number
    else parse_word
    end
  end

  def parse_object
    expect("{")
    h = {}
    skip_ws
    if peek == "}"
      @pos += 1
      return h
    end
    loop do
      skip_ws
      key = parse_string
      expect(":")
      h[key] = parse_value
      skip_ws
      c = peek
      @pos += 1
      break if c == "}"
      raise JsonError.new("expected ',' or '}'", @pos - 1) if c != ","
    end
    h
  end

  def parse_array
    expect("[")
    a = []
    skip_ws
    if peek == "]"
      @pos += 1
      return a
    end
    loop do
      a << parse_value
      skip_ws
      c = peek
      @pos += 1
      break if c == "]"
      raise JsonError.new("expected ',' or ']'", @pos - 1) if c != ","
    end
    a
  end

  def parse_string
    raise JsonError.new("expected string", @pos) if peek != "\""
    @pos += 1
    out = +""
    loop do
      c = peek
      raise JsonError.new("unterminated string", @pos) if !c    
      @pos += 1
      break if c == "\""
      if c == "\\"
        e = peek
        @pos += 1
        out << case e
               when "n" then "\n"
               when "t" then "\t"
               when "u"
                 code = @src[@pos, 4].hex
                 @pos += 4
                 code.chr
               else e
               end
      else
        out << c
      end
    end
    out
  end

  def parse_number
    m = @src[@pos..].match(/\A-?\d+(\.\d+)?([eE][-+]?\d+)?/)
    raise JsonError.new("bad number", @pos) unless m
    text = m.to_s
    @pos += text.size
    !m[1]     && !m[2]     ? text.to_i : text.to_f
  end

  def parse_word
    [["true", true], ["false", false], ["null", nil]].each do |word, value|
      if @src[@pos..].start_with?(word)
        @pos += word.size
        return value
      end
    end
    raise JsonError.new("unexpected '#{peek}'", @pos)
  end
end

def parse_json(text)
  ps = Parser.new(text, 0)
  v = ps.parse_value
  ps.skip_ws
  raise JsonError.new("trailing data", ps.pos) if ps.pos < text.size
  v
end

def quote(s)
  "\"" + s.gsub("\\", "\\\\\\\\").gsub("\"", "\\\"").gsub("\n", "\\n") + "\""
end

def scalar?(v) = !(v.is_a?(Array) || v.is_a?(Hash))

def compact(v)
  case v
  when nil then "null"
  when String then quote(v)
  when Array then "[" + v.map { |x| compact(x) }.join(", ") + "]"
  when Hash then "{" + v.map { |k, x| quote(k) + ": " + compact(x) }.join(", ") + "}"
  else v.to_s
  end
end

def pretty(v, indent, width)
  flat = compact(v)
  return flat if flat.size + indent <= width || scalar?(v)
  pad = " " * (indent + 2)
  items =
    case v
    when Array then v.map { |x| pad + pretty(x, indent + 2, width) }
    when Hash then v.map { |k, x| pad + quote(k) + ": " + pretty(x, indent + 2, width) }
    end
  open, close = v.is_a?(Array) ? ["[", "]"] : ["{", "}"]
  open + "\n" + items.join(",\n") + "\n" + " " * indent + close
end

def inputs
  [
    "{\"name\":\"sake\",\"version\":[0,1,2],\"typed\":true,\"ratio\":0.75,\"owner\":null}",
    "{\"servers\":[{\"host\":\"alpha.example\",\"ports\":[80,443],\"tags\":[\"edge\",\"tls\"]},{\"host\":\"beta\",\"ports\":[],\"note\":\"line1\\nline2 \\u0041\\u0042\"}],\"retries\":3,\"backoff\":1.5e2}",
    "[1, 2,, 3]",
    "{\"a\": tru}",
    "\"unterminated",
    "[1] 2"
  ]
end

inputs.each_with_index do |text, i|
  puts "--- input #{i + 1}"
  begin
    puts pretty(parse_json(text), 0, 40)
  rescue JsonError => e
    puts "error at #{e.pos}: #{e.message}"
  end
end
