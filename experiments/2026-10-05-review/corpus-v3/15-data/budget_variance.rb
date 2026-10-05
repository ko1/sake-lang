def budget
  {
    "Marketing" => { "ads" => 40000, "events" => 15000, "swag" => 3000 },
    "Engineering" => { "cloud" => 60000, "tools" => 12000, "training" => 8000 },
    "Support" => { "tools" => 6000, "training" => 4000 }
  }
end

def transactions
  [
    ["Marketing", "ads", 18250], ["Marketing", "ads", 24400], ["Marketing", "events", 9100],
    ["Marketing", "swag", 3900], ["Engineering", "cloud", 31000], ["Engineering", "cloud", 27750],
    ["Engineering", "tools", 4300], ["Engineering", "conferences", 5200], ["Support", "tools", 6150],
    ["Support", "training", 900], ["Engineering", "training", 2500], ["Legal", "outside counsel", 12000]
  ]
end

def status(budgeted, actual)
  return "UNBUDGETED" if budgeted == 0
  ratio = actual * 1.0 / budgeted
  if ratio > 1.05 then "OVER"
  elsif ratio < 0.5 then "under"
  else "ok"
  end
end

actuals = Hash.new(0)
transactions.each { |dept, line, amt| actuals[[dept, line]] += amt }

plan = budget
lines = []
plan.each { |dept, items| items.each_key { |line| lines << [dept, line] } }
actuals.each_key { |key| lines << key unless lines.include?(key) }

puts format("%-12s %-16s %9s %9s %9s %7s  %s", "dept", "line", "budget", "actual", "variance", "used", "status")
lines.group_by { |dept, line| dept }.each do |dept, keys|
  dept_budget = 0
  dept_actual = 0
  keys.each do |key|
    d, line = key
    b = plan.dig(d, line) || 0
    a = actuals[key]
    dept_budget += b
    dept_actual += a
    used = b == 0 ? "-" : format("%.0f%%", a * 100.0 / b)
    puts format("%-12s %-16s %9d %9d %+9d %7s  %s", d, line, b, a, a - b, used, status(b, a))
  end
  puts format("%-12s %-16s %9d %9d %+9d", "", "subtotal", dept_budget, dept_actual, dept_actual - dept_budget)
end

total_b = plan.sum { |d, items| items.values.sum }
total_a = actuals.values.sum
puts
puts format("TOTAL budget %d, actual %d, variance %+d (%.1f%% of budget)", total_b, total_a, total_a - total_b, total_a * 100.0 / total_b)
over = lines.select { |(d, l)| status(plan.dig(d, l) || 0, actuals[[d, l]]) == "OVER" }
puts "Over budget: #{over.map { |d, l| "#{d}/#{l}" }.join(", ")}"
