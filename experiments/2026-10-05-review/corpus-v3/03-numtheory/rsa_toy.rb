# Textbook RSA with small primes: key generation, encrypting text in blocks,
# signatures, and breaking a weak key by factoring the modulus.

class BadExponent < StandardError
  attr_reader :e

  def initialize(message, e)
    super(message)
    @e = e
  end
end

class Key
  attr_reader :n, :e, :d, :p, :q

  def initialize(n, e, d, p, q)
    @n = n
    @e = e
    @d = d
    @p = p
    @q = q
  end

  def public_part = "(n=#{@n}, e=#{@e})"
  def encrypt(m) = m.pow(@e, @n)
  def decrypt(c) = c.pow(@d, @n)
  def sign(h) = h.pow(@d, @n)
  def verify(h, s) = s.pow(@e, @n) == h % @n
end

def inverse(a, m)
  old_r, r = a, m
  old_s, s = 1, 0
  while r != 0
    q = old_r / r
    old_r, r = r, old_r - q * r
    old_s, s = s, old_s - q * s
  end
  raise BadExponent.new("e=#{a} is not invertible mod #{m}", a) if old_r != 1
  old_s % m
end

def make_key(p, q, e)
  phi = (p - 1) * (q - 1)
  Key.new(p * q, e, inverse(e, phi), p, q)
end

# pack text into blocks of `width` bytes, each block a base-256 number
def to_blocks(text, width)
  text.bytes.each_slice(width).map { |chunk| chunk.reduce(0) { |acc, b| acc * 256 + b } }
end

def from_blocks(blocks, width)
  s = +""
  blocks.each do |v|
    chars = []
    while v > 0
      chars.unshift((v % 256).chr)
      v /= 256
    end
    s << chars.join
  end
  s
end

def toy_hash(text) = text.bytes.reduce(7) { |h, b| (h * 31 + b) % 1000003 }

def factor_modulus(n)
  f = 3
  while f * f <= n
    return [f, n / f] if n % f == 0
    f += 2
  end
  nil
end

key = make_key(1000003, 1000033, 65537)
puts "public key: #{key.public_part}"
puts "d * e mod phi = #{key.d * key.e % ((key.p - 1) * (key.q - 1))}"

msg = "Number theory is useful!"
blocks = to_blocks(msg, 4)
cipher = blocks.map { |m| key.encrypt(m) }
plain = cipher.map { |c| key.decrypt(c) }
puts "blocks:  #{blocks}"
puts "cipher:  #{cipher.take(3)} ..."
puts "decoded: #{from_blocks(plain, 4)}"
puts "round trip ok: #{from_blocks(plain, 4) == msg}"

h = toy_hash(msg)
sig = key.sign(h)
puts "signature of hash #{h}: #{sig}"
puts "verify original: #{key.verify(h, sig)}"
puts "verify tampered: #{key.verify(toy_hash(msg + "?"), sig)}"

puts "bad exponents:"
[3, 5, 17].each do |e|
  k = make_key(61, 53, e)
  puts "  e=#{e}: d=#{k.d}"
rescue BadExponent => err
  puts "  e=#{e}: #{err.message}"
end

puts "breaking a weak key:"
weak = make_key(1009, 3001, 17)
secret = to_blocks("hi!", 1).map { |m| weak.encrypt(m) }
n = weak.n
if (pq = factor_modulus(n))
  p, q = pq
  cracked = make_key(p, q, weak.e)
  puts "  n=#{n} = #{p} * #{q}, recovered d=#{cracked.d}"
  puts "  message: #{from_blocks(secret.map { |c| cracked.decrypt(c) }, 1)}"
end

puts "homomorphic property: E(a)*E(b) = E(a*b)"
a = 1234
b = 5678
lhs = key.encrypt(a) * key.encrypt(b) % key.n
puts "  #{lhs == key.encrypt(a * b)}"
