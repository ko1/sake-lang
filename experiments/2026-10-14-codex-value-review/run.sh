#!/bin/bash
# Runs the value review with Codex on a snapshot of the repository (a detached worktree at the commit in
# commit.txt), retrying every 15 minutes while Codex reports its usage limit. Writes codex.log (the whole
# session), report.md (Codex's final message), and status (DONE/LIMIT/FAIL lines with UTC times).
set -u
E=$(cd "$(dirname "$0")" && pwd)
WT=$1
for i in $(seq 1 24); do
  echo "start $(date -u +%FT%TZ) try $i" >> "$E/status"
  codex exec -C "$WT" -s workspace-write --skip-git-repo-check -o "$E/report.md" - < "$E/prompt.md" > "$E/codex.log" 2>&1
  rc=$?
  if [ -s "$E/report.md" ] && [ $rc -eq 0 ]; then echo "DONE $(date -u +%FT%TZ)" >> "$E/status"; exit 0; fi
  if grep -q "usage limit" "$E/codex.log"; then echo "LIMIT $(date -u +%FT%TZ)" >> "$E/status"; rm -f "$E/report.md"; sleep 900; continue; fi
  echo "FAIL rc=$rc $(date -u +%FT%TZ)" >> "$E/status"; exit 1
done
echo "GAVE UP $(date -u +%FT%TZ)" >> "$E/status"; exit 1
