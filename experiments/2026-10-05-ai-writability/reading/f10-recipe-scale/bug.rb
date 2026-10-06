class BadLine < StandardError; end

# unit => [family, size in the family's base unit]
UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:mass, 1], "kg" => [:mass, 1000],
  "ml" => [:volume, 1], "l" => [:volume, 1000],
  "-" => [:count, 1]
}.freeze

def parse_number(s)
  case s
  when /\A(\d+)\z/ then Rational($1.to_i)
  when /\A(\d+)\.(\d+)\z/ then Rational("#{$1}.#{$2}")
  when %r{\A(\d+)/(\d+)\z}
    raise BadLine, "bad quantity" if $2.to_i.zero?
    Rational($1.to_i, $2.to_i)
  else raise BadLine, "bad quantity"
  end
end

def show(q)
  if q.denominator <= 8
    whole, rest = q.numerator.divmod(q.denominator)
    return whole.to_s if rest.zero?
    return "#{rest}/#{q.denominator}" if whole.zero?
    "#{whole} #{rest}/#{q.denominator}"
  else
    cents = (q * 100 + Rational(1, 2)).floor
    format("%d.%02d", cents / 100, cents % 100)
  end
end

def nice?(q) = q > 1 && q.denominator <= 4

def present(family, base)
  case family
  when :spoon
    unit = %w[cup tbsp].find { |u| nice?(base / UNITS[u][1]) } || "tsp"
    "#{show(base / UNITS[unit][1])} #{unit}"
  when :mass then base >= 1000 ? "#{show(base / 1000)} kg" : "#{show(base)} g"
  when :volume then base >= 1000 ? "#{show(base / 1000)} l" : "#{show(base)} ml"
  else base.ceil.to_s
  end
end

lines = $stdin.each_line.map(&:chomp)
head = (lines.first || "").split
unless head.size == 4 && head[0] == "SERVES" && head[2] == "->" &&
       [head[1], head[3]].all? { |s| s.match?(/\A\d+\z/) && s.to_i.between?(1, 100) }
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(head[3].to_i, head[1].to_i)
puts "serves #{head[3].to_i} (x #{show(factor)})"

totals = {} # [name, family] => base amount, in first-seen order
lines.each_with_index do |line, i|
  next if i.zero?
  f = line.split
  next if f.empty? || f[0].start_with?("#")
  begin
    first = f.shift
    qty = parse_number(first)
    qty += parse_number(f.shift) if first.match?(/\A\d+\z/) && f[0]&.match?(%r{\A\d+/\d+\z})
    raise BadLine, "bad quantity" if qty.zero?
    unit = f.shift
    raise BadLine, "missing unit" unless unit
    raise BadLine, "unknown unit #{unit}" unless UNITS.key?(unit)
    family, size = UNITS[unit]
    raise BadLine, "missing name" if f.empty?
    key = [f.join(" "), family]
    totals[key] = (totals[key] || 0) + qty * size * factor
  rescue BadLine => e
    puts "line #{i + 1}: error: #{e.message}"
  end
end
totals.each do |(name, family), base|
  puts "#{present(family, base)} #{name}"
end
