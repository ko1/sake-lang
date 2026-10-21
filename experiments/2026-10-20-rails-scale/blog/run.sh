#!/bin/bash
# The Sake blog: a fresh database (bin/rails db:schema:load db:seed), `bin/rails server` (WEBrick) on 127.0.0.1 and
# a free port, ../walk.sh, the server stopped. SAKE=path/to/bin/sake to use another interpreter.
cd "$(dirname "$0")"
sake=${SAKE:-../../../bin/sake}
port=$(ruby -rsocket -e 's = TCPServer.new("127.0.0.1", 0); puts s.addr[1]; s.close')
mkdir -p log storage   # not in git: a fresh checkout has neither
rm -f storage/development.sqlite3 log/development.log
$sake --strict bin/rails.sake db:schema:load 2> log/db.err
$sake --strict bin/rails.sake db:seed 2>> log/db.err
$sake --strict bin/rails.sake server -b 127.0.0.1 -p "$port" > log/server.out 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null' EXIT
# --strict checks the whole app before it serves (~1.5 min locally): wait up to 10 min
for i in $(seq 1 6000); do curl -s -o /dev/null "http://127.0.0.1:$port/up" && break; sleep 0.1; done
../walk.sh "http://127.0.0.1:$port"
