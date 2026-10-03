# webapp-native: the web app with Sake as the server (2026-10-03)

The `webapp` framework and its todo / URL-shortener apps, served by Sake itself instead of CGI.
Needs the threads and sockets of commit 2eee894 (branch `io`, merged into main at 7d8b842).

- `lib.sake`: `webapp/lib.sake` with three changes. `read_request(io)` reads from a Socket (or stdin
  when io is nil; a socket's body is read with `Socket.read(io, n)`). `respond(routes, io)` is one
  request cycle. `Web.serve(routes, port, workers)`: a `TCPServer`, accepted connections pushed to a
  `Queue`, `workers` threads popping them; the handlers run inside one `Mutex`, since the apps keep
  their state in files. `Web.run(routes)` (CGI) is kept.
- `client_todo.sake` (port 18441), `client_shorten.sake` (port 18442): `Web.run(routes)` →
  `Web.serve(routes, PORT, 4)`, nothing else changed.
- Run: `bin/sake --strict=3 client_todo.sake` (checked once, before serving). The clients start with
  `require "lib"` (since 2026-10-03; before, `build.sh` concatenated lib.sake and a client, and
  messages pointed into the joined file).
- `curl_session.txt`: the list page, a POST that redirects (303), a validation error, the JSON API,
  and a 404 for a missing id.
- `bench.sh URL N PARALLEL`, `bench.txt`: GET / repeated, CGI (`webapp/serve.rb`, which runs
  `bin/sake --strict=3` per request, one request at a time) against this server. Informal: the
  shared development machine (load average 7), not the benchmark machines, three rounds.

| | sequential, median | 4 in parallel, median |
|---|---|---|
| CGI | 273–353 ms | 1,070–1,089 ms |
| Sake server | 3 ms | 5–6 ms |

The CGI cost is starting Ruby, loading Sake, and checking the program on every request; the CGI
server also handles one request at a time. The Sake server pays these once.

Design notes: `yield` inside the worker threads reaches the block given to `Web.serve` (the
handlers), and each worker's `c` is its own (the variables of blocks around `Thread.new` are copied
when a thread starts). A worker survives a dropped connection by rescuing `IOError`.
