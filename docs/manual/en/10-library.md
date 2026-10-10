# The library (sakelib)

The interpreter ships with `sakelib/`, Ruby's standard library and the main gems rewritten in Sake. This chapter covers how a library is loaded, what has been ported, the test framework minitest, and how each port is checked. Each library's API is in `sakelib/notes/NAME.md`; this chapter is the overview.

## Loading and names

A library is loaded with `require "json"`. The names of the libraries and of their operations follow Ruby's, so the names you know from Ruby work as they are. Only the shape of the call differs.

- **Where it looks.** `require "name"` first looks for `name.sake` in the directory of the requiring file. When there is none, it reads `sakelib/name.sake`, shipped with the interpreter. The sakelib copy is also taken when the `name.sake` next door is the requiring file itself, or a program rather than a library. From whatever directory the program runs, `require "json"` reads the same `sakelib/json.sake`.
- **Names with `/`.** Ruby's `net/http` and `open-uri` are written `net_http` and `open_uri`.
- **Module functions as in Ruby.** `JSON.parse(s)` and `Base64.encode64(s)` are spelled as in Ruby.
- **Instance methods take the subject first.** Ruby's `ss.scan(/\w+/)` is `StringScanner.scan(ss, /\w+/)`; in a chain, `ss.StringScanner.scan(/\w+/)` ([Program structure and name resolution](02-program.md)).
- **Nested names are flattened.** Sake has no nested names, so `Net::HTTP` is `NetHTTP` and `Concurrent::Future` is `ConcurrentFuture`. Each library's notes have the table.

```ruby
require "base64"
require "strscan"

e = Base64.encode64("hello")
p(e)                                  # => "aGVsbG8=\n"
p(Base64.decode64(e))                 # => "hello"
ss = StringScanner.new("foo bar")
p(StringScanner.scan(ss, /\w+/))      # => "foo"
p(StringScanner.scan(ss, /\w+/))      # => nil
p(ss.StringScanner.scan(/\s+/))       # => " "
```

Each library's notes are in `sakelib/notes/NAME.md`: what differs from Ruby and why, what is missing, and a table of Ruby's API against Sake's. The libraries not ported, with the reason, are in `sakelib/notes/not-ported.md`.

## Ports of the standard library

The parts of Ruby's standard library that can be written in Sake are ported. Most of what cannot rests on `method_missing`, `define_method`, special variables or first-class blocks, which Sake leaves out on purpose. What needs the OS or a C implementation, such as TLS, UDP and the terminal, is built into the interpreter rather than written as a library.

```ruby
require "json"

doc = JSON.parse("{\"name\": \"ann\", \"tags\": [\"a\", \"b\"]}")
p(doc)                                # => {"name" => "ann", "tags" => ["a", "b"]}
if doc in Hash
  p(doc["name"])                      # => "ann"
  puts(JSON.generate(doc))            # => {"name":"ann","tags":["a","b"]}
end
```

`JSON.parse` returns one of Hash, Array, String, Integer, Float, true/false and nil, so narrow it with `if doc in Hash` before indexing ([Control flow and patterns](06-control.md)). Written without the narrowing, `doc["name"]` makes the checker report that the receiver may be a type that cannot be indexed.

| Area | Libraries |
|---|---|
| Data formats | json, csv, yaml, toml, ini, base64, digest, zlib, xml, erb, mustache |
| Strings and parsing | strscan, optparse, getoptlong, shellwords, abbrev, prettyprint, pp, text, diff, terminal_table |
| Numbers | bigdecimal, matrix, prime, securerandom, units |
| Time | time, date |
| I/O and OS | fileutils, pathname, find, tempfile, stringio, logger, benchmark |
| Network | net_http, open_uri, uri, cgi, ipaddr, webrick |
| Concurrency | monitor, mutex_m, timeout, observer, event_emitter |
| Data structures | pqueue, lru_cache, trie, tsort, state_machine, semver |

### Partial ports and notes

- **yaml** is a subset of Psych; **xml** a subset of REXML.
- **digest** computes MD5 and SHA in Sake (slowly). **zlib** has only the CRC-32 and Adler-32 checksums, no compression.
- **net_http** names `Net::HTTP` `NetHTTP`. https goes through the built-in `Socket.connect_ssl`.
- **timeout** runs the block in a Thread of its own and, when the time is up, really stops it with the built-in `Thread.raise`.
- **pp** is the PP that wraps at a width, distinct from the built-in one-line `pp`.

### Built in, so not required

Some things Ruby requires are built-in operations in Sake. `require "tmpdir"` is a static error saying there is no file to read.

| Ruby's require | Sake's built-in |
|---|---|
| `tmpdir` | `Dir.mktmpdir`, `Dir.tmpdir` (the latter added by tempfile) |
| `open3` | `Open3.capture2`, `capture2e`, `capture3`, `Kernel.system` |
| `set` | `Set[...]`, `Set.add`, ... ([Values and types](03-values.md)) |
| `socket` | `TCPServer`, `Socket` (TCP only) |

### Small libraries after gems

