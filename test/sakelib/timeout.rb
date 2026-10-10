require "timeout"

# Deterministic: generous margins, pass/fail only where time is involved.
def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# in time: the block's value
p Timeout.timeout(5) { 42 }
p Timeout.timeout(5.0) { "fast" }
p Timeout.timeout(nil) { :no_limit }
p Timeout.timeout(0) { :no_limit_either }
p Timeout.timeout(5) { nil }
p Timeout.timeout(5) { sleep 0.05; [1, 2] }

# too slow: Timeout::Error, raised near the deadline
t0 = now
begin
  Timeout.timeout(0.2) { sleep 3 }
  puts "no error"
rescue Timeout::Error => e
  puts "Timeout::Error: #{e.message}"
end
elapsed = now - t0
puts(elapsed >= 0.2 && elapsed < 1.5 ? "pass: raised near the deadline" : "fail: #{elapsed}")

# a message
begin
  Timeout.timeout(0.1, nil, "too slow") { sleep 3 }
rescue Timeout::Error => e
  puts e.message
end

# an exception in the block comes out as itself
begin
  Timeout.timeout(5) { raise "inner" }
rescue RuntimeError => e
  puts "RuntimeError: #{e.message}"
end
begin
  Timeout.timeout(5) { raise ArgumentError, "bad" }
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

# a negative time
begin
  Timeout.timeout(-1) { 1 }
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

# nested: the inner one expires first
begin
  Timeout.timeout(5) do
    Timeout.timeout(0.1) { sleep 3 }
  end
rescue Timeout::Error => e
  puts "inner: #{e.message}"
end

# the block sees the function's variables
def collect(n)
  out = []
  Timeout.timeout(5) { n.times { |i| out.push(i * i) } }
  out
end
p collect(4)
