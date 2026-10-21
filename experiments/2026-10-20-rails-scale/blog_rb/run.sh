#!/bin/bash
# The Ruby twin: a fresh database, `bin/rails server` on 127.0.0.1 and a free port, walk.sh, the server stopped.
cd "$(dirname "$0")"
port=$(ruby -rsocket -e 's = TCPServer.new("127.0.0.1", 0); puts s.addr[1]; s.close')
rm -f storage/development.sqlite3 log/development.log
bin/rails db:schema:load db:seed > /dev/null
bin/rails server -b 127.0.0.1 -p "$port" > log/server.out 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null' EXIT
for i in $(seq 1 100); do curl -s -o /dev/null "http://127.0.0.1:$port/up" && break; sleep 0.1; done
../../../examples/apps/rails_blog/walk.sh "http://127.0.0.1:$port"
