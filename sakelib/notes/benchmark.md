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
| `Benchmark.measure("label") { }` | `Benchmark.measure_label("label") { }` | differs: a user function has no optional arguments |
| `Benchmark.bm(width) { \|x\| x.report("l") { } }` | `Benchmark.bm(width) { \|x\| BenchmarkReport.report(x, "l") { } }` | same output layout |
| `Benchmark.bm` (no width), `bm(w, *labels)` (extra total lines) | — | missing: fixed number of arguments; the labels form needs the block to return Tms |
| `Benchmark.benchmark(caption, width, format) { }` | same | same |
| `Benchmark.bmbm(width) { \|x\| x.report(...) { } }` | `Benchmark.bmbm(width) { \|x\| BenchmarkReport.report(x, ...) { } }` | differs: the outer block runs three times (see below) |
| `x.report(label) { }`, `x.item` | `BenchmarkReport.report(x, label) { }`, `item` | same |
| `Benchmark::CAPTION`, `Benchmark::FORMAT` | `Benchmark.CAPTION`, `Benchmark.FORMAT` | differs: functions, not constants |
| `Benchmark::Tms.new(u, s, cu, cs, real, label)` | `BenchmarkTms.new(...)` | same (all fields have defaults) |
| `tms.utime`, `stime`, `cutime`, `cstime`, `real`, `label`, `total` | `BenchmarkTms.get_utime(t)`, ..., `BenchmarkTms.total(t)` | same |
| `tms + tms`, `-`, `*`, `/` (with a Tms or a number) | the same operators | same |
| `tms.format(fmt)` (`%u %y %U %Y %t %r %n` with flags) | `BenchmarkTms.format(t, fmt)` | same, including `%%` and an `ArgumentError` on a stray `%` |
| `tms.format` (no argument) | `BenchmarkTms.to_s(t)`, `puts(t)` | same |
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
- **`String.gsub(s, re) { |m| ... }`**: Ruby's `Tms#format` is seven `gsub!` calls with blocks.

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
