#!/bin/sh
# Makes P4's work directories and solver prompts: prep_p4.sh REP...   (e.g. prep_p4.sh r1 r2)
# Per REP: 20 change tasks x {sake, ruby}, agentic only, 5 tasks per agent -> 8 prompts.
set -e
cd "$(dirname "$0")/.."
changes=$(ls changes)
for rep in "$@"; do
  for lang in sake ruby; do
    run=p4-$lang-agentic-$rep
    ruby harness/make_change_run.rb "$run" "$lang" agentic 1 $changes
    for g in 1 2 3 4; do
      BRIEF=brief-change-solve.md sh harness/make_prompt.sh "$run" "$lang" agentic full \
        $(echo "$changes" | sed -n "$((g * 5 - 4)),$((g * 5))p" | cut -c1-3) > "prompts/$run-g$g.md"
    done
  done
done