In the table above, toml (toml-rb), ini (inifile), mustache, units (ruby-units), text, diff (diff-lcs), terminal_table, event_emitter (Node's EventEmitter), pqueue, lru_cache (lru_redux), trie, state_machine (AASM-like) and semver are not Ruby's standard library but were written after popular gems or libraries of other languages. The head of each one's notes names its model.

### Instead of what is not ported

- Instead of **singleton**, `once { T.new(...) }` ([Functions and blocks](04-functions.md)).
- Instead of **forwardable / delegate**, write the delegating operations one by one.
- Instead of **ostruct**, a Record `{a: 1}` or a Hash.

## Ports of gems

Popular gems are ported too, as far as Sake can express them. Each port keeps the gem's names where Sake can (`Inflector.pluralize(s)`, `Redis.get(r, k)`).

| Area | Libraries |
|---|---|
| Terminal and CLI | colorize, ruby_progressbar, highline, thor, awesome_print |
| ActiveSupport | active_support_inflector, active_support_core_ext, active_support_number_helper |
| Text | kramdown, liquid, i18n, faker |
| Web | rack, rackup, webrick, httparty |
| Data | redis, dotenv, money, rubyzip, chronic, jwt |
| Concurrency and testing | concurrent_ruby, rspec, minitest |

### Notes

- **active_support_core_ext** is the modules `Blank`, `StringExt`, `ArrayExt`, `HashExt` and `Duration`.
- **kramdown** is the GFM dialect, **redis** a RESP2 client, **jwt** HS256/384/512.
- **concurrent_ruby** has `ConcurrentFuture`, `ConcurrentPromise`, `ConcurrentAtom`, `ConcurrentMap`, `Semaphore` and more.
- **rspec** is written in the shape of minitest, naming the example: `RSpec.expect(ex, x).To.eq(y)`.

### Dropped features

The features dropped and why are tabulated in `sakelib/notes/not-ported.md`. The main three:

- **Stored blocks**, such as `then(rescuer) {}` and registered callbacks. Blocks are second-class and cannot be stored ([Functions and blocks](04-functions.md)).
- **Reflection**: `constantize`, `send`, `define_method`. There is no call by name.
- **APIs that pass a class as a value**, such as `expect(x).to be_a(T)`. A type is not a value; write `x in T` or one function per type.

## minitest

`sakelib/minitest.sake` is a test framework in the style of Ruby's Minitest, for programs written in Sake. Sake's own test suite (`test/sake/*_test.sake`) is written with it.

### Writing a test

Sake has no reflection, so a test is not a method found by name but a block given to `Minitest.test`. Every assertion names the test it belongs to (the block's parameter `t`) as its first argument, as every Sake operation names its subject.

```ruby
require "minitest"

suite = Minitest.suite("strings")
Minitest.test(suite, "upcase and split") do |t|
  Minitest.assert_equal(t, "ABC", String.upcase("abc"))
  Minitest.assert_equal(t, Array["a", "b"], String.split("a,b", ","))
  Minitest.assert(t, String.empty?(""))
end
Minitest.run(suite)      # prints the report; exits with 1 when a test failed
```

```
# Running strings:

.

Finished in 0.026718s

1 runs, 3 assertions, 0 failures, 0 errors
```

- **Tests run on the spot.** `Minitest.test` runs the block at once and records the result. Tests run in the order defined.
- **`Minitest.run(suite)`** prints the report and exits with code 1 when there was a failure or an error. `Minitest.report(suite)` only prints, and returns true or false for whether everything passed.

### Assertions

Functions of `Minitest`; each takes the test `t` first and an optional message last.

| Function | Checks |
|---|---|
| `assert(t, cond)`, `refute(t, cond)` | truthy / falsy |
| `assert_equal(t, expected, actual)`, `refute_equal` | `==` |
| `assert_nil(t, x)`, `refute_nil` | nil |
| `assert_in_delta(t, expected, actual, delta = 0.001)` | difference within delta |
| `assert_includes(t, collection, x)`, `refute_includes` | contains the element |
| `assert_empty(t, collection)`, `refute_empty` | empty |
| `assert_match(t, pattern, s)` | matches the Regexp |
| `assert_raises(t) { ... }` | the block raises; gives the exception's message |

There is no `assert_output`: a Sake program cannot capture its own output, so print the value and compare.

### Failures and errors

A failed assertion raises `AssertionFailed` and is recorded as a failure (F). Any other exception is recorded as an error (E), as in Ruby's Minitest.

```ruby
require "minitest"

suite = Minitest.suite("numbers")
Minitest.test(suite, "integer division floors") do |t|
  Minitest.assert_equal(t, 3, 7 / 2)
end
Minitest.test(suite, "divides by zero") do |t|
  Minitest.assert_equal(t, 0, 1 / 0)
end
Minitest.test(suite, "wrong expectation") do |t|
  Minitest.assert_equal(t, 4, 2 + 3)
end
Minitest.run(suite)      # exit code 1
```

```
# Running numbers:

.EF

Finished in 0.035481s

  1) Error:
divides by zero
divided by 0

  2) Failure:
wrong expectation
expected 4, got 5

3 runs, 2 assertions, 1 failures, 1 errors
```

## Tests

Each library port has a Ruby twin: `test/sakelib/NAME.sake`, the program written with Sake's library, and `test/sakelib/NAME.rb`, the same program with Ruby's library. The two must print the same output; that sameness is the definition of a correct port.

```ruby
# the shape of test/sakelib/shellwords.sake
require "shellwords"
p(Shellwords.split("a 'b c' d"))      # => ["a", "b c", "d"]
p(Shellwords.escape("it's"))          # => "it\\'s"
```

```ruby
# its twin shellwords.rb, printing the same two lines in Ruby
require "shellwords"
p(Shellwords.split("a 'b c' d"))
p(Shellwords.escape("it's"))
```

- **Running them.** `ruby test/test_sakelib.rb` runs each `.sake` with `bin/sake --strict` (level 2) and each `.rb` with Ruby, inside `test/sakelib/`, and compares the outputs.
- **When the gem is not installed.** The twin of a gem that is not installed runs on `test/sakelib/ref/NAME.rb`, a plain-Ruby reference with the gem's names and output.
- **Notes.** Where the twins differ, and where Sake departs from Ruby, is written in `sakelib/notes/NAME.md`.
