#!/bin/sh
# Concatenates lib.sake and each client into out/<client>.sake (Sake has no require).
# A marker line records where the client starts, to map error line numbers back.
set -e
cd "$(dirname "$0")"
mkdir -p out
for c in ${@:-client_*.sake}; do
  name=$(basename "$c" .sake)
  n=$(($(wc -l < lib.sake) + 2))
  { cat lib.sake; echo "# ---- $c starts at line $n (client line = line - $((n - 1)))"; cat "$c"; } > "out/$name.sake"
done
