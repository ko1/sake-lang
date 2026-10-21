#!/bin/bash
# On sp4: Spinel's analysis + C generation (`spinel -c`, no C compile) of roundhouse's output for the blog
# (out-spinel from spinel/run.sh), N runs, wall time, max RSS and Spinel's own --timing phases.
# usage: spinel_check.sh <out-spinel dir> <spinel checkout> [N]   (the caller runs `bench-lease check` first)
set -eu
out=$(cd "$1" && pwd) spdir=$(cd "$2" && pwd) n=${3:-3}
flags="--require-gate -I $HOME/.cache/spin/packages/bcrypt-0.1.1 -I $out --rbs $out"
cd "$out"
echo "# $(date -u +%FT%TZ) $(hostname) $("$spdir/bin/spinel" --version) $(cc --version | head -1) load=$(cut -d' ' -f1-3 /proc/loadavg)"
for i in $(seq $n); do
  /usr/bin/time -f "spinel -c run $i: %e s %M KB exit=%x" -o /tmp/spinel_c.$i.time "$spdir/bin/spinel" $flags main.rb -c -o /tmp/spinel_blog.c --force --timing > /tmp/spinel_c.$i.log 2>&1 || true
  cat /tmp/spinel_c.$i.time
  grep -E 'phase=(frontend|analysis|codegen_program|write_c) ' /tmp/spinel_c.$i.log | sed 's/^/  /'
done
echo "C lines: $(wc -l < /tmp/spinel_blog.c)"
echo DONE
