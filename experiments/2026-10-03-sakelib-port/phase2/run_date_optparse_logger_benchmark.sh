#!/bin/sh
# CPU time (user+sys) of before/ (phase-1 libraries) and after (sakelib/), interleaved, 3 runs each.
# Usage (from the repo root): sh experiments/2026-10-03-sakelib-port/phase2/run_date_optparse_logger_benchmark.sh
D=experiments/2026-10-03-sakelib-port/phase2
uptime
for i in 1 2 3; do
  /usr/bin/time -f "startup cpu=%U+%S" bin/sake $D/bench_startup.sake >/dev/null
  for l in date optparse logger benchmark; do
    /usr/bin/time -f "$l before cpu=%U+%S" bin/sake $D/before/bench_$l.sake >/dev/null
    /usr/bin/time -f "$l after cpu=%U+%S" bin/sake $D/bench_$l.sake >/dev/null
  done
done
uptime
