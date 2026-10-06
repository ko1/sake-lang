def fmt(q)
  if q.denominator <= 8
    w = q.floor
    fr = q - w
    if fr == 0
      w.to_s
    elsif w == 0
      "#{fr.numerator}/#{fr.denominator}"
    else
      "#{w} #{fr.numerator}/#{fr.denominator}"
    end
  else
    c = (q * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

SPOON = { "tsp" => 1, "tbsp" => 3, "cup" => 48 }
GRAM = { "g" => 1, "kg" => 1000 }
MLIT = { "ml" => 1, "l" => 1000 }

lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
first = (lines[0] || "").split
unless first.size == 4 && first[0] == "SERVES" && first[1] =~ /\A\d+\z/ && first[2] == "->" &&
       first[3] =~ /\A\d+\z/ && first[1].to_i.between?(1, 100) && first[3].to_i.between?(1, 100)
  puts "line 1: error: bad servings"
  exit
end
m = first[3].to_i
factor = Rational(m, first[1].to_i)
out = ["serves #{m} (x #{fmt(factor)})"]

order = []
totals = Hash.new(0)

lines[1..].each_with_index do |raw, i|
  n = i + 2
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  qty = nil
  rest = nil
  bad = false
  if f[0] =~ /\A\d+\z/ && f[1] =~ /\A(\d+)\/(\d+)\z/
    if $2.to_i == 0
      bad = true
    else
      qty = Rational(f[0].to_i) + Rational($1.to_i, $2.to_i)
    end
    rest = f[2..]
  elsif f[0] =~ /\A\d+\z/
    qty = Rational(f[0].to_i)
    rest = f[1..]
  elsif f[0] =~ /\A(\d+)\.(\d+)\z/
    qty = Rational($1.to_i) + Rational($2.to_i, 10**$2.size)
    rest = f[1..]
  elsif f[0] =~ /\A(\d+)\/(\d+)\z/
    if $2.to_i == 0
      bad = true
    else
      qty = Rational($1.to_i, $2.to_i)
    end
    rest = f[1..]
  else
    bad = true
  end
  if bad || qty <= 0
    out << "line #{n}: error: bad quantity"
    next
  end
  rest ||= []
  if rest.empty?
    out << "line #{n}: error: missing unit"
    next
  end
  unit = rest[0]
  if unit == "-"
    grp = :count
    base = qty
  elsif SPOON.key?(unit)
    grp = :spoon
    base = qty * SPOON[unit]
  elsif GRAM.key?(unit)
    grp = :gram
    base = qty * GRAM[unit]
  elsif MLIT.key?(unit)
    grp = :ml
    base = qty * MLIT[unit]
  else
    out << "line #{n}: error: unknown unit #{unit}"
    next
  end
  name = rest[1..].join(" ")
  if name.empty?
    out << "line #{n}: error: missing name"
    next
  end
  key = [name, grp]
  order << key unless totals.key?(key)
  totals[key] += base * factor
end

order.each do |key|
  name, grp = key
  a = totals[key]
  case grp
  when :count
    out << "#{a.ceil} #{name}"
  when :spoon
    cups = a / 48
    tbsp = a / 3
    if cups >= 1 && cups.denominator <= 4
      out << "#{fmt(cups)} cup #{name}"
    elsif tbsp >= 1 && tbsp.denominator <= 4
      out << "#{fmt(tbsp)} tbsp #{name}"
    else
      out << "#{fmt(a)} tsp #{name}"
    end
  when :gram
    out << (a >= 1000 ? "#{fmt(a / 1000)} kg #{name}" : "#{fmt(a)} g #{name}")
  when :ml
    out << (a >= 1000 ? "#{fmt(a / 1000)} l #{name}" : "#{fmt(a)} ml #{name}")
  end
end
puts out
