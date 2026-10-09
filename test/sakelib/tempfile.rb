require "tempfile"
require "tmpdir"

def try
  yield
rescue IOError, ArgumentError, EOFError, Errno::EINVAL, Errno::ENOENT => e
  puts "error: #{e.message.sub(/\/\S+/, "<path>")}"
end

# The names are random: the tests print the pattern of the basename, never the name.
def name_pattern(path) = File.basename(path).sub(/\d{8}-\d+-[0-9a-z]+/, "<stamp>")

# Tempfile.new: a new empty file in Dir.tmpdir, mode 0600
t = Tempfile.new("foo")
path = t.path
p path != nil
path => String
p File.exist?(path)
p File.dirname(path) == Dir.tmpdir
p name_pattern(path)
p File.size(path)
p t.size
p t.closed?
p t.inspect == "#<Tempfile:#{path}>"

# write, read, rewind, pos, seek, eof?
p t.write("hello")
p t.pos
p t.read
p t.rewind
p t.read
p t.eof?
p t.size
p File.read(path)
p t.write(" ", "wörld", 1)
t.rewind
p t.read(5)
p t.seek(1)
p t.read(4)
p t.seek(-1, 2)
p t.read
t.pos = 0
p t.write("J")
p t.pos
p File.read(path)
p t.truncate(5)
p File.read(path)
p t.length
try { t.pos = -1 }
try { t.read(-1) }

# puts, print, <<, printf, putc, gets, readline, readlines, each_line, getc
t.truncate(0)
t.rewind
p t.puts("a", ["b", "c"], 1)
p t.print("x", :y)
t2 = t << "z" << 2
p t2.path == path
p t.printf("|%03d\n", 7)
p t.putc("qq")
t.flush
p File.read(path)
t.rewind
p t.gets
p t.gets(chomp: true)
p t.readline
p t.getc
p t.getbyte
p t.readlines
p t.gets
try { t.readline }
t.rewind
t.each_line { |l| print l.length, "," }
puts
t.rewind
p (t.each_line(chomp: true) { |l| print l, "|" }).path == path
puts
p (t.flush).path == path
p t.fsync

# close, open, close!, unlink: the file stays until unlinked
p t.close
p t.closed?
p File.exist?(path)
p t.size
try { t.write("x") }
try { t.read }
try { t.pos }
p t.path == path
p t.open.path == path
p t.closed?
p t.pos
p t.gets
p t.unlink
p t.path
p t.inspect
p File.exist?(path)
p t.unlink
p t.delete
p t.close
p t.closed?
try { t.open }

# close! and a [prefix, suffix] basename, an explicit directory
Dir.mktmpdir do |dir|
  t = Tempfile.new(["report-", ".txt"], dir)
  path = t.path
  path => String
  p File.dirname(path) == dir
  p name_pattern(path)
  p File.extname(path)
  t.write("data")
  p t.close!
  p File.exist?(path)
  p t.path
  p Dir.children(dir).size
  t = Tempfile.new("", dir)
  path = t.path
  path => String
  p name_pattern(path)
  t.close(true)
  p Dir.children(dir)
  # characters other than , - . 0-9 A-Z _ a-z ~ are dropped from the names
  t = Tempfile.new("a/b c", dir)
  path = t.path
  path => String
  p name_pattern(path)
  t.close!
  t = Tempfile.new(["x y", "/.z"], dir)
  path = t.path
  path => String
  p name_pattern(path)
  t.close!
  p Dir.children(dir)
end

# Tempfile.create with a block: the file is removed afterwards; the value is the block's
kept = ""
r = Tempfile.create("blk") do |f|
  kept = f.path || ""
  p name_pattern(kept)
  p File.exist?(kept)
  f.write("in block")
  f.rewind
  f.read
end
p r
p File.exist?(kept)

# Tempfile.create without a block: an open file that stays
f = Tempfile.create(["c-", ".log"])
path = f.path || ""
p name_pattern(path)
p f.write("abc\ndef\n")
f.rewind
p f.gets
p f.read
p f.close
p File.read(path)
p File.exist?(path)
File.unlink(f.path)
p File.exist?(path)

# two files at once have different names
a = Tempfile.new("same")
b = Tempfile.new("same")
p a.path != b.path
a.write("A")
b.write("B")
a.rewind
b.rewind
p a.read + b.read
a.close!
b.close!
p a.path
