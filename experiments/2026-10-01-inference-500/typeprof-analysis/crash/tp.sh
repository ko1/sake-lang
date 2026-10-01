#!/bin/bash
# usage: tp.sh FILE [VMEM_KB=3000000] [TIMEOUT_S=120]
# Runs ONE typeprof under ulimit -v and timeout; prints status, wall time, peak RSS, first output line.
f=$1; lim=${2:-3000000}; to=${3:-120}
# one run at a time from this analysis (other analyses may run their own typeprof)
exec 9>"$(dirname "$0")/.tp.lock"; flock 9
out=$(mktemp); tm=$(mktemp)
( ulimit -v "$lim"; /usr/bin/time -v -o "$tm" timeout "$to" typeprof --show-errors "$f" >"$out" 2>&1 ); rc=$?
w=$(grep 'Elapsed (wall' "$tm" | awk '{print $NF}'); r=$(grep 'Maximum resident' "$tm" | awk '{print $NF}')
[ -n "$w" ] && [ -n "$r" ] || { echo "time -v output missing" >&2; cat "$tm" >&2; exit 3; }
printf '%s rc=%s wall=%s maxrss=%dMB first=%s\n' "$f" "$rc" "$w" $((r/1024)) "$(grep -m1 -v '^$' "$out" | cut -c1-120)"
[ -n "$KEEP" ] && cp "$out" "$KEEP"
rm -f "$out" "$tm"
