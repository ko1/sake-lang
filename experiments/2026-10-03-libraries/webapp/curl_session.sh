#!/bin/bash
# Runs the end-to-end curl session against serve.rb (todo on :18431, shortener on :18432).
J=$(mktemp); J2=$(mktemp)
T=http://127.0.0.1:18431; S=http://127.0.0.1:18432
run() { echo "\$ $*"; "$@"; echo; echo; }
echo "### todo app (client_todo.sake), served by: ruby serve.rb client_todo 18431 3"
echo
run curl -s -i $T/
run curl -s -i -c $J -b $J -d "title=Buy+milk+%26+eggs" $T/todos
run curl -s -c $J -b $J -L -d "title=%E9%85%92%E3%82%92%E8%B2%B7%E3%81%86+%3Cb%3Ebold%3F%3C%2Fb%3E" $T/todos
run curl -s -i -d "title=++" $T/todos
run curl -s -i -d "title=$(printf 'x%.0s' $(seq 61))" $T/todos
run curl -s -i $T/todos/1
run curl -s -L -d "" $T/todos/1/toggle
run curl -s -i $T/api/todos
run curl -s $T/api/todos/2
run curl -s -i $T/todos/99
run curl -s -i $T/api/todos/abc
run curl -s -i $T/nowhere
run curl -s -i -X DELETE $T/todos/1
run curl -s -c $J -b $J -L -d "" $T/todos/1/delete
run curl -s $T/api/todos
run cat data/todos.tsv
echo "### URL shortener (client_shorten.sake), served by: ruby serve.rb client_shorten 18432 3"
echo
run curl -s -i -c $J2 -b $J2 -d "url=https%3A%2F%2Fwww.ruby-lang.org%2Fen%2F" $S/links
run curl -s -c $J2 -b $J2 -L -d "url=https%3A%2F%2Fexample.com%2F%3Fq%3D1%26r%3D2&code=ex1" $S/links
run curl -s -i -d "url=ftp%3A%2F%2Fx&code=!!" $S/links
run curl -s -i -d "url=https%3A%2F%2Fa.b&code=ex1" $S/links
run curl -s -i $S/s/ex1
run curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" $S/s/ex1
run curl -s -c $J2 -b $J2 $S/
run curl -s "$S/api/links?min_hits=1"
run curl -s -i $S/s/nope/info
run cat data/links.tsv
rm -f $J $J2
