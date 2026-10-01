# worst-case number of drops with `eggs` eggs and `floors` floors
def drops_table(eggs, floors)
  t = Array.new(eggs + 1) { Array.new(floors + 1, 0) }
  first = Array.new(eggs + 1) { Array.new(floors + 1, 0) }
  1.upto(floors) do |f|
    t[1][f] = f
    first[1][f] = 1
  end
  2.upto(eggs) do |e|
    1.upto(floors) do |f|
      best = nil
      1.upto(f) do |x|
        worst = 1 + [t[e - 1][x - 1], t[e][f - x]].max
        if best.nil? || worst < best
          best = worst
          first[e][f] = x
        end
      end
      t[e][f] = best
    end
  end
  [t, first]
end

# the other view: how many floors can d drops with e eggs cover?
def floors_covered(eggs, drops)
  cover = Array.new(eggs + 1, 0)
  drops.times do
    eggs.downto(1) { |e| cover[e] = cover[e] + cover[e - 1] + 1 }
  end
  cover[eggs]
end

def min_drops_by_cover(eggs, floors)
  d = 0
  d += 1 while floors_covered(eggs, d) < floors
  d
end

# play the strategy against a building whose critical floor is `critical`
def simulate(table, first, eggs, floors, critical)
  low = 0
  remaining = floors
  log = []
  while remaining > 0
    x = first[eggs][remaining]
    floor = low + x
    if floor > critical
      log << "#{floor}:break"
      eggs -= 1
      remaining = x - 1
    else
      log << "#{floor}:ok"
      low = floor
      remaining -= x
    end
  end
  [low, log]
end

floors = 36
table, first = drops_table(3, floors)
puts "worst-case drops for #{floors} floors:"
(1..3).each do |e|
  puts "  #{e} egg(s): #{table[e][floors]} drops (first drop from floor #{first[e][floors]})"
end

puts "table (eggs x floors):"
columns = [1, 2, 5, 10, 20, 36]
puts "     " + columns.map { |f| f.to_s.rjust(4) }.join
(1..3).each do |e|
  puts "  e#{e} " + columns.map { |f| table[e][f].to_s.rjust(4) }.join
end

puts "simulations with 2 eggs:"
[0, 7, 8, 20, 35, 36].each do |critical|
  found, log = simulate(table, first, 2, floors, critical)
  status = found == critical ? "found" : "WRONG"
  puts format("  critical %2d -> %2d %s in %d drops: %s", critical, found, status, log.size, log.join(" "))
end

puts "larger buildings via coverage:"
[[2, 100], [3, 100], [2, 1000], [4, 5000], [10, 1000000]].each do |eggs, n|
  d = min_drops_by_cover(eggs, n)
  puts format("  %2d eggs, %7d floors: %2d drops (covers %d)", eggs, n, d, floors_covered(eggs, d))
end
