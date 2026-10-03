#!/bin/bash
# Concatenates lib.sake with each client into out/<client>.sake (Sake has no require).
set -e
cd "$(dirname "$0")"
mkdir -p out
for c in ${@:-client_*.sake}; do
  name=$(basename "$c")
  { cat lib.sake; echo "# ---- $name ----"; cat "$c"; } > "out/$name"
  echo "out/$name (client starts at line $(($(wc -l < lib.sake) + 2)))"
done
