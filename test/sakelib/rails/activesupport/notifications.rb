# ActiveSupport::Notifications: subscribe (String, Regexp, all), the three listener kinds, instrument,
# exceptions in the payload, unsubscribe, subscribed, publish, errors in listeners, Event.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/notifications"

def show(payload) = payload.except(:exception_object).inspect

# A listener called with an Event (Ruby: call with one parameter).
class Collector
  def initialize(tag) = @tag = tag
  def call(event)
    puts("  #{@tag}: #{event.name} #{show(event.payload)} #{event.duration >= 0} #{event.transaction_id.size}")
  end
end

# A listener called with the times (Ruby: call with five parameters).
class Timer
  def call(name, started, finished, id, payload)
    puts("  timer: #{name} #{finished >= started} #{id.size} #{show(payload)}")
  end
end

# A listener with start and finish (Ruby: Evented).
class Tracer
  def start(name, id, payload) = puts("  start #{name}")
  def finish(name, id, payload) = puts("  finish #{name} #{show(payload)}")
end

class Failing
  def initialize(error) = @error = error
  def call(event) = raise(@error, "from #{event.name}")
end

N = ActiveSupport::Notifications

puts("instrument:")
sql = N.subscribe("sql.active_record", Collector.new("sql"))
ar = N.subscribe(/\.active_record\z/, Timer.new)
all = N.subscribe(nil, Tracer.new)
p(N.instrument("sql.active_record", { sql: "SELECT 1" }) { |payload| payload[:rows] = 1; :result })
p(N.instrument("instantiation.active_record", { count: 2 }))
p(N.instrument("render.action_view") { :rendered })
puts("listening:")
p([N.notifier.listening?("sql.active_record"), N.notifier.listening?("nothing")])
N.unsubscribe(all)
p(N.notifier.listening?("nothing"))
p(N.instrument("nothing") { :no_listener })
puts("exception:")
begin
  N.instrument("sql.active_record", { sql: "BAD" }) { raise ArgumentError, "syntax error" }
rescue ArgumentError => e
  puts("  rescued #{e.message}")
end
puts("unsubscribe by name (a Regexp subscriber excludes it):")
N.unsubscribe("sql.active_record")
N.instrument("sql.active_record", { sql: "SELECT 2" })
N.instrument("cache.active_record", { key: "k" })
N.unsubscribe(ar)
puts("subscribed:")
N.subscribed(Collector.new("temp"), "temp.app") do
  N.instrument("temp.app", { n: 1 })
end
N.instrument("temp.app", { n: 2 })
puts("publish:")
t = N.subscribe("pub.app", Timer.new)
N.publish("pub.app", Time.now, Time.now, "x" * 20, { via: :publish })
N.unsubscribe(t)
puts("errors in listeners:")
f1 = N.subscribe("fail.app", Failing.new(ArgumentError))
begin
  N.instrument("fail.app")
rescue ArgumentError => e
  puts("  ArgumentError: #{e.message}")
end
f2 = N.subscribe("fail.app", Failing.new(KeyError))
begin
  N.instrument("fail.app")
rescue ActiveSupport::Notifications::InstrumentationSubscriberError => e
  puts("  #{e.message}")
  p(e.exceptions.map(&:message))
end
N.unsubscribe(f1)
N.unsubscribe(f2)
puts("event:")
ev = ActiveSupport::Notifications::Event.new("job.app", nil, nil, "id1", { job: "Mail" })
p(ev.record { |payload| payload[:done] = true; :ok })
p([ev.name, ev.transaction_id, ev.payload, ev.duration >= 0, ev.time <= ev.end, ev.allocations >= 0])
