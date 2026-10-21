#!/bin/bash
# On sp4: whole-app check of the blog (bin/sake -c --strict bin/rails.sake), N runs (the caller runs `bench-lease check` before invoking), wall time and max RSS.
# usage: blog_check.sh <sake tree> <ruby> [N]   (output: one line per run, then "DONE")
set -eu
tree=$1 ruby=$2 n=${3:-3}
cd "$tree/experiments/2026-10-20-rails-scale/blog"
mkdir -p log storage tmp
echo "# $(date -u +%FT%TZ) $(hostname) $($ruby -v) tree=$tree load=$(cut -d' ' -f1-3 /proc/loadavg)"
for i in $(seq $n); do

  /usr/bin/time -f "run $i: %e s %M KB exit=%x" $ruby -I"$tree/lib" "$tree/bin/sake" -c --strict bin/rails.sake > /tmp/blog_check.$i.out 2>/tmp/blog_check.$i.time || true
  tail -1 /tmp/blog_check.$i.time
  tail -1 /tmp/blog_check.$i.out | cut -c1-120
done
echo DONE
