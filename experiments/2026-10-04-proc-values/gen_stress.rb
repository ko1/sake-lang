# Generates stress programs: stress_handlers_N (N blocks in one container, all called with each of
# 3 payload types) and stress_compose_N (N procs composed pairwise: procs passed to a function).
dir = File.join(__dir__, "stress")
Dir.mkdir(dir) unless Dir.exist?(dir)
[5, 10, 20, 40, 80].each do |n|
  src = +"hs = Array[]\nacc = Array[]\n"
  n.times { |i| src << "Array.push(hs, proc { |x| Array.push(acc, \"#{i}:\#{x}\") })\n" }
  src << "Array.each(hs) { |h| Proc.call(h, 1) }\nArray.each(hs) { |h| Proc.call(h, \"s\") }\nArray.each(hs) { |h| Proc.call(h, :k) }\np Array.size(acc)\n"
  File.write(File.join(dir, "stress_handlers_#{n}.sake"), src)

  src = +"def compose(f, g) = proc { |x| Proc.call(f, Proc.call(g, x)) }\n"
  n.times { |i| src << "f#{i} = proc { |x| x + #{i} }\n" }
  src << "c = f0\n"
  (1...n).each { |i| src << "c = compose(c, f#{i})\n" }
  src << "p Proc.call(c, 0)\np Proc.call(c, 0.5)\n"
  File.write(File.join(dir, "stress_compose_#{n}.sake"), src)
end
