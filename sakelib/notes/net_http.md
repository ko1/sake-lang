# net_http (Ruby's net/http, client side)

`require "net_http"` → `sakelib/net_http.sake` (it requires `uri`). Test: `test/sakelib/net_http.{sake,rb}`
(identical output; the test also covers `open_uri`). Each test starts a small HTTP/1.1 server in a thread on
an ephemeral port (`TCPServer.new("127.0.0.1", 0)`) and runs the client against it; nothing printed depends
on the port or on timing. Ruby twin: ruby 4.0.2 (its net/http no longer supplies a default Content-Type).

Ruby's `Net::` names are kept, nested in `module Net` (since 2026-10-10; before namespaces nested they were flattened to `NetHTTP`, `NetHTTPResponse`, `NetHTTPGet`, ...):

| Ruby | Sake |
|---|---|
| `Net::HTTP` | `Net::HTTP` (a Struct type: `address`, `port`, `open_timeout`, `read_timeout`) |
| `Net::HTTPResponse` and its subclasses `Net::HTTPOK`, `Net::HTTPNotFound`, ... | one type `Net::HTTPResponse`; the `code` decides `success?` & co. and the class name `inspect` shows |
| `Net::HTTP::Get`, `Post`, `Head`, `Put`, `Delete`, `Patch` | one type `Net::HTTPRequest` (`method` is the verb); constructors `Net::HTTP::Get.new(path, initheader = nil)` & co. (modules with a `new` module function, nested in `class HTTP`) |
| `Net::HTTPHeader` (the mixin) | module `Net::HTTPHeader`, included by both types |
| `Net::HTTPBadResponse` | `Net::HTTPBadResponse` |
| `Net::HTTPError`, `HTTPRetriableError`, `HTTPClientException`, `HTTPFatalError` (from `res.value`) | `Net::HTTPError`, `Net::HTTPRetriableError`, `Net::HTTPClientException`, `Net::HTTPFatalError`, each with `response` |

