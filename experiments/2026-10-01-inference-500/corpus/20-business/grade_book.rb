class Assignment
  attr_reader :name, :category, :max_points

  def initialize(name, category, max_points)
    @name = name
    @category = category
    @max_points = max_points
  end
end

class Student
  attr_reader :name, :scores

  def initialize(name, scores)
    @name = name
    @scores = scores
  end
end

WEIGHTS = { homework: 0.3, exam: 0.5, project: 0.2 }

def letter(pct)
  if pct >= 90 then "A"
  elsif pct >= 80 then "B"
  elsif pct >= 70 then "C"
  elsif pct >= 60 then "D"
  else "F"
  end
end

def parse_roster(text)
  lines = text.lines
  header = lines.shift.strip.split(",")
  header.shift
  assignments = header.map do |h|
    name, cat, max = h.split(":")
    Assignment.new(name, cat.to_sym, max.to_i)
  end
  students = lines.map do |line|
    cells = line.strip.split(",")
    name = cells.shift
    scores = {}
    assignments.each_with_index do |a, i|
      cell = cells[i]
      scores[a.name] = (cell.nil? || cell == "-") ? nil : cell.to_f
    end
    Student.new(name, scores)
  end
  [assignments, students]
end

# percentage in one category; missing work counts as zero, lowest homework is dropped
def category_pct(student, assignments, category)
  items = assignments.select { |a| a.category == category }
  return nil if items.empty?
  pcts = items.map do |a|
    s = student.scores[a.name]
    (s || 0.0) / a.max_points * 100
  end
  if category == :homework && pcts.size > 2
    pcts.delete_at(pcts.index(pcts.min))
  end
  pcts.sum / pcts.size
end

def final_pct(student, assignments)
  total = 0.0
  used = 0.0
  WEIGHTS.each do |cat, w|
    pct = category_pct(student, assignments, cat)
    next unless pct
    total += pct * w
    used += w
  end
  total / used
end

def median(xs)
  s = xs.sort
  n = s.size
  n.odd? ? s[n / 2] : (s[n / 2 - 1] + s[n / 2]) / 2.0
end

def stddev(xs)
  mean = xs.sum / xs.size
  Math.sqrt(xs.map { |x| (x - mean)**2 }.sum / xs.size)
end

roster = <<~CSV
  name,hw1:homework:10,hw2:homework:10,hw3:homework:10,mid:exam:50,proj:project:40,final:exam:100
  Avery,9,10,8,41,35,88
  Blake,7,-,9,30,28,71
  Casey,10,10,10,48,39,95
  Devon,5,6,4,22,30,55
  Emery,8,9,-,38,-,79
  Finley,6,8,7,35,33
CSV

assignments, students = parse_roster(roster)

puts format("%-8s %6s %6s %6s %7s  %s", "student", "hw", "exam", "proj", "final", "grade")
finals = {}
students.each do |st|
  hw = category_pct(st, assignments, :homework)
  ex = category_pct(st, assignments, :exam)
  pr = category_pct(st, assignments, :project)
  f = final_pct(st, assignments)
  finals[st.name] = f
  puts format("%-8s %6.1f %6.1f %6.1f %7.2f  %s", st.name, hw, ex, pr, f, letter(f))
end

puts
puts "Missing work:"
students.each do |st|
  missing = assignments.select { |a| st.scores[a.name].nil? }
  next if missing.empty?
  puts "  #{st.name}: #{missing.map(&:name).join(", ")}"
end

puts
values = finals.values
puts format("mean %.2f  median %.2f  stddev %.2f", values.sum / values.size, median(values), stddev(values))

best_name, best = finals.max_by { |_n, f| f }
puts format("top: %s (%.2f)", best_name, best)

distribution = values.map { |f| letter(f) }.tally
puts "grades: " + distribution.keys.sort.map { |g| "#{g}=#{distribution[g]}" }.join(" ")

# curve: lift everyone so that the top score becomes 100, but never more than 8 points
bump = (100.0 - best).clamp(0.0, 8.0)
puts format("curve +%.2f", bump)
changed = finals.select { |_n, f| letter(f) != letter(f + bump) }
changed.each { |n, f| puts "  #{n}: #{letter(f)} -> #{letter(f + bump)}" }

per_assignment = assignments.map do |a|
  got = students.filter_map { |st| st.scores[a.name] }
  [a.name, got.sum / got.size / a.max_points * 100]
end
hardest, pct = per_assignment.min_by { |_n, p| p }
puts format("hardest assignment: %s (avg %.1f%%)", hardest, pct)
