# usage: ruby tools/btdump.rb FILE.rb  -- run TypeProf in-process and sample the main thread's backtrace
main = Thread.current
Thread.new do
  sleep 5
  3.times { |i| $stderr.puts "---- sample #{i}"; $stderr.puts main.backtrace.first(40).grep(/typeprof/).map { _1.sub(%r{.*/gems/typeprof-0.31.1/}, "") }; sleep 1.3 }
  exit! 0
end
load Gem.bin_path("typeprof", "typeprof")
