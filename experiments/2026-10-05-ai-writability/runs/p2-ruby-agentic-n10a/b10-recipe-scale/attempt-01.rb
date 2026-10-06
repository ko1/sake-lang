lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split(" ")
unless h.size == 4 && h[0] == "SERVES" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/ && h[2] == "->" &&
       (1..100).cover?(h[1].to_i) && (1..100).cover?(h[3].to_i)
  puts "line 1: error: bad servings"
  exit
end
n = h[1].to_i
m = h[3].to_i
factor = Rational(m, n)

def fmt(q)
  d = q.denominator
  if d <= 8
    w = q.numerator / d
    r = q - w
    if r == 0 then w.to_s
    elsif w == 0 then "#{r.numerator}/#{r.denominator}"
    else "#{w} #{r.numerator}/#{r.denominator}"
    end
  else
    c = (q * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

def pq(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A\d+\.\d+\z/ then Rational(s)
  when %r{\A(\d+)/(\d+)\z}
    $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

UNITS = {"tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
         "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000],
         "-" => [:count, 1]}

puts "serves #{m} (x #{fmt(factor)})"
order = []
sums = Hash.new(0)
lines.each_with_index do |raw, i|
  next if i == 0
  no = i + 1
  f = raw.split(" ")
  next if f.empty? || f[0].start_with?("#")
  q = nil
  rest = nil
  if f[0] =~ /\A\d+\z/ && f[1] && f[1] =~ %r{\A\d+/\d+\z}
    fr = pq(f[1])
    q = fr && Rational(f[0].to_i) + fr
    rest = f[2..]
  else
    q = pq(f[0])
    rest = f[1..] || []
  end
  if q.nil? || q <= 0
    puts "line #{no}: error: bad quantity"; next
  end
  if rest.empty?
    puts "line #{no}: error: missing unit"; next
  end
  u = rest[0]
  unless UNITS.key?(u)
    puts "line #{no}: error: unknown unit #{u}"; next
  end
  if rest.size < 2
    puts "line #{no}: error: missing name"; next
  end
  name = rest[1..].join(" ")
  g, mult = UNITS[u]
  key = [name, g]
  order << key unless sums.key?(key)
  sums[key] += q * mult * factor
end

order.each do |key|
  name, g = key
  a = sums[key]
  case g
  when :spoon
    c = a / 48
    t = a / 3
    if c >= 1 && c.denominator <= 4 then puts "#{fmt(c)} cup #{name}"
    elsif t >= 1 && t.denominator <= 4 then puts "#{fmt(t)} tbsp #{name}"
    else puts "#{fmt(a)} tsp #{name}"
    end
  when :g
    puts a >= 1000 ? "#{fmt(a / 1000)} kg #{name}" : "#{fmt(a)} g #{name}"
  when :ml
    puts a >= 1000 ? "#{fmt(a / 1000)} l #{name}" : "#{fmt(a)} ml #{name}"
  when :count
    puts "#{a.ceil} #{name}"
  end
end
