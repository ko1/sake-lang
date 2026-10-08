#!/bin/sh
# P11: grades every run marked finished (runs/<run>/DONE, written when its agent reports) that has no final/
# yet and whose baseline exists; loops until runs/autograde-p11.stop exists. Several copies may run: each run is
# claimed with mkdir runs/<run>/grading (atomic).
#   nohup sh harness/autograde_p11.sh WORKER [nosake] &   (nosake: skip Sake runs, so slow Sake grades do not block the rest)      log: runs/autograde-p11.log (heartbeat each pass)
cd "$(dirname "$0")/.." || exit 1
me=${1:-1}
skip=${2:-}
log=runs/autograde-p11.log
while [ ! -e runs/autograde-p11.stop ]; do
  echo "$(date +%T) pass $me" >> $log
  for d in runs/p11-*/DONE; do
    [ -e "$d" ] || continue
    w=$(dirname "$d"); run=$(basename "$w")
    [ -e "$w/final" ] && continue
    [ "$skip" = nosake ] && case "$run" in *-sake-*) continue;; esac
    src=$(ruby -rjson -e 'm=JSON.parse(File.read(ARGV[0])); print m["src"], " ", m["change"]' "$w/meta.json")
    grep -q "\"src\":\"${src% *}\",\"change\":\"${src#* }\"" runs/baseline-p11.jsonl 2>/dev/null || continue
    mkdir "$w/grading" 2>/dev/null || continue
    ruby harness/grade_p11.rb "$run" >> $log 2>&1 || echo "FAILED $run" >> $log
  done
  sleep 60
done
echo "$(date +%T) stopped $me" >> $log
