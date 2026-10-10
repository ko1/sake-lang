# Built-in operations

The tables below are a guide to the most used operations. **Every operation is documented in detail (arguments, result, nil, exceptions, examples) in Part 2, the built-in reference, one chapter per type ([Array](ref/Array.md), [String](ref/String.md), [Hash](ref/Hash.md), [Kernel](ref/Kernel.md), ...).** The names follow Ruby's core library; "→" gives the result type. Operations marked "block" require one.

## Kernel

| Operation | Result | Notes |
|---|---|---|
| `puts(*xs)` | nil | prints like Ruby's `puts`; Arrays and Tuples print one element per line |
| `print(*xs)` | nil | no newline |
| `p(x)`, `p(x, y)`, `pp(x)` | x · `[x, y]` · x | prints each argument in Ruby's `inspect` format, one per line; `p()` gives nil |
| `format(fmt, *xs)`, `sprintf` | String | Ruby's format; arguments are Integer, Float, String, Symbol, nil, true, false |
| `Integer(x)`, `Float(x)`, `Rational(a, [b])`, `Complex(re, [im])` | the number | Ruby's strict conversions; `ArgumentError` on bad input |
| `rand`, `rand(n)`, `srand(seed)` | Float, or Integer/Float below n | |
| `loop { }` | the value of a `break` | runs the block until a `break` |
| `sleep(secs)` | Integer | |
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

`Math::PI`, `Math::E`, `Float::INFINITY`, `Float::NAN`, `Float::EPSILON`, `Float::MAX`, `Float::MIN` are read as operations (`Math.PI`), as `ARGV` is: Sake has no value constants, and no other nested names.

`Arithmetic.round(x)`, `floor`, `ceil`, `truncate` (with an optional digit count), `abs`, `to_f`, `to_i`, `zero?` take any real number (Integer, Float, Rational), as Ruby's `x.round` does; the result's type follows x's (round without digits gives an Integer). `Float.round` names a Float only.

## Integer / Float

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

## String

| Operation | Result |
|---|---|
| `+(a, b)`, `*(s, n)`, `%` | String |
| `== != < <= > >=` | true/false |
| `length`, `size`, `count(s, chars)`, `to_i(s, base = 10)` · `to_f` | Integer · Float |
| `upcase`, `downcase`, `capitalize`, `swapcase`, `reverse`, `strip`, `lstrip`, `rstrip`, `chomp`, `chop`, `to_s` | String |
| `sub(s, pat, repl)`, `gsub(...)` | String; repl is a String (with `\1`), a Hash, or a block `{ \|m\| ... }`; `sub!`, `gsub!` in place |
| `ljust(s, n, [pad])`, `rjust`, `center` · `tr(s, a, b)`, `delete(s, chars)`, `squeeze(s, [chars])`, `succ`, `next` | String |
| `empty?`, `include?(s, t)`, `start_with?`, `end_with?`, `match?(s, re)`, `casecmp?` | true/false |
| `chars`, `lines`, `bytes`, `split(s, [sep, [limit]])`, `scan(s, re)` | Array |
| `index(s, t, [start])`, `rindex`, `byteindex` | Integer or nil |
| `match(s, re, [pos])` | MatchData or nil |
| `ord` · `hex` · `oct` · `to_sym`, `intern` | Integer · Symbol |
| `byteslice(s, i, [n])`, `b`, `force_encoding(s, enc)`, `encode`, `encoding`, `valid_encoding?`, `unpack(s, fmt)`, `unpack1` | bytes and conversions, as Ruby's |
| `each_line(s) { }`, `each_char(s) { }`, `each_byte` | s (block) |

## Array

