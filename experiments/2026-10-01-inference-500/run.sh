#!/bin/sh
# Measures a corpus: ./run.sh [CORPUS_DIR] [OUT_DIR]   (defaults: corpus results)
# Writes OUT_DIR/{verify.tsv,sake.jsonl,typeprof.jsonl,strict.tsv,crosscheck*.md,results.md}.
set -e
cd "$(dirname "$0")"
C=${1:-corpus}
O=${2:-results}
J=${J:-4}
SAKE=../../bin/sake
mkdir -p "$O"
FILES=$(ls "$C"/*/*.sake)

# 1. each program runs (exit 0), and Sake, Ruby, and the recorded .out agree
for f in $FILES; do
  b=${f%.sake}
  s=$($SAKE --strict=0 "$f" 2>&1) && st=0 || st=$?
  r=$(ruby "$b.rb" 2>&1) || true
  e=$(cat "$b.out" 2>/dev/null) || e="(no .out)"
  ok=ok
  [ "$st" = 0 ] || ok="exit$st"
  [ "$s" = "$r" ] || ok="$ok,ruby-differs"
  [ "$s" = "$e" ] || ok="$ok,out-differs"
  printf '%s\t%s\n' "$f" "$ok"
done > "$O/verify.tsv"

# 2. inference coverage
echo "$FILES" | xargs -P "$J" -n 10 ruby measure.rb > "$O/sake.jsonl"
ls "$C"/*/*.rb | xargs -P "$J" -n 5 ruby typeprof_measure.rb > "$O/typeprof.jsonl"

# 3. checks before running, on programs that are all correct: every report is a false one
for lvl in 1 2 3 4; do
  for f in $FILES; do
    n=$($SAKE -c --strict=$lvl "$f" 2>&1 | grep -c ': error:') || true
    printf '%s\t%s\t%s\t%s\n' "$f" "$lvl" "$([ "$n" -gt 0 ] && echo 1 || echo 0)" "$n"
  done
done > "$O/strict.tsv"

# 4. soundness: observed run-time types are inside the inferred ones; the sabotaged typer must fail
X=crosscheck.rb
ruby -w $X $FILES > "$O/crosscheck.md" 2> "$O/crosscheck.err" || true
ruby $X --sabotage $FILES > "$O/crosscheck-sabotage.md" 2> "$O/crosscheck-sabotage.err" || true

ruby summarize.rb "$O" > "$O/results.md"
