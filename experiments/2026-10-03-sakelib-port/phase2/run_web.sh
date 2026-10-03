#!/bin/sh
# Usage: run_web.sh LIBDIR LABEL [LIBS...]
# LIBDIR holds json/base64/shellwords/cgi/uri/erb .sake under test; they are copied next to the benches,
# so require picks them before sakelib/. 3 runs each of bin/sake --strict bench_<lib>.sake; prints
# user+sys CPU seconds of the whole process (check + run) and the bench's own "work" wall time.
set -e
here=$(cd "$(dirname "$0")" && pwd)
sake=$here/../../../bin/sake
work=$(mktemp -d)
libdir=$(cd "$1" && pwd); label=$2; shift 2
libs=${*:-json base64 shellwords cgi uri erb}
for l in $libs; do cp "$libdir"/$l.sake "$here"/bench_$l.sake "$work"/; done
cd "$work"
for l in $libs; do
  printf '%s\t%s\t' "$label" "$l"
  for i in 1 2 3; do
    /usr/bin/time -f "%U %S" "$sake" --strict bench_$l.sake >out.txt 2>err.txt || { echo FAIL; cat err.txt; exit 1; }
    w=$(grep '^work' err.txt | awk '{print $2}')
    tail -1 err.txt | awk -v w="$w" '{printf "cpu=%.2f work=%s  ", $1 + $2, w}'
  done
  printf 'load=%s out=%s\n' "$(cut -d' ' -f1 /proc/loadavg)" "$(md5sum < out.txt | cut -c1-8)"
done
rm -rf "$work"
