# Built-in operations

There are about 550 built-in operations, and their names are those of Ruby's core library. This chapter is a guide by namespace: what each type is for, the two or three operations you reach for first, a short example, and a link to the chapter with the details. **Every operation's exact signature, arguments, nil cases, exceptions, and examples are in Part 2, the built-in reference, one chapter per type** ([Array](ref/Array.md), [String](ref/String.md), [Hash](ref/Hash.md), [Kernel](ref/Kernel.md), ...).

The table in each section groups the operations by what you want to do; the "Result" column gives the result type. Operations marked "block" require one. `[x]` is an optional argument. The rules for operators (`+`, `<`, `[]`) are in [Operators and indexing](05-operators.md); the properties of each type's values are in [Values and types](03-values.md).

## Kernel

Kernel is the set of operations callable by bare name from anywhere in the program. You write `puts(x)`, `Integer(s)`, `loop { }`, and need not write `Kernel.puts(x)`. The first ones you use are `p` and `puts` for output, `Integer(s)` to convert a string to a number, and `loop` to repeat. Details: [Kernel](ref/Kernel.md).

```ruby
puts("total:", 3)
# => total:
# => 3
p(format("%05.1f", 3.14159))     # => "003.1"
p(Integer("42") + 1)             # => 43
x = loop { break 7 }
p(x)                             # => 7
p(Math.PI > 3)                   # => true
```

| Operation | Result | Notes |
|---|---|---|
| `puts(*xs)` | nil | prints like Ruby's `puts`; Arrays and Tuples print one element per line |
| `print(*xs)` | nil | no newline |
| `p(x)`, `p(x, y)`, `pp(x)` | x · `[x, y]` · x | prints each argument in Ruby's `inspect` format, one per line; `p()` gives nil |
| `format(fmt, *xs)`, `sprintf` | String | Ruby's format; arguments are Integer, Float, String, Symbol, nil, true, false |
| `Integer(x)`, `Float(x)`, `Rational(a, [b])`, `Complex(re, [im])` | the number | Ruby's strict conversions; `ArgumentError` on bad input |
| `rand`, `rand(n)`, `srand(seed)` | Float, or Integer/Float below n | |
| `sleep(secs)` | Integer | |
| `loop { }` | the value of a `break` | runs the block until a `break` |
| `dup(x)` | a copy of x | Ruby's `obj.dup`; a type that defines `dup` gets its own |
| `gets` | String or nil | a line of standard input |
| `exit(status)` | | Integer, or true for 0 / false for 1 (default 0); `ensure` clauses run; code after it is not reached |
| `warn(x, ...)` | nil | to the error stream, as `puts` does to the output |
| `system(cmd)` | true / false / nil | Ruby's `system` |
| `at_exit { }` | nil | a block run when the program ends |
| `ARGV` | Array of String | the program's arguments; written like Ruby's constant, but an operation (`Kernel.ARGV`); every use gives the same Array, so `Array.shift(ARGV)` works |
| `Kernel.PROGRAM_NAME` | String | the running file's name; unlike `ARGV` it cannot be written bare (a capitalized name is a type) |
| `equal?(a, b)` | true/false | identity |
| `block_given?` | true/false | whether the current function got a block |

- **Constants are operations.** `Math::PI`, `Math::E`, `Float::INFINITY`, `Float::NAN`, `Float::EPSILON`, `Float::MAX`, `Float::MIN` are read as operations (`Math.PI`), as `ARGV` is. Sake has no value constants, and no other nested names.

## Integer / Float

Integer is an integer without an upper bound; Float is a double-precision floating-point number. Arithmetic and comparison are written with operators; conversions such as `Integer.to_s(n, 16)` and iterations such as `Integer.times(n) { }` are called with the type. The first ones you use are `/` and `%` (integer division between Integers), `Float.round`, and `Integer.times`. Details: [Integer](ref/Integer.md), [Float](ref/Float.md), [Arithmetic](ref/Arithmetic.md).

