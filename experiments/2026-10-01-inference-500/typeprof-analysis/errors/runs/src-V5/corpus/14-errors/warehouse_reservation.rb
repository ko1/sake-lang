# Reserve stock for orders across warehouses; all-or-nothing per order, with locks released in ensure.
require "set"

class OutOfStock < StandardError
  attr_reader :sku, :requested, :available

  def initialize(message, sku, requested, available)
    super(message)
    @sku = sku
    @requested = requested
    @available = available
  end
end

class UnknownItem < StandardError
  attr_reader :sku

  def initialize(message, sku)
    super(message)
    @sku = sku
  end
end

class LockBusy < StandardError
  attr_reader :warehouse

  def initialize(message, warehouse)
    super(message)
    @warehouse = warehouse
  end
end

class Warehouse
  attr_reader :code, :stock
  attr_accessor :locked, :lock_count

  def initialize(code, stock, locked, lock_count)
    @code = code
    @stock = stock
    @locked = locked
    @lock_count = lock_count
  end

  def lock
    raise LockBusy.new("#{@code} is locked", @code) if @locked
    @locked = true
    @lock_count += 1
  end

  def unlock = @locked = false
  def available(sku) = @stock.fetch(sku, 0)
end

def total_available(warehouses, sku)
  warehouses.sum { |w| w.available(sku) }
end

# Take from the warehouse with most stock first; returns [[code, qty], ...]
def plan(warehouses, sku, qty, known)
  raise UnknownItem.new("no such item #{sku}", sku) unless known.include?(sku)
  have = total_available(warehouses, sku)
  raise OutOfStock.new("not enough #{sku}", sku, qty, have) if have < qty
  remaining = qty
  picks = []
  warehouses.sort_by { |w| -w.available(sku) }.each do |w|
    break if remaining.zero?
    take = w.available(sku).clamp(0, remaining)
    next if take.zero?
    picks << [w, take]
    remaining -= take
  end
  picks
end

def reserve(warehouses, order, known)
  locked = []
  begin
    warehouses.each do |w|
      w.lock
      locked << w
    end
    all_picks = order.flat_map { |sku, qty| plan(warehouses, sku, qty, known).map { |w, n| [sku, w, n] } }
    all_picks.each { |sku, w, n| w.stock[sku] = w.available(sku) - n }
    all_picks.map { |sku, w, n| "#{sku}:#{w.code}x#{n}" }
  ensure
    locked.each(&:unlock)
  end
end

warehouses = [
  Warehouse.new("OSA", { "bolt" => 40, "nut" => 100, "gear" => 3 }, false, 0),
  Warehouse.new("TYO", { "bolt" => 15, "gear" => 8, "belt" => 2 }, false, 0),
  Warehouse.new("FUK", { "nut" => 20, "belt" => 1 }, false, 0)
]
known = Set["bolt", "nut", "gear", "belt", "chain"]

orders = [
  ["o1", [["bolt", 45], ["nut", 10]]],
  ["o2", [["gear", 5], ["belt", 4]]],
  ["o3", [["gear", 11], ["chain", 1]]],
  ["o4", [["nut", 110], ["spring", 2]]],
  ["o5", [["belt", 3], ["gear", 6]]],
  ["o6", [["bolt", 10]]]
]

backorders = []
orders.each do |id, lines|
  warehouses[2].locked = true if id == "o6"
  begin
    picks = reserve(warehouses, lines, known)
    puts "#{id}: reserved #{picks.join(", ")}"
  rescue OutOfStock => e
    backorders << [id, e.sku, e.requested - e.available]
    puts "#{id}: #{e.message} (want #{e.requested}, have #{e.available})"
  rescue UnknownItem => e
    puts "#{id}: rejected, #{e.message}"
  rescue LockBusy => e
    puts "#{id}: retry later, #{e.message}"
  end
end
warehouses[2].locked = false

puts "stock:"
warehouses.each do |w|
  items = w.stock.keys.sort.map { |k| "#{k}=#{w.stock[k]}" }
  puts "  #{w.code} #{items.join(" ")} (locked #{w.lock_count} times)"
end
puts "backorders: #{backorders.map { |id, sku, n| "#{id}/#{sku}/#{n}" }.join(" ")}"
puts "any lock left: #{warehouses.any?(&:locked)}"
