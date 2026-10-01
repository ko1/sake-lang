# Grade book: nested Hashes of scores, weighted averages, letter grades by Float Ranges, curves, honors.

def weights = {"hw" => 0.3, "midterm" => 0.3, "final" => 0.4}

def letter_table
  [
    [90.0..100.0, "A"], [80.0...90.0, "B"], [70.0...80.0, "C"], [60.0...70.0, "D"], [0.0...60.0, "F"]
  ]
end

def letter(score)
  row = letter_table.find { |r, l| r.cover?(score) }
  row ? row[1] : "?"
end

def book
  {
    "ana" => {"hw" => [95, 88, 92, 100], "midterm" => [91], "final" => [94]},
    "bo" => {"hw" => [70, 65, 0, 80], "midterm" => [72], "final" => [68]},
    "cy" => {"hw" => [85, 90, 87], "midterm" => [79], "final" => [88]},
    "dot" => {"hw" => [100, 100, 98, 99], "midterm" => [97], "final" => [99]},
    "ed" => {"hw" => [50, 61, 58, 40], "midterm" => [55], "final" => []},
    "flo" => {"hw" => [82, 79, 91, 85], "midterm" => [84]}
  }
end

def mean(xs) = xs.empty? ? nil : xs.sum / xs.size.to_f

def hw_average(scores)
  return nil if scores.empty?
  kept = scores.size > 3 ? scores.sort.drop(1) : scores
  mean(kept)
end

def weighted(parts)
  missing = weights.keys.reject { |k| parts.key?(k) && !!parts[k]     }
  return [nil, missing] unless missing.empty?
  [weights.sum { |k, w| parts[k] * w }, missing]
end

students = book
results = students.transform_values do |cats|
  parts = cats.to_h { |cat, scores| [cat, cat == "hw" ? hw_average(scores) : mean(scores)] }
  weighted(parts)
end

puts "== Final scores =="
complete, incomplete = results.partition { |name, r| !!r[0]     }
complete.sort_by { |name, r| -r[0] }.each do |name, r|
  puts format("%-4s %6.2f %s", name, r[0], letter(r[0]))
end
incomplete.each { |name, r| puts format("%-4s incomplete (missing %s)", name, r[1].join(", ")) }

scores = complete.map { |name, r| r[0] }
avg = mean(scores)
puts format("class average: %.2f", avg)
hi = complete.max_by { |name, r| r[0] }
lo = complete.min_by { |name, r| r[0] }
puts "top: #{hi[0]}, bottom: #{lo[0]}"

dist = scores.map { |s| letter(s) }.tally
puts "distribution: #{letter_table.map { |r, l| "#{l}=#{dist.fetch(l, 0)}" }.join(" ")}"

puts "== Curve to a 90 average (capped at 100) =="
bump = [90.0 - avg, 0.0].max
complete.each do |name, r|
  curved = (r[0] + bump).clamp(0.0, 100.0)
  change = letter(r[0]) == letter(curved) ? "" : " (#{letter(r[0])} -> #{letter(curved)})"
  puts format("%-4s %6.2f%s", name, curved, change)
end

puts "== Per category =="
weights.each_key do |cat|
  all = students.values.flat_map { |cats| cats.fetch(cat, []) }
  zeros = all.count(0)
  lo, hi = all.minmax
  puts format("%-8s n=%2d min=%3d max=%3d mean=%6.2f zeros=%d", cat, all.size, lo, hi, mean(all), zeros)
end

honors = complete.select { |name, r| r[0] >= 90.0 }.map(&:first)
perfect_hw = students.select { |name, cats| cats.fetch("hw", []).all? { |s| s >= 95 } }.keys
puts "honors: #{honors.join(", ")}"
puts "hw always >= 95: #{perfect_hw.join(", ")}"
puts "needs attention: #{students.select { |n, cats| cats.fetch("hw", []).any? { |s| s < 60 } }.keys.sort.join(", ")}"
