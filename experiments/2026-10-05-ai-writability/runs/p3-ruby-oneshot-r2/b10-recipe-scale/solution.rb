def fmt(r)
  if r.denominator <= 8
    w = r.floor
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

UNITS = {
  "tsp" => [:spoon, Rational(1)], "tbsp" => [:spoon, Rational(3)], "cup" => [:spoon, Rational(48)],
  "g" => [:gram, Rational(1)], "kg" => [:gram, Rational(1000)],
  "ml" => [:ml, Rational(1)], "l" => [:ml, Rational(1000)],
  "-" => [:count, Rational(1)],
}

lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").strip.split(/ +/)
if h.size == 4 && h[0] == "SERVES" && h[2] == "->" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/ &&
   h[1].to_i.between?(1, 100) && h[3].to_i.between?(1, 100)
  nn = h[1].to_i
  mm = h[3].to_i
else
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(mm, nn)
puts "serves #{mm} (x #{fmt(factor)})"

totals = {}
order = []
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.strip.split(/ +/)
  next if f.empty? || f[0].start_with?("#")
  q = nil
  rest = nil
  if f[0] =~ /\A\d+\z/ && f[1] && f[1] =~ /\A(\d+)\/(\d+)\z/
    if $2.to_i != 0
      q = Rational(f[0].to_i) + Rational($1.to_i, $2.to_i)
    end
    rest = f[2..]
  elsif f[0] =~ /\A\d+\z/
    q = Rational(f[0].to_i)
    rest = f[1..]
  elsif f[0] =~ /\A(\d+)\.(\d+)\z/
    q = Rational(f[0])
    rest = f[1..]
  elsif f[0] =~ /\A(\d+)\/(\d+)\z/
    q = Rational($1.to_i, $2.to_i) if $2.to_i != 0
    rest = f[1..]
  end
  if q.nil? || q <= 0
    puts "line #{n}: error: bad quantity"
    next
  end
  if rest.empty?
    puts "line #{n}: error: missing unit"
    next
  end
  u = UNITS[rest[0]]
  if u.nil?
    puts "line #{n}: error: unknown unit #{rest[0]}"
    next
  end
  if rest.size < 2
    puts "line #{n}: error: missing name"
    next
  end
  name = rest[1..].join(" ")
  key = [name, u[0]]
  unless totals.key?(key)
    totals[key] = Rational(0)
    order << key
  end
  totals[key] += q * u[1] * factor
end

order.each do |key|
  name, grp = key
  a = totals[key]
  case grp
  when :spoon
    cups = a / 48
    tbsp = a / 3
    if cups >= 1 && cups.denominator <= 4 then puts "#{fmt(cups)} cup #{name}"
    elsif tbsp >= 1 && tbsp.denominator <= 4 then puts "#{fmt(tbsp)} tbsp #{name}"
    else puts "#{fmt(a)} tsp #{name}"
    end
  when :gram
    puts a >= 1000 ? "#{fmt(a / 1000)} kg #{name}" : "#{fmt(a)} g #{name}"
  when :ml
    puts a >= 1000 ? "#{fmt(a / 1000)} l #{name}" : "#{fmt(a)} ml #{name}"
  when :count
    puts "#{a.ceil} #{name}"
  end
end
