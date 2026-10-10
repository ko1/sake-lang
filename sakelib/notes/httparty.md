# httparty (HTTParty.get/post & co., Response, the class DSL)

`require "httparty"` → `sakelib/httparty.sake`, over `net_http.sake`, `uri.sake`, `json.sake`. The gem is not
installed here, so `test/sakelib/ref/httparty.rb` is a plain-Ruby reference (Net::HTTP) of the same API, and
`test/sakelib/httparty.rb` requires it; both sides serve the test API with WEBrick (Ruby: a servlet; Sake: the
`webrick.sake` port). `HTTParty::Response` and `HTTParty::RedirectionTooDeep` are nested in the module, as the gem's (since 2026-10-10; they
were `HTTPartyResponse` / `HTTPartyRedirectionTooDeep`); the class-level DSL (`include HTTParty; base_uri ...`) → a `HTTPartyClient` value.

## API

| Ruby | Sake | |
|---|---|---|
| `HTTParty.get(url, query:, headers:, basic_auth:, timeout:, follow_redirects:)` | `HTTParty.get(url, query:, headers:, basic_auth:, timeout: 60, follow_redirects: true)` | same (`url` a String or URI; `query` appended to the URL; `basic_auth: Hash[username:, password:]`) |
| `HTTParty.post(url, body:, ...)`, `put`, `patch`, `delete`, `head`, `options` | same names | same: a Hash body is form-encoded (`HashConversions.to_params`, `a[b]=1&c[]=2`) with `application/x-www-form-urlencoded`; a String body as given (JSON: set `headers: Hash["Content-Type" => "application/json"]`) |
| redirects: followed (limit 5), 303 and 301/302 after POST → GET | same | same; `HTTParty::RedirectionTooDeep` past the limit (`follow_redirects: false` returns the 3xx) |
| `HTTParty::HashConversions.to_params(h)`, `normalize_param(k, v)` | `HTTParty.to_params(h)`, `normalize_param(k, v)` | same |
| `response.code` (Integer), `body`, `headers`, `message`, `request_uri`, `response` (the Net::HTTPResponse) | `HTTParty::Response.code(r)`, `body`, `headers`, `message`, `request_uri`, `response` (a Net::HTTPResponse) | same (`headers` is a Hash of downcased name => values joined with ", "; HTTParty's is a `Headers` object with the same `[]`) |
| `response.parsed_response` | `HTTParty::Response.parsed_response(r)` | same for JSON (`application/json`, `text/json`, `+json`, `application/x-javascript`) and plain text (the String); differs: XML, CSV, HTML parsers not ported (would need rexml/csv) |
| `response["key"]` | `r["key"]` | same (a Hash/Array index into the parsed JSON, a String index into a text body: `(Hash\|Array\|String).[]`) |
| `success?`, `ok?`, `redirection?`, `client_error?`, `server_error?`, `not_found?`, `unauthorized?`, `forbidden?`, `bad_request?`, `nil?` | same names | same (`nil?` is the gem's: no body) |
| `content_type`, `content_length`, `headers["name"]` / `response.header(name)` | `content_type(r)`, `content_length(r)`, `header(r, name)` | same |
| `to_s` (the body), `inspect` | same | same shape (`inspect` without the object address) |
| `class API; include HTTParty; base_uri "..."; headers "X" => "y"; default_params k: v; basic_auth u, p; format :json; end` then `API.get("/path")` | `api = HTTPartyClient.new(base, Hash["X" => "y"], Hash["k" => "v"])`, `HTTPartyClient.get(api, "/path", query:, headers:)`, `post(... body:)`, … | differs: the class macros become fields of a value (see below); `format` is not needed (the content type decides); `debug_output`, `logger`, `pem`, `ssl_*`, `digest_auth`, `cookies`, `maintain_method_across_redirects`, `parser`, `connection_adapter` missing |
| `HTTParty.get(url) { \|chunk\| }` (streaming), `stream_body`, `multipart` bodies, `HTTParty::Parser` subclasses, `HTTParty::Error` classes, `response.request` | — | missing |

~35 operations ported (HTTParty 10, HTTParty::Response 19, HTTPartyClient 8).

## できたこと / できなかったこと

- **Module functions with keywords** carry HTTParty's option Hash: `get(url, query: nil, headers: nil, basic_auth:
  nil, timeout: 60, follow_redirects: true)`. A misspelled option (`querry:`) is a static error; in the gem it is
  silently ignored.
- **The class DSL** (`include HTTParty` + `base_uri`, `headers`, `default_params`, `basic_auth` as class macros that
  store per-class state) has no Sake shape: no class state, no `include` with side effects. It became
  `HTTPartyClient`, a value with those fields; `HTTPartyClient.get(client, path, ...)` merges the defaults and calls
  `HTTParty.get`. "include HTTParty" → "hold a client" is the honest translation (the gem's class is a singleton
  client anyway).
- **Response** parses JSON once in `initialize` into `parsed_response`; everything else is Ruby's. `response["key"]`
  works through `include Indexable` and `(Hash|Array|String).[](parsed, k)` (§5.7), which also lets a text body be
  indexed by position, as the gem's `String#[]` does.
- **Not ported:** XML/CSV parsing, streaming (`get(url) { |chunk| }` is a block kept across reads), multipart,
  digest auth, cookies jar, `HTTParty::Logger`, `connection_adapter` (a class passed as a value), SSL options beyond
  `https://` (net_http.sake verifies the peer and has no `verify: false`).

## 書き心地

- **The twin exposed a WEBrick fact, not a Sake one.** The first Ruby twin served the API with `mount_proc`, and
  `HTTParty.patch`/`delete` came back `405 unsupported method 'PATCH'` (ProcHandler only answers `do_GET`, `do_POST`,
  `do_PUT`, HEAD); the Sake webrick port had answered everything. Fixed on both sides: the Ruby test mounts a servlet
  with `def service(req, res)`, and `webrick.sake` got the `HTTPHandler.allow?(h, method)` hook (default
  GET/HEAD/POST/PUT, `def allow?(h, m) = true` in the test's `Api` type). The default-in-module, override-in-type
  pattern (as `state_machine.sake`'s `aasm_guard`) read well: one line in the type says "this servlet answers
  everything".
- **`(Hash|Array|String).[](pr, k)`** for `response["key"]`: the gem relies on duck typing (`parsed_response[k]`
  whatever it is). Writing the three types on the operation was the only change, and the checker then reports a
  `r[0]` on a response whose parsed value could be nil (a 204) — which is right, since `nil["x"]` is Ruby's
  NoMethodError. The test guards with a JSON content type.
- **`basic_auth => Hash` then `basic_auth[:username]`**: the keyword's value is a Hash of Symbol keys as the gem's;
  the assertion documents the shape where it is used, and a Record `{username:, password:}` would have worked with a
  pattern instead. Kept the Hash so the Ruby twin is the same literal.
- **The recursion in `_request`** (follow a redirect by calling `_request` again with `limit - 1`) and `(url in
  URI) ? URI.dup(url) : URI.parse(url)` typed without a report: the union of String | URI at the entry narrows at
  the `in`.
- **First `--strict` run passed** on the whole httparty file; the reference Ruby took longer to get right than the
  Sake port (WEBrick's 405, `Net::HTTPGenericRequest.new(method, has_body, response_has_body, path, headers)`).
- **Skipping an internal field in `new`.** Wrote `HTTParty::Response.new(code, body, hdrs, u, res, nil, message)`:
  the `nil` stands for `parsed_response`, which `initialize` computes. Then remembered §10.1: `new` takes a later
  field by keyword and the skipped one is nil for initialize, so it is `HTTParty::Response.new(code, body, hdrs, u,
  res, message: m)` now. Positional-then-keyword `new` is the right tool for "fields the constructor fills"; the
  first draft shows it is not the first thing one reaches for. HTTParty's `Response#inspect` shows an object address;
  dropped from the test (`p(r)` would be unrepeatable on both sides anyway).

## Built-ins requested

- `Time.httpdate`/`Time.rfc2822` parsing and formatting (cookie `expires`, `Date` headers): written with
  `strftime` in rack.sake, no parser for the other direction.
- `String.unpack1(s, "m")` is there; a `Base64` module is in sakelib already. Nothing else was missing for the
  client; what is missing is in net_http (no `verify_mode`, no streaming body).
- (Language) nothing further: `T.new(..., message: m)` already skips an internal field (see 書き心地).
