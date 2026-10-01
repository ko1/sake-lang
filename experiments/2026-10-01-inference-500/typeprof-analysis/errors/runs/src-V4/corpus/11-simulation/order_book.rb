class Order
  attr_reader :id, :trader, :side, :price, :seq
  attr_accessor :qty

  def initialize(id, trader, side, price, qty, seq)
    @id = id
    @trader = trader
    @side = side
    @price = price
    @qty = qty
    @seq = seq
  end
end

class Trade
  attr_reader :buy_id, :sell_id, :price, :qty

  def initialize(buy_id, sell_id, price, qty)
    @buy_id = buy_id
    @sell_id = sell_id
    @price = price
    @qty = qty
  end
end

class InvalidOrder < StandardError
  attr_reader :order_id

  def initialize(message, order_id)
    super(message)
    @order_id = order_id
  end
end

class Book
  attr_reader :bids, :asks, :trades

  def initialize
    @bids = []
    @asks = []
    @trades = []
    @seq = 0
  end

  def better?(side, p1, p2) = side == :buy ? p1 > p2 : p1 < p2

  def rest(o)
    queue = o.side == :buy ? @bids : @asks
    idx = queue.find_index { |x| better?(o.side, o.price, x.price) }
    if idx
      queue.insert(idx, o)
    else
      queue << o
    end
  end

  def crosses?(o, best)
    return true if !o.price    
    o.side == :buy ? o.price >= best.price : o.price <= best.price
  end

  def submit(id, trader, side, price, qty)
    raise InvalidOrder.new("order #{id}: quantity must be positive", id) if qty <= 0
    raise InvalidOrder.new("order #{id}: bad price", id) if price && price <= 0
    @seq += 1
    o = Order.new(id, trader, side, price, qty, @seq)
    opposite = side == :buy ? @asks : @bids
    filled = 0
    while o.qty > 0
      best = opposite.first
      break if !best     || !crosses?(o, best)
      if best.trader == trader
        opposite.shift
        next
      end
      q = [o.qty, best.qty].min
      buy_id = side == :buy ? id : best.id
      sell_id = side == :sell ? id : best.id
      @trades << Trade.new(buy_id, sell_id, best.price, q)
      o.qty -= q
      best.qty -= q
      filled += q
      opposite.shift if best.qty == 0
    end
    rest(o) if o.qty > 0 && price
    [filled, o.qty]
  end

  def cancel(id)
    [@bids, @asks].each do |queue|
      idx = queue.find_index { |o| o.id == id }
      return queue.delete_at(idx) if idx
    end
    nil
  end

  def depth(queue)
    levels = Hash.new(0)
    queue.each { |o| levels[o.price] += o.qty }
    levels
  end

  def spread
    bid = @bids.first
    ask = @asks.first
    return nil if !bid     || !ask    
    ask.price - bid.price
  end
end

def show_price(p) = !p     ? "MKT" : format("%d.%02d", p / 100, p % 100)

book = Book.new
orders = [
  [:new, 1, "alpha", :sell, 10150, 100], [:new, 2, "bravo", :sell, 10100, 50],
  [:new, 3, "carol", :buy, 10000, 80], [:new, 4, "delta", :buy, 10050, 40],
  [:new, 5, "alpha", :sell, 10100, 30], [:new, 6, "echo", :buy, 10100, 60],
  [:cancel, 3, "", :buy, 0, 0], [:new, 7, "bravo", :buy, nil, 120],
  [:new, 8, "carol", :sell, 9900, 0], [:new, 9, "delta", :sell, 10050, 70],
  [:new, 10, "echo", :buy, 10200, 90], [:new, 11, "alpha", :buy, 10180, 25],
  [:new, 12, "alpha", :sell, 10180, 40], [:cancel, 99, "", :buy, 0, 0],
  [:new, 13, "fox", :sell, nil, 10], [:new, 14, "gus", :buy, 9950, 15]
]

orders.each do |action, id, trader, side, price, qty|
  if action == :cancel
    removed = book.cancel(id)
    puts(removed ? "cancel ##{id}: removed #{removed.qty} left" : "cancel ##{id}: not found")
    next
  end
  begin
    filled, left = book.submit(id, trader, side, price, qty)
    status = left == 0 ? "filled" : (!price     ? "unfilled #{left} dropped" : "resting #{left}")
    puts format("#%-2d %-5s %-4s %3d @ %-6s -> traded %3d, %s", id, trader, side, qty, show_price(price), filled, status)
  rescue InvalidOrder => e
    puts "rejected: #{e.message}"
  end
end

puts "--- trades"
trades = book.trades
trades.each do |t|
  puts format("buy #%-2d sell #%-2d %3d @ %s", t.buy_id, t.sell_id, t.qty, show_price(t.price))
end
volume = trades.sum(&:qty)
notional = trades.sum { |t| t.qty * t.price }
puts format("volume %d, vwap %.4f", volume, notional / 100.0 / volume) if volume > 0
puts "--- book"
asks = book.depth(book.asks)
asks.keys.sort.reverse_each { |p| puts format("  ask %s x %d", show_price(p), asks[p]) }
bids = book.depth(book.bids)
bids.keys.sort.reverse_each { |p| puts format("  bid %s x %d", show_price(p), bids[p]) }
sp = book.spread
puts(sp ? "spread #{show_price(sp)}" : "spread n/a (one side empty)")
