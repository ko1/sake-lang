def qty(r)
  d = r.denominator
  if d <= 8
    w = r.numerator / d
    fr = r - w
    return w.to_s if fr == 0
    s = "#{fr.numerator}/#{fr.denominator}"
    w == 0 ? s : "#{w} #{s}"
  else
    c = (r * 100 + Rational(1, 2)).floor
    format("%d.%02d", c / 100, c % 100)
  end
end

def num(s)
  case s
  when /\A\d+\z/ then Rational(s.to_i)
  when /\A(\d+)\.(\d+)\z/ then Rational("#{$1}.#{$2}")
  when /\A(\d+)\/(\d+)\z/ then $2.to_i == 0 ? nil : Rational($1.to_i, $2.to_i)
  end
end

lines = $stdin.each_line.to_a
head = (lines[0] || "").split(" ")
unless head.size == 4 && head[0] == "SERVES" && head[2] == "->" &&
       head[1] =~ /\A\d+\z/ && head[3] =~ /\A\d+\z/ &&
       head[1].to_i.between?(1, 100) && head[3].to_i.between?(1, 100)
  puts "line 1: error: bad servings"
  exit
end
factor = Rational(head[3].to_i, head[1].to_i)
out = ["serves #{head[3].to_i} (x #{qty(factor)})"]

UNITS = {
  "tsp" => [:sp, 1], "tbsp" => [:sp, 3], "cup" => [:sp, 48],
  "g" => [:g, 1], "kg" => [:g, 1000], "ml" => [:ml, 1], "l" => [:ml, 1000], "-" => [:ct, 1],
}
acc = {}
order = []

lines.each_with_index do |raw, i|
  next if i == 0
  n = i + 1
  f = raw.strip.split(" ")
  next if f.empty? || f[0].start_with?("#")
  q = num(f[0])
  idx = 1
  if f[0] =~ /\A\d+\z/ && f[1] && f[1] =~ /\A\d+\/\d+\z/ && (fr = num(f[1]))
    q += fr
    idx = 2
  end
  if q.nil? || q <= 0
    out << "line #{n}: error: bad quantity"; next
  end
  if f[idx].nil?
    out << "line #{n}: error: missing unit"; next
  end
  u = UNITS[f[idx]]
  if u.nil?
    out << "line #{n}: error: unknown unit #{f[idx]}"; next
  end
  name = f[(idx + 1)..].join(" ")
  if name.empty?
    out << "line #{n}: error: missing name"; next
  end
  key = [name, u[0]]
  order << key unless acc.key?(key)
  acc[key] = (acc[key] || 0) + q * u[1] * factor
end

order.each do |key|
  name, g = key
  a = acc[key]
  case g
  when :sp
    if a / 48 >= 1 && (a / 48).denominator <= 4 then out << "#{qty(a / 48)} cup #{name}"
    elsif a / 3 >= 1 && (a / 3).denominator <= 4 then out << "#{qty(a / 3)} tbsp #{name}"
    else out << "#{qty(a)} tsp #{name}"
    end
  when :g
    out << (a >= 1000 ? "#{qty(a / 1000)} kg #{name}" : "#{qty(a)} g #{name}")
  when :ml
    out << (a >= 1000 ? "#{qty(a / 1000)} l #{name}" : "#{qty(a)} ml #{name}")
  when :ct
    out << "#{a.ceil} #{name}"
  end
end
puts out
