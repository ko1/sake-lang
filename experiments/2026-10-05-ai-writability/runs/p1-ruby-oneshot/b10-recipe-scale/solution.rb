INT_RE = /\A\d+\z/
DEC_RE = /\A(\d+)\.(\d+)\z/
FRAC_RE = %r{\A(\d+)/(\d+)\z}

def show(r)
  if r.denominator <= 8
    w = r.floor
    fr = r - w
    return w.to_s if fr == 0
    return "#{fr.numerator}/#{fr.denominator}" if w == 0
    "#{w} #{fr.numerator}/#{fr.denominator}"
  else
    c = (r * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

# Returns [value, fields consumed] or nil.
def parse_qty(f)
  a = f[0]
  if a.match?(INT_RE)
    if f[1] && (m = FRAC_RE.match(f[1]))
      return nil if m[2].to_i == 0
      v = Rational(a.to_i) + Rational(m[1].to_i, m[2].to_i)
      return v > 0 ? [v, 2] : nil
    end
    v = Rational(a.to_i)
    v > 0 ? [v, 1] : nil
  elsif (m = DEC_RE.match(a))
    v = Rational(m[1].to_i) + Rational(m[2].to_i, 10**m[2].size)
    v > 0 ? [v, 1] : nil
  elsif (m = FRAC_RE.match(a))
    return nil if m[2].to_i == 0
    v = Rational(m[1].to_i, m[2].to_i)
    v > 0 ? [v, 1] : nil
  end
end

lines = $stdin.each_line.to_a
h = lines[0] ? lines[0].split : []
unless h.size == 4 && h[0] == "SERVES" && h[1].match?(INT_RE) && h[3].match?(INT_RE) &&
       h[2] == "->" && (1..100).cover?(h[1].to_i) && (1..100).cover?(h[3].to_i)
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(h[3].to_i, h[1].to_i)
puts "serves #{h[3].to_i} (x #{show(factor)})"

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000],
  "-" => [:count, 1]
}

totals = {}  # [name, group] => Rational, insertion-ordered
lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  q = parse_qty(f)
  if q.nil?
    puts "line #{n}: error: bad quantity"
    next
  end
  val, used = q
  rest = f[used..]
  if rest.empty?
    puts "line #{n}: error: missing unit"
    next
  end
  unit = rest[0]
  unless UNITS.key?(unit)
    puts "line #{n}: error: unknown unit #{unit}"
    next
  end
  if rest.size < 2
    puts "line #{n}: error: missing name"
    next
  end
  name = rest[1..].join(" ")
  group, mult = UNITS[unit]
  key = [name, group]
  totals[key] = (totals[key] || Rational(0)) + val * mult * factor
end

totals.each do |(name, group), amt|
  case group
  when :spoon
    cups = amt / 48
    tbsp = amt / 3
    if cups >= 1 && cups.denominator <= 4 then puts "#{show(cups)} cup #{name}"
    elsif tbsp >= 1 && tbsp.denominator <= 4 then puts "#{show(tbsp)} tbsp #{name}"
    else puts "#{show(amt)} tsp #{name}"
    end
  when :g
    puts amt >= 1000 ? "#{show(amt / 1000)} kg #{name}" : "#{show(amt)} g #{name}"
  when :ml
    puts amt >= 1000 ? "#{show(amt / 1000)} l #{name}" : "#{show(amt)} ml #{name}"
  when :count
    puts "#{amt.ceil} #{name}"
  end
end
