# benchmark

`require "benchmark"`. `Benchmark::Tms` and `Benchmark::Report` become the types `BenchmarkTms`
and `BenchmarkReport`, because Sake has no nested namespaces.

```ruby
t = Benchmark.realtime { work }                  # Float seconds
Benchmark.bm(7) do |x|
  BenchmarkReport.report(x, "sort:") { Array.sort(xs) }
  BenchmarkReport.report(x, "min:") { Array.min(xs) }
end
```

The measured times differ between runs, so the test (`test/sakelib/benchmark.{sake,rb}`) prints
only the structure: result types, labels, `Tms` arithmetic and `format` on fixed values, and
`Benchmark.benchmark` with a label-only format. Output with times was compared by eye:
`bm` and `bmbm` give the same layout as Ruby's.

## API

| Ruby | Sake | |
|---|---|---|
| `Benchmark.realtime { }` | `Benchmark.realtime { }` | differs: uses `Time.now`, not the monotonic clock |
| `Benchmark.ms { }` | `Benchmark.ms { }` | same, with the same clock caveat |
| `Benchmark.measure { }` | `Benchmark.measure { }` | differs: utime/stime/cutime/cstime are always 0.0 |
| `Benchmark.measure(label = "") { }` | `Benchmark.measure(label = "") { }` | same (phase 2; `measure_label` removed) |
| `Benchmark.bm(width = 0) { \|x\| x.report("l") { } }` | `Benchmark.bm(width = 0) { \|x\| BenchmarkReport.report(x, "l") { } }` | same output layout (default since phase 2) |
| `bm(w, *labels)` (extra total lines) | — | missing: no rest parameters; the labels form needs the block to return Tms |
| `Benchmark.benchmark(caption = "", width = nil, format = nil) { }` | `Benchmark.benchmark(caption = "", width = 0, format = Benchmark.FORMAT) { }` | same |
| `Benchmark.bmbm(width = 0) { \|x\| x.report(...) { } }` | `Benchmark.bmbm(width = 0) { \|x\| BenchmarkReport.report(x, ...) { } }` | differs: the outer block runs three times (see below) |
| `x.report(label = "") { }`, `x.item` | `BenchmarkReport.report(x, label = "") { }`, `item` | same (the `*format` rest is missing) |
| `Benchmark::CAPTION`, `Benchmark::FORMAT` | `Benchmark.CAPTION`, `Benchmark.FORMAT` | differs: functions, not constants |
| `Benchmark::Tms.new(u, s, cu, cs, real, label)` | `BenchmarkTms.new(...)` | same (all fields have defaults) |
| `tms.utime`, `stime`, `cutime`, `cstime`, `real`, `label`, `total` | `BenchmarkTms.get_utime(t)`, ..., `BenchmarkTms.total(t)` | same |
| `tms + tms`, `-`, `*`, `/` (with a Tms or a number) | the same operators | same |
| `tms.format(fmt = nil)` (`%u %y %U %Y %t %r %n` with flags) | `BenchmarkTms.format(t, fmt = nil)` | same: Ruby's seven `gsub` steps, then `str % args` when a format is given (`%%`, `ArgumentError` on a stray `%`); no `*args` |
| `tms.format`, `to_s` | `BenchmarkTms.format(t)`, `BenchmarkTms.to_s(t)`, `puts(t)` | same |
| `tms.to_a`, `to_h` | `BenchmarkTms.to_a`, `to_h` | same |
| `tms.add { }`, `add! { }` | `BenchmarkTms.add(t) { }`, `add!(t) { }` | same |

## Differences from Ruby, and why

- **CPU times.** Ruby reads `Process.times`, which Sake does not have. The user and system fields
  are always 0.0. `real` is measured with `Time.now`, which can jump if the clock is adjusted.
