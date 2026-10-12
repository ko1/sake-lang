#!/bin/bash
# Serves the todo app twice on 127.0.0.1 with a free port: app.sake (Sake, sakelib/sinatra.sake) and app.rb
# (Ruby, the sinatra gem). Each gets the same curl requests; the raw responses are printed, then compared with
# the parts that cannot be equal removed (Date, Server, Connection, Content-Length, the session cookie's value, the port, header case).
# Every server started here is stopped here.
set -u
cd "$(dirname "$0")"
SAKE=../../../bin/sake
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

scenario() {   # $1 = port
  local base="http://127.0.0.1:$1" jar="$OUT/jar.$1"
  local c=(curl -s -i --max-time 10 -c "$jar" -b "$jar")
  echo "### GET /";                    "${c[@]}" "$base/"; echo
  echo "### POST /todos (form)";       "${c[@]}" -d "title=Write <the> notes" "$base/todos"; echo
  echo "### POST /todos (empty)";      "${c[@]}" -d "title=" "$base/todos"; echo
  echo "### POST /todos/2/done";       "${c[@]}" -d "" "$base/todos/2/done"; echo
  echo "### GET / (after redirects)";  "${c[@]}" "$base/"; echo
  echo "### GET /todos/2";             "${c[@]}" "$base/todos/2"; echo
  echo "### GET /todos.json";          "${c[@]}" "$base/todos.json"; echo
  echo "### GET /todos/99 (404)";      "${c[@]}" "$base/todos/99"; echo
  echo "### GET /nowhere (404)";       "${c[@]}" "$base/nowhere"; echo
}

serve() {   # $1 = label, rest = command; runs the scenario against it and stops it
  local label=$1; shift
  "$@" > "$OUT/$label.log" 2>&1 &
  local pid=$! port=""
  for _ in $(seq 1 200); do
    port=$(sed -n 's/^port \([0-9]*\)$/\1/p' "$OUT/$label.log")
    [ -n "$port" ] && break
    sleep 0.1
  done
  if [ -z "$port" ]; then echo "$label: server did not start"; cat "$OUT/$label.log"; kill $pid; exit 1; fi
  echo "======== $label (pid $pid, port $port)"
  scenario "$port" | tr -d '\r' | tee "$OUT/$label.out"
  kill $pid; wait $pid 2>/dev/null
}

serve sake "$SAKE" --strict app.sake
serve ruby ruby app.rb

normalize() {
  sed -E -e 's/^([A-Za-z-]+):/\L\1:/' "$1" \
    | grep -v -E '^(date|server|connection|content-length):' \
    | sed -E -e 's/^(set-cookie: rack\.session=)[^;]*/\1.../' -e 's/127\.0\.0\.1:[0-9]+/127.0.0.1:PORT/'
}
echo "======== diff (sake vs ruby, normalized)"
if diff <(normalize "$OUT/sake.out") <(normalize "$OUT/ruby.out"); then echo "same responses"; fi
