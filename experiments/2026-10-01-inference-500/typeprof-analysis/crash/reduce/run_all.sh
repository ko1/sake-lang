#!/bin/bash
cd "$(dirname "$0")"
for f in goldbach xor_breaker staff_multikey_sort cpu_scheduler descriptive_stats room_bookings password_policy nested_schema 20-business/payroll; do
  case $f in */*) src=../../../corpus/$f.rb; n=$(basename $f);; *) src=$(ls ../../../corpus/*/$f.rb); n=$f;; esac
  echo "=== $n start $(date)"
  ruby reduce.rb "$src" "$n.min.rb" mem 2>&1
  echo "=== $n end $(date) rc=$?"
done
echo ALL-DONE
