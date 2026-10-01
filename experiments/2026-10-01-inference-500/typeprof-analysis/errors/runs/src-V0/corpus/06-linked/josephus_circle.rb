class Seat
  attr_accessor :name, :next

  def initialize(name, nxt)
    @name = name
    @next = nxt
  end
end

def make_circle(names)
  first = nil
  last = nil
  names.each do |n|
    seat = Seat.new(n, nil)
    if last
      last.next = seat
    else
      first = seat
    end
    last = seat
  end
  last.next = first if last
  last
end

def circle_names(before_start)
  out = []
  return out if before_start.nil?
  cur = before_start.next
  loop_start = cur
  out << cur.name
  cur = cur.next
  until cur.equal?(loop_start)
    out << cur.name
    cur = cur.next
  end
  out
end

def eliminate(names, k)
  raise ArgumentError, "k must be positive, got #{k}" if k < 1
  prev = make_circle(names)
  order = []
  return [order, nil] if prev.nil?
  until prev.next.equal?(prev)
    (k - 1).times { prev = prev.next }
    out = prev.next
    order << out.name
    prev.next = out.next
  end
  [order, prev.name]
end

def josephus_formula(n, k)
  pos = 0
  (2..n).each { |m| pos = (pos + k) % m }
  pos
end

players = %w[Ada Bo Cy Di Ed Flo Gus]
puts "circle: #{circle_names(make_circle(players)).join(" -> ")} -> (back to Ada)"
[1, 2, 3, 5].each do |k|
  order, winner = eliminate(players, k)
  formula = players[josephus_formula(players.size, k)]
  puts format("k=%d out: %-30s winner: %-4s formula: %s", k, order.join(","), winner, formula)
end

soldiers = (1..41).map { |i| "s#{i}" }
order, survivor = eliminate(soldiers, 3)
puts "41 soldiers, every 3rd: last two out #{order.last.inspect} then #{survivor}"
puts "first ten out: #{order.take(10).join(" ")}"

order, winner = eliminate([], 2)
puts "empty circle: #{order.inspect} winner=#{winner.inspect}"
_, winner = eliminate(["solo"], 4)
puts "one player: winner=#{winner}"
begin
  eliminate(players, 0)
rescue ArgumentError => e
  puts "error: #{e.message}"
end

wins = Hash.new(0)
(1..12).each { |k| wins[eliminate(players, k)[1]] += 1 }
wins.sort_by { |name, n| [-n, name] }.each { |name, n| puts "  #{name}: #{n}" }
