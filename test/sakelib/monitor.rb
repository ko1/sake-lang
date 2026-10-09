require "monitor"

# Deterministic: prints counts and totals, never timing. The Sake version passes a thread identity (`me`)
# where Ruby uses Thread.current; the output is the same.

# 1. enter / exit / try_enter / mon_locked? / mon_owned?, reentrant
m = Monitor.new
p m.mon_locked?
m.enter
p m.mon_locked?
p m.mon_owned?
p Thread.new { m.mon_owned? }.value
p m.try_enter                        # re-entry: true
m.exit
p m.mon_locked?                      # still held once
m.exit
p m.mon_locked?
p m.try_enter
m.exit

# exit without enter
begin
  m.exit
rescue ThreadError => e
  puts "ThreadError: #{e.message}"
end

# nested synchronize, and the value of the block
v = m.synchronize do
  m.synchronize { m.mon_locked? ? 10 : 0 } + 1
end
p v
p m.mon_locked?

# an exception inside synchronize releases the monitor
begin
  m.synchronize { raise "boom" }
rescue RuntimeError => e
  puts e.message
end
p m.mon_locked?

# 2. a counter shared by threads
def count_up(m, threads, rounds)
  counter = 0
  ts = (1..threads).to_a.map do |i|
    Thread.new do
      rounds.times { m.synchronize { counter += 1 } }
    end
  end
  ts.each { |t| t.join }
  counter
end
p count_up(Monitor.new, 4, 500)

# 3. try_enter from another thread while it is held
held = Queue.new
release = Queue.new
t = Thread.new do
  m.synchronize do
    held.push(true)
    release.pop
  end
  :done
end
held.pop
p m.try_enter
p m.mon_locked?
p m.mon_owned?
release.push(true)
p t.value
p m.try_enter
m.exit

# 4. condition variables: a bounded buffer
def bounded_buffer(n, capacity)
  m = Monitor.new
  not_full = m.new_cond
  not_empty = m.new_cond
  buf = []
  consumer = Thread.new do
    total = 0
    n.times do
      m.synchronize do
        not_empty.wait_while { buf.empty? }
        x = buf.shift
        total += x if x != nil
        not_full.signal
      end
    end
    total
  end
  n.times do |i|
    m.synchronize do
      not_full.wait_until { buf.size < capacity }
      buf.push(i + 1)
      not_empty.signal
    end
  end
  consumer.value
end
p bounded_buffer(20, 3)

# broadcast wakes every waiter
def broadcast_all(k)
  m = Monitor.new
  cond = m.new_cond
  ready = false
  waiting = 0
  woken = 0
  ts = (1..k).to_a.map do |i|
    Thread.new do
      m.synchronize do
        waiting += 1
        cond.wait_until { ready }
        woken += 1
      end
    end
  end
  # wait until every thread waits (each released the monitor in wait)
  sleep 0.01 until m.synchronize { waiting == k }
  m.synchronize do
    ready = true
    cond.broadcast
  end
  ts.each { |t| t.join }
  woken
end
p broadcast_all(3)

# signal without holding the monitor
cond = m.new_cond
begin
  cond.signal
rescue ThreadError => e
  puts "ThreadError: #{e.message}"
end

# 5. MonitorMixin
class Account
  include MonitorMixin
  attr_accessor :balance
  def initialize
    super()
    @balance = 0
  end
  def deposit(amount, me) = synchronize { @balance += amount }
end

acct = Account.new
ts = (1..3).to_a.map do |i|
  Thread.new { 200.times { acct.deposit(i, i) } }
end
ts.each { |t| t.join }
p acct.balance
p acct.mon_locked?
acct.mon_enter
p acct.mon_locked?
p acct.mon_owned?
p acct.mon_try_enter
acct.mon_exit
acct.mon_exit
p acct.mon_locked?
c = acct.new_cond
p acct.mon_synchronize { c.signal; :ok }
