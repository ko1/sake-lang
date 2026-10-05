require_relative "ref/event_emitter"

# Listeners: objects with call (a block would do in Ruby; the Sake test cannot keep one).
Printer = Struct.new(:prefix) do
  def call(*args) = puts("#{prefix}: #{args.map { |a| a.inspect }.join(", ")}")
end

Counter = Struct.new(:name, :count) do
  def initialize(name, count = 0) = super
  def call(*args)
    self.count += 1
  end
end

Summer = Struct.new(:total) do
  def initialize(total = 0) = super
  def call(*args)
    args.each { |a| self.total += a if a in Integer }
  end
end

# A listener that adds another one while the event is emitted.
Recruiter = Struct.new(:emitter) do
  def call(*args)
    puts "recruiting"
    emitter.on(:data, Printer.new("recruit"))
  end
end

e = EventEmitter.new
counter = Counter.new("data")
sum = Summer.new
e.on(:data, Printer.new("first"))
e.on(:data, counter)
e.on(:data, sum)
e.prepend_listener(:data, Printer.new("zeroth"))
p e.emit(:data, 1, 2)
p e.emit(:data, "x", :y, nil)
p e.emit(:nothing, 1)
p [counter.count, sum.total]
p e.listener_count(:data)
p e.listener_count(:nothing)
p e.event_names

# once
e.once(:ready, Printer.new("ready once"))
e.on(:ready, Printer.new("ready always"))
e.prepend_once_listener(:ready, Printer.new("ready first, once"))
p e.listener_count(:ready)
e.emit(:ready)
e.emit(:ready, 2)
p e.listener_count(:ready)

# off: by ==, the most recently added one first
e.off(:data, Printer.new("first"))
e.off(:data, Printer.new("not there"))
e.emit(:data, 3)
p e.listeners(:data)
e.on(:tick, Counter.new("a"))
e.on(:tick, Counter.new("a"))
e.remove_listener(:tick, Counter.new("a"))
p e.listener_count(:tick)
e.remove_listener(:tick, Counter.new("a"))
p e.event_names

# adding while emitting takes effect from the next emit
r = EventEmitter.new
r.once(:data, Recruiter.new(r))
r.emit(:data, "a")
r.emit(:data, "b")

# remove all; an unhandled :error raises
e.remove_all_listeners(:ready)
p e.event_names
e.remove_all_listeners
p e.event_names
p e.emit(:data, 1)
begin
  e.emit(:error, "disk full")
rescue RuntimeError => err
  puts err.message
end
e.on(:error, Printer.new("handled"))
p e.emit(:error, "disk full")
