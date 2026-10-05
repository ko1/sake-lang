# URL percent escapes for path segments and form values, decoding with validation,
# and parsing / rebuilding query strings with repeated keys.

def unreserved?(b)
  b.between?(65, 90) || b.between?(97, 122) || b.between?(48, 57) ||
    b == 45 || b == 46 || b == 95 || b == 126
end

def escape(s, form)
  s.bytes.map do |b|
    if unreserved?(b)
      b.chr
    elsif form && b == 32
      "+"
    else
      format("%%%02X", b)
    end
  end.join
end

def unescape(s, form)
  bytes = []
  i = 0
  chars = s.chars
  while i < chars.size
    c = chars[i]
    if c == "%"
      hex = chars.drop(i + 1).take(2).join
      raise ArgumentError, "bad escape at #{i}: %#{hex}" unless hex.match?(/\A[0-9A-Fa-f]{2}\z/)
      bytes << hex.hex
      i += 3
    else
      bytes << (form && c == "+" ? 32 : c.ord)
      i += 1
    end
  end
  [bytes, bytes.map { |b| format("%02x", b) }.join]
end

def decode_text(s, form)
  bytes, _hex = unescape(s, form)
  bytes.map(&:chr).join
end

def parse_query(q)
  params = {}
  q.split("&").each do |pair|
    next if pair.empty?
    k, sep, v = pair.partition("=")
    (params[decode_text(k, true)] ||= []) << (sep.empty? ? "" : decode_text(v, true))
  end
  params
end

def build_query(params)
  params.keys.sort.flat_map do |k|
    params.fetch(k).map { |v| "#{escape(k, true)}=#{escape(v, true)}" }
  end.join("&")
end

puts "== escaping =="
samples = ["hello world", "a+b=c&d", "50% off!", "~user/path_name.txt", "naïve/日本"]
samples.each do |s|
  path = escape(s, false)
  form = escape(s, true)
  _bytes, hex = unescape(path, false)
  puts format("%-22s path=%-36s form=%s", s, path, form)
  puts "  utf-8 bytes: #{hex}"
end

puts "== query strings =="
query = "q=sake+lang&tag=ruby&tag=types%2Finference&empty=&flag&page=2&note=100%25+sure&q=again"
params = parse_query(query)
params.each { |k, vs| puts "  #{k}: #{vs.inspect}" }
page = params["page"]
page_no = page ? (page.first || "1").to_i : 1
puts "page number: #{page_no}"
puts "sort given: #{!params["sort"].nil?}"
rebuilt = build_query(params)
puts "rebuilt: #{rebuilt}"
puts "stable after rebuild: #{parse_query(rebuilt) == params}"

puts "== bad input =="
["100%", "%zz", "ok%2", "fine%20here"].each do |s|
  puts "#{s} -> #{decode_text(s, false).inspect}"
rescue ArgumentError => e
  puts "#{s} -> #{e.message}"
end
