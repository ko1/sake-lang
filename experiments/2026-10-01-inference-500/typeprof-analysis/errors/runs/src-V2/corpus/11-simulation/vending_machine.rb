class SoldOut < StandardError
  attr_reader :slot

  def initialize(message, slot)
    super(message)
    @slot = slot
  end
end

class NoChange < StandardError
  attr_reader :owed

  def initialize(message, owed)
    super(message)
    @owed = owed
  end
end

class Slot
  attr_reader :code, :name, :price
  attr_accessor :count

  def initialize(code, name, price, count)
    @code = code
    @name = name
    @price = price
    @count = count
  end
end

class Machine
  ACCEPTED = [5, 10, 25, 100].freeze

  attr_reader :slots, :coins, :sales, :state, :credit

  def initialize(slots, coins)
    @slots = slots
    @coins = coins
    @sales = []
    @state = :idle
    @credit = 0
    @inserted = []
  end

  def describe = "#{@state} credit=#{@credit} coins=#{coin_summary}"

  def coin_summary
    @coins.keys.sort.map { |c| "#{c}x#{@coins[c]}" }.join(",")
  end

  def insert(coin)
    return "rejected coin #{coin}" unless ACCEPTED.include?(coin)
    @coins[coin] += 1
    @inserted << coin
    @credit += coin
    @state = :collecting
    "credit #{@credit}"
  end

  def make_change(amount)
    plan = Hash.new(0)
    left = amount
    @coins.keys.sort.reverse_each do |c|
      while left >= c && @coins[c] - plan[c] > 0
        plan[c] += 1
        left -= c
      end
    end
    raise NoChange.new("cannot make change for #{amount}", amount) if left > 0
    plan.each { |c, n| @coins[c] -= n }
    plan
  end

  def choose(code)
    slot = @slots.find { |s| s.code == code }
    return "no slot #{code}" if slot.nil?
    raise SoldOut.new("#{slot.name} is sold out", code) if slot.count == 0
    price = slot.price
    return "need #{price - @credit} more for #{slot.name}" if @credit < price
    @state = :dispensing
    change = make_change(@credit - price)
    slot.count -= 1
    @sales << [code, price]
    @credit = 0
    @inserted.clear
    @state = :idle
    parts = change.select { |_c, n| n > 0 }.map { |c, n| "#{n}x#{c}" }
    "vend #{slot.name}, change #{parts.empty? ? "none" : parts.join(" ")}"
  end

  def cancel
    returned = @inserted.sum
    @inserted.each { |c| @coins[c] -= 1 }
    @inserted.clear
    @credit = 0
    @state = :idle
    "returned #{returned}"
  end

  def handle(event)
    case event
    in { insert: coin } then insert(coin)
    in { select: code }
      begin
        choose(code)
      rescue SoldOut => e
        "sold out: #{e.slot}"
      rescue NoChange => e
        @state = :collecting
        "exact change only (owed #{e.owed}); #{cancel}"
      end
    in { cancel: _ } then cancel
    in { restock:, count: }
      slot = @slots.find { |s| s.code == restock }
      if slot
        slot.count += count
        "restocked #{restock} to #{slot.count}"
      else
        "no slot #{restock}"
      end
    end
  end
end

slots = [
  Slot.new("A1", "cola", 125, 2), Slot.new("A2", "water", 90, 5),
  Slot.new("B1", "chips", 65, 1), Slot.new("B2", "gum", 35, 0)
]
m = Machine.new(slots, { 5 => 0, 10 => 1, 25 => 2, 100 => 0 })

events = [
  { insert: 100 }, { insert: 25 }, { select: "A1" },
  { insert: 100 }, { select: "B1" },
  { insert: 25 }, { insert: 3 }, { select: "A2" }, { insert: 100 }, { select: "A2" },
  { insert: 100 }, { insert: 100 }, { select: "A1" },
  { select: "B2" }, { restock: "B2", count: 10 }, { insert: 25 }, { insert: 10 }, { select: "B2" },
  { insert: 100 }, { select: "B1" }, { insert: 100 }, { select: "C9" }, { cancel: true },
  { insert: 100 }, { select: "A2" }, { insert: 5 }, { insert: 5 }, { cancel: true }
]

events.each_with_index do |ev, i|
  msg = m.handle(ev)
  puts format("%2d %-36s | %s", i + 1, m.describe, msg)
end

puts "--- sales"
totals = Hash.new(0)
m.sales.each { |code, price| totals[code] += price }
totals.each { |code, amount| puts "#{code}: #{amount}" }
puts "revenue: #{m.sales.sum { |_code, price| price }}"
cash = m.coins.sum { |c, n| c * n }
puts "cash in machine: #{cash}"
slots.each { |s| puts "#{s.code} #{s.name.ljust(6)} left #{s.count}" }
