#!/bin/bash
# Concatenate lib.sake with each client into out/<client>.sake and run it at --strict (level 2).
cd "$(dirname "$0")"
mkdir -p out
SAKE=../../../bin/sake
status=0
for c in ${@:-client_*.sake}; do
  name=$(basename "$c" .sake)
  cat lib.sake "$c" > "out/$name.sake"
  echo "=== $name (client line = out line - $(wc -l < lib.sake))"
  $SAKE --strict "out/$name.sake" || status=1
done
exit $status
