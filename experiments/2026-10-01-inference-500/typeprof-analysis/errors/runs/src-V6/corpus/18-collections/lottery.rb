# Lottery checker: tickets and draws as Sets, prize tiers from match counts, hot and cold numbers.

def prize_table = {6 => "jackpot", 5 => "second", 4 => "third", 3 => "fourth"}

def draws
  [
    [Set[3, 11, 19, 27, 34, 45], 8],
    [Set[1, 11, 22, 27, 38, 41], 19],
    [Set[5, 11, 19, 30, 34, 49], 2],
    [Set[7, 14, 21, 28, 35, 42], 11]
  ]
end

def tickets
  {
    "amy" => [Set[3, 11, 19, 27, 34, 40], Set[1, 2, 3, 4, 5, 6]],
    "ben" => [Set[5, 11, 19, 30, 34, 2]],
    "cat" => [Set[7, 14, 21, 28, 35, 49], Set[11, 19, 27, 34, 45, 3]],
    "dan" => [Set[10, 20, 30, 40, 44, 48], Set[6, 5, 4, 3, 2, 1]]
  }
end

def check(ticket, draw, bonus)
  hits = (ticket & draw).size
  tier = prize_table[hits]
  tier = "second+bonus" if hits == 5 && ticket.include?(bonus)
  [hits, tier]
end

results = Hash.new(0)
draws.each_with_index do |(draw, bonus), i|
  puts "draw #{i + 1}: #{draw.sort.join(" ")} + #{bonus}"
  tickets.each do |name, list|
    list.each_with_index do |t, j|
      hits, tier = check(t, draw, bonus)
      next unless tier
      results[tier] += 1
      puts "  #{name} ticket #{j + 1}: #{hits} hits -> #{tier} (#{(t & draw).sort.join(",")})"
    end
  end
end
puts "prizes: #{results.map { |tier, n| "#{tier}=#{n}" }.join(" ")}"

all_drawn = draws.flat_map { |draw, _| draw.to_a }
freq = all_drawn.tally
top = freq.values.max
hot = freq.select { |n, c| c == top }.keys.sort
puts "hottest: #{hot.join(" ")} (#{top} times)"
never = (1..49).reject { |n| freq.key?(n) }
puts "never drawn: #{never.size} numbers, lowest #{never.take(5).join(" ")}"
by_decade = all_drawn.map { |n| n / 10 * 10 }.tally
puts "by decade: #{by_decade.keys.sort.map { |d| "#{d}s:#{by_decade[d]}" }.join(" ")}"

puts "== Ticket quality =="
tickets.each do |name, list|
  best = list.max_by { |t| draws.sum { |draw, _| (t & draw).size } }
  total = draws.sum { |draw, _| (best & draw).size }
  odd = best.count(&:odd?)
  span = best.max - best.min
  puts format("  %-3s best ticket %-20s total hits %2d, odd %d, span %d", name, best.sort.join(","), total, odd, span)
end
same = tickets.values.flatten.combination(2).select { |a, b| a == b }
puts "identical tickets: #{same.size}"
