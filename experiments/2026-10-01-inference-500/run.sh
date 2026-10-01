#!/bin/sh
# Measures a corpus: ./run.sh [CORPUS_DIR] [OUT_DIR]   (defaults: corpus results; J=parallel jobs, default 8)
# The interpreter and typer measured are the ones in ../../lib (this checkout).
# Writes OUT_DIR/{verify.tsv,strict.tsv,sake.jsonl,typeprof.jsonl,crosscheck*.md,polysites.jsonl,dispatch.jsonl,results.md}.
# crosscheck*.md mix the table rows with the violation lines (stderr); summarize.rb reads the rows.
set -e
cd "$(dirname "$0")"
export TZ=UTC # two programs format dates in local time
C=${1:-corpus}
O=${2:-results}
J=${J:-8}
mkdir -p "$O"
FILES=$(ls "$C"/*/*.sake)
RBS=$(ls "$C"/*/*.rb)

# Each parallel batch writes its own file (long lines written to one shared pipe interleave).
par() { # par N OUT CMD...: run CMD on the files from stdin, N at a time, batches in parallel; concatenate into OUT
  n=$1; out=$2; shift 2
  rm -rf "$out.d"; mkdir -p "$out.d"
  xargs -P "$J" -n "$n" sh -c 'f=$(mktemp "$0/XXXXXX"); "$@" > "$f"' "$out.d" "$@"
  cat "$out.d"/* > "$out"; rm -rf "$out.d"
}

# 1. each program runs (exit 0), Sake/Ruby/.out agree; 3. checks before running at levels 1-4
#    (every program is correct, so every report is a false one)
echo "$FILES" | par 1 "$O/one.tsv" tools/one.sh
grep '^verify' "$O/one.tsv" | cut -f2- | sort > "$O/verify.tsv"
grep '^strict' "$O/one.tsv" | cut -f2- | sort > "$O/strict.tsv"
rm "$O/one.tsv"

# 2. inference coverage (Sake typer; TypeProf on the Ruby versions)
echo "$FILES" | par 10 "$O/sake.jsonl" ruby measure.rb
echo "$RBS" | par 5 "$O/typeprof.jsonl" ruby typeprof_measure.rb

# 4. soundness: observed run-time types are inside the inferred ones; the sabotaged typer must fail
echo "$FILES" | par 10 "$O/crosscheck.md" sh -c 'ruby -w crosscheck.rb "$@" 2>&1; true' sh
echo "$FILES" | par 10 "$O/crosscheck-sabotage.md" sh -c 'ruby crosscheck.rb --sabotage "$@" 2>&1; true' sh

# 5. dispatch demand: receivers of 2+ classes in the Ruby versions; hand-written dispatch in Sake
echo "$RBS" | par 10 "$O/polysites.jsonl" ruby polysites.rb
echo "$FILES" | xargs -n 50 ruby sake_dispatch.rb | sort > "$O/dispatch.jsonl"

ruby summarize.rb "$O" > "$O/results.md"
