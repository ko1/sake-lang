#!/bin/sh
# Wall time of `bin/sake --strict=2 -c` on the two SQL engines, Typer (SAKE_TYPER=1), Typer2 and Typer2 with the
# type variables off, 3 alternating runs. Run on an idle machine (check uptime first).
cd "$(dirname "$0")/../.." || exit 1
for i in 1 2 3; do
  for n in 1 2; do
    E=experiments/2026-10-05-ai-writability/runs/p10-sake-$n/stage-6/code/main.sake
    /usr/bin/time -f "sake-$n typer1: %e s (user %U) %M KB" env SAKE_TYPER=1 bin/sake --strict=2 -c $E 2>&1 >/dev/null | tail -1
    /usr/bin/time -f "sake-$n typer2: %e s (user %U) %M KB" env SAKE_TYPER=2 bin/sake --strict=2 -c $E 2>&1 >/dev/null | tail -1
    /usr/bin/time -f "sake-$n typer2 nopoly: %e s (user %U) %M KB" env SAKE_TYPER=2 SAKE_TYPER2_NOPOLY=1 bin/sake --strict=2 -c $E 2>&1 >/dev/null | tail -1
  done
done
