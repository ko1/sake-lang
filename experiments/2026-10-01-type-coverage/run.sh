#!/bin/sh
# Reproduce results-*.md (run from this directory).
set -e
# The corpus was written for Data.define, renamed to Struct.new on 2026-10-01; type a renamed copy.
C=$(mktemp -d)
mkdir -p "$C/corpus/first"
for f in corpus/*.sake corpus/first/*.sake; do sed 's/Data\.define(/Struct.new(/g' "$f" > "$C/$f"; done
# Samples that stop at static checks cannot be typed.
F="$C/corpus/*.sake $(ls ../../test/samples/*.sake | grep -v -e static -e ruby_times -e _errors -e value_constant)"
ruby -w crosscheck.rb $F > results-narrow.md
ruby -w crosscheck.rb --no-narrow $F > results-no-narrow.md
ruby crosscheck.rb --sabotage $F > results-sabotage.md 2> results-sabotage.err || true
for f in "$C"/corpus/*.sake "$C"/corpus/first/linked_list.sake; do echo "== $f"; ../../bin/sake --types "$f"; done > types-report.txt
