#!/bin/sh
# Makes P3's work directories and solver prompts: prep_p3.sh REP...   (e.g. prep_p3.sh r1 r2)
# Per REP: 20 tasks x {sake, ruby} x {agentic, oneshot}, 5 tasks per agent (as in P2) -> 16 prompts.
set -e
cd "$(dirname "$0")/.."
tasks=$(ls tasks)
for rep in "$@"; do
  for lang in sake ruby; do
    for mode in agentic oneshot; do
      run=p3-$lang-$mode-$rep
      ruby harness/make_run.rb "$run" "$lang" "$mode" 1 $tasks
      for g in 1 2 3 4; do
        sh harness/make_prompt.sh "$run" "$lang" "$mode" full $(echo "$tasks" | sed -n "$((g * 5 - 4)),$((g * 5))p" | cut -c1-3) \
          > "prompts/$run-g$g.md"
      done
    done
  done
done
