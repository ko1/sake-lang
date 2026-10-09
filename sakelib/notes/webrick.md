# webrick (WEBrick::HTTPServer subset)

`require "webrick"` → `sakelib/webrick.sake`. Test: `test/sakelib/webrick.{sake,rb}` (identical output; the Ruby
side is the real `webrick` 1.9.2 gem). Flattened names: `WEBrick::HTTPServer` → `HTTPServer`, `HTTPRequest`,
`HTTPResponse`, `HTTPStatus`, `HTTPUtils`, `HTMLUtils`; `WEBrick::HTTPStatus::NotFound` & co. → one exception type
`HTTPStatusError` with a `code`, made by `HTTPStatus.error(404, msg)`.

## API

| Ruby | Sake | |
|---|---|---|
| `HTTPServer.new(BindAddress:, Port:, Logger:, AccessLog:)` | `HTTPServer.new(host, port)` | differs: two positional fields; no logger/access log (nothing is printed); port 0 → `HTTPServer.port(srv)` is the one bound |
| `server.mount_proc(dir) { \|req, res\| }` | `HTTPServer.mount_proc(srv, dir, handler)` / `mount` | differs: `handler` is a value of a type that includes `HTTPHandler` and defines `call(h, req, res)` (below) |
| `server.mount(dir, Servlet, *opts)` | `HTTPServer.mount(srv, dir, handler)` | differs: a servlet instance, no class + options |
| `server.unmount(dir)` / `umount` | `HTTPServer.unmount(srv, dir)` / `umount` | same |
| `server.start` / `shutdown` / `stop` | `HTTPServer.start(srv)` / `shutdown` / `stop` | same (`start` blocks; run it in `Thread.new`; `shutdown` closes the listener, which ends `start`) |
| `server.status` | `HTTPServer.status(srv)` | same (`:Stop`, `:Running`, `:Shutdown`) |
| `server.listeners` / `config[:Port]` | `HTTPServer.listeners(srv)` / `HTTPServer.port(srv)` | same / differs (no config Hash) |
| mount table: longest prefix at a `/` boundary, `script_name` + `path_info` | same | same |
| ProcHandler: GET, HEAD, POST, PUT; other methods 405; OPTIONS → `Allow` | same | same (`HTTPHandler.allow?` hook, below) |
| keep-alive, chunked responses, HTTPS, `DocumentRoot` (FileHandler), CGI, auth, `Daemon`, `virtual_host`, `Logger`, `AccessLog` | — | missing: one request per connection, `Connection: close`; files/CGI/auth not ported (time) |
| `req.request_method`, `unparsed_uri`, `http_version`, `request_line`, `path`, `query_string`, `script_name`, `path_info` | `HTTPRequest.request_method(req)`, … | same (`http_version` is a String "1.1", Ruby's is an HTTPVersion) |
| `req.header` / `req["Name"]` / `req.each { \|k, v\| }` | `HTTPRequest.header(req)` / `req["Name"]` / `HTTPRequest.each(req)` | same (downcased name => Array of values; `[]` joins with ", " where Ruby joins with "") |
| `req.body` | `HTTPRequest.body(req)` | same (whole body by Content-Length, nil without; no chunked request bodies, no block form) |
| `req.query` | `HTTPRequest.query(req)` | differs: name => the first value as a String (Ruby: FormData with `list`); GET/HEAD from the query string, POST from a form body, else `{}`, as Ruby; multipart not parsed |
| `req.content_type`, `content_length`, `host`, `request_uri`, `peeraddr` | `HTTPRequest.content_type(req)`, … | same; `content_length` nil without the field (Ruby raises); `peeraddr` is nil (no built-in) |
| `req.keep_alive?`, `accept`, `cookies`, `user`, `addr`, `attributes`, `meta_vars` | — | missing |
| `res.status`, `res.status = c` (sets `reason_phrase`) | `HTTPResponse.status(res)`, `HTTPResponse.set_status(res, c)` | same |
| `res["Name"]`, `res["Name"] = v`, `res.header`, `res.each` | `res["Name"]`, `res["Name"] = v`, `HTTPResponse.header(res)`, `each` | same (one value per name, as Ruby) |
| `res.body = s`, `res.body` | `res.HTTPResponse.body = s`, `HTTPResponse.body(res)` | same (a String only; no IO bodies) |
| `res.content_type`, `content_type=`, `content_length`, `content_length=` | `content_type(res)`, `set_content_type(res, t)`, `content_length`, `set_content_length` | same |
| `res.cookies` (Array, one `Set-Cookie:` line each) | `HTTPResponse.cookies(res)` | same (an Array of String; Ruby's holds Cookie objects too) |
| `res.set_redirect(HTTPStatus::Found, url)` | `HTTPResponse.set_redirect(res, 302, url)` | differs: the status is an Integer; raises, as Ruby's; the Location is made absolute when sent, as Ruby's |
| `res.set_error(ex)` | `HTTPResponse.set_error(res, code, message)` | differs: Ruby's HTML page; the `<ADDRESS>` says `WEBrick (Sake)` instead of version and address |
| `res.status_line`, `reason_phrase`, `http_version`, `sent_size` | same names | same (`sent_size` stays 0) |
| `res.chunked=`, `keep_alive`, `upgrade!`, `setup_header`, `send_response` | — | missing (internal or unsupported) |
| `raise HTTPStatus::NotFound, "msg"` in a handler → that status | `raise HTTPStatus.error(404, "msg")` | differs: one type with a code; `HTTPStatus.error(code)` defaults the message to the reason phrase |
| `HTTPStatus.reason_phrase(c)`, `info?`, `success?`, `redirect?`, `error?`, `client_error?`, `server_error?` | same names | same (the same table as WEBrick 1.9.2) |
| `HTTPUtils.parse_query(s)` | `HTTPUtils.parse_query(s)` | same keys and first values (FormData → String) |
| `HTTPUtils.escape`, `unescape`, `escape_form`, `unescape_form`, `escape_path` | same names | same (the same unsafe sets; `escape_path` per `/segment`) |
| `HTTPUtils.mime_type(name, DefaultMimeTypes)` | `HTTPUtils.mime_type(name)` | differs: a built-in table of 15 common types, no table argument / `load_mime_types` |
| `HTMLUtils.escape(s)` | `HTMLUtils.escape(s)` | same (`& < > "` only) |
| `HTTPUtils.parse_header`, `parse_range_header`, `dequote`, `split_header_value`, `FormData` | — | missing |

~70 operations ported (HTTPServer 12, HTTPRequest 16, HTTPResponse 20, HTTPStatus 8, HTTPUtils 8, HTMLUtils 1,
HTTPHandler 2).

## できたこと / できなかったこと

- **Handlers are types.** `mount_proc(dir) { |req, res| ... }` stores a block; Sake keeps no blocks (§7). The port's
  `HTTPHandler` is a module with the required `call(h, req, res)` (a body of `raise NotImplementedError`), and a
  handler is a value of a type that includes it; the server runs `HTTPHandler.call(handler, req, res)`, which
  dispatches on the handler's type (§5.6). What the block closed over becomes the type's fields
  (`Hello.new("Hi")`, `Redirector.new("/hello")`). The mount table is a plain `Hash` of path => handler holding
  values of several types; the dispatch checks that each includes `HTTPHandler`.
- **Ruby's method table through a module default.** WEBrick's ProcHandler answers only `do_GET/POST/PUT` (+HEAD),
  and 405s the rest; a servlet class answers whatever `do_X` it defines. That is a per-type method set, expressed
  here as a hook with a default: `HTTPHandler.allow?(h, method)` is defined in the module (GET/HEAD/POST/PUT), and a
  type that answers everything (the rackup adapter, a test servlet) defines its own `def allow?(h, m) = true`, which
  wins, as `state_machine.sake`'s `aasm_guard` does. The comparison with the real gem found this: the first
  httparty twin got `405 unsupported method 'PATCH'` from WEBrick's `mount_proc`.
- **One request per connection, in a thread.** `start` loops on `TCPServer.accept` and starts a `Thread` per
  connection (`_serve`: parse, dispatch, send, close). No keep-alive, no chunked encoding, no HTTPS listener
  (`Socket.connect_ssl` is a client built-in only): kept small, as the brief asked.
- **Shutdown** closes the listening socket from another thread; `accept` then raises `IOError`, caught in `_accept`,
  and `start` returns, setting `status` back to `:Stop` as WEBrick does. `status` is written under a `Mutex`.
- **Errors in a handler** → 500 with WEBrick's HTML page; `HTTPStatusError` → its code (a redirect code keeps the
  handler's body, an error code gets the page), as WEBrick's `HTTPServer#run` does.
- **Not ported:** FileHandler/DocumentRoot, CGI, basic/digest auth, access logs, HTTPS, keep-alive, request bodies
  without Content-Length, `req.cookies`/`accept*`, `HTTPUtils::FormData` (multiple values; Sake gives the first).
  `peeraddr` is nil: Sake has no `Socket.peeraddr`.

## 書き心地

- **An interpreter crash from a Regexp literal.** WEBrick's unsafe-byte classes are `/[...\x7f-\xff]/n`. Wrote
  `_escape(s, /[\x00-\x20\x7f-\xff<>#%"{}|\\^\[\]`]/n)` → `warning: type checks skipped (internal error in the type
  checker: RegexpError: invalid multibyte escape ...)` and then a Ruby backtrace from `lib/sake/lower.rb:102`: the
  lowering rebuilds the literal without its `n` flag. Repro: `notes/webrick_bug_regexp_n_flag.sake`. Wrote
  `/[\x00-\x20\x7f<>#%"{}|\\^\[\]`]|[^\x00-\x7f]/` on a `String.b` copy instead (one byte per match, `String.ord`).
- **A write to a reader field from the server.** Wrote `req.HTTPRequest.script_name = dir` in `HTTPServer.service`
  (the field is `attr_reader`). Rather than widen it to `attr_accessor` for everyone, moved the write into
  `HTTPRequest._route(req, dir)`, where `@script_name = ...` is allowed: the type keeps its fields read-only outside
  and the server calls one named operation. Ruby's WEBrick sets `req.script_name=` from outside; the Sake rule
  made the boundary explicit, which read well.
- **Thread-local by construction.** `loop { c = accept; Thread.new { serve(c) } }` would share `c` between the loop
  and the thread (a function's locals are shared; §15 "Variables in a thread"), so the next accept could overwrite it
  before the thread reads it. Wrote `def _spawn(srv, c) = Thread.new { _serve(srv, c) }`: a parameter per call,
  no race. The rule is easy to meet once known, but nothing warns; worth a line in the tutorial.
- **`rescue` as an expression.** Wanted `c = begin TCPServer.accept(@sock) rescue IOError nil end`; wrote a
  function `_accept(srv)` with a `def`-level `rescue IOError` returning nil instead, which reads better anyway.
- **Ternary with an assignment** `vs ? Array.push(vs, x) : header[last] = String[x]` parses badly in Ruby too; wrote
  `if`/`else`. Not a Sake matter.
- **`--strict` passed on the first full run** (after the Regexp crash): the nil checks on `Socket.gets`, `m[1]`,
  `header[last]` were already written with `|| ""` / `if vs` because the API makes the nil visible
  (`String.chomp(l)` on a `String | nil` is rejected at once). `def initialize(req)` with `@script_name = "" if
  @script_name == nil` for trailing fields left out of `HTTPRequest.new(...)` worked as documented.
- **What read as well as Ruby:** `res["Content-Type"] = "text/plain"` (`include Indexable`), `HTTPStatus.error(404,
  "...")` raised and caught by the server, and the handler types: `class Hello; attr_reader greeting; include
  HTTPHandler; def call(h, req, res) ...` is as short as the block, and the test's `Created.new(201)` /
  `Created.new(204)` is the Ruby lambda-returning-lambda (`created.(201)`) without the lambda.
- **What the comparison found in the gem:** WEBrick 1.9.2 quotes paths as `'/missing' not found.` (older notes
  show backticks), its `HTMLUtils.escape` leaves `'` alone, `escape_form` does not escape the space (it becomes `+`
  afterwards), `escape_path` drops text before the first `/`, and a relative `Location` is made absolute against the
  request URI; each was matched after a diff.

## Built-ins requested

- **Regexp literals with `/n`** (and `\x80-\xff` ranges): the lowering drops the flag and the interpreter dies; a
  byte-class on a binary String is the natural way to write an escaper.
- `Socket.peeraddr(s)` (or `Socket.remote_address`): `req.peeraddr` and Rack's `REMOTE_ADDR` cannot be filled.
- `TCPServer.accept` with a timeout, or `IO.select`: a shutdown that does not rely on closing the socket under a
  blocked `accept` (works, but raises `IOError` in the server thread by design).
- `Thread.new` with explicit arguments (`Thread.new(c) { |c| ... }`, as Ruby's): the "a function's locals are shared"
  rule needs a helper function today.
- `Socket.read_nonblock` / `readpartial` with a timeout for slow clients (now a client can hold a thread forever).
