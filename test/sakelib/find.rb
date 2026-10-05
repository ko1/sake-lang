require "find"
require "pathname"
require "tmpdir"

# The test walks a tree in a temporary directory and shows each path relative to it.
def try
  yield
rescue SystemCallError => e
  puts "error"
end

Dir.mktmpdir do |dir|
  short = ->(f) { f.delete_prefix(dir) }
  Dir.mkdir(File.join(dir, "src"))
  Dir.mkdir(File.join(dir, "src", "lib"))
  Dir.mkdir(File.join(dir, "src", "skip"))
  Dir.mkdir(File.join(dir, "empty"))
  File.write(File.join(dir, "src", "a.txt"), "a")
  File.write(File.join(dir, "src", "b.rb"), "b")
  File.write(File.join(dir, "src", "lib", "c.rb"), "c")
  File.write(File.join(dir, "src", "skip", "d.rb"), "d")
  File.write(File.join(dir, "top.rb"), "t")
  a = File.join(dir, "src", "a.txt")

  Find.find(dir) { |f| p short.(f) }
  p Find.find(a, File.join(dir, "top.rb")) { |f| puts "visit #{short.(f)}" }
  p Find.find(File.join(dir, "src")).to_a.map(&short)
  p Find.find(Pathname.new(a)).to_a.map(&short)
  p Find.find(File.join(dir, "empty"), ignore_error: false).to_a.map(&short)

  # prune: skip a directory's contents
  seen = []
  Find.find(dir) do |f|
    Find.prune if File.basename(f) == "skip"
    seen.push(short.(f)) if f.end_with?(".rb")
  end
  p seen
  sizes = 0
  Find.find(dir) { |f| sizes += File.size(f) if File.file?(f) }
  p sizes
  n = 0
  Find.find(a) do |f|
    n += 1
    Find.prune
  end
  p n

  # a missing path is reported before anything is yielded
  count = 0
  try { Find.find(a, File.join(dir, "missing")) { |f| count += 1 } }
  p count

  # Pathname#find
  Pathname.new(File.join(dir, "src", "lib")).find { |x| p short.(x.to_s) }
  p Pathname.new(a).find.to_a.map { |x| short.(x.to_s) }
end
Pathname.new(".").find do |x|
  p x
  Find.prune
end