```ruby
p(7 / 2)                         # => 3
p(7.0 / 2)                       # => 3.5
p(Integer.divmod(7, 2))          # => [3, 1]
p(Integer.to_s(255, 16))         # => "ff"
p(Float.round(3.14159, 2))       # => 3.14
Integer.times(3) { |i| print(i) }
puts                             # => 012
```

| Operation | Result |
|---|---|
| `+ - * / % **` | Integer (Float with a Float) |
| `< <= > >= == !=` | true/false |
| `Integer.to_s(n, base = 10)`, `to_f`, `abs`, `succ`, `pred` | String, Float, Integer, Integer, Integer |
| `even?`, `odd?`, `zero?` | true/false |
| `times(n) { \|i\| }` · `upto(a, b) { }` · `downto(a, b) { }` · `step` | n · a · a (block) |
| `& \| ^ << >>` | Integer |
| `divmod(a, b)` | `[quotient, remainder]` Tuple (`[Integer, Float]` for a Float) |
| `gcd`, `lcm`, `pow(a, b, [mod])`, `bit_length`, `sqrt(n)`, `clamp(n, lo, hi)` | Integer |
| `digits` · `chr` · `between?(n, lo, hi)` | Array of Integer · String · true/false |
| `Float.to_i`, `floor`, `ceil`, `truncate` · `round(f)` / `round(f, digits)` | Integer · Integer / Float |
| `nan?` · `finite?` · `infinite?` | true/false · true/false · 1, -1, or nil |
| `Float.to_r`, `rationalize` | Rational |

- **Rounding any real number.** `Arithmetic.round(x)`, `floor`, `ceil`, `truncate` (with an optional digit count), `abs`, `to_f`, `to_i`, `zero?` take any real number (Integer, Float, Rational), as Ruby's `x.round` does; the result's type follows x's (round without digits gives an Integer). `Float.round` names a Float only.

## String

A String is a sequence of characters with an encoding, and it is mutable. An operation whose name ends in `!` changes the subject in place; the others return a new String. The first ones you use are `String.split`, `String.sub`/`gsub`, `String.include?`, and `+` to concatenate. Details: [String](ref/String.md).

```ruby
s = "Hello, World"
p(String.length(s))              # => 12
p(String.upcase(s))              # => "HELLO, WORLD"
p(String.split(s, ", "))         # => ["Hello", "World"]
p(String.sub(s, "World", "Sake"))   # => "Hello, Sake"
p(String.include?(s, "World"))   # => true
p(String.index(s, "x"))          # => nil
p(s + "!")                       # => "Hello, World!"
```

| Purpose | Operation | Result |
|---|---|---|
| concatenate, repeat, format | `+(a, b)`, `*(s, n)`, `%` | String |
| compare | `== != < <= > >=` | true/false |
| length and numbers | `length`, `size`, `count(s, chars)`, `to_i(s, base = 10)` · `to_f` | Integer · Float |
| transform | `upcase`, `downcase`, `capitalize`, `swapcase`, `reverse`, `strip`, `lstrip`, `rstrip`, `chomp`, `chop`, `to_s` | String |
| replace | `sub(s, pat, repl)`, `gsub(...)` | String; `sub!`, `gsub!` in place |
| pad and swap characters | `ljust(s, n, [pad])`, `rjust`, `center` · `tr(s, a, b)`, `delete(s, chars)`, `squeeze(s, [chars])`, `succ`, `next` | String |
| query | `empty?`, `include?(s, t)`, `start_with?`, `end_with?`, `match?(s, re)`, `casecmp?` | true/false |
| split | `chars`, `lines`, `bytes`, `split(s, [sep, [limit]])`, `scan(s, re)` | Array |
| positions | `index(s, t, [start])`, `rindex`, `byteindex` | Integer or nil |
| regexp match | `match(s, re, [pos])` | MatchData or nil |
| to other types | `ord` · `hex` · `oct` · `to_sym`, `intern` | Integer · Symbol |
| bytes and conversions | `byteslice(s, i, [n])`, `b`, `force_encoding(s, enc)`, `encode`, `encoding`, `valid_encoding?`, `unpack(s, fmt)`, `unpack1` | as Ruby's |
| iterate | `each_line(s) { }`, `each_char(s) { }`, `each_byte` | s (block) |

