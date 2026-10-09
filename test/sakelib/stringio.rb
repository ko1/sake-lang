require "stringio"

def try
  yield
rescue IOError, ArgumentError, EOFError, Errno::EINVAL => e
  puts "error: #{e.message}"
end

# read, read(n), eof?
io = StringIO.new("abc\ndef\n")
p io.string
p io.pos
p io.eof?
p io.read(2)
p io.pos
p io.read
p io.read
p io.read(1)
p io.read(0)
p io.eof?
p io.size
p io.length
try { io.read(-1) }

# gets: separators, limit, chomp, lineno
io = StringIO.new("abc\ndef\nghi")
p io.gets
p io.lineno
p io.gets("e")
p io.gets(chomp: true)
p io.gets(2)
p io.gets(nil)
p io.gets
p io.lineno
io.lineno = 10
p io.lineno
p io.rewind
p io.lineno
p io.gets("\n", 2)
p io.gets("", chomp: true)
p io.gets(0)
io = StringIO.new("a\n\n\nb\nc")
p io.gets("")
p io.pos
p io.gets("")
p io.gets("")
io = StringIO.new("héllo wörld")
p io.gets(2)
p io.getc
p io.getc
p io.read(2)
p io.read

# readline, readlines, each_line
io = StringIO.new("a\nb\n\nc")
p io.readline
p io.readlines
p io.readlines
try { io.readline }
io.rewind
p io.readlines(chomp: true)
io.rewind
p io.readlines("")
io.rewind
r = io.each_line { |l| p l }
p r == io
io.rewind
io.each_line(chomp: true) { |l| print l, "|" }
puts
io.rewind
io.each("\n") { |l| print l.length }
puts

# getc, ungetc, getbyte, ungetbyte, readchar, readbyte, each_char, each_byte
io = StringIO.new("abc")
p io.getc
p io.ungetc("Z")
p io.string
p io.pos
p io.getc
p io.getbyte
p io.readchar
p io.getc
p io.getbyte
try { io.readchar }
try { io.readbyte }
p io.ungetc("XYZ")
p io.string
p io.pos
io.rewind
p io.ungetbyte(65)
p io.string
p io.ungetc(66)
p io.string
io.rewind
io.each_char { |c| print c, "." }
puts
io.rewind
io.each_byte { |b| print b, "," }
puts
io.rewind
p io.ungetc("ab")
p io.string
p io.pos

# write, <<, print, puts, printf, putc
io = StringIO.new
p io.write("hello")
p io.write(" ", "wörld", 1)
p io.string
p io.pos
io.pos = 0
p io.write("J")
p io.string
p io.pos
p io.read
io.pos = 20
p io.write("Q")
p io.string
p io.size
io = StringIO.new
p io.puts("a", "b\n", 1, nil, ["x", ["y", "z"]], [])
p io.string
io.puts
p io.string
io = StringIO.new
p io.print("a", 1, nil, :b, 2.5)
p io.string
(io << "x") << 42
p io.string
io2 = io << "y" << :z
p io2 == io
p io.string
p io.printf("%05.1f|%-3s|%x", 3.14159, "ab", 255)
p io.string
io = StringIO.new
p io.putc("xy")
p io.putc(65)
p io.putc(256 + 66)
p io.string

# pos=, seek, rewind, tell
io = StringIO.new("abcdef")
p io.seek(2)
p io.tell
p io.read(1)
p io.seek(1, 1)
p io.pos
p io.seek(-1, 2)
p io.read
p io.seek(0, IO::SEEK_SET)
p io.read(1)
p io.seek(-1, IO::SEEK_CUR)
p io.read(1)
p io.seek(-2, IO::SEEK_END)
p io.read
try { io.seek(-10) }
try { io.seek(0, 5) }
try { io.pos = -1 }
p io.pos = 3
p io.read
p io.pos = 100
p io.read
p io.read(1)
p io.eof?
p io.rewind
p io.gets

# truncate, string=, reopen, pread
io = StringIO.new("abcdef")
io.read(4)
p io.truncate(2)
p io.string
p io.pos
p io.read
p io.truncate(4)
p io.string
try { io.truncate(-1) }
p io.string = "new string"
p io.pos
p io.read(3)
p io.pread(3, 4)
p io.pread(0, 4)
p io.pos
try { io.pread(3, 40) }
r = io.reopen("xyz", "r")
p r == io
p io.read
try { io.write("q") }

# modes
io = StringIO.new("abc", "r")
try { io.write("x") }
try { io.puts("x") }
p io.read
io = StringIO.new("abc", "w")
p io.string
p io.write("w")
try { io.read }
try { io.gets }
try { io.eof? }
io = StringIO.new("abc", "w+")
p io.string
io = StringIO.new("abc", "a")
p io.write("d")
p io.string
p io.pos
try { io.read }
io = StringIO.new("abc", "a+")
p io.read
io.rewind
p io.write("d")
p io.string
p io.read
io = StringIO.new("abc", "rb")
p io.read(1)
io = StringIO.new("abc", "r+")
io.read(1)
p io.write("X")
p io.string
try { StringIO.new("abc", "q") }

# the String is shared and changed in place
s = "shared"
io = StringIO.new(s)
io.write("SH")
p s
io.truncate(3)
p s

# close, close_read, close_write, closed?
io = StringIO.new("abc")
p io.closed?
p io.closed_read?
p io.closed_write?
p io.close_write
p io.closed?
p io.closed_write?
try { io.write("x") }
p io.read(1)
p io.close_read
p io.closed?
try { io.read }
try { io.seek(0) }
p io.string
io = StringIO.new("abc", "r")
try { io.close_write }
p io.closed_write?
p io.close
p io.closed?
try { io.read }
try { io.getc }
try { io.eof? }
p io.string = "again"
p io.closed?
try { io.read }
p io.reopen("open again") == io
p io.closed?
p io.read
p io.write("!")

# the IO-compatible no-ops
io = StringIO.new("abc")
p io.flush == io
p io.fsync
p io.sync
p io.sync = false
p io.fileno
p io.isatty
p io.tty?
p io.pid
p io.binmode == io
p io.internal_encoding
p io.readpartial(2)
p io.read_nonblock(5)
try { io.readpartial(1) }
