#!/bin/bash
# Times each benchmark compiled with and without the range analysis's elision (--keep-checks), through
# C (bin/ceec) and Rust (bin/sabic). Prints: bench impl run seconds.
set -eu
RUBY=${RUBY:-$HOME/ruby/install/bench-40/bin/ruby}
SAKE=${SAKE:-$HOME/sake-bench/sake}
cd "$(dirname "$0")"
mkdir -p build/elide
WORDS=$($RUBY -e 'srand(1); puts Array.new(100) { Array.new(40) { ("a".."f").to_a.sample }.join }.join(" ")')
args_of() { case $1 in loops) echo 7;; fib) echo 38;; levenshtein) echo "$WORDS";; shapes|shapes_mono) echo 1000000;; esac; }
echo "# $(date -u +%FT%TZ) host=$(hostname) rustc=$(rustc --version) cc=$(${CC:-cc} --version | head -1) sake=$(cat $SAKE/REVISION 2>/dev/null)" >&2
TIMEFORMAT=%R
for b in loops fib levenshtein shapes shapes_mono; do
  $RUBY $SAKE/bin/ceec $b.sake -o build/elide/$b.c-elide
  $RUBY $SAKE/bin/ceec $b.sake --keep-checks -o build/elide/$b.c-keep
  $RUBY $SAKE/bin/sabic $b.sake -o build/elide/$b.rs-elide
  $RUBY $SAKE/bin/sabic $b.sake --keep-checks -o build/elide/$b.rs-keep
  for impl in c-elide c-keep rs-elide rs-keep; do
    for r in 1 2 3; do
      t=$( { time build/elide/$b.$impl $(args_of $b) > build/elide/$b.$impl.out; } 2>&1 )
      echo "$b $impl $r $t"
    done
  done
  for impl in c-keep rs-elide rs-keep; do cmp -s build/elide/$b.c-elide.out build/elide/$b.$impl.out || echo "# $b: $impl OUTPUT DIFFERS" >&2; done
done
echo DONE >&2