- **The repl of a replacement.** The repl of `sub` and `gsub` is a String (with `\1`), a Hash (match => replacement), or a block `{ |m| ... }`.

## Array

An Array is a sequence whose length varies. `Array[1, 2]` makes one (the literal `[1, 2]` is a Tuple). The first ones you use are `Array.push`, `Array.each`, `Array.map`, and `Array.select`. Details: [Array](ref/Array.md).

```ruby
xs = Array[3, 1, 2]
Array.push(xs, 5)
p(xs)                                      # => [3, 1, 2, 5]
p(Array.map(xs) { |x| x * 2 })             # => [6, 2, 4, 10]
p(Array.select(xs) { |x| x > 1 })          # => [3, 2, 5]
p(Array.sort(xs))                          # => [1, 2, 3, 5]
p(Array.reduce(xs, 0) { |acc, x| acc + x })   # => 11
p(Array.first(xs))                         # => 3
p(Array.join(xs, "-"))                     # => "3-1-2-5"
p(Array.tally(Array["a", "b", "a"]))       # => {"a" => 2, "b" => 1}
```

| Purpose | Operation | Result |
|---|---|---|
| make | `Array[...]` · `Array.new(n)`, `Array.new(n, v)`, `Array.new(n) { \|i\| }` | a new Array |
| length and query | `length`, `size` · `empty?`, `include?(a, x)` | Integer · true/false |
| add and remove (in place) | `push(a, *xs)`, `append`, `unshift`, `concat(a, b)`, `insert(a, i, *xs)`, `delete_if`, `clear` | a |
| one element | `first`, `last`, `min`, `max`, `pop`, `shift`, `at(a, i)`, `sample`, `delete(a, x)`, `delete_at(a, i)` | an element, or nil |
| a part | `first(a, n)`, `last(a, n)`, `shift(a, n)`, `take`, `drop`, `slice(a, i, n)` | a new Array |
| fail when missing | `fetch(a, i, [default])` | the element, the default, or `IndexError` |
| to a String | `join(a, [sep])` | String |
| sum | `sum(a, [init])` | the sum (see below) |
| reorder and the like | `reverse`, `sort`, `sort_by`, `uniq`, `compact`, `flatten`, `rotate`, `shuffle`, `dup` | a new Array |
| iterate | `each`, `each_with_index`, `each_slice(a, n)`, `each_cons(a, n)`, `cycle` | a (block) |
| map and filter | `map`, `flat_map`, `select`, `filter`, `reject`, `partition`, `group_by`, `tally`, `to_h`, `zip`, `product` | a new Array / Hash / Tuple |
| test and count | `any?`, `all?`, `none?`, `count` | true/false · Integer (block optional) |
| fold | `reduce(a, init) { }`, `inject`, `each_with_object(a, memo) { }` | the accumulated value |
| search | `find`, `detect`, `min_by`, `max_by`, `index(a, x)`, `find_index`, `assoc`, `rassoc` | an element or nil · Integer or nil |
| rewrite (in place) | `map!`, `select!`, `reject!`, `sort!`, `uniq!`, `compact!`, `flatten!`, `reverse!`, `slice!`, `fill`, `replace` | a |
| to bytes | `pack(a, fmt)` | String |

- **`sum`.** The elements are numbers, or of a type including `Arithmetic`. An empty Array gives `init` (default 0).
- **Iteration without a block.** `each_slice` and the like, called without a block, give an Array.
- **Rewriting in place.** `map!` and the others are for mappings within one type.

## Tuple, Range

