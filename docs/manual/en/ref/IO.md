# IO

IO is the type of open files and of the program's standard streams. Its values come from operations: `IO.stdin`, `IO.stdout`, and `IO.stderr` give the standard streams, `File.open(path, mode)` gives a file (Sake has no `$stdout` or `STDOUT`, see [Values and types](../03-values.md)). Files and streams share one type, so a function that takes an IO writes to either. There is no IO literal.

Ruby's `io.puts(x)` is written `IO.puts(io, x)`. Of Ruby's `IO` methods only those listed here exist. A failing read or write (a closed IO, an IO not opened for that direction, an error from the OS) is an `IOError` (Ruby's `Errno::ENOENT` and the like are all `IOError`, see [Exceptions](../08-exceptions.md)).

The only operators on IO are `==` and `!=` (equal when the two values are the same stream or the same result of `File.open`). An operation without arguments, `IO.stdout()`, can also be written `IO.stdout`.

## stdin, stdout, stderr

`IO.stdin()`

`IO.stdout()`

`IO.stderr()`

The program's standard input, standard output, and standard error as IO values. Every call gives the same value: `IO.stdout == IO.stdout` is true. `Kernel.puts` and `Kernel.p` write to `IO.stdout`; `Kernel.gets` reads from `IO.stdin`. Writing to `IO.stderr` flushes stdout first, so the lines of the two streams keep their order. Do not `IO.close` a standard stream: afterwards any output (`p`, ...) stops the program with Ruby's `IOError`.

```ruby
out = IO.stdout
IO.puts(out, "hello")            # => hello
p(IO.stdout == out)              # => true
p(IO.stdout == IO.stderr)        # => false
p(IO.stdin)                      # => #<IO:<STDIN>>
```

## puts

`IO.puts(x, *Any)`

Writes each argument to `x` as `Kernel.puts` does and returns nil. One line per argument (a newline is added unless the text ends with one); an Array or Tuple is flattened to one line per element, an empty Array is an empty line, and no arguments give one empty line. Values other than Strings are written as `Kernel.to_s` shows them (nil as an empty line, a Symbol as its name). A closed or read-only IO is an `IOError`.

```ruby
out = IO.stdout
IO.puts(out, "a", 1)             # => a
                                 # => 1
IO.puts(out, [1, Array[2, 3]])   # => 1
                                 # => 2
                                 # => 3
IO.puts(out, "x\n")              # => x
p(IO.puts(out, :s))              # => s
                                 # => nil
```

## print

`IO.print(x, *Any)`

Writes the `to_s` of each argument to `x` without newlines and returns nil (Ruby's `io.print`). An Array is written as `[1, 2]`, nil as an empty string.

```ruby
out = IO.stdout
IO.print(out, "a", 1, :s, "\n")  # => a1s
IO.print(out, Array[1, 2], "\n") # => [1, 2]
```

## write

`IO.write(x, String)`

Writes the string to `x` as it is and returns the number of bytes written (an Integer). No newline is added. The argument must be a String; another type is a `type` problem statically (unlike `puts` and `print`, nothing is converted).

```ruby
p(IO.write(IO.stdout, "ab\n"))   # => ab
                                 # => 3
p(IO.write(IO.stdout, "日本\n")) # => 日本
                                 # => 7
```

```ruby error
IO.write(IO.stdout, 1)           # !> IO.write: argument 2 must be String, but is Integer
```

## flush

`IO.flush(x)`

Writes out buffered output and returns `x`. `IO.write` and `IO.puts` to a file from `File.open` are buffered; the data reaches the file on `flush` or `close`.

```ruby
f = File.open("log.txt", "w")
IO.puts(f, "a")
p(File.read("log.txt"))          # => ""
IO.flush(f)
p(File.read("log.txt"))          # => "a\n"
IO.close(f)
```

## gets

`IO.gets(x)`

The next line including its newline (Ruby's `io.gets`), or nil at the end. The result is `String | nil`, so `--strict` (level 2) reports using it unchecked as a `nil` problem: test it first, as `if line` or `while (line = IO.gets(io))`. A write-only IO is an `IOError`.

```ruby
io = IO.stdin
line = IO.gets(io)
if line
  p(String.to_i(line))           # => 3
end
while (l = IO.gets(io))
  p(l)                           # => "1 2\n"
end
p(IO.gets(io))                   # => nil
```

```ruby error
line = IO.gets(IO.stdin)
p(String.upcase(line))           # !> argument 1 may be nil
```

## read

`IO.read(x, [Integer])`

`IO.read(io)` reads everything from the current position to the end and returns a String (at the end it is the empty string `""`, never nil). `IO.read(io, n)` reads up to `n` bytes (bytes, not characters) and returns nil when the end has been reached (with `n` 0 it is always `""`). Only this two-argument form is `String | nil` and checked at level 2. An IO not opened for reading is an `IOError`.

```ruby
io = IO.stdin
p(IO.read(io, 2))                # => "3\n"
p(IO.read(io))                   # => "1 2\n"
p(IO.read(io))                   # => ""
p(IO.read(io, 1))                # => nil
```

## getc

`IO.getc(x)`

The next character as a String, or nil at the end (`String | nil`, level 2).

```ruby
io = IO.stdin
p(IO.getc(io))                   # => "3"
p(IO.getc(io))                   # => "\n"
IO.read(io)
p(IO.getc(io))                   # => nil
```

## readlines

`IO.readlines(x)`

The rest, from the current position to the end, as an Array of Strings, one per line (each keeps its newline). At the end it is an empty Array.

```ruby
p(IO.readlines(IO.stdin))        # => ["3\n", "1 2\n"]
p(IO.readlines(IO.stdin))        # => []
```

## each_line

`IO.each_line(x) { }`

Passes each line (a String with its newline) from the current position to the end to the block and returns `x`. The block's value is not used. As Ruby's `io.each_line`; the block is required.

```ruby
r = IO.each_line(IO.stdin) { |l| p(String.chomp(l)) }   # => "3"
                                                         # => "1 2"
p(r == IO.stdin)                 # => true
```

## eof?

`IO.eof?(x)`

True when the read position is at the end. A write-only or closed IO is an `IOError`.

```ruby
io = IO.stdin
p(IO.eof?(io))                   # => false
IO.read(io)
p(IO.eof?(io))                   # => true
```

## seek

`IO.seek(x, Integer, [Integer|Symbol])`

Moves the read/write position and returns 0 (Ruby's `io.seek`). The second argument is the offset, the third the origin, the start of the file (`0`) when omitted: `0`/`:SET` counts from the start, `1`/`:CUR` from the current position, `2`/`:END` from the end (with a negative offset). Only these three Symbols exist; another Symbol stops the program with Ruby's `NameError`. A stream that cannot seek (`IO.stdin` as a pipe) is an `IOError`.

```ruby
File.write("a.txt", "hello\n")
f = File.open("a.txt")
IO.seek(f, 2)
p(IO.read(f, 2))                 # => "ll"
IO.seek(f, -2, :END)
p(IO.read(f))                    # => "o\n"
p(IO.seek(f, 1, :SET))           # => 0
p(IO.getc(f))                    # => "e"
IO.close(f)
```

## pos

`IO.pos(x)`

The current position (bytes from the start, an Integer). A stream that cannot seek is an `IOError`.

```ruby
File.write("a.txt", "日本\n")
f = File.open("a.txt")
p(IO.pos(f))                     # => 0
IO.getc(f)
p(IO.pos(f))                     # => 3
IO.close(f)
```

## rewind

`IO.rewind(x)`

Moves the position back to the start and returns 0, to read the file again.

```ruby
File.write("a.txt", "one\n")
f = File.open("a.txt")
p(IO.gets(f))                    # => "one\n"
p(IO.rewind(f))                  # => 0
p(IO.gets(f))                    # => "one\n"
IO.close(f)
```

## size

`IO.size(x)`

The size of the open file in bytes (an Integer), including writes not yet flushed. It does not apply to an IO that is not a file (a stream such as `IO.stdin`): that stops the program with Ruby's `NoMethodError`, not an `IOError`.

```ruby
f = File.open("a.txt", "w")
IO.write(f, "abc")
p(IO.size(f))                    # => 3
IO.close(f)
```

## truncate

`IO.truncate(x, Integer)`

Cuts the file to `n` bytes and returns 0. A file not opened for writing is an `IOError`.

```ruby
File.write("a.txt", "hello")
r = File.open("a.txt", "r+") { |f| IO.truncate(f, 3) }
p(r)                             # => 0
p(File.read("a.txt"))            # => "hel"
```

```ruby error
File.write("a.txt", "hello")
f = File.open("a.txt")
IO.truncate(f, 1)                # !> IOError: IO.truncate: not opened for writing
```

## close

`IO.close(x)`

Closes the IO and returns nil. Buffered output is written out. Closing a closed IO does nothing (as in Ruby). Reading or writing a closed IO is an `IOError`. The block form of `File.open` closes the file after the block, so `close` is needed only for a file opened by hand.

```ruby
f = File.open("a.txt", "w")
IO.write(f, "x")
p(IO.close(f))                   # => nil
p(IO.close(f))                   # => nil
p(File.read("a.txt"))            # => "x"
```

```ruby error
f = File.open("a.txt", "w")
IO.close(f)
IO.write(f, "x")                 # !> IOError: IO.write: closed stream
```

## closed?

`IO.closed?(x)`

True when the IO is closed. The IO passed to the block of `File.open` is closed after the block.

```ruby
kept = IO.stdout
File.open("a.txt", "w") { |f| kept = f }
p(IO.closed?(kept))              # => true
p(IO.closed?(IO.stdout))         # => false
```

## tty?

`IO.tty?(x)`

True when the IO is a terminal (Ruby's `io.tty?`); false for a file or a pipe. Under the checker the standard streams are pipes, so it is false there too.

```ruby
f = File.open("a.txt", "w")
p(IO.tty?(f))                    # => false
IO.close(f)
```

## ==, !=

`IO.==(x, Any)`

`IO.!=(x, Any)`

Two IO values are equal when they are the same stream or the same result of `File.open` (`!=` is the negation). Opening the same path twice gives two different values. A value that is not an IO is never equal.

```ruby
f = File.open("a.txt", "w")
g = File.open("a.txt", "w")
p(f == f)                        # => true
p(f == g)                        # => false
p(IO.stdout != IO.stdin)         # => true
IO.close(f)
IO.close(g)
```
