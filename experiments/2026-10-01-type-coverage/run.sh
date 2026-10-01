#!/bin/sh
# Reproduce results-*.md (run from this directory).
set -e
# Samples that fail static checks (static_errors, typed_array_static, ruby_times) cannot be typed.
F="corpus/*.sake $(ls ../../test/samples/*.sake | grep -v -e static -e ruby_times)"
ruby -w crosscheck.rb $F > results-narrow.md
ruby -w crosscheck.rb --no-narrow $F > results-no-narrow.md
ruby crosscheck.rb --sabotage $F > results-sabotage.md 2> results-sabotage.err || true
for f in corpus/*.sake corpus/first/linked_list.sake; do echo "== $f"; ../../bin/sake --types "$f"; done > types-report.txt
