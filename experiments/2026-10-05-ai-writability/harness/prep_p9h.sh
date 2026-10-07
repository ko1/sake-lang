#!/bin/sh
# Makes P9h (can Haiku 4.5's Sake be helped?) work directories and prompts: prep_p9h.sh REP...
# Per REP, 20 tasks, 5 per agent, Sake only, prompts as in P3/P7h except:
#   p9h-sake-agentic-cheat / p9h-sake-oneshot-cheat: the cheatsheet (cheatsheet.md) instead of docs/
#   p9h-sake-agentic-verify: docs/ as usual plus verify-ops.txt (look every operation up before writing it)
set -e
cd "$(dirname "$0")/.."
tasks=$(ls tasks)
for rep in "$@"; do
  for cond in agentic-cheat oneshot-cheat agentic-verify; do
    mode=${cond%-*} kind=${cond#*-}
    run=p9h-sake-$cond-$rep
    ruby harness/make_run.rb "$run" sake "$mode" 1 $tasks
    for g in 1 2 3 4; do
      ts=$(echo "$tasks" | sed -n "$((g * 5 - 4)),$((g * 5))p" | cut -c1-3)
      if [ "$kind" = cheat ]; then
        sh harness/make_prompt.sh "$run" sake "$mode" cheat $ts > "prompts/$run-g$g.md"
      else
        { sh harness/make_prompt.sh "$run" sake "$mode" full $ts; echo; cat verify-ops.txt; } > "prompts/$run-g$g.md"
      fi
    done
  done
done
