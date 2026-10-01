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

def weights = { "homework" => 0.3, "quiz" => 0.2, "exam" => 0.5 }

def assignments
  [
    Assignment.new("HW1", "homework", 20), Assignment.new("HW2", "homework", 20),
    Assignment.new("HW3", "homework", 25), Assignment.new("Q1", "quiz", 10),
    Assignment.new("Q2", "quiz", 10), Assignment.new("Midterm", "exam", 100),
    Assignment.new("Final", "exam", 150)
  ]
end

def students
  [
    Student.new("Avery", { "HW1" => 18, "HW2" => 20, "HW3" => 22, "Q1" => 9, "Q2" => 8, "Midterm" => 88, "Final" => 131 }),
    Student.new("Blake", { "HW1" => 15, "HW2" => 12, "Q1" => 6, "Q2" => 7, "Midterm" => 71, "Final" => 102 }),
    Student.new("Casey", { "HW1" => 20, "HW2" => 19, "HW3" => 25, "Q1" => 10, "Q2" => 10, "Midterm" => 95, "Final" => 144 }),
    Student.new("Devon", { "HW1" => 10, "HW2" => 14, "HW3" => 12, "Q1" => 5, "Midterm" => 58, "Final" => 80 }),
    Student.new("Emery", { "HW1" => 19, "HW2" => 17, "HW3" => 21, "Q1" => 8, "Q2" => 9, "Midterm" => 79, "Final" => 120 }),
    Student.new("Finley", { "HW1" => 20, "HW2" => 20, "HW3" => 24, "Q1" => 9, "Q2" => 10, "Midterm" => 91, "Final" => 139 }),
    Student.new("Gray", { "HW2" => 8, "Q1" => 3, "Q2" => 4, "Midterm" => 42 })
  ]
end

def category_percent(student, category, items)
  in_cat = items.select { |a| a.category == category }
  earned = in_cat.sum { |a| student.scores.fetch(a.name, 0) }
  possible = in_cat.sum(&:max_points)
  earned * 100.0 / possible
end

def weighted(student, items)
  weights.sum { |cat, w| category_percent(student, cat, items) * w }
end

def letter(pct)
  if pct >= 90 then "A"
  elsif pct >= 80 then "B"
  elsif pct >= 70 then "C"
  elsif pct >= 60 then "D"
  else "F"
  end
end

def mean(xs) = xs.sum / xs.size

def stddev(xs)
  m = mean(xs)
  Math.sqrt(xs.sum { |x| (x - m) ** 2 } / xs.size)
end

def competition_ranks(scores)
  sorted = scores.sort_by { |name, s| -s }
  ranks = {}
  prev = nil
  rank = 0
  sorted.each_with_index do |(name, s), i|
    rank = i + 1 if !prev     || s.round(1) != prev.round(1)
    ranks[name] = rank
    prev = s
  end
  ranks
end

items = assignments
roster = students
finals = roster.map { |s| [s.name, weighted(s, items)] }
ranks = competition_ranks(finals)

puts format("%-7s %8s %8s %8s %8s  %s  %s", "Student", "HW", "Quiz", "Exam", "Final", "Grade", "Rank")
roster.each do |s|
  hw = category_percent(s, "homework", items)
  qz = category_percent(s, "quiz", items)
  ex = category_percent(s, "exam", items)
  total = weighted(s, items)
  puts format("%-7s %7.1f%% %7.1f%% %7.1f%% %7.1f%%    %s    %d", s.name, hw, qz, ex, total, letter(total), ranks[s.name])
end

puts
totals = finals.map { |n, t| t }
puts format("class mean %.2f, stddev %.2f, high %.2f, low %.2f", mean(totals), stddev(totals), totals.max, totals.min)
dist = totals.map { |t| letter(t) }.tally
"ABCDF".each_char do |g|
  n = dist.fetch(g, 0)
  puts format("  %s %-8s %d", g, "*" * n, n)
end

puts
puts "Missing work:"
roster.each do |s|
  missing = items.reject { |a| s.scores.key?(a.name) }
  next if missing.empty?
  puts "  #{s.name}: #{missing.map(&:name).join(", ")}"
end

puts
puts "Hardest assignment by average percent:"
avg_by = items.map do |a|
  got = roster.filter_map { |s| s.scores[a.name] }
  [a.name, mean(got) * 100.0 / a.max_points, got.size]
end
avg_by.sort_by { |n, pct, c| pct }.first(3).each do |n, pct, c|
  puts format("  %-8s %5.1f%% (%d submitted)", n, pct, c)
end
