require 'bigdecimal'

weights = {}
students = {}
errors = []
line_num = 0

STDIN.each_line do |line|
  line_num += 1
  line = line.strip
  next if line.empty? || line.start_with?('#')

  fields = line.split

  if fields[0] == 'weight'
    if fields.size != 3
      errors << "line #{line_num}: bad format"
      next
    end
    category = fields[1]
    w = fields[2]

    if w !~ /^\d+$/ || w.to_i < 1 || w.to_i > 100
      errors << "line #{line_num}: bad weight #{w}"
      next
    end

    if weights.key?(category)
      errors << "line #{line_num}: duplicate category #{category}"
      next
    end

    weights[category] = w.to_i
  else
    if fields.size != 3
      errors << "line #{line_num}: bad format"
      next
    end

    student = fields[0]
    category = fields[1]
    score_str = fields[2]

    students[student] ||= { scores: {}, missing: 0 }

    if !weights.key?(category)
      errors << "line #{line_num}: unknown category #{category}"
      next
    end

    if score_str == 'EX'
      students[student][:scores][category] ||= []
      students[student][:scores][category] << { p: nil, m: nil, excused: true }
    elsif score_str =~ /^-\/(\d+)$/
      m_val = $1.to_i
      if m_val == 0
        errors << "line #{line_num}: bad score #{score_str}"
        next
      end
      students[student][:scores][category] ||= []
      students[student][:scores][category] << { p: 0, m: m_val, excused: false }
      students[student][:missing] += 1
    elsif score_str =~ /^(\d+)\/(\d+)$/
      p_val = $1.to_i
      m_val = $2.to_i

      if m_val == 0
        errors << "line #{line_num}: bad score #{score_str}"
        next
      end

      if p_val > m_val
        errors << "line #{line_num}: bad score #{score_str}"
        next
      end

      students[student][:scores][category] ||= []
      students[student][:scores][category] << { p: p_val, m: m_val, excused: false }
    else
      errors << "line #{line_num}: bad score #{score_str}"
    end
  end
end

errors.each { |e| puts e }

# Calculate percentages and grades
results = []
total_percentage = 0.0
count_with_percentage = 0

students.each do |name, data|
  category_fractions = {}
  missing = data[:missing]

  weights.each do |category, weight|
    scores = data[:scores][category] || []
    valid_scores = scores.reject { |s| s[:excused] }

    if valid_scores.empty?
      next
    end

    total_p = valid_scores.sum { |s| s[:p] }
    total_m = valid_scores.sum { |s| s[:m] }

    if total_m > 0
      category_fractions[category] = BigDecimal(total_p) / BigDecimal(total_m)
    end
  end

  if category_fractions.empty?
    results << {
      name: name,
      percentage: nil,
      grade: '-',
      missing: missing
    }
  else
    weighted_sum = BigDecimal(0)
    weight_sum = 0

    category_fractions.each do |category, fraction|
      weight = weights[category]
      weighted_sum += fraction * weight
      weight_sum += weight
    end

    percentage = (weighted_sum / weight_sum * 100).to_f
    total_percentage += percentage
    count_with_percentage += 1

    rounded = (percentage * 10).round.to_f / 10

    grade = case rounded
            when 90.0..Float::INFINITY
              'A'
            when 80.0..89.9
              'B'
            when 70.0..79.9
              'C'
            when 60.0..69.9
              'D'
            else
              'F'
            end

    results << {
      name: name,
      percentage: percentage,
      rounded: rounded,
      grade: grade,
      missing: missing
    }
  end
end

max_name_len = [7, students.keys.map(&:length).max || 0].max

header = "Student#{' ' * (max_name_len - 7)}  Score  G  Missing"
puts header

with_percentage = results.select { |r| r[:percentage] }
without_percentage = results.select { |r| !r[:percentage] }

with_percentage.sort_by { |r| [-r[:rounded], r[:name]] }.each do |r|
  name_pad = ' ' * (max_name_len - r[:name].length)
  score_str = sprintf("%.1f", r[:rounded])
  missing_str = r[:missing].to_s.rjust(7)
  puts "#{r[:name]}#{name_pad}  #{score_str.rjust(5)}  #{r[:grade]}  #{missing_str}"
end

without_percentage.sort_by { |r| r[:name] }.each do |r|
  name_pad = ' ' * (max_name_len - r[:name].length)
  missing_str = r[:missing].to_s.rjust(7)
  puts "#{r[:name]}#{name_pad}    n/a  -  #{missing_str}"
end

if count_with_percentage > 0
  avg = total_percentage / count_with_percentage
  avg_rounded = (avg * 10).round.to_f / 10
  puts "class average: #{sprintf('%.1f', avg_rounded)}"
else
  puts "class average: n/a"
end
