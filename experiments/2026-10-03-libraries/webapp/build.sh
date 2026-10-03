#!/bin/sh
# Usage: ./build.sh [client_x.sake ...]   (default: every client_*.sake)
# Concatenates lib.sake and each client into out/<client>.sake.
cd "$(dirname "$0")"
mkdir -p out
[ $# -eq 0 ] && set -- client_*.sake
for c in "$@"; do
  cat lib.sake "$c" > "out/$c"
  echo "out/$c (lib: lines 1-$(wc -l < lib.sake), client starts at line $(( $(wc -l < lib.sake) + 1 )))"
done
