require "find"
require "pathname"

# Sake cannot create or list directories: the test walks files named _find_* in this directory,
# and directories only where the block prunes them; it removes its files at the end.
def try
  yield
rescue SystemCallError => e
  puts "error"
end

File.write("_find_a.txt", "a")
File.write("_find_b.rb", "b")

Find.find("_find_a.txt") { |f| p f }
p Find.find("_find_a.txt", "_find_b.rb") { |f| puts "visit #{f}" }
p Find.find("_find_b.rb", "_find_a.txt").to_a
p Find.find(Pathname.new("_find_a.txt")).to_a
p Find.find("_find_a.txt", ignore_error: false).to_a

# a directory is fine when the block prunes it
seen = []
Find.find(".", "_find_a.txt", "..") do |f|
  seen.push(f)
  Find.prune if File.directory?(f)
end
p seen
n = 0
Find.find("_find_a.txt") do |f|
  n += 1
  Find.prune
end
p n

# a missing path is reported before anything is yielded
count = 0
try { Find.find("_find_a.txt", "_find_missing") { |f| count += 1 } }
p count

# Pathname#find
Pathname.new("_find_b.rb").find { |x| p x }
p Pathname.new("_find_a.txt").find.to_a
Pathname.new(".").find do |x|
  p x
  Find.prune
end

File.delete("_find_a.txt")
File.delete("_find_b.rb")
p File.exist?("_find_a.txt")
