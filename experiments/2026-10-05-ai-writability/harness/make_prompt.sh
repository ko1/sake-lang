#!/bin/sh
# Makes a solver prompt: [BRIEF=brief-*.md] make_prompt.sh RUN LANG MODE DOCS TASK... > prompts/NAME.md
#   LANG sake|ruby, MODE oneshot|agentic, DOCS full (tutorial+spec+builtins) | cheat (cheatsheet.md only)
#   | read (the full documents, without the note on the checker; for the reading tasks)
cd "$(dirname "$0")/.."
run=$1 lang=$2 mode=$3 docs=$4; shift 4
if [ "$lang" = sake ]; then ext=sake; name=Sake; else ext=rb; name="Ruby (4.0; the standard library is allowed)"; fi
sed -e "s/\*\*LANG\*\*/**$name**/" -e "/MODE_TEXT/{r mode-$mode.txt
d}" "${BRIEF:-brief-solve.md}" | sed "s/EXT/$ext/g"
echo
if [ "$lang" = sake ]; then
  case "$docs" in cheat) sed "s/STRICT/1/" lang-sake-cheat.txt ;; read) cat lang-sake-read.txt ;; *) sed "s/STRICT/1/" lang-sake.txt ;; esac
fi
echo
echo "Your tasks, in order (directories under /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/$run/):"
for t in "$@"; do echo "- $(basename runs/$run/$t-*)"; done