| Operation | Result |
|---|---|
| `Array[...]` · `Array.new(n)`, `Array.new(n, v)`, `Array.new(n) { \|i\| }` | a new Array |
| `length`, `size` · `empty?`, `include?(a, x)` | Integer · true/false |
| `push(a, *xs)`, `append`, `unshift`, `concat(a, b)`, `insert(a, i, *xs)`, `delete_if`, `clear` | a, in place |
| `first`, `last`, `min`, `max`, `pop`, `shift`, `at(a, i)`, `sample`, `delete(a, x)`, `delete_at(a, i)` | an element, or nil |
| `first(a, n)`, `last(a, n)`, `shift(a, n)`, `take`, `drop`, `slice(a, i, n)` | a new Array |
| `fetch(a, i, [default])` | the element, the default, or `IndexError` |
| `join(a, [sep])` | String |
| `sum(a, [init])` | the sum; elements are numbers (or of a type including `Arithmetic`); an empty Array gives `init` (default 0) |
| `reverse`, `sort`, `sort_by`, `uniq`, `compact`, `flatten`, `rotate`, `shuffle`, `dup` | a new Array |
| `each`, `each_with_index`, `each_slice(a, n)`, `each_cons(a, n)`, `cycle` | a (block; without a block `each_slice` and the like give an Array) |
| `map`, `flat_map`, `select`, `filter`, `reject`, `partition`, `group_by`, `tally`, `to_h`, `zip`, `product` | a new Array / Hash / Tuple |
| `any?`, `all?`, `none?`, `count` | true/false · Integer (block optional) |
| `reduce(a, init) { }`, `inject`, `each_with_object(a, memo) { }` | the accumulated value |
| `find`, `detect`, `min_by`, `max_by`, `index(a, x)`, `find_index`, `assoc`, `rassoc` | an element or nil · Integer or nil |
| `map!`, `select!`, `reject!`, `sort!`, `uniq!`, `compact!`, `flatten!`, `reverse!`, `slice!`, `fill`, `replace` | a, in place (for mappings within one type) |
| `pack(a, fmt)` | String |

## Tuple, Range

| Operation | Result |
|---|---|
| `Tuple.size`, `length` · `to_a` · `max`, `min` · `minmax` | Integer · Array · an element (never nil) · `[min, max]` |
| `Range.each`, `each_with_index`, `step(r, n)` | r (block) |
| `to_a`, `map`, `select`, `filter`, `reject`, `zip` | Array |
| `reduce`, `inject` · `sum` · `size` · `count` | accumulated value · Integer |
| `any?`, `all?`, `none?` · `find`, `detect` · `include?`, `cover?`, `member?`, `exclude_end?` | true/false · an element or nil · true/false |
| `first`, `last`, `min`, `max`, `begin`, `end` | an element or nil (`first(r, n)`, `last(r, n)` give an Array) |

## Hash, Set

| Operation | Result |
|---|---|
| `Hash[k => v, ...]` · `Hash.new([default])` · `Set[...]` | a new Hash · Set |
| `length`, `size`, `empty?`, `key?`, `has_key?`, `include?`, `member?`, `value?` | Integer · true/false |
| `fetch(h, k, [default])` · `dig(h, k)` · `delete(h, k)` · `key(h, v)` | the value · value or nil · removed value or nil · key or nil |
| `store(h, k, v)`, `merge!`, `update`, `clear`, `transform_values!`, `transform_keys!`, `select!`, `reject!`, `compact!` | in place |
| `merge(a, b)`, `invert`, `select`, `filter`, `reject`, `transform_values`, `transform_keys`, `compact`, `slice`, `except` | a new Hash |
| `keys` · `values` · `to_a` · `map` · `sort_by` · `group_by` · `partition` | Array |
| `each`, `each_pair`, `each_key`, `each_value` | h (block) |
| `any?`, `all?`, `none?`, `count`, `sum`, `find`, `detect`, `min_by`, `max_by` | with a block |
| `Set.add(s, x)`, `add?`, `delete`, `merge`, `subtract`, `clear` · `to_a`, `each`, `map`, `select`, `filter`, `reject` | s, in place · Array |
| `union`, `intersection`, `difference`, `\|`, `&`, `-` · `subset?`, `superset?`, `disjoint?`, `intersect?` | a new Set · true/false |

## Regexp, MatchData, Symbol, Time, Math

