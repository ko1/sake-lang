class Trade
  attr_reader :buy_day, :sell_day, :buy_price, :sell_price

  def initialize(buy_day, sell_day, buy_price, sell_price)
    @buy_day = buy_day
    @sell_day = sell_day
    @buy_price = buy_price
    @sell_price = sell_price
  end

  def gain = @sell_price - @buy_price
  def to_s = "buy d#{@buy_day}@#{@buy_price} sell d#{@sell_day}@#{@sell_price} (+#{gain})"
end

# at most k transactions; profit[t][d] = best profit using t trades within days 0..d
def best_with_k(prices, k)
  n = prices.size
  return { profit: 0, trades: [] } if n < 2 || k == 0
  profit = Array.new(k + 1) { Array.new(n, 0) }
  1.upto(k) do |t|
    hold = profit[t - 1][0] - prices[0]
    1.upto(n - 1) do |d|
      profit[t][d] = [profit[t][d - 1], prices[d] + hold].max
      hold = [hold, profit[t - 1][d] - prices[d]].max
    end
  end
  trades = []
  t = k
  d = n - 1
  while t > 0 && d > 0
    if profit[t][d] == profit[t][d - 1]
      d -= 1
      next
    end
    # find the buy day b that explains profit[t][d]
    b = (0..(d - 1)).find { |b| profit[t - 1][b] - prices[b] + prices[d] == profit[t][d] }
    trades.unshift(Trade.new(b, d, prices[b], prices[d]))
    t -= 1
    d = b
  end
  { profit: profit[k][n - 1], trades: trades }
end

# unlimited trades, one day of rest after each sale
def best_with_cooldown(prices)
  hold = nil
  sold = 0
  rest = 0
  prices.each do |p|
    prev_sold = sold
    sold = !hold     ? 0 : hold + p
    hold = [hold, rest - p].compact.max
    rest = [rest, prev_sold].max
  end
  [sold, rest].max
end

# unlimited trades, a fee per completed trade
def best_with_fee(prices, fee)
  cash = 0
  hold = -prices[0]
  prices.drop(1).each do |p|
    cash = [cash, hold + p - fee].max
    hold = [hold, cash - p].max
  end
  cash
end

markets = {
  "steady" => [3, 2, 6, 5, 0, 3],
  "volatile" => [1, 7, 2, 9, 3, 8, 1, 10, 4, 6],
  "falling" => [9, 8, 7, 5, 4, 2],
  "single" => [5],
  "swings" => [2, 4, 1, 7, 5, 11, 3, 9, 6, 14, 8, 12]
}

markets.each do |name, prices|
  puts "#{name}: #{prices.join(" ")}"
  [1, 2, 3].each do |k|
    best_with_k(prices, k) => { profit:, trades: }
    puts "  k=#{k}: profit #{profit}"
    trades.each { |t| puts "    #{t}" }
    total = trades.sum(&:gain)
    puts "    MISMATCH #{total}" if total != profit
  end
  if prices.size > 1
    puts "  cooldown: #{best_with_cooldown(prices)}, fee 2: #{best_with_fee(prices, 2)}"
  end
end

swings = markets["swings"]
puts "profit by number of trades (swings):"
(0..6).each do |k|
  best_with_k(swings, k) => { profit: }
  puts format("  %d %3d %s", k, profit, "#" * (profit / 2))
end