- **bmbm.** Ruby keeps each `report` block and runs it twice: a rehearsal, then the real run.
  Sake's blocks cannot be stored. `bmbm` runs the block given to it three times instead. The first
  run collects the labels (and does not run the report blocks), because the header width depends on
  them. The second run is the rehearsal, and the third is the real run. The output is Ruby's. Code
  in the outer block, outside `report`, runs three times, where Ruby runs it once. Ruby also calls
  `GC.start` before each real item; Sake has no GC control.
- **Names.** `Benchmark::Tms` is `BenchmarkTms`, because `A::B` namespaces are rejected. The
  constants become functions with uppercase names.

## Built-ins requested

- **`Process.clock_gettime(Process::CLOCK_MONOTONIC)`** (or another monotonic clock): needed for
  correct intervals.
- **`Process.times`** (or CPU-time clocks): without it, `measure` reports only real time, and the
  "user system total" columns are zeros.
- **`GC.start`**: needed for `bmbm`'s isolation between items.
- ~~`String.gsub(s, re) { |m| ... }`~~: added; `Tms#format` now uses it.

## Friction

- `p(t in Float)` → `syntax error: unexpected 'in'` → `p((t in Float))` (as the spec says, and as
  in Ruby).
- The Tms `format` scanner was written by hand: `String.gsub` takes a replacement String, not a
  block, so Ruby's `gsub!(/(%[-+.\d]*)u/) { "#{$1}f" % utime }` cannot be ported directly. A
  `String.gsub` that takes a block (it is a built-in, so the block is not stored) would make this
  one line per directive.
- `Array.join(Array.[](cs, i + 1, len) || Array[])` → `Array.join: argument 1 must be Array, but
  can be String [type]`. This is a checker bug: `a[start, length]` is typed as an element, not as
  an Array. Repro: [benchmark_bug_array_slice_type.sake](benchmark_bug_array_slice_type.sake). I
  wrote `Array.take(Array.drop(cs, i + 1), len)` instead. (I had changed the scanner from
  `String.[](fmt, i, 1)` to `String.chars` + `Array.fetch` to satisfy `--strict=3`.)

## Phase 2

- **Ruby's optional arguments**: `measure(label = "")` (`measure_label` removed), `bm(width = 0)`,
  `bmbm(width = 0)`, `benchmark(caption = "", width = 0, format = FORMAT)`, `report(x, label = "")`,
  `Tms#format(fmt = nil)` (`to_s` is `format(t)`).
- **`Tms#format` is Ruby's code**: seven `String.gsub` calls with a block replace the hand-written
  character scanner (`String.chars` + `Array.fetch`, about 40 lines). The block gets the matched text, not
  the MatchData, so the flags are `String.chop(m)` instead of `$1`. A side effect shared with Ruby: a
  label is formatted first, so `%u` inside a label is replaced too.
- The array-slice checker bug (`benchmark_bug_array_slice_type.sake`) is no longer on the code path.

Speed (1000 `Tms#format` calls (default and a custom format)). CPU s (user+sys) of `bin/sake` on `experiments/2026-10-03-sakelib-port/phase2/bench_benchmark.sake`, the phase-1 library (`phase2/before/`) and this one interleaved, 3 runs each, by `phase2/run_date_optparse_logger_benchmark.sh` (raw: `result_date_optparse_logger_benchmark.txt`; base commit af197cd). The machine was shared, load average about 36 on 16 CPUs. Startup with the four libraries loaded and nothing run is 0.69-0.70 s of each run.

| | run 1 | run 2 | run 3 |
|---|---|---|---|
| before | 3.02 | 3.22 | 3.14 |
| after | 1.15 | 1.24 | 1.14 |

Result: about 2.7x faster in total, about 5x after subtracting startup: seven native `gsub` passes instead of a character loop.

## IO and optional blocks

Output goes through `IO.print(IO.stdout, ...)`, as Ruby's `benchmark` prints to `$stdout`; the
result is the same as `print` (which also writes to stdout). Every block of the library is
required in Ruby too, so `block_given?` is not used.
