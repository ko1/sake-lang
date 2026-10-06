#!/bin/sh
# Makes P5's (reading) work directories and prompts: prep_p5.sh REP...   (e.g. prep_p5.sh r1 r2)
# Per REP: {predict, fix} x {sake, ruby} x 20 tasks, 5 tasks per agent -> 16 prompts. Nothing is run by the reader.
set -e
cd "$(dirname "$0")/.."
for rep in "$@"; do
  for kind in predict fix; do
    case $kind in predict) tasks=$(ls reading | grep '^p') ;; fix) tasks=$(ls reading | grep '^f') ;; esac
    for lang in sake ruby; do
      run=p5-$lang-$kind-$rep
      ruby harness/make_reading_run.rb "$run" "$lang" "$kind" $tasks
      for g in 1 2 3 4; do
        BRIEF=brief-read-$kind.md sh harness/make_prompt.sh "$run" "$lang" read read \
          $(echo "$tasks" | sed -n "$((g * 5 - 4)),$((g * 5))p" | cut -c1-3) > "prompts/$run-g$g.md"
      done
    done
  done
done
