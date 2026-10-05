class InvalidTransition < StandardError
  attr_reader :state, :event

  def initialize(message, state, event)
    super(message)
    @state = state
    @event = event
  end
end

TRANSITIONS = {
  [:closed, :passive_open] => [:listen, nil],
  [:closed, :active_open] => [:syn_sent, :syn],
  [:listen, :rcv_syn] => [:syn_received, :syn_ack],
  [:listen, :close] => [:closed, nil],
  [:listen, :send] => [:syn_sent, :syn],
  [:syn_sent, :rcv_syn] => [:syn_received, :ack],
  [:syn_sent, :rcv_syn_ack] => [:established, :ack],
  [:syn_sent, :close] => [:closed, nil],
  [:syn_received, :rcv_ack] => [:established, nil],
  [:syn_received, :close] => [:fin_wait_1, :fin],
  [:syn_received, :rcv_rst] => [:listen, nil],
  [:established, :close] => [:fin_wait_1, :fin],
  [:established, :rcv_fin] => [:close_wait, :ack],
  [:fin_wait_1, :rcv_ack] => [:fin_wait_2, nil],
  [:fin_wait_1, :rcv_fin] => [:closing, :ack],
  [:fin_wait_1, :rcv_fin_ack] => [:time_wait, :ack],
  [:fin_wait_2, :rcv_fin] => [:time_wait, :ack],
  [:closing, :rcv_ack] => [:time_wait, nil],
  [:close_wait, :close] => [:last_ack, :fin],
  [:last_ack, :rcv_ack] => [:closed, nil],
  [:time_wait, :timeout] => [:closed, nil]
}

class Conn
  attr_reader :name, :state, :history

  def initialize(name)
    @name = name
    @state = :closed
    @history = [@state]
  end

  def fire(event)
    entry = TRANSITIONS[[@state, event]]
    raise InvalidTransition.new("#{@name}: #{event} not allowed in #{@state}", @state, event) unless entry
    next_state, reply = entry
    @state = next_state
    @history << next_state
    reply
  end

  def run(events)
    sent = []
    events.each do |ev|
      reply = fire(ev)
      sent << reply if reply
    end
    sent
  end
end

def reachable_from(start)
  seen = Set[start]
  queue = [start]
  until queue.empty?
    s = queue.shift
    TRANSITIONS.each do |(from, _ev), (to, _reply)|
      if from == s && !seen.include?(to)
        seen << to
        queue << to
      end
    end
  end
  seen
end

scenarios = [
  ["client", [:active_open, :rcv_syn_ack, :close, :rcv_ack, :rcv_fin, :timeout]],
  ["server", [:passive_open, :rcv_syn, :rcv_ack, :rcv_fin, :close, :rcv_ack]],
  ["simul", [:active_open, :rcv_syn, :rcv_ack, :close, :rcv_fin, :rcv_ack, :timeout]],
  ["broken", [:passive_open, :rcv_syn, :rcv_fin]],
  ["reset", [:passive_open, :rcv_syn, :rcv_rst, :close]]
]

scenarios.each do |name, events|
  c = Conn.new(name)
  begin
    sent = c.run(events)
    puts "#{name}: ok, sent #{sent.map(&:to_s).join(",")}"
  rescue InvalidTransition => e
    puts "#{name}: FAILED #{e.message} (state=#{e.state})"
  end
  puts "  path: #{c.history.map(&:upcase).join(" > ")}"
end

states = Set[]
TRANSITIONS.each do |(from, _ev), (to, _r)|
  states << from
  states << to
end
puts "states: #{states.size}, transitions: #{TRANSITIONS.size}"
r = reachable_from(:listen)
puts "reachable from listen: #{r.map(&:to_s).sort.join(" ")}"
by_event = Hash.new(0)
TRANSITIONS.each_key { |k| by_event[k[1]] += 1 }
top = by_event.max_by { |ev, n| n }
puts "most used event: #{top[0]} (#{top[1]})" if top
