#!/bin/sh
# Makes P6's work directories and prompts: prep_p6.sh REP...   (e.g. prep_p6.sh r1 r2)
# Per REP: 8 changes x {ruby, sake (port), sake-scratch}, one change per agent -> 24 prompts.
set -e
cd "$(dirname "$0")/.."
exp=$(pwd)
changes=$(ls large/mini/changes)
for rep in "$@"; do
  for cb in ruby sake sake-scratch; do
    run=p6-$cb-$rep
    ruby harness/make_mini_run.rb "$run" "$cb" $changes
    for ch in $changes; do
      w=$exp/runs/$run/$ch
      if [ "$cb" = ruby ]; then name='Ruby (4.0; the standard library is allowed)'; ext=rb; note=''; lang=''
      else name=Sake; ext=sake
        note='checks the program with `bin/sake --strict=2 -c` (this can take a minute or more; a program it rejects does not run), then '
        lang='**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read.'
      fi
      ruby -e 'b=File.read("brief-mini-solve.md"); puts b.gsub("WORK_DIR"){ARGV[0]}.gsub("**LANG**"){"**"+ARGV[1]+"**"}.gsub("EXT"){ARGV[2]}.gsub("CHECK_NOTE"){ARGV[3]}; puts; puts ARGV[4] unless ARGV[4].empty?' \
        "$w" "$name" "$ext" "$note" "$lang" > "prompts/$run-$ch.md"
    done
  done
done
