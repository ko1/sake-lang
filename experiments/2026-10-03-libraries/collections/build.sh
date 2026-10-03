#!/bin/sh
# Concatenate lib.sake with each client into out/<client>.sake and run it at level 2.
# Usage: ./build.sh [client_x.sake ...]   (default: every client_*.sake)
cd "$(dirname "$0")"
SAKE=../../../bin/sake
mkdir -p out
[ $# -eq 0 ] && set -- client_*.sake
status=0
for c in "$@"; do
  out="out/$c"
  libn=$(wc -l < lib.sake)
  { cat lib.sake; echo "# ---- $c (line 1 of the client is line $((libn + 2)) here)"; cat "$c"; } > "$out"
  echo "== $out (client line N = out line N+$((libn + 1)))"
  $SAKE --strict "$out" || status=$?
done
exit $status
