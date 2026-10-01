#!/bin/sh
# One corpus program: prints "verify<TAB>file<TAB>status" and "strict<TAB>file<TAB>level<TAB>rejected<TAB>diagnostics".
f=$1
SAKE=${SAKE_BIN:-../../bin/sake}
b=${f%.sake}
s=$($SAKE --strict=0 "$f" 2>&1) && st=0 || st=$?
r=$(ruby "$b.rb" 2>&1) || true
e=$(cat "$b.out" 2>/dev/null) || e="(no .out)"
ok=ok
[ "$st" = 0 ] || ok="exit$st"
[ "$s" = "$r" ] || ok="$ok,ruby-differs"
[ "$s" = "$e" ] || ok="$ok,out-differs"
printf 'verify\t%s\t%s\n' "$f" "$ok"
for lvl in 1 2 3 4; do
  n=$($SAKE -c --strict=$lvl "$f" 2>&1 | grep -c ': error:') || true
  printf 'strict\t%s\t%s\t%s\t%s\n' "$f" "$lvl" "$([ "$n" -gt 0 ] && echo 1 || echo 0)" "$n"
done
