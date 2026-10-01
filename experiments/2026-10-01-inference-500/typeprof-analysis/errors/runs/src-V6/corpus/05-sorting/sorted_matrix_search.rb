# Searching 2-D tables: a price table sorted along rows and columns (staircase
# search, k-th smallest by binary search on the value), and a row-major sorted
# table searched as one flat array.

def staircase_find(grid, target)
  r = 0
  c = grid[0].size - 1
  steps = 0
  while r < grid.size && c >= 0
    steps += 1
    v = grid[r][c]
    return [r, c, steps] if v == target
    if v > target
      c -= 1
    else
      r += 1
    end
  end
  [nil, nil, steps]
end

def count_at_most(grid, x)
  n = 0
  c = grid[0].size - 1
  grid.each do |row|
    c -= 1 while c >= 0 && row[c] > x
    n += c + 1
  end
  n
end

def kth_smallest(grid, k)
  lo = grid[0][0]
  hi = grid.last.last
  while lo < hi
    mid = lo + (hi - lo) / 2
    if count_at_most(grid, mid) < k
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def flat_search(table, target)
  cols = table[0].size
  lo = 0
  hi = table.size * cols - 1
  while lo <= hi
    mid = (lo + hi) / 2
    r, c = mid.divmod(cols)
    v = table[r][c]
    return [r, c] if v == target
    if v < target
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  nil
end

def ordinal(n)
  suffix = (11..13).cover?(n % 100) ? "th" : %w[th st nd rd th th th th th th][n % 10]
  "#{n}#{suffix}"
end

def show_grid(grid)
  grid.each { |row| puts "  " + row.map { |v| v.to_s.rjust(4) }.join }
end

# prices[size][topping count]: grows to the right and downwards
prices = [
  [5, 7, 9, 12, 15],
  [6, 8, 11, 14, 18],
  [9, 11, 13, 17, 21],
  [10, 14, 16, 20, 25],
  [12, 15, 19, 24, 30]
]
puts "price table:"
show_grid(prices)
sizes = %w[S M L XL XXL]
[14, 13, 4, 30, 22].each do |budget|
  r, c, steps = staircase_find(prices, budget)
  if r && c
    puts "exactly #{budget}: size #{sizes[r]} with #{c} toppings (#{steps} steps)"
  else
    puts "exactly #{budget}: none (#{steps} steps), #{count_at_most(prices, budget)} options cost at most #{budget}"
  end
end
total = prices.sum(&:size)
[1, 5, 13, total].each do |k|
  puts "#{ordinal(k)} cheapest price: #{kth_smallest(prices, k)}"
end
median = kth_smallest(prices, (total + 1) / 2)
check = prices.flatten.sort[(total + 1) / 2 - 1]
puts "median #{median} (by sorting: #{check})"

# seat numbers by row: fully sorted in row-major order
seats = [
  [101, 104, 105, 109],
  [110, 111, 115, 120],
  [121, 130, 133, 134],
  [140, 141, 150, 151]
]
[115, 101, 151, 135, 99].each do |seat|
  case flat_search(seats, seat)
  in nil then puts "seat #{seat}: not sold"
  in [row, pos] then puts "seat #{seat}: row #{row + 1}, position #{pos + 1}"
  end
end
