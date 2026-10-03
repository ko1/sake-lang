require "benchmark"

# Times differ between runs: this prints the structure (labels, types, formats of fixed values) only.
t = Benchmark.realtime { 1000.times { |i| i * i } }
p((t in Float))
p(t >= 0.0)
p(Benchmark.ms { 1 + 1 } >= 0.0)

m = Benchmark.measure { (1..1000).to_a.map { |i| i * 2 }.sum }
p(m.real >= 0.0)
p(m.label)
p(m.to_a.size)
p(m.to_h.keys)

print(Benchmark::CAPTION)
print(Benchmark::FORMAT)

a = Benchmark::Tms.new(1.5, 0.25, 0.0, 0.125, 2.0, "fixed")
b = Benchmark::Tms.new(0.5, 0.75, 1.0, 0.0, 1.0, "other")
puts(a)
print(a.format("%n|%u|%y|%U|%Y|%t|%r\n"))
print(a.format("[%-8n] %5.2u %.1t %3r %%\n"))
print(a.format("total: %tsec\n"))
print(a.format("ラベル %n ✓\n"))
print(a.format(""))
begin
  print(a.format("100% %q"))
rescue ArgumentError => e
  puts("ArgumentError")
end
p(a.total)
p(a.to_a)
p(a.to_h)
p((a + b).to_a)
p((a - b).to_a)
p((a * 2).to_a)
p((a / 2).to_a)
p((a / 2.0).to_a)
p(Benchmark::Tms.new.to_a)
p(a.add { 1 }.label)
c = Benchmark::Tms.new(0.0, 0.0, 0.0, 0.0, 0.0, "acc")
c.add! { 1 }
p(c.label)
p(c.real >= 0.0)

# A format with only the labels makes Benchmark.benchmark's output fixed.
list = Benchmark.benchmark("CAPTION\n", 7, "<%n>\n") do |x|
  x.report("first") { 10.times { |i| i } }
  x.report("a much longer label") { 1 }
  x.item("") { 2 }
end
p(list.map { |r| r.label })

list = Benchmark.benchmark("", 0, "%n.\n") do |x|
  x.report("ü") { 1 }
end
p(list.size)
