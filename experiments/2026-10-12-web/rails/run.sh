#!/bin/bash
# Serves the blog (blog/, on the Sake framework in this directory) with WEBrick on 127.0.0.1 and a free port, walks
# the scenario with curl (index, new, create with a validation error, create, show, comment, edit, update, delete,
# a missing post), prints each raw response, then the server's log. The server started here is stopped here.
# The models, route helpers and templates are generated as the server starts (`generate` in
# config/application.sake); no generated file is on disk.
# The database is a fresh temporary directory (DATABASE_DIR), removed at the end.
set -u
cd "$(dirname "$0")/blog"
SAKE=../../../../bin/sake
OUT=$(mktemp -d)
export DATABASE_DIR="$OUT/db"
PID=""
cleanup() { [ -n "$PID" ] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null; rm -rf "$OUT"; }
trap cleanup EXIT

echo "######## bin/rails routes"
$SAKE --strict bin/rails.sake routes
echo "######## the generated source (bin/rails source, joined in by generate in config/application.sake)"
$SAKE --strict --dump=generated config/application.sake > "$OUT/generated.sake" || exit 1
echo "$(wc -l < "$OUT/generated.sake") lines (bin/sake --dump=generated config/application.sake)"

start_server() {
  $SAKE bin/server.sake 0 > "$OUT/server.out" 2>> "$OUT/server.log" &
  PID=$!
  port=""
  for _ in $(seq 1 300); do
    port=$(sed -n 's/^Listening on http:\/\/127.0.0.1:\([0-9]*\)$/\1/p' "$OUT/server.out")
    [ -n "$port" ] && break
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.1
  done
  if [ -z "$port" ]; then echo "server did not start"; cat "$OUT/server.out" "$OUT/server.log"; exit 1; fi
  echo "######## server pid $PID, port $port"
  base="http://127.0.0.1:$port"
}
stop_server() { kill "$PID"; wait "$PID" 2>/dev/null; PID=""; echo; echo "######## server stopped"; }
dump_db() {
  echo; echo "######## database ($1)"
  for f in "$DATABASE_DIR"/*.json; do echo "--- $(basename "$f")"; cat "$f"; done
}
jar="$OUT/cookies"
c=(curl -s -i --max-time 10 -c "$jar" -b "$jar")
req() { echo; echo "######## $1"; shift; "${c[@]}" "$@" | tr -d '\r'; }

start_server
req "GET / (root: posts#index, empty)"            "$base/"
req "GET /posts/new"                              "$base/posts/new"
req "POST /posts (invalid: short title, no body)" --data-urlencode "post[title]=Hi" --data-urlencode "post[body]=" "$base/posts"
req "POST /posts"                                 --data-urlencode "post[title]=Hello from Sake" --data-urlencode "post[body]=Types on <operations>, not on values." "$base/posts"
req "GET /posts/1 (the redirect; flash notice)"   "$base/posts/1"
req "POST /posts/1/comments"                      --data-urlencode "comment[commenter]=ko1" --data-urlencode "comment[body]=Rails-shaped & typed" "$base/posts/1/comments"
req "POST /posts/1/comments (invalid: empty)"     --data-urlencode "comment[commenter]=" --data-urlencode "comment[body]=" "$base/posts/1/comments"
req "GET /posts/1 (with the comment; flash alert)" "$base/posts/1"
dump_db "after the comment"
stop_server
start_server
echo "(a new server process: the records come back from the JSON files; the session store is in memory, so the cookie is new)"
req "GET /posts/1/edit"                           "$base/posts/1/edit"
req "PATCH /posts/1 (as POST _method=patch)"      --data-urlencode "_method=patch" --data-urlencode "post[title]=Hello again" --data-urlencode "post[body]=Edited." "$base/posts/1"
req "GET /posts (index; flash notice)"            "$base/posts"
req "DELETE /posts/1/comments/1"                  --data-urlencode "_method=delete" "$base/posts/1/comments/1"
req "DELETE /posts/1 (as POST _method=delete)"    --data-urlencode "_method=delete" "$base/posts/1"
req "GET /posts (empty again)"                    "$base/posts"
req "GET /posts/99 (RecordNotFound: 404)"         "$base/posts/99"
req "GET /nowhere (no route: 404)"                "$base/nowhere"

dump_db "at the end"
stop_server
echo; echo "######## server log (both runs)"
cat "$OUT/server.log"
