# Pythagorean triples: Euclid's formula for primitive triples, all triples up to
# a perimeter bound, perimeters with many triples, and the Berggren tree.

class Triple
  include Comparable
  attr_reader :a, :b, :c

  def initialize(a, b, c)
    @a = a
    @b = b
    @c = c
  end

  def self.build(a, b, c) = a < b ? new(a, b, c) : new(b, a, c)
  def perimeter = @a + @b + @c
  def area = @a * @b / 2
  def primitive? = @a.gcd(@b).gcd(@c) == 1
  def scale(k) = Triple.new(@a * k, @b * k, @c * k)
  def valid? = @a * @a + @b * @b == @c * @c

  def <=>(other)
    by_c = @c <=> other.c
    by_c != 0 ? by_c : @a <=> other.a
  end

  def to_s = "(#{@a}, #{@b}, #{@c})"
end

def primitives_up_to(max_c)
  out = []
  m = 2
  while m * m + 1 <= max_c
    (1...m).each do |n|
      next unless (m - n).odd? && m.gcd(n) == 1
      c = m * m + n * n
      out << Triple.build(m * m - n * n, 2 * m * n, c) if c <= max_c
    end
    m += 1
  end
  out.sort
end

def all_by_perimeter(max_p)
  by_p = {}
  primitives_up_to(max_p / 2).each do |t|
    p0 = t.perimeter
    k = 1
    while p0 * k <= max_p
      (by_p[p0 * k] ||= []) << t.scale(k)
      k += 1
    end
  end
  by_p
end

# Berggren matrices applied to (a, b, c)
def children(t)
  a, b, c = t.a, t.b, t.c
  [
    Triple.build(a - 2 * b + 2 * c, 2 * a - b + 2 * c, 2 * a - 2 * b + 3 * c),
    Triple.build(a + 2 * b + 2 * c, 2 * a + b + 2 * c, 2 * a + 2 * b + 3 * c),
    Triple.build(-a + 2 * b + 2 * c, -2 * a + b + 2 * c, -2 * a + 2 * b + 3 * c)
  ]
end

prims = primitives_up_to(100)
puts "primitive triples with c <= 100: #{prims.size}"
prims.each_slice(4) { |row| puts "  " + row.map(&:to_s).join(" ") }
raise "invalid triple" unless prims.all? { |t| t.valid? && t.primitive? }

by_p = all_by_perimeter(1000)
best_p = by_p.keys.max_by { |p| [by_p[p].size, -p] }
puts "perimeter <= 1000 with most triples: #{best_p}"
by_p[best_p].sort.each { |t| puts "  #{t} area #{t.area}" }

single = by_p.keys.count { |p| by_p[p].size == 1 }
puts "perimeters with exactly one triple: #{single}"

areas = prims.map(&:area)
puts "smallest areas: #{areas.sort.take(6).join(" ")}"
largest = prims.max
puts "largest primitive (by c, then a): #{largest}"
puts "first with c > 50: #{prims.find { |t| t.c > 50 }}"

puts "Berggren tree, 3 levels:"
level = [Triple.new(3, 4, 5)]
3.times do |depth|
  puts "  depth #{depth}: " + level.sort.map(&:to_s).join(" ")
  level = level.flat_map { |t| children(t) }
end
in_tree = level.select { |t| t.c <= 100 }
puts "  depth 3 triples with c <= 100: #{in_tree.size}"
