#!/bin/bash
# Builds and times the three micro benchmarks under Ruby (YJIT), the Sake interpreter, Sake compiled
# through Rust (bin/sabic), and Rust written by hand. Prints one line per run: name, impl, run, seconds.
#   RUBY=.../ruby SAKE=.../sake-repo REPS=3 ./run.sh > results.txt
# The interpreter runs loops at 1/100 of the inner loop (loops_small), and that variant is timed for every
# implementation too, so the ratio is still like for like.
set -eu
RUBY=${RUBY:-$HOME/ruby/install/bench-40/bin/ruby}
SAKE=${SAKE:-$HOME/sake-bench/sake}
REPS=${REPS:-3}
INTERP_REPS=${INTERP_REPS:-1}
cd "$(dirname "$0")"
mkdir -p build
sed 's/while j < 100000/while j < 1000/; s/100,000/1,000/' loops.sake > build/loops_small.sake
sed 's/while j < 100000/while j < 1000/; s/100,000/1,000/' loops.rb > build/loops_small.rb
sed 's/while j < 100000/while j < 1000/' hand/loops.rs > build/loops_small_hand.rs
cp fib.sake levenshtein.sake loops.sake build/
cp fib.rb levenshtein.rb loops.rb build/
cp hand/fib.rs build/fib_hand.rs; cp hand/levenshtein.rs build/levenshtein_hand.rs; cp hand/loops.rs build/loops_hand.rs
cp fib.sake build/fib_big.sake; cp fib.rb build/fib_big.rb; cp hand/fib.rs build/fib_big_hand.rs   # fib 38: too long for the interpreter
cp shapes.sake shapes_mono.sake shapes.rb shapes_mono.rb build/
cp hand/shapes_enum.rs build/shapes_hand.rs; cp hand/shapes_mono.rs build/shapes_mono_hand.rs; cp hand/shapes_dyn.rs build/shapes_dyn_hand.rs

echo "# $(date -u +%FT%TZ) host=$(hostname) ruby=$($RUBY -v) rustc=$(rustc --version) sake=$(cat $SAKE/REVISION 2>/dev/null)" >&2
for b in loops loops_small fib fib_big levenshtein shapes shapes_mono; do
  $RUBY $SAKE/bin/sabic build/$b.sake -o build/$b.sakers
  rustc --edition 2021 -O -C overflow-checks=on -o build/$b.hand build/${b}_hand.rs 2>/dev/null
done
rustc --edition 2021 -O -C overflow-checks=on -o build/shapes_dyn.hand build/shapes_dyn_hand.rs 2>/dev/null

WORDS=$($RUBY -e 'srand(1); puts Array.new(100) { Array.new(40) { ("a".."f").to_a.sample }.join }.join(" ")')
args_of() { case $1 in loops|loops_small) echo 7;; fib) echo 32;; fib_big) echo 38;; levenshtein) echo "$WORDS";; shapes|shapes_mono) echo 10000;; esac; }

TIMEFORMAT=%R
time_it() { # bench impl reps cmd...
  local b=$1 impl=$2 reps=$3; shift 3
  for r in $(seq "$reps"); do
    local t
    t=$( { time "$@" $(args_of "$b") > "build/$b.$impl.out"; } 2>&1 )
    echo "$b $impl $r $t"
  done
}

for b in ${BENCHES:-loops_small fib fib_big levenshtein shapes shapes_mono loops}; do
  time_it "$b" ruby "$REPS" "$RUBY" --yjit "build/$b.rb"
  time_it "$b" sake-rust "$REPS" "build/$b.sakers"
  time_it "$b" hand-rust "$REPS" "build/$b.hand"
  [ "$b" = shapes ] && time_it "$b" hand-rust-dyn "$REPS" "build/shapes_dyn.hand"
  if [ "$b" != loops ] && [ "$b" != fib_big ]; then
    time_it "$b" sake-interp "$INTERP_REPS" "$RUBY" "$SAKE/bin/sake" "build/$b.sake"
  fi
  if [ "$b" = fib ] || [ "$b" = levenshtein ] || [ "$b" = shapes ] || [ "$b" = shapes_mono ]; then
    for impl in sake-rust hand-rust sake-interp; do
      cmp -s "build/$b.ruby.out" "build/$b.$impl.out" && echo "# $b: $impl output agrees with ruby" >&2 || echo "# $b: $impl OUTPUT DIFFERS from ruby" >&2
    done
  fi
done
