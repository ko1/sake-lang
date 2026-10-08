#!/bin/sh
# P11: grades every P10/P10b engine (stage 6, unchanged) on the suites of every change that has a change.md
# and no baseline yet, one run per engine -> runs/baseline-p11.jsonl.
#   sh harness/baselines_p11.sh       (3 engines at a time; refuses to start while another copy runs)
# Log: runs/baselines-p11.log (a line per engine and change, "DONE" at the end).
cd "$(dirname "$0")/.." || exit 1
lock=runs/baselines-p11.lock
mkdir "$lock" 2>/dev/null || { echo "another baselines_p11.sh is running ($lock)"; exit 1; }
trap 'rmdir "$lock"' EXIT INT TERM
log=runs/baselines-p11.log
for src in ruby-1 ruby-2 java-1 java-2 haskell-1 haskell-2 scheme-1 scheme-2 steep-1 steep-2 sake-1 sake-2; do
  echo "p10-$src"
done | xargs -P 3 -L 1 sh -c 'echo "$(date +%T) start $0" >> runs/baselines-p11.log; ruby harness/grade_p11.rb --baseline "$0" >> runs/baselines-p11.log 2>&1 || echo "FAILED $0" >> runs/baselines-p11.log'
echo "$(date +%T) DONE" >> "$log"
