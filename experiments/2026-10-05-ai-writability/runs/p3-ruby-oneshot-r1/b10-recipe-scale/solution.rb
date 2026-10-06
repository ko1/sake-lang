def fmt_q(q)
  if q.denominator <= 8
    whole = q.floor
    fr = q - whole
    if fr == 0
      whole.to_s
    elsif whole == 0
      "#{fr.numerator}/#{fr.denominator}"
    else
      "#{whole} #{fr.numerator}/#{fr.denominator}"
    end
  else
    c = (q * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

lines = $stdin.read.split("\n", -1)
first = lines[0]
f0 = first ? first.split : []
unless f0.size == 4 && f0[0] == "SERVES" && f0[1] =~ /\A\d+\z/ && f0[2] == "->" && f0[3] =~ /\A\d+\z/ &&
       f0[1].to_i.between?(1, 100) && f0[3].to_i.between?(1, 100)
  puts "line 1: error: bad servings"
  exit
end
nn = f0[1].to_i
mm = f0[3].to_i
factor = Rational(mm, nn)

UNITS = {
  "tsp" => [:spoon, 1], "tbsp" => [:spoon, 3], "cup" => [:spoon, 48],
  "g" => [:gram, 1], "kg" => [:gram, 1000],
  "ml" => [:ml, 1], "l" => [:ml, 1000],
  "-" => [:count, 1],
}

def parse_q(f)
  # returns [quantity, fields_used] or nil
  a = f[0]
  case a
  when /\A\d+\z/
    if f[1] && f[1] =~ /\A(\d+)\/(\d+)\z/
      return nil if $2.to_i == 0
      q = a.to_i + Rational($1.to_i, $2.to_i)
      return q > 0 ? [q, 2] : nil
    end
    q = Rational(a.to_i)
    q > 0 ? [q, 1] : nil
  when /\A(\d+)\.(\d+)\z/
    q = Rational($1.to_i * 10**$2.size + $2.to_i, 10**$2.size)
    q > 0 ? [q, 1] : nil
  when /\A(\d+)\/(\d+)\z/
    return nil if $2.to_i == 0
    q = Rational($1.to_i, $2.to_i)
    q > 0 ? [q, 1] : nil
  end
end

order = []
tot = {}
out = ["serves #{mm} (x #{fmt_q(factor)})"]
errs = []

lines[1..].to_a.each_with_index do |raw, i|
  n = i + 2
  f = raw.split
  next if f.empty? || f[0].start_with?("#")
  r = parse_q(f)
  if r.nil?
    errs << "line #{n}: error: bad quantity"
    next
  end
  q, used = r
  rest = f[used..]
  if rest.empty?
    errs << "line #{n}: error: missing unit"
    next
  end
  u = UNITS[rest[0]]
  if u.nil?
    errs << "line #{n}: error: unknown unit #{rest[0]}"
    next
  end
  if rest.size < 2
    errs << "line #{n}: error: missing name"
    next
  end
  name = rest[1..].join(" ")
  key = [name, u[0]]
  order << key unless tot.key?(key)
  tot[key] = (tot[key] || 0) + q * factor * u[1]
end

out.concat(errs)
order.each do |key|
  name, grp = key
  a = tot[key]
  case grp
  when :spoon
    cups = a / 48
    tb = a / 3
    if cups >= 1 && cups.denominator <= 4
      out << "#{fmt_q(cups)} cup #{name}"
    elsif tb >= 1 && tb.denominator <= 4
      out << "#{fmt_q(tb)} tbsp #{name}"
    else
      out << "#{fmt_q(a)} tsp #{name}"
    end
  when :gram
    out << (a >= 1000 ? "#{fmt_q(a / 1000)} kg #{name}" : "#{fmt_q(a)} g #{name}")
  when :ml
    out << (a >= 1000 ? "#{fmt_q(a / 1000)} l #{name}" : "#{fmt_q(a)} ml #{name}")
  when :count
    out << "#{a.ceil} #{name}"
  end
end
puts out
