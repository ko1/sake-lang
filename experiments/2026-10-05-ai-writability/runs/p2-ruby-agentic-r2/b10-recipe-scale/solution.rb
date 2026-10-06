def fmt_q(r)
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

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:gram, 1], "kg" => [:gram, 1000],
  "ml" => [:ml, 1], "l" => [:ml, 1000],
  "-" => [:count, 1],
}.freeze

def parse_q(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A(\d+)\.(\d+)\z/ then Rational($1 + $2) / (10**$2.size)
  when /\A(\d+)\/(\d+)\z/ then $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

lines = $stdin.each_line.map(&:chomp)
h = (lines[0] || "").strip.split(/ +/)
if h.size == 4 && h[0] == "SERVES" && h[1] =~ /\A\d+\z/ && h[2] == "->" && h[3] =~ /\A\d+\z/ &&
   (1..100).cover?(h[1].to_i) && (1..100).cover?(h[3].to_i)
  n = h[1].to_i
  m = h[3].to_i
else
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(m, n)
puts "serves #{m} (x #{fmt_q(factor)})"

acc = {}
lines.each_with_index do |raw, i|
  next if i == 0
  ln = i + 1
  f = raw.strip.split(/ +/)
  next if f.empty? || f[0].start_with?("#")
  err = ->(msg) { puts "line #{ln}: error: #{msg}" }
  q = parse_q(f[0])
  rest = f[1..]
  if q && f[0] =~ /\A\d+\z/ && rest[0] =~ /\A\d+\/\d+\z/
    fr = parse_q(rest[0])
    q = fr && (q + fr)
    rest = rest[1..]
  end
  if q.nil? || q <= 0
    err.("bad quantity"); next
  end
  if rest.empty? then err.("missing unit"); next end
  u = UNITS[rest[0]]
  unless u then err.("unknown unit #{rest[0]}"); next end
  if rest.size < 2 then err.("missing name"); next end
  name = rest[1..].join(" ")
  key = [name, u[0]]
  acc[key] = (acc[key] || 0) + q * u[1] * factor
end

acc.each do |(name, grp), amt|
  case grp
  when :spoon
    cups = amt / 48
    tbsp = amt / 3
    if cups >= 1 && cups.denominator <= 4 then puts "#{fmt_q(cups)} cup #{name}"
    elsif tbsp >= 1 && tbsp.denominator <= 4 then puts "#{fmt_q(tbsp)} tbsp #{name}"
    else puts "#{fmt_q(amt)} tsp #{name}"
    end
  when :gram
    puts amt >= 1000 ? "#{fmt_q(amt / 1000)} kg #{name}" : "#{fmt_q(amt)} g #{name}"
  when :ml
    puts amt >= 1000 ? "#{fmt_q(amt / 1000)} l #{name}" : "#{fmt_q(amt)} ml #{name}"
  when :count
    puts "#{amt.ceil} #{name}"
  end
end
