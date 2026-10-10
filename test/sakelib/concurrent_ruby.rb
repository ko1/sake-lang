require "concurrent"

# The Sake program (concurrent_ruby.sake) with the real gem. The names are the same there (Concurrent::X); the class
# methods Promise.fulfill / reject are Concurrent::Promise.fulfilled / rejected, and every call names its type.

# 1. Future
puts "-- Future"
f = Concurrent::Future.execute { 1 + 1 }
p f.value
p f.state
p f.fulfilled?
p f.rejected?
p f.reason
p f.value(0.1)
g = Concurrent::Future.execute { raise "boom" }
g.wait
p g.value
p g.state
r = g.reason
puts(r == nil ? "no reason" : r.message)
p g.rejected?
begin
  g.value!
rescue RuntimeError => e
  puts "value! raised: #{e.message}"
end
h = Concurrent::Future.execute do
  sleep 0.3
  :late
end
p h.value(0.01)   # not yet
p h.complete?
h.wait
p h.value
p h.complete?

# 2. Promise: then / rescue / zip / fulfill / reject
puts "-- Promise"
pr = Concurrent::Promise.execute { 10 }
c = pr.then { |v| v * 2 }
d = c.then { |v| v + 1 }
p d.value
p c.value
p pr.value
p d.state
bad = Concurrent::Promise.execute { raise "bad" }.then { |v| v * 2 }
bad.wait
p bad.state
r2 = bad.reason
puts(r2 == nil ? "no reason" : r2.message)
p bad.value
res = Concurrent::Promise.execute { raise "bad" }.rescue { |reason| "rescued #{reason.message}" }
p res.value
p res.state
p Concurrent::Promise.execute { 5 }.rescue { |reason| 0 }.value
z = Concurrent::Promise.zip(Concurrent::Promise.execute { 1 }, Concurrent::Promise.execute { 2 }, Concurrent::Promise.execute { 3 })
p z.value
p Concurrent::Promise.fulfill(3).value
rj = Concurrent::Promise.reject(RuntimeError.new("x")).reason
puts(rj == nil ? "no reason" : rj.message)
t = Concurrent::Promise.execute { 1 }.then { |v| raise "in then" }
t.wait
rt = t.reason
puts(rt == nil ? "no reason" : rt.message)

# 3. Atom, AtomicFixnum, AtomicBoolean, AtomicReference
puts "-- Atom"
a = Concurrent::Atom.new(0)
p a.value
p a.swap { |v| v + 1 }
p a.compare_and_set(1, 5)
p a.compare_and_set(1, 7)
p a.value
p a.reset(9)
p a.value

n = Concurrent::AtomicFixnum.new(5)
p n.increment
p n.increment(3)
p n.decrement
p n.value
p n.compare_and_set(8, 1)
p n.value
p n.update { |v| v * 10 }
p(n.value = 3)
p n.value
# 4 threads x 1000 increments
counter = Concurrent::AtomicFixnum.new
ts = (1..4).to_a.map do |i|
  Thread.new { 1000.times { counter.increment } }
end
ts.each { |th| th.join }
p counter.value

b = Concurrent::AtomicBoolean.new
p b.value
p b.make_true
p b.make_true
p b.true?
p b.false?
p b.make_false
p(b.value = true)
p b.value

ar = Concurrent::AtomicReference.new(:a)   # Symbols: compare_and_set compares by identity
p ar.get
p ar.set(:b)
p ar.get_and_set(:c)
p ar.get
p ar.compare_and_set(:c, :d)
p ar.value
p ar.update { |v| (v.to_s + "!").to_sym }

# 4. Map
puts "-- Map"
m = Concurrent::Map.new
p m.put_if_absent(:a, 1)
p m.put_if_absent(:a, 2)
p m[:a]
p m.compute_if_absent(:b) { 7 }
p m.compute_if_absent(:b) { 8 }
p m.fetch(:b)
p m.fetch(:c, 0)
p m.fetch(:c) { |k| "no #{k}" }
begin
  m.fetch(:zz)
rescue KeyError => e
  puts "KeyError: #{e.message}"
