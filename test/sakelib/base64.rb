require "base64"

["", "a", "ab", "abc", "abcd", "Hello, World!", "あいう", "\u0000\xff", "a" * 45, "b" * 46, "c" * 100].each do |s|
  p Base64.encode64(s)
  p Base64.strict_encode64(s)
  p Base64.urlsafe_encode64(s)
  p Base64.urlsafe_encode64(s, padding: false)
  p Base64.urlsafe_encode64(s, padding: true)
  p Base64.decode64(Base64.encode64(s)) == s.b
end

# decoding gives binary; relabel it for text
s = Base64.decode64("44GC44GE44GG")
p s
p s.encoding.to_s
puts s.force_encoding("UTF-8")

# decode64 is lenient: other characters are skipped, "=" ends the data
["", "YQ", "YWI", "YWJj", "YW Jj\nZA==", "YWJj*ZGVm", "YQ==YWJj", "Y=Q", "!!!", "YWJjZA", "Y", "/+8=", "_-8"].each do |e|
  p Base64.decode64(e)
end

# strict_decode64 rejects what decode64 forgives
["", "YQ==", "YWI=", "YWJj", "YQ", "YR==", "YWJ=", "YW Jj", "YQ==YWJj", "Y===", "====", "_-8=", "YWJj\n"].each do |e|
  begin
    p Base64.strict_decode64(e)
  rescue ArgumentError => err
    puts "#{e.inspect}: ArgumentError: #{err.message}"
  end
end

# urlsafe_decode64 accepts missing padding and "-" "_"
["_-8", "_-8=", "YQ", "YWI", "YWJj", "", "+/8=", "YQ=", "Y"].each do |e|
  begin
    p Base64.urlsafe_decode64(e)
  rescue ArgumentError => err
    puts "#{e.inspect}: ArgumentError: #{err.message}"
  end
end

# all 256 byte values round-trip
bytes = (0..255).to_a.pack("C*")
enc = Base64.strict_encode64(bytes)
puts enc
p Base64.strict_decode64(enc) == bytes
p Base64.urlsafe_decode64(Base64.urlsafe_encode64(bytes)) == bytes
