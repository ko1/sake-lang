class Recipe
  attr_reader :name, :per_batch, :mix_min, :bake_min, :ingredients

  def initialize(name, per_batch, mix_min, bake_min, ingredients)
    @name = name
    @per_batch = per_batch
    @mix_min = mix_min
    @bake_min = bake_min
    @ingredients = ingredients
  end
end

class Order
  attr_reader :id, :customer, :product, :qty, :due
  attr_accessor :ready_at

  def initialize(id, customer, product, qty, due)
    @id = id
    @customer = customer
    @product = product
    @qty = qty
    @due = due
    @ready_at = nil
  end
end

class Oven
  attr_reader :name
  attr_accessor :busy_until, :batches

  def initialize(name)
    @name = name
    @busy_until = 0
    @batches = 0
  end
end

class OutOfStock < StandardError
  attr_reader :ingredient, :short

  def initialize(message, ingredient, short)
    super(message)
    @ingredient = ingredient
    @short = short
  end
end

RECIPES = {
  "baguette" => Recipe.new("baguette", 12, 15, 25, { "flour" => 3000, "yeast" => 30, "salt" => 60 }),
  "croissant" => Recipe.new("croissant", 18, 30, 18, { "flour" => 1800, "butter" => 1000, "yeast" => 25, "sugar" => 150 }),
  "rye" => Recipe.new("rye", 6, 20, 50, { "rye" => 2500, "flour" => 500, "salt" => 50 }),
  "muffin" => Recipe.new("muffin", 24, 10, 22, { "flour" => 1200, "sugar" => 600, "butter" => 400, "egg" => 8 })
}.freeze

def consume(stock, recipe, batches)
  needs = recipe.ingredients.transform_values { |amt| amt * batches }
  needs.each do |ing, amt|
    have = stock.fetch(ing, 0)
    raise OutOfStock.new("short of #{ing}", ing, amt - have) if have < amt
  end
  needs.each { |ing, amt| stock[ing] -= amt }
  needs
end

def clock(min) = format("%02d:%02d", 4 + min / 60, min % 60)

def plan(orders, stock, ovens, deliveries)
  mixer_free = 0
  log = []
  queue = orders.sort_by { |o| [o.due, o.id] }
  queue.each do |o|
    recipe = RECIPES[o.product]
    batches = o.qty.ceildiv(recipe.per_batch)
    start = mixer_free
    begin
      consume(stock, recipe, batches)
    rescue OutOfStock => e
      ing = e.ingredient
      arrival = deliveries.find { |_at, item, amount| item == ing && amount >= e.short }
      if arrival.nil?
        log << "#{clock(start)} order #{o.id} cancelled: no #{ing}"
        next
      end
      at, item, amount = arrival
      deliveries.delete(arrival)
      stock[item] = stock.fetch(item, 0) + amount
      start = at if at > start
      log << "#{clock(start)} took delivery of #{amount} #{item}"
      retry
    end
    batches.times do
      mix_done = start + recipe.mix_min
      oven = ovens.min_by(&:busy_until)
      bake_start = [oven.busy_until, mix_done].max
      oven.busy_until = bake_start + recipe.bake_min
      oven.batches += 1
      o.ready_at = oven.busy_until
      start = mix_done
    end
    mixer_free = start
    late = o.ready_at - o.due
    log << format("%s order %d %-9s x%-3d %d batch(es) ready %s%s", clock(start), o.id, o.product,
      o.qty, batches, clock(o.ready_at), late > 0 ? " LATE #{late}m" : "")
  end
  log
end

orders = [
  Order.new(1, "cafe", "croissant", 40, 150), Order.new(2, "hotel", "baguette", 30, 200),
  Order.new(3, "deli", "rye", 10, 280), Order.new(4, "school", "muffin", 60, 240),
  Order.new(5, "cafe", "baguette", 12, 210), Order.new(6, "market", "rye", 14, 360),
  Order.new(7, "hotel", "croissant", 30, 300), Order.new(8, "deli", "muffin", 20, 320)
]
stock = { "flour" => 30000, "yeast" => 400, "salt" => 600, "butter" => 3000, "sugar" => 4000, "rye" => 6000, "egg" => 30 }
deliveries = [[150, "butter", 5000], [200, "rye", 10000], [90, "egg", 24]]
ovens = [Oven.new("deck"), Oven.new("rack")]

log = plan(orders, stock, ovens, deliveries)
log.each { |line| puts line }
puts "--- ovens"
ovens.each { |ov| puts "#{ov.name}: #{ov.batches} batches, free at #{clock(ov.busy_until)}" }
puts "--- leftover stock"
stock.keys.sort.each { |ing| puts format("%-7s %6d", ing, stock[ing]) }
done = orders.select(&:ready_at)
late = done.select { |o| o.ready_at > o.due }
puts "orders done #{done.size}/#{orders.size}, late #{late.size}"
by_customer = Hash.new(0)
done.each { |o| by_customer[o.customer] += o.qty }
puts by_customer.sort_by { |e__0| c, _n = e__0; c }.map { |c, n| "#{c}=#{n}" }.join(" ")
