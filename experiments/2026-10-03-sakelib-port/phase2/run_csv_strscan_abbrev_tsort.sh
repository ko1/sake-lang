#!/bin/sh
# usage: run_csv_strscan_abbrev_tsort.sh LABEL  -- 3 runs of each bench, CPU time (user+sys) from /usr/bin/time; appends to results_csv_strscan_abbrev_tsort.txt
cd "$(dirname "$0")"
SAKE=../../../bin/sake
for b in csv strscan abbrev tsort; do
  for i in 1 2 3; do
    out=$( { /usr/bin/time -f "%U %S %e" $SAKE --strict bench_$b.sake >/dev/null; } 2>&1 | tail -1 ) || { echo "FAIL $b"; exit 1; }
    set -- $out
    cpu=$(echo "$1 + $2" | bc)
    echo "$LABEL $b run$i cpu=$cpu wall=$3 load=$(cut -d' ' -f1 /proc/loadavg)" | tee -a results_csv_strscan_abbrev_tsort.txt
  done
done
