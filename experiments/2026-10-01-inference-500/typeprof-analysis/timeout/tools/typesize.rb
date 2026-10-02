# Diagnostic (observation only): at each of TS_AT seconds (default "10,30,60"), print the number of
# Type::Array (tuple) objects alive and the largest number of types held by one Vertex, then exit at the last one.
require "typeprof"
at = ENV.fetch("TS_AT", "10,30,60").split(",").map(&:to_f)
Thread.new do
  t0 = 0
  at.each do |t|
    sleep t - t0; t0 = t
    tuples = ObjectSpace.each_object(TypeProf::Core::Type::Array).count
    mx = ObjectSpace.each_object(TypeProf::Core::Vertex).map { (_1.instance_variable_get(:@types) || {}).size }.max
    $stderr.puts "TS t=#{t}s tuples_alive=#{tuples} max_types_in_one_vertex=#{mx} rss=#{File.read("/proc/self/status")[/VmRSS:\s*(\d+)/, 1].to_i / 1024}MB"
  end
  exit! 3
end
