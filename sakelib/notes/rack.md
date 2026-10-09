# rack (Rack 3: Utils, Request, Response, MockRequest) and rackup (Rackup::Handler::WEBrick)

`require "rack"` → `sakelib/rack.sake`; `require "rackup"` → `sakelib/rackup.sake` (requires rack and webrick).
Test: `test/sakelib/rack.{sake,rb}` (identical output; the Ruby side is the real `rack` 3.2.6 and `rackup` 2.3.1,
with WEBrick as the server). Flattened names: `Rack::Utils` → `RackUtils`, `Rack::Request` → `RackRequest`,
`Rack::Response` → `RackResponse`, `Rack::MockRequest` → `RackMockRequest`, `Rack::QueryParser::ParameterTypeError`
→ `RackParameterTypeError`, `ParamsTooDeepError` → `RackParamsTooDeepError`, `Rackup::Handler::WEBrick` →
`RackupHandlerWEBrick`.

## The app shape

A Rack app is anything with `call(env)`, usually a lambda; middleware is a class holding the next app. Sake has no
stored blocks and no dispatch on a value, so:

```ruby
module RackApp                                   # in rack.sake
  def call(app, env) = raise(NotImplementedError)  # required: every app type defines it
end

class Hello                                      # the app: Ruby's ->(env) { [200, {...}, ["hello"]] }
  include RackApp
  def call(app, env) = [200, Hash["content-type" => "text/plain"], String["hello"]]
end

class Counter                                    # middleware: Ruby's `use Counter`
  attr_reader app
  attr_accessor count
  include RackApp
  def initialize(mw) = @count = 0
  def call(mw, env)
    @count += 1
    status, headers, body = RackApp.call(@app, env)   # dispatches to the next app's type
    headers["x-count"] = Integer.to_s(@count)
    [status, headers, body]
  end
end

app = Counter.new(Hello.new)                     # Rack::Builder: use Counter; run Hello.new
status, headers, body = RackApp.call(app, RackMockRequest.env_for("/"))
```

The triple is a Tuple `[Integer, Hash, Array]`; `RackResponse.finish` returns one. The env is a `Hash` of
`String => String`: the CGI keys, `HTTP_*`, `rack.url_scheme`, `HTTPS`, and `rack.input` as the body **String**
(Rack: an IO). Rack also stores parsed Hashes in the env (`rack.request.query_hash`) and a `StringIO` in
`rack.errors`; here those are not in the env (see 書き心地), so every env value is a String.

## API

