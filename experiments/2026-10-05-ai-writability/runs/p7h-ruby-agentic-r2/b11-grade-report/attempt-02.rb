#!/usr/bin/env ruby

def round_half_up(value, decimals = 1)
  factor = 10 ** decimals
  ((value * factor).round(half: :up) / factor.to_f)
end

def get_grade(percentage)
  return '-' if percentage.nil?
  case percentage
  when 90.0..Float::INFINITY
    'A'
  when 80.0...90.0
    'B'
  when 70.0...80.0
    'C'
  when 60.0...70.0
    'D'
  else
    'F'
  end
end

# Read input
lines = STDIN.readlines.map(&:strip)

# Parse weights and scores
weights = {}
student_scores = {}  # {student => {category => [(p, m), ...]}}
errors = []

lines.each_with_index do |line, idx|
  line_num = idx + 1

  next if line.empty? || line.start_with?('#')

  fields = line.split

  if fields[0] == 'weight'
    if fields.size != 3
      errors << [line_num, 'bad format']
      next
    end

    category = fields[1]
    weight_str = fields[2]

    unless weight_str.match?(/^\d+$/)
      errors << [line_num, "bad weight #{weight_str}"]
      next
    end

    w = weight_str.to_i
    unless (1..100).include?(w)
      errors << [line_num, "bad weight #{weight_str}"]
      next
    end

    if weights.key?(category)
      errors << [line_num, "duplicate category #{category}"]
      next
    end

    weights[category] = w
  else
    if fields.size != 3
      errors << [line_num, 'bad format']
      next
    end

    student = fields[0]
    category = fields[1]
    score_str = fields[2]

    unless weights.key?(category)
      errors << [line_num, "unknown category #{category}"]
      next
    end

    student_scores[student] ||= {}
    student_scores[student][category] ||= []

    # Parse score
    if score_str == 'EX'
      student_scores[student][category] << ['EX', nil]
    elsif score_str.match?(%r{^-/(\d+)$})
      m = $1.to_i
      student_scores[student][category] << [0, m]
    elsif score_str.match?(%r{^(\d+)/(\d+)$})
      p = $1.to_i
      m = $2.to_i

      if m <= 0
        errors << [line_num, "bad score #{score_str}"]
        next
      end

      if p > m
        errors << [line_num, "bad score #{score_str}"]
        next
      end

      student_scores[student][category] << [p, m]
    else
      errors << [line_num, "bad score #{score_str}"]
      next
    end
  end
end

# Output errors
errors.each do |line_num, error|
  puts "line #{line_num}: #{error}"
end

# Compute percentages and other data
student_data = {}

student_scores.each do |student, categories|
  total_weighted_sum = 0.0
  total_weight = 0
  has_percentage = false

  categories.each do |category, score_list|
    # Check if category has any counted entries
    sum_p = 0
    sum_m = 0

    score_list.each do |p, m|
      next if p == 'EX'  # EX entries are ignored
      sum_p += p
      sum_m += m
    end

    next if sum_m == 0  # No counted entries in this category

    fraction = sum_p.to_f / sum_m
    weight = weights[category]

    total_weighted_sum += fraction * weight
    total_weight += weight
    has_percentage = true
  end

  if has_percentage
    percentage = round_half_up((total_weighted_sum / total_weight) * 100, 1)
  else
    percentage = nil
  end

  # Count missing entries (entries where P is 0 and M > 0)
  missing = 0
  categories.each do |category, score_list|
    score_list.each do |p, m|
      missing += 1 if p == 0 && m && m > 0
    end
  end

  student_data[student] = {
    percentage: percentage,
    grade: get_grade(percentage),
    missing: missing
  }
end

# Sort students
students_with_percentage = []
students_without_percentage = []

student_data.each do |student, data|
  if data[:percentage]
    students_with_percentage << [student, data[:percentage]]
  else
    students_without_percentage << student
  end
end

students_with_percentage.sort! { |a, b|
  if a[1] != b[1]
    b[1] <=> a[1]  # descending by percentage
  else
    a[0] <=> b[0]  # ascending by name
  end
}

students_without_percentage.sort!

# Compute column width
max_name_len = [student_data.keys.map(&:length).max || 0, 7].max

# Output header
puts "Student" + " " * (max_name_len - 7) + "  Score  G  Missing"

# Output rows
students_with_percentage.each do |student, percentage|
  data = student_data[student]
  name_part = student.ljust(max_name_len)
  score_part = format("%5.1f", percentage)
  grade_part = data[:grade]
  missing_part = format("%7d", data[:missing])

  puts "#{name_part}  #{score_part}  #{grade_part}  #{missing_part}"
end

students_without_percentage.each do |student|
  data = student_data[student]
  name_part = student.ljust(max_name_len)
  grade_part = data[:grade]
  missing_part = format("%7d", data[:missing])

  puts "#{name_part}    n/a  #{grade_part}  #{missing_part}"
end

# Compute class average
percentages = student_data.values.select { |data| data[:percentage] }.map { |data| data[:percentage] }

if percentages.any?
  avg = percentages.sum / percentages.length
  avg_rounded = round_half_up(avg, 1)
  puts "class average: #{avg_rounded}"
else
  puts "class average: n/a"
end
