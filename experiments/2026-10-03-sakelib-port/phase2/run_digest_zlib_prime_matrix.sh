#!/bin/sh
# Usage: run_digest_zlib_prime_matrix.sh LIBDIR LABEL
# LIBDIR holds the digest/zlib/prime/matrix .sake under test; they are copied next to the benches, so
# require picks them before sakelib/. Prints user+sys CPU seconds of bin/sake --strict, 3 runs each.
set -e
here=$(cd "$(dirname "$0")" && pwd)
sake=$here/../../../bin/sake
work=$(mktemp -d)
cp "$1"/digest.sake "$1"/zlib.sake "$1"/prime.sake "$1"/matrix.sake "$work"/
for l in digest zlib prime matrix; do cp "$here"/bench_$l.sake "$work"/; done
cd "$work"
run() { for i in 1 2 3; do /usr/bin/time -f "%U %S" "$sake" --strict "$@" 2>&1 >/dev/null | tail -1 | awk '{printf "%.2f ", $1 + $2}'; done; }
for a in "bench_digest.sake md5 0" "bench_digest.sake md5 16" "bench_digest.sake sha1 16" "bench_digest.sake sha256 16" \
         "bench_digest.sake sha512 16" "bench_zlib.sake crc32 0" "bench_zlib.sake crc32 128" "bench_zlib.sake adler32 128" \
         "bench_prime.sake 0" "bench_prime.sake 50" "bench_matrix.sake 0" "bench_matrix.sake 16"; do
  printf '%s\t%s\t' "$2" "$a"; run $a; printf 'load %s\n' "$(cut -d' ' -f1 /proc/loadavg)"
done
rm -rf "$work"
