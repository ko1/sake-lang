#!/bin/sh
# Makes P7h (P3 with Haiku 4.5) work directories and prompts: prep_p7h.sh REP...   (e.g. prep_p7h.sh r1)
# Per REP: 20 tasks x {sake, ruby} x {agentic, oneshot}, 5 tasks per agent -> 16 prompts, the same as P3.
set -e
cd "$(dirname "$0")/.."
tasks=$(ls tasks)
for rep in "$@"; do
  for lang in sake ruby; do
    for mode in agentic oneshot; do
      run=p7h-$lang-$mode-$rep
      ruby harness/make_run.rb "$run" "$lang" "$mode" 1 $tasks
      for g in 1 2 3 4; do
        sh harness/make_prompt.sh "$run" "$lang" "$mode" full $(echo "$tasks" | sed -n "$((g * 5 - 4)),$((g * 5))p" | cut -c1-3) \
          > "prompts/$run-g$g.md"
      done
    done
  done
done
