lines = $stdin.each_line.to_a
hf = (lines[0] || "").split
unless hf.size == 4 && hf[0] == "SERVES" && hf[1].match?(/\A\d+\z/) && hf[2] == "->" &&
       hf[3].match?(/\A\d+\z/) && hf[1].to_i.between?(1, 100) && hf[3].to_i.between?(1, 100)
  puts "line 1: error: bad servings"
  exit
end
n = hf[1].to_i
m = hf[3].to_i
factor = Rational(m, n)

def fmt(q)
  if q.denominator <= 8
    w = q.floor
    fr = q - w
    if fr == 0 then w.to_s
    elsif w == 0 then "#{fr.numerator}/#{fr.denominator}"
    else "#{w} #{fr.numerator}/#{fr.denominator}"
    end
  else
    c = (q * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

def int_rat(s) = Rational(s.to_i)

def parse_num(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A(\d+)\.(\d+)\z/ then Rational($1 + $2) / (10**$2.size)
  when /\A(\d+)\/(\d+)\z/ then $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000],
  "-" => [:count, 1]
}

order = []
amounts = Hash.new(0)

lines.each_with_index do |raw, idx|
  next if idx == 0
  n_ = idx + 1
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  q = parse_num(f[0])
  rest = f[1..]
  if q && f[0].match?(/\A\d+\z/) && rest[0] && rest[0].match?(/\A\d+\/\d+\z/) && !parse_num(rest[0]).nil?
    q += parse_num(rest[0])
    rest = rest[1..]
  end
  if q.nil? || q <= 0
    puts "line #{n_}: error: bad quantity"
    next
  end
  if rest.empty?
    puts "line #{n_}: error: missing unit"
    next
  end
  u = rest[0]
  unless UNITS.key?(u)
    puts "line #{n_}: error: unknown unit #{u}"
    next
  end
  name_f = rest[1..]
  if name_f.empty?
    puts "line #{n_}: error: missing name"
    next
  end
  name = name_f.join(" ")
  grp, mult = UNITS[u]
  key = [name, grp]
  order << key unless amounts.key?(key)
  amounts[key] += q * mult * factor
end

puts "serves #{m} (x #{fmt(factor)})"
order.each do |key|
  name, grp = key
  a = amounts[key]
  case grp
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
