require "pathname"

# File's path-string functions
names = ["a", "a.", ".a", ".a.b", "a.b.c", "a/b.c/", "a/", "/", "//", "", "a//b", "..", "...", "..a", "a..b", "/usr/lib/libc.so.6"]
names.each do |x|
  p [x, File.basename(x), File.dirname(x), File.extname(x), File.basename(x, ".*"), File.basename(x, ".c")]
  p File.split(x)
end
p File.basename(".c", ".c")
p File.basename("a.c", "c")
p File.join("a", "/b/", "c")
p File.join("a/", "/b")
p File.join
p File.join("", "")
p File.join("a", ["b", ["c"]])
p File.absolute_path?("/x")
p File.absolute_path?("x")

# construction and display
pn = Pathname.new("/usr/bin/ruby")
p pn
puts pn
p pn.to_s
p pn.to_path
p Pathname("lib/x.rb")
p Pathname(Pathname("same")) == Pathname("same")
p Pathname("a") == Pathname("a/")
begin
  Pathname.new("a\0b")
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

# components
paths = ["/usr/bin/ruby", "lib/x.tar.gz", "a/b/", "/", ".", "..", "a", "./a/../b", "/a/./b/../../c/", "a//b//c", "../../x", "/../a", "a/..", "a/../.."]
paths.each do |s|
  x = Pathname.new(s)
  puts "#{s}: base=#{x.basename} dir=#{x.dirname} ext=#{x.extname.inspect} parent=#{x.parent}"
  puts "  abs=#{x.absolute?} rel=#{x.relative?} root=#{x.root?} clean=#{x.cleanpath} conservative=#{x.cleanpath(true)}"
  p x.each_filename.to_a
  p x.split
end
p Pathname.new("x.rb").basename(".rb")
p Pathname.new("x.tar.gz").basename(".*")

# + / join
pairs = [["a", "b"], ["a/", "b"], ["/a", "b"], ["a", "/b"], ["a", ".."], ["a/b", "../c"], ["/", ".."], ["/a", "../.."], [".", "b"], ["a", "."], ["..", "a"], ["a/b", "../../.."], ["a", ""]]
pairs.each do |a, b|
  puts "#{a} + #{b} = #{Pathname.new(a) + b}"
end
p Pathname.new("usr") / "lib" / "ruby"
p Pathname.new("/usr") + Pathname.new("local")
p Pathname.new("a").join("b", "c")
p Pathname.new("a").join("b", "/c", "d")
p Pathname.new("a").join
p Pathname.new("a").join(Pathname.new("x"))

# ascend / descend
Pathname.new("/a/b/c").ascend { |v| p v }
Pathname.new("a/b/c").descend { |v| p v }
p Pathname.new("x/y").ascend.to_a
p Pathname.new("/x/y").descend.to_a
Pathname.new("/p/q/r").each_filename { |f| print f, ";" }
puts

# relative_path_from
rel = [["/a/b/c", "/a"], ["/a", "/a/b/c"], ["/a/b", "/a/b"], ["a/b", "a/c"], ["/a/x", "/b/y"], ["a", "."], [".", "a"]]
rel.each do |a, b|
  puts "#{a} from #{b}: #{Pathname.new(a).relative_path_from(b)}"
end
p Pathname.new("/a/b").relative_path_from(Pathname.new("/a"))
[["/a", "b"], ["a", "../b"]].each do |a, b|
  begin
    p Pathname.new(a).relative_path_from(b)
  rescue ArgumentError => e
    puts "ArgumentError: #{e.message}"
  end
end

# sub_ext / sub / comparison
p Pathname.new("a/b.rb").sub_ext(".txt")
p Pathname.new("a/b").sub_ext(".txt")
p Pathname.new(".bashrc").sub_ext(".bak")
p Pathname.new("src/main.c").sub(/\.c\z/, ".o")
p Pathname.new("a/b") <=> Pathname.new("a-b")
p Pathname.new("a") <=> Pathname.new("a")
sorted = ["b", "a/b", "a-b", "a"].map { |s| Pathname.new(s) }.sort_by { |x| x.to_s.tr("/", "\0") }
p sorted
h = { Pathname.new("k") => 1 }
p h[Pathname.new("k")]

# through File and Dir, in a temporary directory (shown relative to it)
require "tmpdir"
def rel(x, root) = x.relative_path_from(root).to_s
def rels(xs, root) = xs.map { |x| rel(x, root) }.sort
def names(xs) = xs.map(&:to_s).sort

Dir.mktmpdir do |dir|
  root = Pathname.new(dir)
  tmp = root + "test.txt"
  p tmp.exist?
  p tmp.write("one\ntwo\n")
  p tmp.exist?
  p tmp.file?
  p tmp.directory?
  p tmp.symlink?
  p tmp.size
  p tmp.zero?
  p tmp.empty?
  p tmp.ftype
  p Time.now - tmp.mtime < 3600
  p tmp.read
  p tmp.readlines
  p tmp.rename(root + "moved.txt")
  p tmp.exist?
  p rel(tmp.expand_path, root)
  p rel(Pathname.new("moved.txt").expand_path(dir), root)
  p rel(Pathname.new("moved.txt").realpath(root), root)
  p root.realpath == Pathname.new(File.realpath(dir))
  p (root + "a/b/c").mkpath == root + "a/b/c"
  p (root + "a/b/c").directory?
  (root + "a/b/f.rb").write("x")
  (root + "a/g.rb").write("y")
  p (root + "a/b/c").empty?
  p rels(root.children, root)
  p names(root.children(false))
  p rels((root + "a").each_child, root)
  (root + "a").each_child(false) { |c| puts "child #{c}" if c.to_s == "g.rb" }
  p names(root.entries)
  p rels(root.glob("**/*.rb"), root)
  p names(Pathname.glob("**/*.rb", base: dir))
  p rels(Pathname.glob(File.join(dir, "a", "*")), root)
  p rels(Pathname.glob([File.join(dir, "*.txt"), File.join(dir, "a/*.rb")]), root)
  p Pathname.pwd == Pathname.new(Dir.pwd)
  p Pathname.getwd.absolute?
  p (root + "d").mkdir
  p (root + "d").rmdir
  p (root + "d").exist?
  p (root + "moved.txt").delete
  p (root + "moved.txt").exist?
  begin
    (root + "missing").read
  rescue IOError, SystemCallError => e
    puts "error"
  end
  begin
    (root + "missing").mkdir
    (root + "x/y").mkdir
  rescue IOError, SystemCallError => e
    puts "error"
  end
  p (root + "a").rmtree == root + "a"
  p (root + "a").exist?
  p (root + "a").rmtree.exist?
  p rels(root.children, root)
end
p Pathname.new(".").directory?
p Pathname.new(".").file?
p Pathname.new("_no_such_dir").directory?

