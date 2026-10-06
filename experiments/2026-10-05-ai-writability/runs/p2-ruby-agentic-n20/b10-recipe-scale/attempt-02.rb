lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").split(/ +/).reject(&:empty?)
unless h.size == 4 && h[0] == "SERVES" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/ && h[2] == "->" &&
       (1..100).cover?(h[1].to_i) && (1..100).cover?(h[3].to_i)
  puts "line 1: error: bad servings"
  exit
end
m = h[3].to_i
factor = Rational(m, h[1].to_i)

def show(r)
  if r.denominator <= 8
    w = r.numerator / r.denominator
    fr = r - w
    if fr == 0 then w.to_s
    elsif w == 0 then "#{fr.numerator}/#{fr.denominator}"
    else "#{w} #{fr.numerator}/#{fr.denominator}"
    end
  else
    c = (r * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

UNITS = { "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
          "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000], "-" => [:count, 1] }.freeze

def num(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A\d+\.\d+\z/ then Rational(s)
  when %r{\A(\d+)/(\d+)\z} then $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

puts "serves #{m} (x #{show(factor)})"
order = []
sums = {}
lines.each_with_index do |line, i|
  next if i == 0
  no = i + 1
  f = line.split(/ +/).reject(&:empty?)
  next if f.empty? || f[0].start_with?("#")
  q = nil
  rest = nil
  if f[0] =~ /\A\d+\z/ && f[1] =~ %r{\A\d+/\d+\z}
    fr = num(f[1])
    q = fr && Rational(f[0].to_i) + fr
    rest = f[2..]
  else
    q = num(f[0])
    rest = f[1..]
  end
  if q.nil? || q <= 0
    puts "line #{no}: error: bad quantity"
    next
  end
  if rest.empty?
    puts "line #{no}: error: missing unit"
    next
  end
  u = UNITS[rest[0]]
  if u.nil?
    puts "line #{no}: error: unknown unit #{rest[0]}"
    next
  end
  if rest.size < 2
    puts "line #{no}: error: missing name"
    next
  end
  name = rest[1..].join(" ")
  key = [name, u[0]]
  order << key unless sums.key?(key)
  sums[key] = (sums[key] || 0) + q * u[1] * factor
end

order.each do |key|
  name, g = key
  a = sums[key]
  case g
  when :spoon
    cups = a / 48
    tb = a / 3
    if cups >= 1 && cups.denominator <= 4 then puts "#{show(cups)} cup #{name}"
    elsif tb >= 1 && tb.denominator <= 4 then puts "#{show(tb)} tbsp #{name}"
    else puts "#{show(a)} tsp #{name}"
    end
  when :g
    puts a >= 1000 ? "#{show(a / 1000)} kg #{name}" : "#{show(a)} g #{name}"
  when :ml
    puts a >= 1000 ? "#{show(a / 1000)} l #{name}" : "#{show(a)} ml #{name}"
  when :count
    puts "#{a.ceil} #{name}"
  end
end
