# Weighted course grade report.
Student = Struct.new(:name, :cats, :missing)

def tenths(r) = (r * 10).round

def show(t) = format("%d.%d", t / 10, t % 10)

def letter(t)
  if t >= 900 then "A"
  elsif t >= 800 then "B"
  elsif t >= 700 then "C"
  elsif t >= 600 then "D"
  else "F"
  end
end

NUM = /\A\d+(\.\d{1,2})?\z/
weights = {}
students = {}
errors = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.strip
  next if line.empty? || line.start_with?("#")
  f = line.split
  if f[0] == "weight" && f.size == 3
    if f[2] !~ NUM || !(1..100).cover?(f[2].to_r)
      errors << "line #{no}: bad weight #{f[2]}"
    elsif weights.key?(f[1])
      errors << "line #{no}: duplicate category #{f[1]}"
    else
      weights[f[1]] = f[2].to_r
    end
    next
  end
  if f.size != 3
    errors << "line #{no}: bad format"
    next
  end
  name, cat, score = f
  unless weights.key?(cat)
    errors << "line #{no}: unknown category #{cat}"
    next
  end
  m = score.match(%r{\A(\d+(?:\.\d{1,2})?|EX|-)/(\d+(?:\.\d{1,2})?)\z})
  max = m && m[2].to_r
  if m.nil? || max.zero? || (m[1] =~ /\A\d/ && m[1].to_r > max)
    errors << "line #{no}: bad score #{score}"
    next
  end
  st = (students[name] ||= Student.new(name, {}, 0))
  next if m[1] == "EX"
  pts = 0r
  if m[1] == "-"
    st.missing += 1
  else
    pts = m[1].to_r
  end
  acc = (st.cats[cat] ||= [0r, 0r])
  acc[0] += pts
  acc[1] += max
end

rows = students.values.map do |st|
  wsum = 0r
  total = 0r
  st.cats.each do |cat, (pts, max)|
    wsum += weights[cat]
    total += weights[cat] * pts / max
  end
  pct = wsum.zero? ? nil : total * 100 / wsum
  [st, pct]
end

errors.each { |e| puts e }
width = [7, *students.keys.map(&:size)].max
puts "#{'Student'.ljust(width)}  Score  G  Missing"
graded, ungraded = rows.partition { |_, pct| pct }
graded.sort_by! { |st, pct| [-tenths(pct), st.name] }
ungraded.sort_by! { |st, _| st.name }
(graded + ungraded).each do |st, pct|
  score = pct ? show(tenths(pct)).rjust(5) : "  n/a"
  grade = pct ? letter(tenths(pct)) : "-"
  puts "#{st.name.ljust(width)}  #{score}  #{grade}  #{st.missing.to_s.rjust(7)}"
end
if graded.empty?
  puts "class average: n/a"
else
  avg = graded.sum(0r) { |_, pct| pct } / graded.size
  puts "class average: #{show(tenths(avg))}"
end
