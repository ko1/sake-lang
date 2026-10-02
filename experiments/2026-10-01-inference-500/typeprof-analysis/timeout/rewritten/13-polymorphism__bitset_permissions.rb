class UnknownFlag < StandardError
  attr_reader :flag
  def initialize(message, flag)
    super(message)
    @flag = flag
  end
end

FLAG_NAMES = [:read, :write, :delete, :share, :admin, :billing, :audit, :deploy]

class Bits
  attr_reader :mask

  def initialize(mask)
    @mask = mask
  end

  def self.none = Bits.new(0)

  def self.bit(name)
    i = FLAG_NAMES.index(name)
    raise UnknownFlag.new("unknown flag #{name}", name) if i.nil?
    i
  end

  def self.of(names) = names.reduce(none) { |acc, n| acc | Bits.new(1 << bit(n)) }

  def &(b) = Bits.new(@mask & b.mask)
  def |(b) = Bits.new(@mask | b.mask)
  def ^(b) = Bits.new(@mask ^ b.mask)
  def -(b) = Bits.new(@mask & (b.mask ^ 255))
  def <<(n) = Bits.new((@mask << n) & 255)

  def [](i) = (@mask >> i) & 1 == 1
  def []=(i, v)
    if v
      @mask = @mask | (1 << i)
    else
      @mask = @mask & ((1 << i) ^ 255)
    end
  end

  def count
    n = 0
    m = @mask
    while m > 0
      n += m & 1
      m >>= 1
    end
    n
  end

  def include_all?(b) = (@mask & b.mask) == b.mask
  def empty? = @mask == 0

  def names = FLAG_NAMES.select { |n| self[Bits.bit(n)] }
  def to_s = "{#{names.join(",")}}"
  def binary = format("%08b", @mask)
end

ROLES = {
  "viewer" => Bits.of([:read]),
  "editor" => Bits.of([:read, :write, :share]),
  "owner" => Bits.of([:read, :write, :delete, :share]),
  "finance" => Bits.of([:read, :billing, :audit]),
  "ops" => Bits.of([:read, :deploy, :audit]),
  "root" => Bits.new(255)
}

def effective(user_roles, granted, revoked)
  base = user_roles.reduce(Bits.none) { |acc, r| acc | (ROLES[r] || Bits.none) }
  (base | granted) - revoked
end

users = [
  ["ann", ["editor"], [:audit], []],
  ["bob", ["viewer", "finance"], [], [:audit]],
  ["cyd", ["owner", "ops"], [], [:delete]],
  ["dee", ["intern"], [], []],
  ["eve", ["root"], [], [:billing, :deploy]]
]

puts "roles:"
ROLES.each { |name, bits| puts format("  %-8s %s %s", name, bits.binary, bits) }

perms = {}
puts "users:"
users.each do |name, rs, plus, minus|
  e = effective(rs, Bits.of(plus), Bits.of(minus))
  perms[name] = e
  puts format("  %-4s %s %-40s (%d flags)", name, e.binary, e.to_s, e.count)
end

puts "checks:"
checks = [["ann", [:write, :share]], ["bob", [:audit]], ["cyd", [:deploy, :read]],
          ["dee", [:read]], ["eve", [:admin, :delete]], ["ann", [:teleport]]]
checks.each do |who, need|
  begin
    ok = perms[who].include_all?(Bits.of(need))
    puts "  #{who} #{need.join("+")}: #{ok ? "allowed" : "denied"}"
  rescue UnknownFlag => err
    puts "  #{who}: #{err.message}"
  end
end

puts "set algebra:"
ann = perms["ann"]
cyd = perms["cyd"]
puts "  ann & cyd = #{ann & cyd}"
puts "  ann | cyd = #{ann | cyd}"
puts "  ann ^ cyd = #{ann ^ cyd}"
puts "  cyd - ann = #{cyd - ann}"
puts "  ann << 1  = #{ann << 1}"
common = perms.values.reduce(Bits.new(255)) { |acc, b| acc & b }
puts "  shared by everyone: #{common.empty? ? "nothing" : common.to_s}"

puts "toggling:"
b = Bits.of([:read])
b[Bits.bit(:write)] = true
b[Bits.bit(:deploy)] = true
b[Bits.bit(:read)] = false
puts "  #{b} write? #{b[Bits.bit(:write)]} read? #{b[Bits.bit(:read)]}"

counts = Hash.new(0)
perms.each { |name, bits| bits.names.each { |f| counts[f] += 1 } }
popular = counts.max_by { |e__0| f, n = e__0; n }
puts "most granted flag: #{popular[0]} (#{popular[1]} users)" if popular
