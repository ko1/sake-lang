#!/bin/sh
# Concatenate lib.sake with each client into out/<client>.sake (Sake has no require).
# Prints the line offset so a message's line number can be mapped back to the client file.
set -e
cd "$(dirname "$0")"
mkdir -p out
libn=$(wc -l < lib.sake)
for c in ${@:-client_*.sake}; do
  name=$(basename "$c" .sake)
  { cat lib.sake; echo "# ---- $c (client line N = out line N+$((libn+1))) ----"; cat "$c"; } > "out/$name.sake"
  echo "out/$name.sake (client lines start at $((libn+2)))"
done