A Tuple is a sequence with a fixed length and a type per position; the literal `[1, "a"]` makes one. A Range is a pair of ends: `1..5`, `1...5`, and the endless `1..`. Tuples have few operations, and the usual move is `Tuple.to_a` to get an Array. For Ranges, `Range.each` counts, and `Range.to_a` and `Range.include?` are the common ones. Details: [Tuple](ref/Tuple.md), [Range](ref/Range.md).

```ruby
t = [1, "a"]
p(Tuple.size(t))                 # => 2
p(Tuple.to_a(t))                 # => [1, "a"]
p(Tuple.max([3, 7, 5]))          # => 7
p(Range.to_a(1..5))              # => [1, 2, 3, 4, 5]
p(Range.sum(1..5))               # => 15
p(Range.include?(1...5, 5))      # => false
p(Range.map(1..3) { |i| i * i })    # => [1, 4, 9]
p(Range.first(1.., 3))           # => [1, 2, 3]
```

| Operation | Result |
|---|---|
| `Tuple.size`, `length` · `to_a` · `max`, `min` · `minmax` | Integer · Array · an element (never nil) · `[min, max]` |
| `Range.each`, `each_with_index`, `step(r, n)` | r (block) |
| `to_a`, `map`, `select`, `filter`, `reject`, `zip` | Array |
| `reduce`, `inject` · `sum` · `size` · `count` | accumulated value · Integer |
| `any?`, `all?`, `none?` · `find`, `detect` · `include?`, `cover?`, `member?`, `exclude_end?` | true/false · an element or nil · true/false |
| `first`, `last`, `min`, `max`, `begin`, `end` | an element or nil (`first(r, n)`, `last(r, n)` give an Array) |

## Hash, Set

A Hash maps keys to values; `Hash["a" => 1]` or `Hash.new(default)` makes one (`{a: 1}` is a Record). A Set is a collection without duplicates, made with `Set[1, 2]`. The first ones you use are the index `h[k]` and `h[k] = v`, `Hash.each`, `Hash.fetch`, and `Set.add` and `Set.include?`. Details: [Hash](ref/Hash.md), [Set](ref/Set.md).

```ruby
h = Hash["a" => 1]
h["b"] = 2
p(h)                                       # => {"a" => 1, "b" => 2}
p(h["c"])                                  # => nil
p(Hash.fetch(h, "a"))                      # => 1
p(Hash.map(h) { |k, v| [k, v * 10] })      # => [["a", 10], ["b", 20]]
counts = Hash.new(0)
counts["x"] += 1
p(counts)                                  # => {"x" => 1}
s = Set[1, 2]
Set.add(s, 2)
p(s)                                       # => Set[1, 2]
p(Set.include?(s, 2))                      # => true
p(Set.union(s, Set[9]))                    # => Set[1, 2, 9]
```

| Purpose | Operation | Result |
|---|---|---|
| make | `Hash[k => v, ...]` · `Hash.new([default])` · `Set[...]` | a new Hash · Set |
| length and query | `length`, `size`, `empty?`, `key?`, `has_key?`, `include?`, `member?`, `value?` | Integer · true/false |
| one entry | `fetch(h, k, [default])` · `dig(h, k)` · `delete(h, k)` · `key(h, v)` | the value · value or nil · removed value or nil · key or nil |
| rewrite (in place) | `store(h, k, v)`, `merge!`, `update`, `clear`, `transform_values!`, `transform_keys!`, `select!`, `reject!`, `compact!` | h |
| a new Hash | `merge(a, b)`, `invert`, `select`, `filter`, `reject`, `transform_values`, `transform_keys`, `compact`, `slice`, `except` | a new Hash |
| to an Array | `keys` · `values` · `to_a` · `map` · `sort_by` · `group_by` · `partition` | Array |
| iterate | `each`, `each_pair`, `each_key`, `each_value` | h (block) |
| test and search | `any?`, `all?`, `none?`, `count`, `sum`, `find`, `detect`, `min_by`, `max_by` | with a block |
| rewrite a Set (in place) | `Set.add(s, x)`, `add?`, `delete`, `merge`, `subtract`, `clear` | s |
| Set to Array | `to_a`, `each`, `map`, `select`, `filter`, `reject` | Array |
| set operations | `union`, `intersection`, `difference`, `\|`, `&`, `-` · `subset?`, `superset?`, `disjoint?`, `intersect?` | a new Set · true/false |

