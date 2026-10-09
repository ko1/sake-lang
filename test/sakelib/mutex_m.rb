require "mutex_m"

class Counter
  include Mutex_m
  attr_accessor :n
  def initialize
    super
    @n = 0
  end
  def incr(me) = mu_synchronize { @n += 1 }
end

c = Counter.new
p c.mu_locked?
c.mu_lock
p c.mu_locked?
p c.mu_try_lock                        # held: false
begin
  c.mu_lock
rescue ThreadError => e
  puts "ThreadError: #{e.message}"
end
c.mu_unlock
p c.mu_locked?
begin
  c.mu_unlock
rescue ThreadError => e
  puts "ThreadError: #{e.message}"
end
p c.mu_try_lock
p c.locked?
c.unlock

# synchronize: value, release on exception
p c.mu_synchronize { c.mu_locked? ? :inside : :outside }
begin
  c.synchronize { raise "boom" }
rescue RuntimeError => e
  puts e.message
end
p c.mu_locked?

# threads
ts = (1..4).to_a.map do |i|
  Thread.new { 250.times { c.incr(i) } }
end
ts.each { |t| t.join }
p c.n

# try_lock from another thread while held; unlock by a non-owner
held = Queue.new
release = Queue.new
t = Thread.new do
  c.lock
  held.push(true)
  release.pop
  c.unlock
  :done
end
held.pop
p c.try_lock
begin
  c.mu_unlock
rescue ThreadError => e
  puts "ThreadError: #{e.message}"
end
release.push(true)
p t.value
p c.mu_locked?
