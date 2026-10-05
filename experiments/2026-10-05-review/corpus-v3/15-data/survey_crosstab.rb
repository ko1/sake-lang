def responses
  [
    { age: 23, region: "north", answer: "yes" }, { age: 35, region: "south", answer: "no" },
    { age: 41, region: "north", answer: "yes" }, { age: 19, region: "east", answer: "unsure" },
    { age: 52, region: "south", answer: "no" }, { age: 67, region: "east", answer: "no" },
    { age: 29, region: "north", answer: "yes" }, { age: 33, region: "east", answer: "yes" },
    { age: 45, region: "south", answer: "unsure" }, { age: 58, region: "north", answer: "no" },
    { age: 71, region: "south", answer: "no" }, { age: 26, region: "south", answer: "yes" },
    { age: 38, region: "east", answer: "yes" }, { age: 62, region: "north", answer: "unsure" },
    { age: 17, region: "east", answer: "yes" }, { age: 48, region: "north", answer: "no" },
    { age: 31, region: "south", answer: "yes" }, { age: 55, region: "east", answer: "no" },
    { age: 24, region: "north", answer: "skip" }, { age: 44, region: "east", answer: "yes" }
  ]
end

def answers = %w[yes no unsure]

def age_band(age)
  if age < 18 then nil
  elsif age < 30 then "18-29"
  elsif age < 45 then "30-44"
  elsif age < 60 then "45-59"
  else "60+"
  end
end

def crosstab(rows)
  table = Hash.new(0)
  rows.each { |key, ans| table[[key, ans]] += 1 }
  table
end

def print_table(title, table, keys)
  puts title
  puts format("  %-8s", "") + answers.map { |a| format("%14s", a) }.join + format("%7s", "n")
  keys.each do |k|
    n = answers.sum { |a| table[[k, a]] }
    cells = answers.map do |a|
      c = table[[k, a]]
      format("%5d (%5.1f%%)", c, n == 0 ? 0.0 : c * 100.0 / n)
    end
    puts format("  %-8s", k) + cells.join + format("%7d", n)
  end
end

def chi_square(table, keys)
  total = table.sum { |k, v| v }
  stat = 0.0
  keys.each do |k|
    row = answers.sum { |a| table[[k, a]] }
    answers.each do |a|
      col = keys.sum { |kk| table[[kk, a]] }
      expected = row * col * 1.0 / total
      stat += (table[[k, a]] - expected) ** 2 / expected if expected > 0
    end
  end
  [stat, (keys.size - 1) * (answers.size - 1)]
end

all = responses
valid = all.select { |r| answers.include?(r[:answer]) && !age_band(r[:age]).nil? }
dropped = all.size - valid.size
puts "#{all.size} responses, #{valid.size} usable, #{dropped} dropped (minor or invalid answer)"
puts

by_region = crosstab(valid.map { |r| [r[:region], r[:answer]] })
regions = valid.map { |r| r[:region] }.uniq.sort
print_table("Answer by region", by_region, regions)
stat, dof = chi_square(by_region, regions)
puts format("  chi-square %.3f with %d degrees of freedom", stat, dof)
puts

by_age = crosstab(valid.filter_map do |r|
  band = age_band(r[:age])
  band ? [band, r[:answer]] : nil
end)
bands = by_age.keys.map { |band, a| band }.uniq.sort
print_table("Answer by age band", by_age, bands)
stat2, dof2 = chi_square(by_age, bands)
puts format("  chi-square %.3f with %d degrees of freedom", stat2, dof2)
puts

yes_rate = bands.map { |b| n = answers.sum { |a| by_age[[b, a]] }; [b, by_age[[b, "yes"]] * 1.0 / n] }
most = yes_rate.max_by { |b, r| r }
least = yes_rate.min_by { |b, r| r }
if most && least
  mb, mr = most
  lb, lr = least
  puts format("'yes' is most common in %s (%.0f%%) and least in %s (%.0f%%)", mb, mr * 100, lb, lr * 100)
end
