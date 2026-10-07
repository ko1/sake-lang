#!/usr/bin/env ruby

def round_half_up(value, decimals = 1)
  factor = 10 ** decimals
  (value * factor).round / factor.to_f
end

weights = {}
scores = {}
errors = {}
line_num = 0

STDIN.each_line do |line|
  line_num += 1
  stripped = line.strip
  next if stripped.empty? || stripped.start_with?('#')

  fields = stripped.split

  if fields[0] == 'weight'
    if fields.length != 3
      errors[line_num] = 'bad format'
    elsif fields[2] !~ /^\d+$/
      errors[line_num] = "bad weight #{fields[2]}"
    else
      w = fields[2].to_i
      if w < 1 || w > 100
        errors[line_num] = "bad weight #{fields[2]}"
      elsif weights[fields[1]]
        errors[line_num] = "duplicate category #{fields[1]}"
      else
        weights[fields[1]] = w
      end
    end
  else
    if fields.length != 3
      errors[line_num] = 'bad format'
    else
      student, category, score_str = fields
      if !weights[category]
        errors[line_num] = "unknown category #{category}"
      elsif score_str == 'EX' || score_str == '-'
        scores[student] ||= {}
        scores[student][category] ||= []
        scores[student][category] << score_str
      elsif score_str =~ %r{^(\d+)/(\d+)$}
        p, m = $1.to_i, $2.to_i
        if m <= 0 || p > m
          errors[line_num] = "bad score #{score_str}"
        else
          scores[student] ||= {}
          scores[student][category] ||= []
          scores[student][category] << [p, m]
        end
      else
        errors[line_num] = "bad score #{score_str}"
      end
    end
  end
end

# Output errors
errors.sort.each do |line, error|
  puts "line #{line}: #{error}"
end

# Calculate percentages
students = {}
scores.each do |student, categories|
  total_points = 0
  total_max = 0
  missing = 0

  categories.each do |category, entries|
    next unless weights[category]

    points = 0
    max_val = 0
    has_entry = false

    entries.each do |entry|
      if entry == 'EX'
        # ignored
      elsif entry == '-'
        # missing, counts as 0/0 (doesn't count)
        missing += 1
      else
        p, m = entry
        points += p
        max_val += m
        has_entry = true
      end
    end

    if has_entry && max_val > 0
      total_points += points
      total_max += max_val
    elsif entries.any? { |e| e == '-' && entries.all? { |e| e == '-' || e == 'EX' } }
      # All entries for this category are missing or excused
      if entries.any? { |e| e == '-' }
        # has at least one missing
      end
    end
  end

  if total_max > 0
    fraction = total_points.to_f / total_max
    weighted_sum = 0
    weight_total = 0

    categories.each do |category, entries|
      next unless weights[category]

      points = 0
      max_val = 0
      has_entry = false

      entries.each do |entry|
        if entry == 'EX'
          # ignored
        elsif entry == '-'
          # missing, counts as 0
        else
          p, m = entry
          points += p
          max_val += m
          has_entry = true
        end
      end

      if has_entry && max_val > 0
        frac = points.to_f / max_val
        weighted_sum += frac * weights[category]
        weight_total += weights[category]
      end
    end

    if weight_total > 0
      percentage = (weighted_sum / weight_total) * 100
      students[student] = { percentage: percentage, missing: missing }
    else
      students[student] = { missing: missing }
    end
  else
    students[student] = { missing: missing }
  end
end

# Count missing entries
students.each do |student, data|
  missing_count = 0
  scores[student] ||= {}
  scores[student].each do |category, entries|
    next unless weights[category]
    entries.each do |entry|
      missing_count += 1 if entry == '-'
    end
  end
  data[:missing] = missing_count
end

# Sort students
with_percentage = students.select { |_, d| d[:percentage] }.sort do |a, b|
  pct_cmp = b[1][:percentage] <=> a[1][:percentage]
  pct_cmp == 0 ? a[0] <=> b[0] : pct_cmp
end

without_percentage = students.select { |_, d| !d[:percentage] }.sort { |a, b| a[0] <=> b[0] }

sorted_students = (with_percentage + without_percentage).map { |name, _| name }

# Calculate column width
max_width = [7, sorted_students.map(&:length).max || 0].max

# Output header
puts "Student#{' ' * (max_width - 7)}  Score  G  Missing"

# Output rows
sorted_students.each do |student|
  data = students[student]
  name_part = student.ljust(max_width)

  if data[:percentage]
    pct = round_half_up(data[:percentage], 1)
    grade = if pct >= 90.0
              'A'
            elsif pct >= 80.0
              'B'
            elsif pct >= 70.0
              'C'
            elsif pct >= 60.0
              'D'
            else
              'F'
            end
    score_part = format('%5.1f', pct)
  else
    score_part = '  n/a'
    grade = '-'
  end

  missing_part = data[:missing].to_s.rjust(7)

  puts "#{name_part}  #{score_part}  #{grade}  #{missing_part}"
end

# Class average
percentages = students.select { |_, d| d[:percentage] }.map { |_, d| d[:percentage] }
if percentages.any?
  avg = percentages.sum / percentages.length
  avg_rounded = round_half_up(avg, 1)
  puts "class average: #{avg_rounded}"
else
  puts "class average: n/a"
end
