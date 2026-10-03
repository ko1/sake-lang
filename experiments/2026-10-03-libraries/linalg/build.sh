#!/bin/sh
# Concatenate lib.sake with each client into out/<client>.sake, then run it.
cd "$(dirname "$0")"
mkdir -p out
SAKE=../../../bin/sake
status=0
for c in ${@:-client_*.sake}; do
  name=$(basename "$c" .sake)
  cat lib.sake "$c" > "out/$name.sake"
  echo "== $name"
  $SAKE ${SAKE_FLAGS:---strict} "out/$name.sake" || status=$?
done
exit $status
