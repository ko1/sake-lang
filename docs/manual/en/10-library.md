# The library (sakelib)

`require "name"` reads `sakelib/name.sake`, shipped with the interpreter, when there is no `name.sake` next to the requiring file. Names follow Ruby's: `JSON.parse(s)`, `Base64.encode64(s)`. A Ruby instance method becomes an operation with the subject first: `StringScanner.scan(ss, /\w+/)`.

Each library's notes (what differs from Ruby and why, what is missing) are in `sakelib/notes/NAME.md`; the libraries not ported, with the reason, in `sakelib/notes/not-ported.md`.

## Ports of the standard library

```ruby
require "json"
h = JSON.parse(File.read("conf.json"))
```

| Area | Libraries |
|---|---|
| Data formats | json, csv, yaml (partial), toml, ini, base64, digest (MD5/SHA computed in Sake), zlib (built in), xml (part of REXML), erb, mustache |
| Strings and parsing | strscan (StringScanner), optparse, getoptlong, shellwords, abbrev, prettyprint, pp, text, diff, terminal_table |
| Numbers | bigdecimal, matrix, prime, securerandom, units |
| Time | time, date |
| I/O and OS | fileutils, pathname, find, tempfile, tmpdir (built in), stringio, logger, benchmark, open3 (built in) |
| Network | net_http (`Net::HTTP`; https through `Socket.connect_ssl`), open_uri, uri, cgi, ipaddr, webrick |
| Concurrency | monitor, mutex_m, timeout (stops the block with `Thread.raise`), observer, event_emitter |
| Data structures | pqueue, lru_cache, trie, tsort, state_machine, semver |

Instead of singleton use `once`; instead of forwardable/delegate write the delegating operations; instead of ostruct use a Record or a Hash.

## Ports of gems

| Area | Libraries |
|---|---|
| Terminal and CLI | colorize, ruby_progressbar, highline, thor, awesome_print |
| ActiveSupport | active_support_inflector, active_support_core_ext (`Blank`, `StringExt`, `ArrayExt`, `HashExt`, `Duration`), active_support_number_helper |
| Text | kramdown (GFM dialect), liquid, i18n, faker |
| Web | rack, rackup, webrick, httparty |
| Data | redis (RESP2 client), dotenv, money, rubyzip, chronic, jwt (HS256/384/512) |
| Concurrency and testing | concurrent_ruby (Future, Promise, Atom, Map, Semaphore, ...), rspec (`RSpec.expect(ex, x).To.eq(y)`), minitest |

The features dropped and why (stored blocks, reflection, APIs that pass a class as a value, ...) are tabulated in `sakelib/notes/not-ported.md`.

## minitest

`sakelib/minitest.sake` is a test framework for programs written in Sake; Sake's own test suite (`test/sake/*_test.sake`) is written with it. Sake has no reflection, so tests are blocks given to `Minitest.test`, and every assertion names the test it belongs to (the block's parameter), as every Sake operation names its subject.

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

The report's last line is `N runs, M assertions, 0 failures, 0 errors`. A failed assertion raises `AssertionFailed`, recorded as a failure; any other exception is recorded as an error. Tests run in the order defined.

## Tests

Each library port has a Ruby twin: `test/sakelib/NAME.sake` (run with `--strict`) must print what `test/sakelib/NAME.rb`, the same program with Ruby's library, prints (`ruby test/test_sakelib.rb`).
