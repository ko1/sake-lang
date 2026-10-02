#!/bin/bash
# usage: gen_levels.sh L > FILE.rb   -- a recursive-descent "parser" with L precedence levels that builds
# [:opN, lhs, rhs] tuples; TypeProf's signature output for level1 grows ~60-90x per extra level.
L=$1
echo "# $L precedence levels, like a recursive-descent parser building [:op, lhs, rhs] tuples"
for i in $(seq 1 $L); do
  n=$((i+1)); echo "def level$i"
  if [ $i -lt $L ]; then echo "  node = level$n"; echo "  node = [:op$i, node, level$n] while rand < 0.3"; echo "  node"
  else echo "  rand < 0.7 ? [:num, 1] : level1"; fi
  echo "end"
done
echo "p level1"
