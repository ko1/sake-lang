# Sinatra in Sake: the todo demo (Track A, 2026-10-12)

- `app.sake`: a todo list on `sakelib/sinatra.sake`: a form (POST, 303 redirect), a 400 from `halt`, marking
  done, an ERB page with a layout (`views/`), a JSON endpoint, a session visit counter (cookie), a `not_found`
  page for an unknown id (`halt 404`) and for an unknown path. `app.rb`: the same app on the sinatra gem, line
  by line (67 lines each).
- `./run.sh`: starts each on 127.0.0.1 with a free port (WEBrick: `sakelib/webrick.sake` via
  `Rackup::Handler::WEBrick` for Sake, the webrick gem for Ruby), sends the same 9 curl requests with a cookie
  jar (GET /, POST /todos, POST /todos empty, POST /todos/2/done, GET /, GET /todos/2, GET /todos.json,
  GET /todos/99, GET /nowhere), prints the raw responses, stops each server, and diffs the two after removing
  Date, Server, Connection, Content-Length, the cookie value, the port and header case. `run.out` is a run:
  "same responses".
- The port, its test and the notes: `sakelib/sinatra.sake`, `sakelib/mustermann.sake`,
  `test/sakelib/sinatra.{sake,rb}`, `test/sakelib/mustermann.{sake,rb}`, `sakelib/notes/sinatra.md` (the design,
  API table, friction), `sakelib/notes/mustermann.md`.
