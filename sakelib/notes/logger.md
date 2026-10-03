# logger

`require "logger"`. A `Logger` is a Sake type whose operations take the logger first:

```ruby
log = Logger.new(:stdout)              # or :stderr, a file path, or nil for no output
Logger.set_level(log, :warn)           # or Logger.WARN, or "WARN"
Logger.set_progname(log, "app")
Logger.warn(log, "disk almost full")   # W, [2026-10-03T12:34:56.123456]  WARN -- app: disk almost full
Logger.set_formatter(log, "%<severity>s %<progname>s: %<msg>s\n")
```

The test (`test/sakelib/logger.{sake,rb}`) fixes the time: Sake uses `Logger.set_fixed_time`, and
Ruby redefines `Time.now`. Ruby's formatter is also patched to drop the pid (see below).

## API

| Ruby | Sake | |
|---|---|---|
| `Logger.new($stdout)` / `Logger.new($stderr)` / `Logger.new("app.log")` / `Logger.new(nil)` | `Logger.new(:stdout)` / `Logger.new(:stderr)` / `Logger.new("app.log")` / `Logger.new(nil)` | differs: there is no IO value, so the streams are Symbols. `:stderr` writes with `warn`, which adds a newline to text without one (only `<<` can give such text) (phase 2) |
| an IO, `File::NULL` | — | missing: Sake has no IO values |
| `Logger.new(dev, level: ..., progname: ..., formatter: ...)` | `new`, then the setters | differs: no keyword arguments |
| `Logger::DEBUG` ... `Logger::UNKNOWN` | `Logger.DEBUG` ... `Logger.UNKNOWN` | differs: Sake has no value constants, so these are functions |
| `log.level` / `log.level = x` | `Logger.get_level(log)` / `Logger.set_level(log, x)` | same (Integer, Symbol, or String; anything else raises `ArgumentError`, "invalid log level: ...") |
| `log.debug(msg = nil)` ... `log.unknown(msg = nil)` | `Logger.debug(log, msg = nil)` ... `Logger.unknown(log, msg = nil)` | same (phase 2: the argument is optional; with none, the progname is logged, as Ruby) |
| `log.info { "msg" }`, `log.info("prog") { "msg" }` | — | missing: a function that `yield`s must always be given a block, so the block form would need separate names |
| `log.add(sev, msg = nil, prog = nil)`, `log.log` | `Logger.add(log, sev, msg = nil, prog = nil)`, `Logger.log` | same (with msg nil, prog, or else the logger's progname, is the message; severity nil is UNKNOWN; above 5 prints `ANY`) |
| `log << "raw"` | `Logger.<<(log, "raw")` | same (returns the bytesize) |
| `log.debug?` ... `log.fatal?` | `Logger.debug?(log)` ... | same |
| `log.debug!` ... `log.fatal!` | `Logger.debug!(log)` ... | same |
| `log.with_level(:debug) { ... }` | `Logger.with_level(log, :debug) { ... }` | differs: the level is restored after the block. In Ruby's logger 1.7.0, the ensure clause pins the per-Fiber override to the old level, because `prev` is never nil. After that, `level=` and `info!` have no effect |
| `log.progname`, `progname=` | `get_progname`, `set_progname` | same |
| `log.datetime_format=` | `Logger.set_datetime_format(log, fmt)` | same (strftime) |
| `log.formatter = proc { \|sev, time, prog, msg\| ... }` | `Logger.set_formatter(log, "%<severity>s ... %<msg>s\n")` | differs: a format string with the keys `severity`, `datetime` (already formatted), `progname`, and `msg` |
| default format `"%.1s, [%s #%d] %5s -- %s: %s\n"` | the same, without ` #pid` | differs: Sake has no `Process.pid` |
| `msg` not a String | `Kernel.inspect(msg)` | same; an exception message is also inspected, where Ruby writes `message (Class)` and the backtrace |
| `log.close` | `Logger.close(log)` | same; a later write warns `log writing failed. closed stream` on stderr, as Ruby (phase 2) |
| `log.reopen`, log rotation (`shift_age`, `shift_size`) | — | missing |
| (Sake only) | `Logger.set_fixed_time(log, time)` | every entry uses `time`, so that output can be compared |
| `Logger::Formatter#call`, `format_message`, `format_severity` | `Logger.format_message(log, sev, time, prog, msg)`, `Logger.format_severity(n)` | same |

## Differences from Ruby, and why

- **Formatter.** Ruby's formatter is a proc, and Sake's blocks cannot be stored. A format string over
  named fields (`Kernel.format` with a Hash) covers the usual layouts. A formatter that computes
  something, such as JSON escaping, cannot be expressed.
- **Devices.** Sake has no IO values, so the device is `:stdout`, a path, or nil.
- **Files are appended by reading and rewriting.** Sake's `File.write` replaces the whole file, so
  each entry reads the file and writes it back. This is O(n²) in the file's size. The header
  (`# Logfile created on ...`) is written when the file does not exist. Ruby writes it when
  `Logger.new` creates the file; the Sake port writes it at the first entry.
- **Constants.** `Logger::INFO` cannot be written. `Logger.INFO` is a function with an uppercase
  name, and Sake accepts that.

## Built-ins requested

- **Appending to a file** (`File.open(path, "a")`, or `File.append(path, s)`): log files are
  append-only, and rewriting the whole file per line is quadratic.
- ~~`$stderr` / `warn`~~: added; `:stderr` uses `warn`. A stderr `print` (no added newline) is still missing.
- **`Process.pid`**: Ruby's default log line includes it.
- ~~`File.delete`~~: added.

## Friction

- `text = msg in String ? msg : Kernel.inspect(msg)` → `syntax error` → `(msg in String) ? ...`.
- The Ruby side of the test printed nothing for `info` after `with_level` and `info!`, which is the
  logger 1.7.0 behavior described above. The test now uses a separate logger for `with_level`.

## Phase 2

- **Optional arguments as Ruby**: `debug(log, msg = nil)` ... `unknown`, `add(log, sev, msg = nil,
  prog = nil)`, `log(...)`. The test logs with no message, and `add`/`log` with fewer arguments.
- **Fix** found by the new test: with both message and progname nil, Ruby logs the logger's progname
  as the message (phase 1 logged `nil`).
- **`:stderr` device** and the closed-stream warning, with `warn`.
- `Logger.new(dev, level: ..., progname: ...)` still cannot be written: they are keyword arguments in
  Ruby (the positional ones are `shift_age`, `shift_size`), and `new` is the Struct's constructor.
- Tried and dropped: a severity-label table with `once` (slower than the `case`, in a 100k-call
  micro-benchmark under load: 11.2 s vs 8.0 s) and string interpolation in place of `Kernel.format`
  for the default line (no measurable gain). No tables or scans otherwise.

Speed (15000 formatted entries to a nil device, 2000 below the level). CPU s (user+sys) of `bin/sake` on `experiments/2026-10-03-sakelib-port/phase2/bench_logger.sake`, the phase-1 library (`phase2/before/`) and this one interleaved, 3 runs each, by `phase2/run_date_optparse_logger_benchmark.sh` (raw: `result_date_optparse_logger_benchmark.txt`; base commit af197cd). The machine was shared, load average about 36 on 16 CPUs. Startup with the four libraries loaded and nothing run is 0.69-0.70 s of each run.

| | run 1 | run 2 | run 3 |
|---|---|---|---|
| before | 5.71 | 5.27 | 5.30 |
| after | 5.23 | 5.60 | 6.02 |

Result: no difference beyond the spread.
