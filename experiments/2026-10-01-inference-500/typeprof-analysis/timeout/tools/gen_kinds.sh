#!/bin/bash
# usage: gen_kinds.sh K > FILE.rb   -- one recursive method returning [:num, 1] or one of K binary [:opI, expr, expr] tuples.
K=$1
echo "def expr"; echo "  case rand(10)"; echo "  when 0 then [:num, 1]"
for i in $(seq 1 $K); do echo "  when $i then [:op$i, expr, expr]"; done
echo "  end"; echo "end"; echo "p expr"
