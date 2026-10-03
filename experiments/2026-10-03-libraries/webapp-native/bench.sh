#!/bin/sh
# Usage: ./bench.sh URL N PARALLEL   -- N GET requests, PARALLEL at a time; prints the median and the 90th percentile in ms.
url=$1; n=$2; par=$3
seq "$n" | xargs -P "$par" -I{} curl -s -o /dev/null -w "%{time_total}\n" "$url" | sort -n |
  awk '{a[NR]=$1} END {printf "n=%d median=%.0fms p90=%.0fms\n", NR, a[int(NR/2)+1]*1000, a[int(NR*0.9)]*1000}'