## Regexp, MatchData, Symbol, Time, Math

A Regexp is a regular expression, made by the literal `/\d+/`. The result of a match is a MatchData, or nil when nothing matched. A Symbol is a name as a value (`:name`), a Time is one instant, and Math is the set of elementary functions. The first ones you use are `Regexp.match` and `m[1]`, `String.scan`, `Time.now`, and `Math.sqrt`. Details: [Regexp](ref/Regexp.md), [MatchData](ref/MatchData.md), [Symbol](ref/Symbol.md), [Time](ref/Time.md), [Math](ref/Math.md).

```ruby
m = Regexp.match(/(\d+)-(\d+)/, "tel 03-1234")
if m
  p(m[1])                        # => "03"
  p(MatchData.captures(m))       # => ["03", "1234"]
end
p(String.scan("a1 b22", /\d+/))  # => ["1", "22"]
p(Symbol.to_s(:name))            # => "name"
t = Time.at(0, in: "UTC")
p(Time.year(t))                  # => 1970
p(Time.strftime(t, "%Y-%m-%d"))  # => "1970-01-01"
p(Math.sqrt(16))                 # => 4.0
```

| Operation | Result |
|---|---|
| `Regexp.new(s, flags = "")` · `escape(s)` · `source(r)` · `match(r, s, [pos])` · `match?` | Regexp · String · String · MatchData or nil · true/false (flags: letters of `imx`) |
| `MatchData.captures` · `named_captures` · `names` · `to_a` · `to_s`, `pre_match`, `post_match` · `begin(m, i)`, `end(m, i)` | Array · Hash · Array · Array · String · Integer |
| `Symbol.to_s` · `length`, `size` | String · Integer |
| `Time.now` · `at(seconds, [in:])` · `new(y, [m, d, h, min, s, zone])` · `utc(t)`, `getutc` · `getlocal(t, [zone])`, `localtime` | Time |
| `year`, `month`, `day`, `hour`, `min`, `sec`, `wday`, `yday`, `to_i`, `utc_offset` · `to_f` · `to_s`, `strftime(t, fmt)` · `zone` · `utc?` | Integer · Float · String · String or nil · true/false |
| `Math.sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10`, `atan2(y, x)`, `hypot(x, y)` | Float |

- **No `Symbol.to_proc`.** A block is not a value, so `&:name` cannot be written ([Functions and blocks](04-functions.md)).

## Rational, Complex

A Rational is a rational number, always reduced (`1/3r`); a Complex is a complex number (`1 + 2i`). The arithmetic operators work on both, and `Rational(1, 3)` and `Complex(1, 2)` are Kernel operations. Details: [Rational](ref/Rational.md), [Complex](ref/Complex.md).

```ruby
r = Rational(1, 3)
p(r + 1/6r)                      # => (1/2)
p(Rational.numerator(r))         # => 1
p(Rational.to_f(r))              # => 0.3333333333333333
c = Complex(1, 2)
p(c * c)                         # => (-3+4i)
p(Complex.abs(Complex(3, 4)))    # => 5.0
p(Integer.fdiv(7, 2))            # => 3.5
```

| Operation | Result |
|---|---|
| `Rational(a, [b])` · `Integer.to_r` · `Float.to_r` · `Float.rationalize` | Rational |
| `Rational.numerator`, `denominator`, `to_i`, `floor`, `ceil`, `round`, `truncate` · `to_f` · `abs` | Integer · Float · Rational |
| `Complex(re, [im])` · `Complex.real`, `imaginary` · `abs`, `arg` · `conjugate` · `rectangular` · `polar` | Complex · a real number · Float · Complex · `[re, im]` · `[abs, arg]` |
| `Integer.fdiv(a, b)` | Float |

