require "digest"

inputs = ["", "abc", "The quick brown fox jumps over the lazy dog", "日本語のテキスト", "héllo ✓ 😀",
          "a" * 55, "a" * 56, "a" * 64, "a" * 65, "b" * 111, "b" * 112, "b" * 128, "xyz" * 100,
          [0, 255, 128, 1, 127].pack("C*")]
inputs.each do |s|
  puts("#{s.bytesize} bytes")
  puts Digest::MD5.hexdigest(s), Digest::SHA1.hexdigest(s), Digest::SHA256.hexdigest(s)
  puts Digest::SHA384.hexdigest(s), Digest::SHA512.hexdigest(s)
  puts Digest::MD5.base64digest(s), Digest::SHA256.base64digest(s)
end
p Digest::MD5.digest("abc")
p Digest::SHA1.digest("abc").bytesize
p Digest::SHA256.digest("abc").encoding.to_s
puts Digest.hexencode(Digest::MD5.digest("abc"))

md = Digest::SHA256.new
md << "The quick brown "
md << "fox jumps over "
md.update("the lazy dog")
puts md.hexdigest
puts md.hexdigest
puts md.base64digest
p md.digest.bytesize
puts md.to_s
puts "#{md}"
p md
whole = Digest::SHA256.new.update("The quick brown fox jumps over the lazy dog")
p md == whole
p md == Digest::SHA256.new

m5 = Digest::MD5.new
10.times { |i| m5 << "#{i}" * 13 }
puts m5.hexdigest
puts m5.hexdigest!
puts m5.hexdigest
p m5 == Digest::MD5.new
m5 << "abc"
p m5.digest!
m5 << "abc"
puts m5.base64digest!
puts m5.hexdigest
puts Digest::MD5.new.update("zzz").reset.hexdigest

s1 = Digest::SHA1.new
["日本", "語の", "テキスト"].each { |piece| s1 << piece }
puts s1.hexdigest
s5 = Digest::SHA512.new
3.times { s5 << "q" * 100 }
puts s5.hexdigest
s3 = Digest::SHA384.new
s3 << ""
puts s3.hexdigest

p [Digest::MD5.new.digest_length, Digest::SHA1.new.digest_length, Digest::SHA256.new.digest_length,
   Digest::SHA384.new.digest_length, Digest::SHA512.new.digest_length]
p [Digest::MD5.new.block_length, Digest::SHA1.new.block_length, Digest::SHA256.new.block_length,
   Digest::SHA384.new.block_length, Digest::SHA512.new.block_length]
p [Digest::MD5.new.size, Digest::SHA256.new.length]

puts Digest::SHA256.file("digest.rb").hexdigest
begin
  Digest::MD5.file("no-such-file")
rescue SystemCallError
  puts "no file"
end

m1 = Digest::SHA1.new
m1 << "zzz"
puts(m1.hexdigest("abc"))
puts(m1.hexdigest)
p(Digest::MD5.new.digest("abc") == Digest::MD5.digest("abc"))
puts(Digest::SHA512.new.base64digest("x"))
puts(Digest::SHA384.new.update("q").hexdigest("日本語"))

# 2026-10-05: dup gives an independent copy; the instance form of file updates md.
d1 = Digest::SHA256.new
d1 << "abc"
d2 = d1.dup
d2 << "def"
puts(d1.hexdigest)
puts(d2.hexdigest)
p(d1 == Digest::SHA256.new.update("abc"))
m6 = Digest::MD5.new
m6 << "x"
p(m6.file("digest.rb").equal?(m6))
puts(m6.hexdigest)
s4 = Digest::SHA384.new.dup
puts(s4.hexdigest)
