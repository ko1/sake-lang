require "securerandom"

def show(label, v) = puts("#{label}: #{v}")

# hex: 2n lowercase hex digits
[nil, 0, 1, 8, 32].each do |n|
  h = n == nil ? SecureRandom.hex : SecureRandom.hex(n)
  show("hex(#{n.inspect})", "#{h.size} #{h.match?(/\A[0-9a-f]*\z/)}")
end

# random_bytes: binary, n bytes
b = SecureRandom.random_bytes
show("random_bytes", "#{b.bytesize} #{b.encoding}")
show("random_bytes(5)", SecureRandom.random_bytes(5).bytesize)
show("bytes(300)", SecureRandom.bytes(300).bytesize)

# base64 / urlsafe_base64
show("base64", "#{SecureRandom.base64.size} #{SecureRandom.base64(4).match?(/\A[A-Za-z0-9+\/]{6}==\z/)}")
show("urlsafe_base64", "#{SecureRandom.urlsafe_base64.size} #{SecureRandom.urlsafe_base64(30).match?(/\A[A-Za-z0-9_-]{40}\z/)}")
show("urlsafe_base64 padding", SecureRandom.urlsafe_base64(4, true).match?(/\A[A-Za-z0-9_-]{6}==\z/))

# uuid: version 4, variant 10xx
uuid_re = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
ok = (1..200).all? { SecureRandom.uuid.match?(uuid_re) }
show("uuid", "#{SecureRandom.uuid.size} #{ok}")
show("uuid_v4", SecureRandom.uuid_v4.match?(uuid_re))
show("uuids differ", SecureRandom.uuid != SecureRandom.uuid)
v7 = SecureRandom.uuid_v7
show("uuid_v7", v7.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/))
ms = v7.delete("-")[0, 12].hex
show("uuid_v7 time", (ms - (Time.now.to_f * 1000).to_i).abs < 10000)

# random_number: ranges of each form, over many draws
ints = (1..2000).map { SecureRandom.random_number(6) }
show("random_number(6)", "#{ints.all? { |x| x in Integer }} #{ints.uniq.sort}")
show("random_number(1)", (1..20).map { SecureRandom.random_number(1) }.uniq)
big = SecureRandom.random_number(2 ** 100)
show("random_number(2**100)", (big in Integer) && big >= 0 && big < 2 ** 100)
fs = (1..500).map { SecureRandom.random_number }
show("random_number", fs.all? { |x| (x in Float) && x >= 0.0 && x < 1.0 })
fs = (1..500).map { SecureRandom.random_number(2.5) }
show("random_number(2.5)", fs.all? { |x| (x in Float) && x >= 0.0 && x < 2.5 })
[0, -3, 0.0, -1.5].each do |n|
  x = SecureRandom.random_number(n)
  show("random_number(#{n})", (x in Float) && x >= 0.0 && x < 1.0)
end
rs = (1..2000).map { SecureRandom.random_number(10..12) }
show("random_number(10..12)", rs.uniq.sort)
rs = (1..2000).map { SecureRandom.random_number(10...12) }
show("random_number(10...12)", rs.uniq.sort)
show("random_number(2..2)", SecureRandom.random_number(2..2))
e = SecureRandom.random_number(5..1)
show("random_number(5..1)", (e in Float) && e < 1.0)
fr = (1..500).map { SecureRandom.random_number(2.0..3.0) }
show("random_number(2.0..3.0)", fr.all? { |x| (x in Float) && x >= 2.0 && x <= 3.0 })
show("rand(3)", SecureRandom.rand(3) < 3)

# alphanumeric
a = SecureRandom.alphanumeric
show("alphanumeric", "#{a.size} #{a.match?(/\A[A-Za-z0-9]+\z/)}")
show("alphanumeric(40)", SecureRandom.alphanumeric(40).match?(/\A[A-Za-z0-9]{40}\z/))
show("alphanumeric(0)", SecureRandom.alphanumeric(0).inspect)
abc = SecureRandom.alphanumeric(200, chars: ["a", "b", "c"])
show("alphanumeric chars", abc.chars.uniq.sort)
all = (1..50).map { SecureRandom.alphanumeric(100) }.join.chars
show("alphabet", Set[*all].size > 55)

# errors
begin
  SecureRandom.hex(-1)
rescue ArgumentError => e
  show("hex(-1)", e.message)
end
begin
  SecureRandom.random_bytes(-5)
rescue ArgumentError => e
  show("random_bytes(-5)", e.message)
end