## File, Dir, IO, ENV, Process

File and Dir are sets of operations on files and directories by path (a String); they have no values. IO is the type of open files and of the standard streams (`IO.stdin`, `IO.stdout`, `IO.stderr`). ENV is the environment, Process the process's information and clocks, Open3 child processes, and Zlib compression. The first ones you use are `File.read`, `File.write`, `File.open(path) { |io| }`, and `Dir.glob`. Details: [File](ref/File.md), [Dir](ref/Dir.md), [IO](ref/IO.md), [ENV](ref/ENV.md), [Process](ref/Process.md), [Open3](ref/Open3.md), [Zlib](ref/Zlib.md).

```ruby
dir = Dir.mktmpdir
path = File.join(dir, "notes.txt")
p(File.write(path, "one\ntwo\n"))          # => 8
p(File.readlines(path))                    # => ["one\n", "two\n"]
File.open(path, "a") { |io| IO.puts(io, "three") }
p(Array.length(File.readlines(path)))      # => 3
p(Dir.children(dir))                       # => ["notes.txt"]
p(ENV.fetch("NO_SUCH_VAR", "default"))     # => "default"
out, status = Open3.capture2("echo", "hi")
p(out)                                     # => "hi\n"
File.delete(path)
Dir.rmdir(dir)
```

| Operation | Result |
|---|---|
| `File.read(path)` · `readlines` · `write(path, s)` · `exist?`, `file?`, `directory?`, `symlink?`, `zero?`, `empty?`, `readable?`, `writable?`, `executable?`, `absolute_path?` | String · Array · Integer · true/false |
| `File.size`, `mtime`, `atime`, `ftype` · `rename`, `symlink`, `link`, `readlink`, `unlink`, `delete`, `chmod`, `utime` | Integer · Time · String · ... |
| `File.basename(p, [suffix])`, `dirname(p, [levels])`, `extname`, `join(*parts)`, `expand_path(p, [dir])`, `absolute_path`, `realpath` · `split(p)` | String · `[dir, base]` |
| `File.open(path, mode = "r", [perm])` · `File.open(...) { \|io\| }` | IO · the block's value (the file is closed) |
| `Dir.children`, `entries` · `glob(pat, [base:])` · `each_child(path) { }` · `exist?`, `empty?` · `mkdir(path, [mode])`, `rmdir` · `pwd`, `home`, `tmpdir` · `mktmpdir([prefix, [dir]])` | Array of String · ... |
| `IO.puts(io, ...)`, `print`, `write(io, s)` · `gets(io)`, `read(io, [n])`, `readlines`, `getc` · `each_line(io) { }` · `eof?`, `closed?`, `tty?` · `flush`, `close` · `seek(io, off, [whence])`, `pos`, `rewind`, `truncate`, `size` | nil · String or nil · ... |
| `ENV.fetch(name, [default])`, `get(name)`, `set(name, v)`, `key?`, `delete`, `to_h`, `keys` | String · ... |
| `Process.clock_gettime(Process.CLOCK_MONOTONIC)`, `pid` | Float · Integer |
| `Open3.capture2(cmd, ...)`, `capture2e`, `capture3` | Tuples such as `[out, status]` |
| `Zlib.inflate`, `deflate`, `gzip`, `gunzip` | String |

- **Closed IO.** Reading from or writing to a closed IO, or one not opened for it, raises `IOError`.
- **Order with stderr.** Writing to `IO.stderr` flushes stdout first, so their lines keep their order.

## Threads and sockets

