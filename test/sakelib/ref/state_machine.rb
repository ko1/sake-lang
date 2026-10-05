# Reference implementation for test/sakelib/state_machine.rb: a small AASM-like state machine in
# plain Ruby. As in AASM, guards and callbacks are named by Symbols and called with `send`; the
# machine is data built once per class (AASM builds it from a DSL block).

class AASMInvalidTransition < StandardError
  attr_reader :event, :state
  def initialize(message, event, state)
    super(message)
    @event = event
    @state = state
  end
end

AASMTransition = Struct.new(:from, :to, :guard, :after)

class AASMMachine
  attr_reader :initial, :states, :events, :enters, :exits

  def initialize(initial)
    initial => Symbol
    @initial = initial
    @states = [initial]
    @events = {}
    @enters = {}
    @exits = {}
  end

  def state(name, enter: nil, exit: nil)
    name => Symbol
    @states << name unless @states.include?(name)
    @enters[name] = enter if enter
    @exits[name] = exit if exit
    self
  end

  def event(name, from:, to:, guard: nil, after: nil)
    froms = Array(from)
    [*froms, to].each do |s|
      raise ArgumentError, "unknown state #{s.inspect} in event #{name.inspect}" unless @states.include?(s)
    end
    (@events[name] ||= []) << AASMTransition.new(froms, to, guard, after)
    self
  end

  def event_names = @events.keys
end

module AASM
  attr_writer :aasm_state

  # AASM's way: a guard or callback name is a method of the model.
  def aasm_guard(name) = send(name)
  def aasm_callback(name) = send(name)

  def current_state = @aasm_state || aasm.initial
  def is?(state) = current_state == state

  def may_fire_event?(event) = !find_transition(event).nil?

  def fire(event)
    t = find_transition(event)
    return false unless t
    old = current_state
    ex = aasm.exits[old]
    aasm_callback(ex) if ex
    @aasm_state = t.to
    en = aasm.enters[t.to]
    aasm_callback(en) if en
    aasm_callback(t.after) if t.after
    true
  end

  def fire!(event)
    return true if fire(event)
    raise AASMInvalidTransition.new("Event '#{event}' cannot transition from '#{current_state}'.", event, current_state)
  end

  def states = aasm.states
  def events = aasm.event_names
  def permitted_events = events.select { |e| may_fire_event?(e) }

  private

  def find_transition(event)
    ts = aasm.events[event]
    raise ArgumentError, "unknown event #{event.inspect}" unless ts
    ts.find { |t| t.from.include?(current_state) && (t.guard.nil? || aasm_guard(t.guard)) }
  end
end
