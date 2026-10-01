# Ask TypeProf for the type at positions: ruby hover.rb FILE LINE:COL [LINE:COL...]  (COL is 0-based)
require "typeprof"
file = File.expand_path(ARGV.shift)
core = TypeProf::Core::Service.new({})
core.update_rb_file(file, File.read(file))
ARGV.each do |lc|
  l, c = lc.split(":").map(&:to_i)
  puts "#{lc} #{File.readlines(file)[l - 1].strip[0, 60].inspect} => #{core.hover(file, TypeProf::CodePosition.new(l, c)).inspect}"
end
