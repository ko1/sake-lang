lines = $stdin.each_line.to_a
h = lines[0] && lines[0].split
unless h && h.size == 4 && h[0] == "SERVES" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/ && h[2] == "->" &&
       h[1].to_i.between?(1, 100) && h[3].to_i.between?(1, 100)
  puts "line 1: error: bad servings"; exit
end
m = h[3].to_i
fac = Rational(m, h[1].to_i)
def show(r)
  if 8 % r.denominator == 0 || r.denominator <= 8
    w = r.floor; fr = r - w
    return w.to_s if fr == 0
    s = "#{fr.numerator}/#{fr.denominator}"
    w == 0 ? s : "#{w} #{s}"
  else
    c = (r * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end
UNITS = { "tsp" => [:sp, 1], "tbsp" => [:sp, 3], "cup" => [:sp, 48], "g" => [:g, 1], "kg" => [:g, 1000],
          "ml" => [:ml, 1], "l" => [:ml, 1000], "-" => [:ct, 1] }
acc = {}
order = []
puts "serves #{m} (x #{show(fac)})"
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  err = ->(msg) { puts "line #{n}: error: #{msg}" }
  q = nil; used = 1
  if f[0] =~ /\A\d+\z/ && f[1] =~ /\A(\d+)\/(\d+)\z/
    if $2.to_i == 0 then err.("bad quantity"); next end
    q = Rational(f[0].to_i) + Rational($1.to_i, $2.to_i); used = 2
  elsif f[0] =~ /\A\d+\z/ then q = Rational(f[0].to_i)
  elsif f[0] =~ /\A\d+\.\d+\z/ then q = Rational(f[0])
  elsif f[0] =~ /\A(\d+)\/(\d+)\z/
    q = Rational($1.to_i, $2.to_i) if $2.to_i != 0
  end
  if q.nil? || q <= 0 then err.("bad quantity"); next end
  u = f[used]
  (err.("missing unit"); next) unless u
  (err.("unknown unit #{u}"); next) unless UNITS.key?(u)
  name = f[(used + 1)..].join(" ")
  (err.("missing name"); next) if name.empty?
  g, mul = UNITS[u]
  key = [name, g]
  order << key unless acc.key?(key)
  acc[key] = (acc[key] || 0) + q * mul * fac
end
order.each do |key|
  name, g = key
  a = acc[key]
  case g
  when :sp
    c = a / 48; t = a / 3
    if c >= 1 && c.denominator <= 4 then puts "#{show(c)} cup #{name}"
    elsif t >= 1 && t.denominator <= 4 then puts "#{show(t)} tbsp #{name}"
    else puts "#{show(a)} tsp #{name}" end
  when :g then puts a >= 1000 ? "#{show(a / 1000)} kg #{name}" : "#{show(a)} g #{name}"
  when :ml then puts a >= 1000 ? "#{show(a / 1000)} l #{name}" : "#{show(a)} ml #{name}"
  else puts "#{a.ceil} #{name}"
  end
end