A Thread runs a block concurrently, a Mutex gives mutual exclusion, and a Queue passes values between threads. TCPServer and Socket are TCP listening and connections. The first ones you use are `Thread.new { }` and `Thread.value`, `Mutex.synchronize`, and `Queue.push`/`pop`. Details: [Thread](ref/Thread.md), [Mutex](ref/Mutex.md), [Queue](ref/Queue.md), [TCPServer](ref/TCPServer.md), [Socket](ref/Socket.md).

```ruby
count = 0
m = Mutex.new
ts = Array.map(Array[1, 2, 3]) { |w| Thread.new { Mutex.synchronize(m) { count += w }; w * 10 } }
p(Array.map(ts) { |t| Thread.value(t) })   # => [10, 20, 30]
p(count)                                   # => 6
q = Queue.new
producer = Thread.new { Range.each(1..3) { |i| Queue.push(q, i) }; Queue.close(q) }
got = Array[]
loop do
  x = Queue.pop(q)
  break if x == nil
  Array.push(got, x)
end
Thread.join(producer)
p(got)                                     # => [1, 2, 3]
```

| Operation | Result |
|---|---|
| `Thread.new { ... }` · `Thread.value(t)` · `join(t, [limit])` · `alive?(t)` · `current` · `kill(t)` · `raise(t, msg)` | a Thread · the block's value (waits; an error in the thread is raised here) · t or nil · true/false |
| `Mutex.new` · `synchronize(m) { }` · `lock`, `unlock`, `try_lock`, `locked?`, `owned?` | a Mutex · the block's value |
| `Queue.new` · `push(q, x)` · `pop(q, [timeout])` · `close`, `size`, `empty?`, `closed?` | a Queue · q · the oldest element (waits; nil once closed and empty) |
| `TCPServer.new(host, port)` · `accept(s)` · `port(s)` · `close(s)` | a TCPServer (port 0 picks a free one) · a Socket (waits) · Integer · nil |
| `Socket.connect(host, port, [timeout])` · `connect_ssl(host, port, [timeout])` · `set_timeout(s, secs)` | a Socket (`connect_ssl`: TLS, the peer verified) |
| `Socket.gets(s)` · `read(s, n)` · `write(s, str)` · `close_write(s)` · `close(s)` | String or nil · String or nil · Integer · nil · nil |

- **Variables in a thread.** A block shares the variables around it, as every block does. For a thread, the variables of the blocks around `Thread.new` (their parameters and locals), and the thread block's own, are copied when the thread starts; the function's variables stay shared. So `Array.map(xs) { |w| Thread.new { ... w ... } }` in the example gives each thread its own `w`, and the shared counter `count` is a function variable updated inside `Mutex.synchronize`.
- **Leaving a thread block.** `break` and `return` out of a `Thread.new` block are errors (`LocalJumpError`); `next v` ends it with `v`.
- **Errors.** An error inside a thread is raised by `Thread.value` or `Thread.join`. A thread that is never joined ends silently when it fails, and every thread stops when the main program ends.
- **Checking.** The typer runs a thread's block once, at `Thread.new`: its value is the type of `Thread.value`; a Queue's element type is the union of what is pushed (`Queue.pop` adds nil). Interleavings are not analyzed; each operation still checks its arguments while running.

## Typed arrays

`Integer[...]`, `Float[...]`, `Rational[...]`, `Complex[...]`, `String[...]`, `Symbol[...]`, `Tuple[...]`, and `D[...]` for each class `D` create an Array whose element type is that type ([Values and types](03-values.md)). Every write is checked against the element type: a value of another type is a `type` problem statically and a `TypeError` at run time.

```ruby
xs = Integer[1, 2]
Array.push(xs, 3)
p(xs)                            # => [1, 2, 3]
Point = Struct.new(:x, :y)
pts = Point[Point.new(0, 0)]
p(Array.length(pts))             # => 1
p(String[])                      # => []
```

```ruby error
xs = Integer[1, 2]
Array.push(xs, "a")              # !> Array.push: an element must be Integer, but is String [type]
```
