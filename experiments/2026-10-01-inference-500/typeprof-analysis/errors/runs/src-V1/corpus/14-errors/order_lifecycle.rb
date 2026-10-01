# Drive orders through a lifecycle state machine; illegal events raise InvalidTransition.
class InvalidTransition < StandardError
  attr_reader :from, :event

  def initialize(message, from, event)
    super(message)
    @from = from
    @event = event
  end
end

class GuardFailed < StandardError
  attr_reader :reason

  def initialize(message, reason)
    super(message)
    @reason = reason
  end
end

TRANSITIONS = {
  [:new, :pay] => :paid,
  [:new, :cancel] => :cancelled,
  [:paid, :ship] => :shipped,
  [:paid, :cancel] => :refunded,
  [:shipped, :deliver] => :delivered,
  [:shipped, :lose] => :lost,
  [:lost, :refund] => :refunded,
  [:delivered, :return] => :returned,
  [:returned, :refund] => :refunded
}

class Order
  attr_reader :id, :amount
  attr_accessor :state, :history, :paid

  def initialize(id, amount, state, history, paid)
    @id = id
    @amount = amount
    @state = state
    @history = history
    @paid = paid
  end

  def fire(event, arg)
    target = TRANSITIONS[[@state, event]]
    raise InvalidTransition.new("cannot #{event} when #{@state}", @state, event) unless target
    case event
    when :pay
      raise GuardFailed.new("paid #{arg}, expected #{@amount}", "amount") if arg != @amount
      @paid = arg
    when :ship
      raise GuardFailed.new("no tracking number", "tracking") if arg.empty?
    when :return
      raise GuardFailed.new("return window is 14 days, got #{arg}", "window") if arg > 14
    end
    @history << "#{@state}->#{target}"
    @state = target
  end
end

def run(order, events)
  errors = []
  events.each do |event, arg|
    order.fire(event, arg)
  rescue InvalidTransition => e
    errors << "#{event}: #{e.message}"
  rescue GuardFailed => e
    errors << "#{event}: guard #{e.reason} failed (#{e.message})"
  end
  errors
end

scenarios = [
  [Order.new("A-1", 300, :new, [], 0), [[:pay, 300], [:ship, "TRK1"], [:deliver, 0]]],
  [Order.new("A-2", 120, :new, [], 0), [[:ship, "TRK2"], [:pay, 100], [:pay, 120], [:cancel, 0]]],
  [Order.new("A-3", 75, :new, [], 0), [[:pay, 75], [:ship, ""], [:ship, "TRK3"], [:lose, 0], [:deliver, 0], [:refund, 0]]],
  [Order.new("A-4", 980, :new, [], 0), [[:pay, 980], [:ship, "TRK4"], [:deliver, 0], [:return, 20], [:return, 3], [:refund, 0], [:pay, 980]]],
  [Order.new("A-5", 50, :new, [], 0), [[:cancel, 0], [:cancel, 0]]]
]

final_states = Hash.new(0)
refunded_total = 0
scenarios.each do |order, events|
  errors = run(order, events)
  final_states[order.state] += 1
  refunded_total += order.paid if order.state == :refunded
  puts "#{order.id}: #{order.state} via #{order.history.join(", ")}"
  errors.each { |e| puts "    ! #{e}" }
end
puts "final: #{final_states.map { |s, n| "#{s}=#{n}" }.join(" ")}"
puts "refunded #{refunded_total}"