| Operation | Result |
|---|---|
| `Regexp.new(s, flags = "")` · `escape(s)` · `source(r)` · `match(r, s, [pos])` · `match?` | Regexp · String · String · MatchData or nil · true/false (flags: letters of `imx`) |
| `MatchData.captures` · `named_captures` · `names` · `to_a` · `to_s`, `pre_match`, `post_match` · `begin(m, i)`, `end(m, i)` | Array · Hash · Array · Array · String · Integer |
| `Symbol.to_s` · `length`, `size` | String · Integer |
| `Time.now` · `at(seconds, [in:])` · `new(y, [m, d, h, min, s, zone])` · `utc(t)`, `getutc` · `getlocal(t, [zone])`, `localtime` | Time |
| `year`, `month`, `day`, `hour`, `min`, `sec`, `wday`, `yday`, `to_i`, `utc_offset` · `to_f` · `to_s`, `strftime(t, fmt)` · `zone` · `utc?` | Integer · Float · String · String or nil · true/false |
| `Math.sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10`, `atan2(y, x)`, `hypot(x, y)` | Float |

## Rational, Complex

| Operation | Result |
|---|---|
| `Rational(a, [b])` · `Integer.to_r` · `Float.to_r` · `Float.rationalize` | Rational |
| `Rational.numerator`, `denominator`, `to_i`, `floor`, `ceil`, `round`, `truncate` · `to_f` · `abs` | Integer · Float · Rational |
| `Complex(re, [im])` · `Complex.real`, `imaginary` · `abs`, `arg` · `conjugate` · `rectangular` · `polar` | Complex · a real number · Float · Complex · `[re, im]` · `[abs, arg]` |
| `Integer.fdiv(a, b)` | Float |

## File, Dir, IO, ENV, Process

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

Reading from or writing to a closed IO, or one not opened for it, raises `IOError`. Writing to `IO.stderr` flushes stdout first, so their lines keep their order.

## Threads and sockets

| Operation | Result |
|---|---|
| `Thread.new { ... }` · `Thread.value(t)` · `join(t, [limit])` · `alive?(t)` · `current` · `kill(t)` · `raise(t, msg)` | a Thread · the block's value (waits; an error in the thread is raised here) · t or nil · true/false |
| `Mutex.new` · `synchronize(m) { }` · `lock`, `unlock`, `try_lock`, `locked?`, `owned?` | a Mutex · the block's value |
| `Queue.new` · `push(q, x)` · `pop(q, [timeout])` · `close`, `size`, `empty?`, `closed?` | a Queue · q · the oldest element (waits; nil once closed and empty) |
| `TCPServer.new(host, port)` · `accept(s)` · `port(s)` · `close(s)` | a TCPServer (port 0 picks a free one) · a Socket (waits) · Integer · nil |
| `Socket.connect(host, port, [timeout])` · `connect_ssl(host, port, [timeout])` · `set_timeout(s, secs)` | a Socket (`connect_ssl`: TLS, the peer verified) |
| `Socket.gets(s)` · `read(s, n)` · `write(s, str)` · `close_write(s)` · `close(s)` | String or nil · String or nil · Integer · nil · nil |

- **Variables in a thread.** A block shares the variables around it, as every block does. For a thread, the variables of the blocks around `Thread.new` (their parameters and locals), and the thread block's own, are copied when the thread starts; the function's variables stay shared. So `Array.map(xs) { |w| Thread.new { ... w ... } }` gives each thread its own `w`, and a shared counter is a function variable updated inside `Mutex.synchronize`.
- **Leaving a thread block.** `break` and `return` out of a `Thread.new` block are errors (`LocalJumpError`); `next v` ends it with `v`.
- **Errors.** An error inside a thread is raised by `Thread.value` or `Thread.join`. A thread that is never joined ends silently when it fails, and every thread stops when the main program ends.
- **Checking.** The typer runs a thread's block once, at `Thread.new`: its value is the type of `Thread.value`; a Queue's element type is the union of what is pushed (`Queue.pop` adds nil). Interleavings are not analyzed; each operation still checks its arguments while running.

## Typed arrays

`Integer[...]`, `Float[...]`, `Rational[...]`, `Complex[...]`, `String[...]`, `Symbol[...]`, `Tuple[...]`, and `D[...]` for each class `D` create an Array whose element type is that type ([Values and types](03-values.md)).
