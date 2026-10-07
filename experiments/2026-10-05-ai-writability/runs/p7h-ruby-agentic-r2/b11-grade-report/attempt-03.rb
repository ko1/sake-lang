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

  if line.empty? || line.start_with?('#')
    next
  end

  fields = line.split

  if fields.empty?
    next
  elsif fields[0] == 'weight'
    # Weight line
    if fields.size != 3
      errors << "line #{line_num}: bad format"
    else
      category = fields[1]
      weight_str = fields[2]

      if weights.key?(category)
        errors << "line #{line_num}: duplicate category #{category}"
      elsif !weight_str.match?(/^\d+$/)
        errors << "line #{line_num}: bad weight #{weight_str}"
      else
        w = weight_str.to_i
        if w < 1 || w > 100
          errors << "line #{line_num}: bad weight #{weight_str}"
        else
          weights[category] = w
        end
      end
    end
  else
    # Score line
    if fields.size != 3
      errors << "line #{line_num}: bad format"
    else
      student = fields[0]
      category = fields[1]
      score_str = fields[2]

      if !weights.key?(category)
        errors << "line #{line_num}: unknown category #{category}"
      else
        student_scores[student] ||= {}
        student_scores[student][category] ||= []

        # Parse score
        if score_str == 'EX'
          student_scores[student][category] << ['EX', nil]
        elsif score_str.match?(/^-\/(\d+)$/)
          m = score_str.match(/^-\/(\d+)$/)[1].to_i
          student_scores[student][category] << [0, m]
        elsif score_str.match(/^(\d+)\/(\d+)$/)
          p = score_str.match(/^(\d+)\/(\d+)$/)[1].to_i
          m = score_str.match(/^(\d+)\/(\d+)$/)[2].to_i

          if m <= 0
            errors << "line #{line_num}: bad score #{score_str}"
          elsif p > m
            errors << "line #{line_num}: bad score #{score_str}"
          else
            student_scores[student][category] << [p, m]
          end
        else
          errors << "line #{line_num}: bad score #{score_str}"
        end
      end
    end
  end
end

# Output errors
errors.each { |e| puts e }

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
      if p != 'EX'
        sum_p += p
        sum_m += m
      end
    end

    if sum_m > 0
      fraction = sum_p.to_f / sum_m
      weight = weights[category]

      total_weighted_sum += fraction * weight
      total_weight += weight
      has_percentage = true
    end
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
      if p == 0 && m && m > 0
        missing += 1
      end
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