| Ruby | Sake | |
|---|---|---|
| `Rack::Utils.parse_query(qs, sep)` | `RackUtils.parse_query(qs, sep = nil)` | same (repeated key → Array, bare key → nil) |
| `parse_nested_query(qs, sep)` | `RackUtils.parse_nested_query(qs, sep = nil)` | same for `a[b]`, `a[]`, `a[b][c]`, `a[][b]`, `q[`; `ParameterTypeError` / `ParamsTooDeepError` (depth 32) with Rack's messages; `params_hash_has_key?`'s nested lookup simplified |
| `build_query(h)`, `build_nested_query(v, prefix)` | same names | same |
| `escape`, `unescape(s, enc)`, `escape_path`, `unescape_path` | same names | same |
| `status_code(:not_found)` / `(404)` | `RackUtils.status_code(x)` | same (also a numeric String; obsolete symbols not mapped) |
| `HTTP_STATUS_CODES`, `SYMBOL_TO_STATUS_CODE` | `RackUtils.http_status_codes`, `symbol_to_status_code` | differs: functions (Sake has no value constants); same 62 codes as Rack 3.2.6 |
| `parse_cookies_header(s)`, `parse_cookies(env)` | same names | same |
| `set_cookie_header(key, value)` | `RackUtils.set_cookie_header(key, value)` | same: a String, an Array, or a `Hash[value:, domain:, path:, max_age:, expires: Time, secure:, httponly:/http_only:, same_site:, partitioned:]` |
| `delete_set_cookie_header(key, value)`, `set_cookie_header!`, `delete_set_cookie_header!` | same names | same |
| `clean_path_info`, `valid_path?`, `bytesize`, `q_values`, `best_q_match` | same names | same |
| `secure_compare(a, b)` | `RackUtils.secure_compare(a, b)` | differs: `a == b`, not constant time |
| `get_byte_ranges`, `select_best_encoding`, `rfc2822`, `add_cookie_to_header`, `Context`, `HeaderHash` | — | missing |
| `Rack::Request.new(env)` | `RackRequest.new(env)` | same |
| `req.get_header`, `has_header?`, `set_header`, `delete_header`, `fetch_header` | same names | same (`fetch_header` without the block) |
| `request_method`, `script_name`, `path_info`, `query_string`, `path`, `fullpath`, `content_length`, `user_agent`, `referer`, `ip` | same names | same (`ip` is `REMOTE_ADDR` only, no X-Forwarded-For) |
| `scheme`, `ssl?`, `authority`, `host`, `hostname`, `port`, `host_with_port`, `base_url`, `url` | same names | same (IPv6 `[::1]:3000` too); `port` is an Integer also in the SERVER_PORT fallback (Rack: a String there) |
| `content_type`, `media_type`, `media_type_params`, `content_charset`, `form_data?`, `parseable_data?` | same names | same |
| `get?`, `post?`, `put?`, `patch?`, `delete?`, `head?`, `options?`, `link?`, `unlink?`, `trace?`, `xhr?` | same names | same |
| `GET`, `POST`, `params`, `cookies` | `RackRequest.GET(req)`, `POST`, `params`, `cookies` | same (cached in fields, not in the env); multipart bodies not parsed |
| `body` (an IO: `req.body.read`) | `RackRequest.body(req)` | differs: the String itself (readable any number of times; Rack 3's input is read once by `POST`) |
| `accept_encoding`, `accept_language` | same names | same |
| `session`, `logger`, `update_param`, `delete_param`, `[]`, `trusted_proxy?`, `forwarded_for`, `multipart` | — | missing |
| `Rack::Response.new(body = nil, status = 200, headers = {})` | `RackResponse.new(body, status, headers)` | same (positional; a String, an Array of String, or nil body; header names downcased) |
| `status`, `status=`, `body`, `headers` | `RackResponse.status(res)`, `res.RackResponse.status = c`, … | same (`headers` is a plain Hash; Rack 3: a `Rack::Headers`) |
| `write(chunk)`, `finish` / `to_a`, `each`, `redirect(target, status)` | same names | same (Content-Length at `finish` when known; 204/304/1xx drop body and content headers) |
| `set_cookie`, `delete_cookie`, `set_cookie_header`, `add_header`, `get_header`, `set_header`, `has_header?`, `include?`, `delete_header` | same names | same |
| `content_type`, `content_type=`, `media_type`, `content_length`, `location`, `location=`, `cache_control(=)`, `etag(=)`, `do_not_cache!` | `content_type`, `set_content_type`, … | differs: setters are `set_x` |
| `ok?`, `successful?`, `redirection?`, `client_error?`, `server_error?`, `invalid?`, `informational?`, `not_found?`, … (18 predicates), `redirect?` | same names | same |
| `cache!`, `close`, `finish { }`, `Rack::Response::Raw` | — | missing |
| `Rack::MockRequest.env_for(uri, method:, input:, params:, script_name:, "HTTP_X" => v)` | `RackMockRequest.env_for(uri, method:, input:, params:, script_name:, http_version:, headers: Hash[...])` | differs: the String-keyed opts are one `headers:` Hash; `rack.errors`, `:fatal`, `:lint`, multipart params not ported |
| `Rack::MockRequest.new(app).get(uri, opts)` → MockResponse | `RackMockRequest.get(app, uri, params:, headers:)`, `post(... input:)`, `request(app, method, uri, ...)` | differs: returns the app's triple, no MockResponse |
| `Rackup::Handler::WEBrick` (servlet), `.run(app, Host:, Port:)` | `RackupHandlerWEBrick.new(app)` mounted on `HTTPServer`; `RackupHandlerWEBrick.run(app, host, port) { \|srv\| }` | same env keys (REQUEST_METHOD … HTTP_*, rack.input as a String); `REMOTE_ADDR` fixed to 127.0.0.1; repeated `set-cookie` as separate lines |
| `Rack::Builder`, `Rack::Lint`, `Rack::Static`, `Rack::Files`, `Rack::Session`, `Rack::URLMap`, `Rack::Multipart`, `Rack::Logger`, `Rack::CommonLogger`, `Rack::Head`, `Rack::ContentLength` | — | missing: Builder's `use`/`run` is the middleware chain written as `A.new(B.new(app))`; the others are time |

~140 operations ported (RackUtils 30, RackRequest 55, RackResponse 50, RackMockRequest 4, rackup 3).

## できたこと / できなかったこと

- **Apps and middleware** as types including `RackApp` (above). The middleware chain is explicit construction
  instead of `Rack::Builder`'s `use`. Could not be a lambda, and `Rack::Builder`'s block DSL (`use`, `run`, `map`)
  is a block storing other blocks: not ported.
- **Utils** are module functions: the whole query parser (`_normalize_params` with its Hash/Array/nil returns) ported
  line for line; `x[k] ||= Array[]` and `raise ... unless list in Array` narrowed as hoped.
- **Request** holds its caches (`query_hash`, `form_hash`, `cookie_hash`) as `private attr_accessor` fields instead
  of env keys (see below). `body` is the env's String.
- **Response**'s body is always an Array of String after `initialize`; `write` tracks the byte length as Rack does
  (Array body: length unknown until `write` buffers it, so `RackResponse.new(String["a"]).finish` has no
  Content-Length but `RackResponse.new("a")` has, exactly Rack 3's behaviour, confirmed by the twin).
- **Headers** are a plain Hash with downcased names; Rack 3's `Rack::Headers` (a Hash subclass that downcases on
  every access) cannot be a Hash subclass here, so `res.headers["Content-Type"]` finds nothing: the port downcases at
  `new` and the operations use lowercase names. Rack 3 code already uses lowercase.
- **rack.input as a String.** Rack's input is an IO read once by `POST`; the Ruby twin had to `rewind` after
  `params`, and under `Rackup::Handler::WEBrick` cannot rewind at all (`undefined method 'rewind' for
  Rackup::Handler::WEBrick::Input`), so the test splits `/form` (params) from `/raw` (body). In Sake both are
  always available. A streaming body would need an IO value (`StringIO`-like) readable from Sake.
- **MockRequest** returns the triple, not a `MockResponse`; `env_for`'s `params:` builds the query string (GET) or
  a form body (POST), as Rack's.

## 書き心地

- **The checker found a field-order mistake at the caller's line.** First draft:
  `class RackResponse; attr_accessor status, body, headers` (the order I think of them), and the test called
  `RackResponse.new(String["a", "bc"], 201, Hash[...])` (Rack's order: body, status, headers). Report before running:
  `rack.sake:558: Kernel.Integer: argument 1 must be String|Integer|Float, but is String[] [mixed] / hint: reached by
  the call at line 131` and `rack.sake:573: => Array: the value is Integer`. Fixed the declaration to
  `attr_accessor body, status, headers`. In Ruby this is a runtime `TypeError` on the first request; here it was
  found at the `new` call. The `[mixed]` label and the hint about Tuples were misleading, though (the Array was
  not the problem; the position was): the hint should say the field the argument landed in.
- **One type per Hash means: keep the env Strings.** Rack caches `GET`'s Hash in `env["rack.request.query_hash"]`
  and puts a `StringIO` in `env["rack.errors"]`. Writing that would make the env's value type
  `String | Hash | IO`, and every `String.start_with?(@env["HTTP_X"], ...)` a `type` report. So the caches became
  `private attr_accessor query_hash, form_hash, cookie_hash` of `RackRequest`. The result is a cleaner design than
  Rack's (the env is data, the request object has state), and the checker pushed toward it.
- **`String.start_with?(URI.path(u), "/")`** in `env_for` → `argument 1 may be nil (nil | String) [nil] / hint:
  URI.path may be nil (nil is stored at line 69)`. True (Ruby's `uri.path[0]` would also fail on nil for a weird
  URI); wrote `URI.path(u) || ""`. The hint chain naming the storing line in `uri.sake` was useful.
- **Constants → functions.** `Rack::Utils::HTTP_STATUS_CODES` is `RackUtils.http_status_codes` (a `once` Hash) and
  `SYMBOL_TO_STATUS_CODE` is derived from it with the same `gsub(/\s|-|'/, "_")`. Reads fine; the loss is the
  Ruby-side literal spelling in user code.
- **`RackUtils._add_value(cur, v)`** (nil → v, Array → push, else `Array[cur, v]`) replaced Rack's three
  `if header.is_a?(Array)` blocks; `case cur in nil ... in Array ... else` is exactly the shape and reads better than
  the gem.
- **Keyword parameters carried the API.** `env_for(uri, method:, input:, params:, script_name:, http_version:,
  headers:)` and `RackMockRequest.post(app, uri, input:, params:, headers:)` are Rack's option Hash as declared
  keywords; a misspelled option is a static error where Rack ignores it silently.
- **Writing a hook with `include` + `def`:** a middleware is `attr_reader app; include RackApp; def call(mw, env)`:
  three lines where Ruby has `def initialize(app) = @app = app` plus `def call(env)`. `RackApp.call(@app, env)`
  says which type's `call` runs only at run time, as Ruby's `@app.call` does, but the checker knows the finite set
  (every type including `RackApp`) and would reject a type that lacks `call`.
- **Friction:** `def set_header(res, key, v) = @headers[key] = v` is a syntax trap (the `=` form with an index
  assignment), so setters are two-line bodies. `attr_accessor` setters are reached as `res.RackResponse.status =
  404` and the gem's `content_type=` & co. became `set_content_type`, as the convention for strscan.
- **What the twin found in the gem:** `Rack::Utils.parse_http_accept_header` does not exist (it is a private
  `Request` method; `Utils.q_values` is the public one, and it keeps empty parts); `ParamsTooDeepError`'s message is
  its class name; `Response.new(["a"]).finish` has no Content-Length while `Response.new("a").finish` has one.

## Built-ins requested

- A **readable IO value** over a String (an in-memory IO that `IO.read`/`gets` accept, or `StringIO` as a built-in
  IO): `rack.input` could then be an IO as Rack's, and `IO.read(io)`/`gets` could serve both files and bodies.
- `Socket.peeraddr(s)`: `REMOTE_ADDR` is a constant 127.0.0.1 in the rackup adapter.
- `String.=~` / `Regexp.match?` against binary Strings is fine; a **`Hash.dig` with several keys** and
  `Hash.fetch(h, k) { default }` would shorten `Rack::Request#fetch_header`'s port.
- (Checker) when a `T.new(...)` argument lands in the wrong field, name the field in the hint instead of `[mixed]`
  and the Tuple advice (see 書き心地, first item).
