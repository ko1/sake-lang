class Search
  attr_reader :n, :solutions, :nodes

  def initialize(n, solutions, nodes)
    @n = n
    @solutions = solutions
    @nodes = nodes
  end

  def self.count(n)
    s = new(n, 0, 0)
    s.place(0, 0, 0, 0)
    s
  end

  # cols / diag1 / diag2 are bitmasks of attacked columns for the current row
  def place(row, cols, diag1, diag2)
    @nodes += 1
    if row == @n
      @solutions += 1
      return
    end
    full = (1 << @n) - 1
    free = full & ~(cols | diag1 | diag2)
    while free != 0
      bit = free & -free
      free ^= bit
      place(row + 1, cols | bit, ((diag1 | bit) << 1) & full, (diag2 | bit) >> 1)
    end
  end
end

def safe?(queens, row, col)
  queens.each_with_index.none? { |c, r| c == col || (c - col).abs == (r - row).abs }
end

def first_solution(n, queens)
  row = queens.size
  return queens.dup if row == n
  n.times do |col|
    next unless safe?(queens, row, col)
    queens.push(col)
    found = first_solution(n, queens)
    return found if found
    queens.pop
  end
  nil
end

def board(queens)
  n = queens.size
  queens.map { |col| (0...n).map { |c| c == col ? "Q" : "." }.join(" ") }
end

def symmetric?(queens)
  n = queens.size
  queens.map { |c| n - 1 - c } == queens.reverse
end

puts " n  solutions   nodes"
totals = {}
(1..8).each do |n|
  s = Search.count(n)
  totals[n] = s.solutions
  puts format("%2d %10d %7d", n, s.solutions, s.nodes)
end

best = totals.max_by { |_n, count| count }
if best
  n, count = best
  puts "most solutions: n=#{n} (#{count})"
end
puts "unsolvable sizes: #{totals.select { |_n, count| count == 0 }.keys.join(", ")}"

[3, 5, 6, 8].each do |n|
  q = first_solution(n, [])
  if q
    puts "first solution for n=#{n}: #{q.join(" ")}#{symmetric?(q) ? " (point-symmetric)" : ""}"
    board(q).each { |line| puts "  #{line}" }
  else
    puts "first solution for n=#{n}: none"
  end
end
