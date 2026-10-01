#!/bin/sh
# Writes latest-*.md / latest-types-report.txt for the current code (run from this directory).
# results-*.md and types-report.txt are the results recorded at commit 8da5bfc; see README.
set -e
# The corpus was written for Data.define, renamed to Struct.new on 2026-10-01; type a renamed copy.
C=$(mktemp -d)
mkdir -p "$C/corpus/first"
for f in corpus/*.sake corpus/first/*.sake; do sed 's/Data\.define(/Struct.new(/g' "$f" > "$C/$f"; done
# Samples that stop at static checks cannot be typed.
F="$C/corpus/*.sake $(ls ../../test/samples/*.sake | grep -v -e static -e ruby_times -e _errors -e value_constant)"
ruby -w crosscheck.rb $F > latest-narrow.md
ruby -w crosscheck.rb --no-narrow $F > latest-no-narrow.md
ruby crosscheck.rb --sabotage $F > latest-sabotage.md 2> latest-sabotage.err || true
for f in "$C"/corpus/*.sake "$C"/corpus/first/linked_list.sake; do echo "== $f"; ../../bin/sake --types "$f"; done > latest-types-report.txt
