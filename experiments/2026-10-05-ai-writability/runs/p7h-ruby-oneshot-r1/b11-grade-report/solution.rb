def round_half_up(value, decimals = 1)
  factor = 10 ** decimals
  (value * factor + 0.5).floor / factor.to_f
end

def get_grade(percentage)
  return '-' if percentage.nil?
  if percentage >= 90.0
    'A'
  elsif percentage >= 80.0
    'B'
  elsif percentage >= 70.0
    'C'
  elsif percentage >= 60.0
    'D'
  else
    'F'
  end
end

weights = {}
students = {}
errors = []
line_num = 0

STDIN.each_line do |line|
  line_num += 1
  line = line.strip
  next if line.empty? || line.start_with?('#')

  parts = line.split

  if parts[0] == 'weight'
    if parts.size != 3
      errors << "line #{line_num}: bad format"
    else
      category = parts[1]
      w = parts[2]

      if w !~ /^\d+$/ || w.to_i < 1 || w.to_i > 100
        errors << "line #{line_num}: bad weight #{w}"
      elsif weights[category]
        errors << "line #{line_num}: duplicate category #{category}"
      else
        weights[category] = w.to_i
      end
    end
  else
    if parts.size != 3
      errors << "line #{line_num}: bad format"
    else
      student = parts[0]
      category = parts[1]
      score_str = parts[2]

      if !weights[category]
        errors << "line #{line_num}: unknown category #{category}"
      elsif score_str == 'EX'
        students[student] ||= {}
        students[student][category] ||= []
        students[student][category] << [:excused]
      elsif score_str =~ /^(-?)(\d+)\/(\d+)$/
        if $1 == ''
          p = $2.to_i
          m = $3.to_i
          if m == 0 || p > m
            errors << "line #{line_num}: bad score #{score_str}"
          else
            students[student] ||= {}
            students[student][category] ||= []
            students[student][category] << [:normal, p, m]
          end
        else
          m = $3.to_i
          if m == 0
            errors << "line #{line_num}: bad score #{score_str}"
          else
            students[student] ||= {}
            students[student][category] ||= []
            students[student][category] << [:missing, 0, m]
          end
        end
      else
        errors << "line #{line_num}: bad score #{score_str}"
      end
    end
  end
end

errors.each { |err| puts err }

student_data = {}
students.each do |student, categories|
  category_fractions = {}
  missing_count = 0

  categories.each do |cat, scores|
    points = 0
    maxima = 0

    scores.each do |score|
      type = score[0]
      if type == :excused
        # skip
      else
        p = score[1]
        m = score[2]
        points += p
        maxima += m
        if type == :missing
          missing_count += 1
        end
      end
    end

    if maxima > 0
      category_fractions[cat] = points.to_f / maxima
    end
  end

  if category_fractions.empty?
    percentage = nil
  else
    total_weight = category_fractions.keys.sum { |cat| weights[cat] }
    weighted_sum = category_fractions.sum { |cat, frac| frac * weights[cat] }
    percentage = round_half_up(weighted_sum / total_weight * 100, 1)
  end

  student_data[student] = {
    percentage: percentage,
    missing: missing_count
  }
end

with_percentage = student_data
  .select { |_, data| data[:percentage] }
  .sort_by { |_, data| [-data[:percentage], _1] }
without_percentage = student_data
  .reject { |_, data| data[:percentage] }
  .sort_by { |name, _| name }

sorted_students = with_percentage.map(&:first) + without_percentage.map(&:first)

max_name_len = [7, sorted_students.map(&:length).max || 0].max

puts "Student#{' ' * (max_name_len - 7)}  Score  G  Missing"

sorted_students.each do |student|
  data = student_data[student]
  percentage = data[:percentage]

  if percentage.nil?
    score_str = '  n/a'
  else
    score_str = format('%5.1f', percentage)
  end

  grade = get_grade(percentage)
  missing = data[:missing]

  puts "#{student.ljust(max_name_len)}  #{score_str}  #{grade}  #{missing.to_s.rjust(7)}"
end

unrounded_percentages = student_data.values
  .select { |data| data[:percentage] }
  .map { |data| data[:percentage] }

if unrounded_percentages.empty?
  puts "class average: n/a"
else
  avg = round_half_up(unrounded_percentages.sum.to_f / unrounded_percentages.length, 1)
  puts "class average: #{avg}"
end