end
p m.key?(:a)
p m.keys
p m.values
p m.size
p m.delete(:a)
p m.delete(:a)
p m.fetch_or_store(:d) { 4 }
p m.fetch_or_store(:d, 5)
p m.get_and_set(:d, 6)
p m.compute(:d) { |v| (v == nil ? 0 : v) + 1 }
p m.compute_if_present(:zz) { |v| v + 1 }
p m.compute_if_present(:d) { |v| v + 1 }
p m.replace_if_exists(:d, 0)
p m.replace_if_exists(:nope, 0)
p m.replace_pair(:d, 0, 1)
p m.replace_pair(:d, 0, 2)
p m.delete_pair(:d, 9)
p m.delete_pair(:d, 1)
p m.empty?
p m.merge_pair(:x, 1) { |old| old + 1 }
p m.merge_pair(:x, 1) { |old| old + 1 }
m[:q] = 3
p m[:q]
p m.key(3)
p m.value?(3)
pairs = []
m.each_pair { |k, v| pairs.push("#{k}=#{v}") }
p pairs.sort
# compute_if_absent from 4 threads computes once
calls = Concurrent::AtomicFixnum.new
shared = Concurrent::Map.new
ts = (1..4).to_a.map do |i|
  Thread.new do
    100.times do |j|
      shared.compute_if_absent(j) do
        calls.increment
        j * j
      end
    end
  end
end
ts.each { |th| th.join }
p calls.value
p shared.size
p shared[7]

# 5. CountDownLatch
puts "-- CountDownLatch"
l = Concurrent::CountDownLatch.new(3)
p l.count
p l.wait(0.01)
done = []
lock = Mutex.new
ts = (1..3).to_a.map do |i|
  Thread.new do
    lock.synchronize { done.push(i) }
    l.count_down
  end
end
p l.wait
p done.sort
p l.count
p l.wait(0.01)
ts.each { |th| th.join }
l.count_down
p l.count

# 6. Semaphore
puts "-- Semaphore"
s = Concurrent::Semaphore.new(2)
p s.available_permits
p s.acquire
p s.try_acquire
p s.try_acquire
p s.try_acquire(1, 0.01)
p s.release
p s.available_permits
p s.drain_permits
p s.available_permits
p s.release(3)
p s.available_permits
p s.acquire(2)
p s.available_permits
# at most 2 of 6 workers inside at once
sem = Concurrent::Semaphore.new(2)
inside = Concurrent::AtomicFixnum.new
peak = Concurrent::AtomicFixnum.new
ts = (1..6).to_a.map do |i|
  Thread.new do
    sem.acquire
    now = inside.increment
    peak.update { |v| now > v ? now : v }
    sleep 0.01
    inside.decrement
    sem.release
  end
end
ts.each { |th| th.join }
p peak.value <= 2
p peak.value >= 1
p sem.available_permits
# a waiter with a timeout gets the permit when it is released in time
sem2 = Concurrent::Semaphore.new(0)
waiter = Thread.new { sem2.try_acquire(1, 2) }
sleep 0.02
sem2.release
p waiter.value
p sem2.available_permits

# 7. Event
puts "-- Event"
ev = Concurrent::Event.new
p ev.set?
p ev.wait(0.01)
w = Thread.new { ev.wait }
p ev.set
p w.value
p ev.set?
p ev.wait
p ev.wait(0.01)
p ev.try?
p ev.reset
p ev.set?
p ev.try?

# 8. FixedThreadPool
puts "-- FixedThreadPool"
pool = Concurrent::FixedThreadPool.new(2)
p pool.max_length
p pool.running?
results = Queue.new
busy = Concurrent::AtomicFixnum.new
peak = Concurrent::AtomicFixnum.new
def post_square(pool, results, busy, peak, i)
  pool.post do
    now = busy.increment
    peak.update { |v| now > v ? now : v }
    sleep 0.01
    busy.decrement
    results.push(i * i)
  end
end
6.times { |i| p post_square(pool, results, busy, peak, i) }
pool.post { raise "a task failing does not stop the pool" }
pool.shutdown
p pool.running?
p pool.wait_for_termination(5)
p pool.shutdown?
p pool.completed_task_count
p pool.scheduled_task_count
p pool.length
got = []
got.push(results.pop) until results.empty?
p got.sort
p peak.value <= 2
begin
  pool.post { 1 }
rescue Concurrent::RejectedExecutionError => e
  puts "rejected: #{e.message}"
end
p pool.wait_for_termination

# 9. ScheduledTask
puts "-- ScheduledTask"
st = Concurrent::ScheduledTask.execute(0.5) { :never }
p st.pending?
p st.cancel
p st.value
p st.cancel
st2 = Concurrent::ScheduledTask.execute(0.01) { :done }
p st2.value
p st2.fulfilled?
p st2.cancel

# 10. IVar
puts "-- IVar"
iv = Concurrent::IVar.new
p iv.pending?
waiter = Thread.new { iv.value }
iv.set(3)
p waiter.value
p iv.value
p iv.complete?
p iv.fulfilled?
begin
  iv.set(4)
rescue Concurrent::MultipleAssignmentError => e
  puts "second set: #{e.message}"
end
p iv.try_set(5)
p iv.value
iv2 = Concurrent::IVar.new
iv2.fail(RuntimeError.new("f"))
p iv2.rejected?
rf = iv2.reason
puts(rf == nil ? "no reason" : rf.message)
p iv2.value
