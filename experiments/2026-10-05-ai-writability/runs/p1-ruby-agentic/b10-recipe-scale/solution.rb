def fmt(r)
  if r.denominator <= 8
    w = r.numerator / r.denominator
    fr = r - w
    return w.to_s if fr == 0
    return "#{fr.numerator}/#{fr.denominator}" if w == 0
    "#{w} #{fr.numerator}/#{fr.denominator}"
  else
    c = (r * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

lines = $stdin.each_line.to_a
h = (lines[0] || "").split
unless h.size == 4 && h[0] == "SERVES" && h[1] =~ /\A\d+\z/ && h[3] =~ /\A\d+\z/ && h[2] == "->" &&
       (1..100).cover?(h[1].to_i) && (1..100).cover?(h[3].to_i)
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(h[3].to_i, h[1].to_i)
puts "serves #{h[3].to_i} (x #{fmt(factor)})"

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000], "-" => [:count, 1]
}

def num(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A(\d+)\.(\d+)\z/ then Rational($1.to_i) + Rational($2.to_i, 10**$2.size)
  when /\A(\d+)\/(\d+)\z/ then $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

order = []
tot = Hash.new(0)
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  q = num(f[0])
  rest = f[1..]
  if q && f[0] =~ /\A\d+\z/ && f[1] && f[1] =~ /\A\d+\/\d+\z/ && (fr = num(f[1]))
    q += fr
    rest = f[2..]
  end
  err = nil
  if !q || q <= 0 then err = "bad quantity"
  elsif rest.empty? then err = "missing unit"
  elsif !UNITS[rest[0]] then err = "unknown unit #{rest[0]}"
  elsif rest.size < 2 then err = "missing name"
  end
  if err
    puts "line #{n}: error: #{err}"; next
  end
  group, mult = UNITS[rest[0]]
  key = [rest[1..].join(" "), group]
  order << key unless tot.key?(key)
  tot[key] += q * mult * factor
end

order.each do |key|
  name, group = key
  a = tot[key]
  case group
  when :spoon
    cups = a / 48
    tbsp = a / 3
    if cups >= 1 && cups.denominator <= 4 then puts "#{fmt(cups)} cup #{name}"
    elsif tbsp >= 1 && tbsp.denominator <= 4 then puts "#{fmt(tbsp)} tbsp #{name}"
    else puts "#{fmt(a)} tsp #{name}"
    end
  when :g
    puts a >= 1000 ? "#{fmt(a / 1000)} kg #{name}" : "#{fmt(a)} g #{name}"
  when :ml
    puts a >= 1000 ? "#{fmt(a / 1000)} l #{name}" : "#{fmt(a)} ml #{name}"
  else
    puts "#{a.ceil} #{name}"
  end
end