Only `http://` works: Sake has no TLS. An `https` URI raises `ArgumentError` ("https is not supported: Sake
has no TLS"). Every request goes with `Connection: close` on a fresh connection, so `Net::HTTP.start { }` is a
scope and not a kept connection (Ruby keeps the socket alive inside the block).

## API

| Ruby | Sake | |
|---|---|---|
| `Net::HTTP.get(uri)` / `get(host, path, port)` | `Net::HTTP.get(uri)` / `Net::HTTP.get(host, path, port)` | same (the body String; nil for a response without one, such as 204, as Ruby) |
| `Net::HTTP.get(uri, headers)` | `Net::HTTP.get(uri, headers)` | same |
| `Net::HTTP.get_response(uri)` / `(host, path, port)` | `Net::HTTP.get_response(...)` | same |
| `Net::HTTP.get_print(uri)` | `Net::HTTP.get_print(uri)` | same |
| `Net::HTTP.post(uri, data, header = nil)` | `Net::HTTP.post(uri, data, header = nil)` | same |
| `Net::HTTP.post_form(uri, params)` | `Net::HTTP.post_form(uri, params)` | same |
| `Net::HTTP.start(host, port) { \|http\| }` | `Net::HTTP.start(host, port) { \|http\| }` | same (the block's value; `finish` afterwards) |
| `Net::HTTP.new(host, port = 80)` | `Net::HTTP.new(host, port = 80)` | same (`use_ssl`, proxies: missing) |
| `http.start` / `http.start { }` | `Net::HTTP.start(http)` / with a block | same (one function serves Ruby's two `start`s: a String or a Net::HTTP first) |
| `http.started?`, `active?`, `finish` | `Net::HTTP.started?(http)`, `active?`, `finish` | same (`finish` before `start` raises `IOError` as Ruby) |
| `http.address`, `port`, `open_timeout`, `read_timeout` (and `=`) | `Net::HTTP.address(http)`, ..., `Net::HTTP.set_open_timeout(http, s)` | differs: timeouts are stored, not enforced (no socket timeout built-in) |
| `http.request(req, body = nil)` / `{ \|res\| }` | `Net::HTTP.request(http, req, body = nil)` / block | same (the body is read before the block runs, as Ruby's default) |
| `http.get(path, header)` | `Net::HTTP.request_get(http, path, header)` | differs: name (`Net::HTTP.get` is Ruby's class method); Ruby has `request_get` too |
| `http.head(path)`, `http.request_head` | `Net::HTTP.head(http, path)`, `request_head` | same |
| `http.post(path, data, header)` | `Net::HTTP.request_post(http, path, data, header)` | differs: name (as `get`) |
| `http.put`, `request_put`, `patch`, `delete` | `Net::HTTP.put(http, path, data, header)`, ... | same (Ruby's `delete` default header `Depth: Infinity` is not sent) |
| `http.send_request(name, path, data, header)` | `Net::HTTP.send_request(http, name, path, data, header)` | same |
| `http.get(path) { \|chunk\| }` (streaming), `response.read_body { }` | — | missing: the body is always read whole |
| `Net::HTTP::Get.new(path, initheader)` (also with a URI) | `Net::HTTP::Get.new(path, initheader)` | same (a URI gives `request_uri` and `Host`; `""` raises Ruby's ArgumentError) |
| `req.method`, `req.path`, `req.body`, `req.body = s` | `Net::HTTPRequest.method(req)`, `path`, `body`, `set_body(req, s)` | same |
| `req["Name"]`, `req["Name"] = v` (nil deletes) | `req["Name"]`, `req["Name"] = v` | same (`include Indexable`; names are case-insensitive) |
| `req.add_field`, `get_fields`, `key?`, `delete`, `each_header`, `each_name`, `to_hash` | `Net::HTTPRequest.add_field(req, k, v)`, ... | same (`delete` gives the Array of values, as Ruby) |
| `req.content_type`, `req.content_type = t`, `req.content_length` | `Net::HTTPRequest.content_type(req)`, `set_content_type`, `content_length` | same |
| `req.set_form_data(params, sep = "&")` | `Net::HTTPRequest.set_form_data(req, params, sep)` | same |
| `req.basic_auth(user, pass)` | `Net::HTTPRequest.basic_auth(req, user, pass)` | same (`proxy_basic_auth`: missing) |
| `req.request_body_permitted?`, `response_body_permitted?` | same names | same |
| `p req` → `#<Net::HTTP::Get GET>` | `p(req)` | same |
| default request headers | `Accept: */*`, `User-Agent: Ruby`, `Host` | differs: `Accept-Encoding: identity` instead of Ruby's `gzip;q=1.0,deflate;...` (no inflate here) |
| `res.code`, `res.message` / `msg`, `res.http_version`, `res.body` | `Net::HTTPResponse.code(res)`, ... | same (`code` is a String; `body` is nil for HEAD, 1xx, 204, 304) |
| `res["Name"]`, `res.header`-style lookup | `res["Name"]`, `Net::HTTPResponse.header(res, "Name")` | same (several fields of one name joined with ", ") |
| `res.get_fields`, `key?`, `each_header`, `each_name`, `to_hash`, `content_type`, `content_length` | same names | same |
| `res.is_a?(Net::HTTPSuccess)`, `HTTPRedirection`, `HTTPClientError`, `HTTPServerError`, `HTTPInformation` | `Net::HTTPResponse.success?(res)`, `redirection?`, `client_error?`, `server_error?`, `informational?` | differs: predicates instead of classes |
| `res.value`, `res.error!` | `Net::HTTPResponse.value(res)`, `error!` | same (message `404 "Not Found"`; the exception type follows the class of the code) |
| `res.read_body`, `res.entity` | same names | same (already read) |
| `p res` → `#<Net::HTTPOK 200 OK readbody=true>` | `p(res)` | same for the common codes (a table of 30 codes; others give the class of their hundreds) |
| `res.body_encoding`, `res.decode_content`, `res.uri` | — | missing |
| `Net::HTTPResponse.read_new(sock)` (the parser) | `Net::HTTP._read_response(sock, method)` | internal; status line, headers with continuation lines, `Content-Length`, chunked (extensions and trailers), or until EOF |

69 operations ported (13 header operations shared by requests and responses, 16 on requests with 6
constructors, 16 on responses, 24 on Net::HTTP).

## How it works, and what differs

- **One connection per request.** `Net::HTTP.request` connects (`Socket.connect`), writes the head and
  body, `Socket.close_write`, reads the response, `Socket.close`. `start` only marks the session, as a scope
  for `finish`. Ruby's keep-alive, retries of idempotent requests, and `keep_alive_timeout` have no
  counterpart. The test server answers `Connection: close` to every request so that Ruby's client behaves
  the same way.
- **Response body.** Read whole, as Ruby's default (`res.body`). Chunked: size lines may carry extensions,
  trailers are read up to the empty line, as Ruby's `read_chunked`. Without `Content-Length` or chunking the
  body runs to EOF. `Socket.read(s, n)` is called until n bytes arrived (the built-in may stop short).
- **Content-Encoding.** Ruby inflates gzip/deflate bodies and deletes the field; for `identity`/`none` it
  only deletes the field. Sake does the latter; a compressed body stays compressed and keeps its field (the
  request says `Accept-Encoding: identity` so a conforming server does not compress). `sakelib/zlib.sake`
  has no inflate.
- **Encoding of the body.** Bytes from the socket, as Ruby's (`ASCII-8BIT`): `String.force_encoding(body,
  "UTF-8")` to read it as text. `open_uri` does this from the charset.
- **Errors.** A refused connection or a reset is `IOError` (Sake's socket errors), where Ruby raises
  `Errno::ECONNREFUSED` & co.; the test prints a fixed word for both. A malformed status line or header is
  `Net::HTTPBadResponse`.
- **Timeouts** are fields only. Sake's `Socket` has no `open_timeout`/`read_timeout`.
- **No `https`, no proxies** (`ENV["http_proxy"]` is not read; Sake has no ENV built-in anyway), no
  `use_ssl`, no streaming (`read_body { }`), no `Net::HTTP.version_1_2`-style switches.

## Built-ins Sake lacks (requests)

- **Socket timeouts** (`Socket.connect(host, port, timeout)`, `Socket.read_timeout=`): without them a
  stalled server hangs the program; Ruby's `open_timeout`/`read_timeout` cannot be honoured.
- **TLS** (`Socket.connect` with `ssl: true`, or an `SSLSocket`): https is most of today's web; the port
  stops at `http://`.
- **`Zlib.inflate` / gunzip** as a built-in (zlib.sake has crc32/adler32 only): needed to accept
  `Content-Encoding: gzip` as Ruby does.
- `Time.httpdate` / `Time.parse` (`Last-Modified`, `Date`): open_uri's `last_modified` returns the String.
- `ENV` (for `http_proxy` / `no_proxy`).

## Friction

- Wrote `Array.join(status, " ")` where `status` was a Tuple `[code, message]` → `TypeError: Array.join:
  argument 1 must be Array, got String` *at run time*, under `--strict` → the String was my own mistake
  (`OpenURI::Meta.new` takes the fields in declaration order, and I had put `status` before `body`), but the
  checker reported nothing before running; see `open_uri_bug_while_body_after_type_error.sake`. The fix
  that stayed: `"#{code} #{msg}"`; a Tuple has no `join`, and `Tuple.to_a` first reads worse.
- Wrote `raise X if max in Integer && Set.size(seen) > max` → no message; the raise fired on the first
  redirect → Prism (Ruby's grammar) parses it as `(raise X if max in Integer) && (Set.size(seen) > max)`:
  `in` is a statement-level operator, so the `&&` applied to the whole `if` statement. Wrote `(max in
  Integer) && ...`. Ruby does the same, but the dead right operand could be a Sake warning (and
  `p((x in Integer && y))` is a syntax error, so the shape is never what one meant).
- Two `start`s in Ruby (class and instance) are one function here, `start(host_or_http, port = nil)`, with
  `case ... in Net::HTTP` / `in String`. Fine, but `@address` cannot be used in it (the first argument is not
  always a Net::HTTP), so the body calls `Net::HTTP.started?(http)` and `http.Net::HTTP.started = true` instead.
- Ruby's `http.get(path)` cannot keep its name: `Net::HTTP.get` is the class method (there is one namespace
  for both). Ruby's `request_get`/`request_post` names took the instance forms.
- `Net::HTTP::Get.new(path)` has no home: `Net::HTTP::Get` is a nested class. A module `Net::HTTP::Get` with a
  `module_function def new(path, initheader = nil)` is accepted and reads as Ruby, with one line per verb.
- A test file `test/sakelib/net_http.sake` shadows `sakelib/net_http.sake` for every *other* file in
  `test/sakelib/` that writes `require "net_http"` (the loader special-cases only the self-require): a
  temporary repro placed there loaded the test program as the library and reported every definition twice.
- `Socket.read(s, 0)` gives `""` and `Socket.read` at EOF gives `nil`, so the reading loop must stop on
  both; `Socket.gets` gives `nil` at EOF, which `--strict` makes one check (`_read_line` raises
  `Net::HTTPBadResponse` for it, so callers see a String).
- What felt good: `include Net::HTTPHeader` in both types gave `[]`, `[]=`, `add_field`, `each_header` once,
  with `fields(h)` resolving to each type's private reader; `req["X-Token"] = "t"` reads as Ruby with
  `include Indexable`. The first draft ran under `--strict` after one real bug of mine.

## Later the same day (2026-10-09)

Zlib.inflate/deflate/gzip/gunzip and ENV.get/fetch are built in; socket timeouts and TLS are still missing.

## Later the same day, again (2026-10-09)

https works: `Net::HTTP.start(host, 443, true)` / a URI with scheme https connects with `Socket.connect_ssl` (TLS, peer verified); `open_timeout`/`read_timeout` are now applied to the socket (`Socket.connect(host, port, timeout)`, `Socket.set_timeout`). Checked by hand against https://example.com (200). The test still uses a local plain-http server.
