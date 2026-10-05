class Product
  attr_accessor :name, :price, :stock

  def initialize(name, price, stock)
    @name = name
    @price = price
    @stock = stock
  end
end

class VendError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

ACCEPTED_COINS = [100, 25, 10, 5]

class Machine
  attr_reader :state, :credit, :products, :coins, :sales, :log

  def initialize(products)
    @state = :idle
    @credit = 0
    @products = products
    @coins = Hash.new(0)
    ACCEPTED_COINS.each { |c| @coins[c] = 4 }
    @sales = 0
    @log = []
  end

  def note(msg)
    @log << msg
  end

  def insert(coin)
    raise VendError.new("coin #{coin} rejected", :bad_coin) unless ACCEPTED_COINS.include?(coin)
    @credit += coin
    @coins[coin] += 1
    @state = :collecting
    note("credit #{@credit}")
  end

  def make_change(amount)
    change = []
    remaining = amount
    ACCEPTED_COINS.each do |c|
      while remaining >= c && @coins[c] > 0
        @coins[c] -= 1
        remaining -= c
        change << c
      end
    end
    if remaining > 0
      change.each { |c| @coins[c] += 1 }
      raise VendError.new("cannot make change for #{amount}", :no_change)
    end
    change
  end

  def select(slot)
    product = @products[slot]
    raise VendError.new("unknown slot #{slot}", :bad_slot) if product.nil?
    raise VendError.new("#{product.name} sold out", :sold_out) if product.stock == 0
    price = product.price
    if @credit < price
      raise VendError.new("need #{price - @credit} more for #{product.name}", :short)
    end
    @state = :dispensing
    change = make_change(@credit - price)
    product.stock -= 1
    @sales += price
    @credit = 0
    @state = :idle
    note("vend #{product.name} change #{change.join("+")}")
  end

  def cancel
    if @credit == 0
      note("nothing to return")
      return
    end
    change = make_change(@credit)
    note("returned #{change.sum}")
    @credit = 0
    @state = :idle
  end

  def dispatch(kind, arg)
    case kind
    in :coin then insert(arg)
    in :select then select(arg)
    in :cancel then cancel
    end
  rescue VendError => e
    note("error[#{e.code}] #{e.message}")
  end
end

products = {
  "A1" => Product.new("Cola", 125, 2),
  "A2" => Product.new("Water", 90, 1),
  "B1" => Product.new("Chips", 65, 0),
  "B2" => Product.new("Candy", 40, 5)
}
m = Machine.new(products)
events = [
  [:coin, 100], [:coin, 25], [:select, "A1"],
  [:coin, 3], [:coin, 100], [:select, "B1"], [:select, "C9"], [:select, "A2"],
  [:coin, 25], [:coin, 25], [:select, "A1"], [:coin, 100], [:select, "A1"],
  [:cancel, nil], [:coin, 10], [:coin, 10], [:coin, 25], [:select, "B2"],
  [:coin, 100], [:select, "A2"], [:coin, 100], [:coin, 100], [:select, "A1"],
  [:cancel, nil]
]
events.each do |kind, arg|
  m.dispatch(kind, arg)
  puts format("%-8s %-6s state=%-10s credit=%3d | %s", kind, arg, m.state, m.credit, m.log.last)
end

puts "sales: #{m.sales}"
products.each do |slot, prod|
  puts format("%s %-6s stock=%d", slot, prod.name, prod.stock)
end
puts "coins: " + ACCEPTED_COINS.map { |c| "#{c}x#{m.coins[c]}" }.join(" ")
