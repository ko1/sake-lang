lines = $stdin.each_line.map(&:chomp)
hd = (lines[0] || "").split(/ +/).reject(&:empty?)
unless hd.size == 4 && hd[0] == "SERVES" && hd[2] == "->" &&
       hd[1] =~ /\A\d+\z/ && hd[3] =~ /\A\d+\z/ &&
       (1..100).cover?(hd[1].to_i) && (1..100).cover?(hd[3].to_i)
  puts "line 1: error: bad servings"
  exit
end
n, m = hd[1].to_i, hd[3].to_i
factor = Rational(m, n)

def show(q)
  if q.denominator <= 8
    w = q.numerator / q.denominator
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

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:gram, 1], "kg" => [:gram, 1000],
  "ml" => [:ml, 1], "l" => [:ml, 1000], "-" => [:count, 1]
}
INT = /\A\d+\z/
DEC = /\A\d+\.\d+\z/
FRAC = /\A(\d+)\/(\d+)\z/

out = ["serves #{m} (x #{show(factor)})"]
acc = {}
lines.each_with_index do |raw, i|
  next if i == 0
  ln = i + 1
  f = raw.split(/ +/).reject(&:empty?)
  next if f.empty? || f[0].start_with?("#")
  err = ->(msg) { out << "line #{ln}: error: #{msg}" }
  q = nil
  used = 0
  a = f[0]
  if a =~ INT
    if f[1] && f[1] =~ FRAC && $2.to_i != 0
      q = Rational(a.to_i) + Rational($1.to_i, $2.to_i)
      used = 2
    else
      q = Rational(a.to_i); used = 1
    end
  elsif a =~ DEC
    q = Rational(a); used = 1
  elsif a =~ FRAC && $2.to_i != 0
    q = Rational($1.to_i, $2.to_i); used = 1
  end
  (err.("bad quantity"); next) if q.nil? || q <= 0
  (err.("missing unit"); next) if f.size <= used
  u = f[used]
  (err.("unknown unit #{u}"); next) unless UNITS[u]
  (err.("missing name"); next) if f.size <= used + 1
  name = f[(used + 1)..].join(" ")
  grp, mult = UNITS[u]
  key = [name, grp]
  acc[key] = (acc[key] || 0) + q * factor * mult
end

acc.each do |(name, grp), amt|
  case grp
  when :spoon
    cups = amt / 48
    tb = amt / 3
    if cups >= 1 && cups.denominator <= 4 then out << "#{show(cups)} cup #{name}"
    elsif tb >= 1 && tb.denominator <= 4 then out << "#{show(tb)} tbsp #{name}"
    else out << "#{show(amt)} tsp #{name}"
    end
  when :gram
    out << (amt >= 1000 ? "#{show(amt / 1000)} kg #{name}" : "#{show(amt)} g #{name}")
  when :ml
    out << (amt >= 1000 ? "#{show(amt / 1000)} l #{name}" : "#{show(amt)} ml #{name}")
  else
    out << "#{amt.ceil} #{name}"
  end
end
puts out
