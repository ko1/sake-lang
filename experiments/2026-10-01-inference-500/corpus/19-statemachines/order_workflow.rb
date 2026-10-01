class Money
  include Comparable
  attr_reader :cents

  def initialize(cents)
    @cents = cents
  end

  def +(other) = Money.new(@cents + other.cents)
  def -(other) = Money.new(@cents - other.cents)
  def <=>(other) = @cents <=> other.cents
  def to_s = format("$%d.%02d", @cents / 100, @cents % 100)
end

class LineItem
  attr_reader :sku, :qty, :unit

  def initialize(sku, qty, unit)
    @sku = sku
    @qty = qty
    @unit = unit
  end
end

class WorkflowError < StandardError
  attr_reader :order_id, :from, :event

  def initialize(message, order_id, from, event)
    super(message)
    @order_id = order_id
    @from = from
    @event = event
  end
end

ALLOWED = {
  pending: [:pay, :cancel],
  paid: [:ship, :cancel, :refund],
  shipped: [:deliver, :lose],
  delivered: [:refund],
  lost: [:refund],
  cancelled: [],
  refunded: []
}

class Order
  attr_reader :id, :items, :state, :paid, :audit

  def initialize(id, items)
    @id = id
    @items = items
    @state = :pending
    @paid = Money.new(0)
    @audit = []
  end

  def total = @items.reduce(Money.new(0)) { |acc, li| acc + Money.new(li.qty * li.unit) }

  def target(event)
    case event
    in :pay then :paid
    in :cancel then :cancelled
    in :ship then :shipped
    in :deliver then :delivered
    in :lose then :lost
    in :refund then :refunded
    end
  end

  def apply(time, event, amount)
    ok = ALLOWED[@state]
    if ok.nil? || !ok.include?(event)
      raise WorkflowError.new("order #{@id}: cannot #{event} when #{@state}", @id, @state, event)
    end
    if event == :pay
      due = total
      if amount < due
        raise WorkflowError.new("order #{@id}: paid #{amount} < #{due}", @id, @state, event)
      end
      @paid = amount
    end
    if event == :refund
      @audit << [time, "refund #{@paid}"]
      @paid = Money.new(0)
    end
    from = @state
    @state = target(event)
    @audit << [time, "#{from} -> #{@state}"]
  end
end

orders = {}
def add_order(orders, id, items) = orders[id] = Order.new(id, items)

add_order(orders, 101, [LineItem.new("pen", 3, 150), LineItem.new("pad", 1, 499)])
add_order(orders, 102, [LineItem.new("ink", 2, 1299)])
add_order(orders, 103, [LineItem.new("desk", 1, 18900), LineItem.new("lamp", 2, 2450)])
add_order(orders, 104, [LineItem.new("clip", 10, 15)])

events = [
  [1, 101, :pay, 949], [2, 102, :ship, 0], [3, 102, :pay, 2000], [4, 102, :pay, 2598],
  [5, 103, :pay, 23800], [6, 101, :ship, 0], [7, 104, :cancel, 0], [8, 103, :ship, 0],
  [9, 101, :deliver, 0], [10, 104, :pay, 150], [11, 103, :lose, 0], [12, 103, :refund, 0],
  [13, 102, :refund, 0], [14, 105, :pay, 100], [15, 101, :ship, 0], [16, 102, :cancel, 0]
]

errors = []
events.each do |time, id, event, cents|
  order = orders[id]
  if order.nil?
    errors << "t=#{time}: no order #{id}"
    next
  end
  begin
    order.apply(time, event, Money.new(cents))
  rescue WorkflowError => e
    errors << "t=#{time}: #{e.message} [#{e.from}/#{e.event}]"
  end
end

orders.each do |id, o|
  puts "order #{id}: #{o.state} total=#{o.total} paid=#{o.paid}"
  o.audit.each { |t, msg| puts format("  t=%-3d %s", t, msg) }
end
puts "errors:"
errors.each { puts "  #{it}" }

by_state = orders.values.group_by(&:state)
by_state.each { |st, os| puts "#{st}: #{os.map(&:id).join(",")}" }
revenue = orders.values.reduce(Money.new(0)) { |acc, o| acc + o.paid }
puts "revenue held: #{revenue}"
biggest = orders.values.max_by(&:total)
puts "largest order: #{biggest.id} (#{biggest.total})" if biggest
