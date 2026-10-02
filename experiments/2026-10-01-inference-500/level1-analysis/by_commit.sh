#!/bin/sh
# Level-1 (and level-2) diagnostics on corpus-v2 at each commit: OUT/<commit>.l<N>.txt, one diagnostic per line.
# usage: level1-analysis/by_commit.sh COMMIT...   (run in the experiment directory; J=parallel jobs, default 8)
set -e
cd "$(dirname "$0")/.."
J=${J:-8}
for c in "$@"; do
  wt=$(mktemp -d)/wt
  git -C ../.. worktree add -q --detach "$wt" "$c"
  for l in 1 2; do
    ls corpus-v2/*/*.sake | xargs -P "$J" -I{} sh -c "'$wt/bin/sake' -c --strict=$l {} 2>&1 | grep ': error:' || true" | sort > "level1-analysis/$c.l$l.txt"
  done
  git -C ../.. worktree remove --force "$wt"
  echo "$c $(wc -l < level1-analysis/$c.l1.txt) $(wc -l < level1-analysis/$c.l2.txt)"
done
