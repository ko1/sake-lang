# sinatra (Sinatra 4.2.1: Base, Request, Response, Helpers, erb templates) and mustermann (sinatra patterns)

`require "sinatra"` → `sakelib/sinatra.sake` (requires rack, rackup, erb, erubi, json, base64, digest, mustermann).
Test: `test/sakelib/sinatra.{sake,rb}`: one app with 28 routes, 3 filters and 3 error handlers, 35 requests through
`Rack::MockRequest`, 324 lines of output (status, every header sorted, body) identical to the real gem
(sinatra 4.2.1, mustermann 3.1.1, rack 3.2.6, rack-protection, rack-session). Templates in
`test/sakelib/sinatra_views/`, a static file in `test/sakelib/sinatra_public/`. The two programs are written line
by line in parallel (241 lines each). Demo: `experiments/2026-10-12-web/sinatra/` (a todo app served by
WEBrick, the same curl scenario against `app.sake` and the Ruby twin `app.rb`, same responses).
Patterns: `sakelib/mustermann.sake`, see `notes/mustermann.md`.

## The app shape: the class body becomes `routes(app)`, run again for every request

Ruby's Sinatra keeps each `get "/" do ... end` block in a class-level table and calls it later. Sake keeps no
blocks, so a stored-block design cannot be followed. What can be kept is the *text* of the app: the class body
becomes one function, and Sinatra calls it again for every request, once per phase. Each DSL call looks at the
phase and either does nothing or runs its block right away:

```ruby
# Ruby                                         # Sake
class App < Sinatra::Base                      class App < Sinatra::Base
                                                 def routes(app)
  enable :sessions                                 enable(app, :sessions)
  before do                                        before(app) do
    headers "x-before" => "yes"                      headers(app, Hash["x-before" => "yes"])
  end                                              end
  get "/hello/:name" do                            get(app, "/hello/:name") do
    "Hello, #{params["name"]}!"                      "Hello, #{params(app)["name"]}!"
  end                                              end
  not_found do                                     not_found(app) do
    "no route for #{request.path_info}"              "no route for #{Sinatra::Request.path_info(request(app))}"
  end                                              end
                                                 end
end                                            end
App.call(env)                                  Rack::App.call(App.new, env)
```

- `App.new` runs `routes(app)` in the **settings** phase (`set`, `enable`, `template`, `configure` act;
  Ruby: the class body at load time).
- `Rack::App.call(app, env)` is Ruby's `call(env) = dup.call!(env)`: `dup(app)` then `call!`, so the request's
  fields (`env`, `request`, `response`, `params`, a field the app declares such as `attr_accessor user`) belong to
  the copy, and the prototype stays clean (checked: `@user` set in a before filter, read in the route, nil on
  the prototype afterwards).
- `call!` runs the phases in Ruby's order: **before** (each matching `before` block), **route** (the first
  `get`/`post`/... whose verb and pattern match runs its block and raises `Sinatra::Halt` with the value, Ruby's
  `throw :halt`; the rest of `routes(app)` is not reached), **after**, and **error** when needed.
- `pass` raises `Sinatra::Pass`; the route that caught it restores `params` and returns, so the next `get`
  below it is tried, as Ruby's `catch(:pass)`.
- Error handlers (Ruby's `error_block!`): handlers for a key are tried last-defined first, and a nil result falls
  back to the one defined before it. With no table to walk backwards, `routes(app)` runs once to count the
  handlers that match, then once per handler, running only the n-th. Ruby's order and fallback hold.
- The phase is checked at the top of every DSL function; a request calls `routes(app)` 3 times
  (before, route, after) plus 2 or more in error cases, and each call is a few comparisons per route. Patterns are
  compiled once per pattern String (a `once` Hash).

`class App < Sinatra::Base` is Sake's copy (fields and functions), which here gives what Ruby's subclassing gives:
`get`, `params`, `halt`, ... are App's own functions, called bare inside `routes(app)`, and the copied `call!`
calls App's `routes`. `App` includes `Rack::App` through the copy, so `Rackup::Handler::WEBrick.new(App.new)`
serves it.

## API

| Ruby | Sake | |
|---|---|---|
| `class App < Sinatra::Base` + class body | `class App < Sinatra::Base` + `def routes(app)` | differs: the body is a function run per phase (above) |
| `App.call(env)` / `run App` | `Rack::App.call(App.new, env)` / `Rackup::Handler::WEBrick.new(App.new)` | same responses |
| `App.run!(bind:, port:, **options) { \|server\| }` | `App.run!(app, bind:, port:) { \|server\| }` | same: the keywords are `set` first, then `settings.bind`/`settings.port` are read (WEBrick only; port 0 → `WEBrick::HTTPServer.port(server)`) |
| `set :port, 8080`, `set :bind, "0.0.0.0"`, `settings.port`, `settings.bind` | `set(app, :port, 8080)`, …, `Settings.port(settings(app))` | same (bind's default is `localhost` in development, else `0.0.0.0`; port's is `ENV["PORT"]` or 4567) |
| `get/post/put/patch/delete/head/options/link/unlink(path) { }` | `get(app, path) { }` … | same (GET also answers HEAD; Rack::Head drops the body) |
| route options (`provides:`, `host_name:`, `user_agent:`, `condition`) | — | missing |
| `before(path = /.*/) { }`, `after` | `before(app, path = nil) { }`, `after` | same (filter params merged for the block, restored after) |
| patterns: `/:name`, `*`, `*name`, `{name}`, `(...)`, `?`, `(.:format)?`, Regexp | same (`mustermann.sake`) | same params; a Regexp route's `params["captures"]`; percent-encoded literals not matched |
| `params` (IndifferentHash) | `params(app)`: a Hash with String keys | differs: `params[:name]` (Symbol) is not found; values are `String \| Array \| Hash \| nil` |
| `request`, `response`, `env` | `request(app)` (a `Sinatra::Request`), `response(app)`, `env(app)` | same |
| `Sinatra::Request#accept`, `accept?`, `preferred_type`, `safe?`, `idempotent?`, `forwarded?`, `secure?` | `Sinatra::Request.accept(req)` … | same (`accept` gives Strings; Ruby: AcceptEntry) |
| `status(code)`, `body(value)`, `headers(hash)` | `status(app, code)`, `body(app, v)`, `headers(app, Hash[...])` | same |
| `halt`, `halt 404`, `halt "x"`, `halt 401, "x"`, `halt 418, {h}, "x"` | `halt(app, ...)` same forms | same |
| route value: String, Integer, `[status, body]`, `[status, headers, body]`, Array of String | same | same |
| `pass` | `pass(app)` | same (`pass { }` with a block: missing) |
| `redirect(uri, *args)`, `uri/url/to(addr, absolute, script_name)`, `back` | same names, `app` first | same (302 / 303 for non-GET HTTP/1.1, absolute Location) |
| `content_type(:json)`, `content_type("text/plain", charset: "x")`, `mime_type` | `content_type(app, :json)`, `content_type(app, t, Hash[charset: "x"])` | same (a table of 22 common types for Rack::Mime) |
| `error(code, body)`, `not_found(body)` (helpers) | `error(app, code, body)`, `not_found(app, body)` without a block | same |
| `error(*codes) { }`, `error(400..499)`, `error { \|e\| }`, `not_found { }` | `error(app, *codes) { \|e\| }`, `not_found(app) { }` | same order and fallback; `e` is nil for a status without an exception (as Ruby) |
| `error MyError do ... end` | — | missing: a class is not a value in Sake; write `error(app) { \|e\| case e in MyError ... }` (server errors) |
| `set :x, v`, `enable`, `disable`, `settings.x`, `configure(:env) { }` | `set(app, :x, v)`, `enable(app, ...)`, `settings(app)`, `configure(app, :production) { }` | Sinatra's own options are typed fields of `Sinatra::Settings` (`Sinatra::Settings.views(settings(app))`); any other name is `settings(app)[:x]` |
| `set :x, proc { }` (lazy settings), `set` with a Hash merging | — | missing (a stored block); `views`/`public_folder` follow `root` as Ruby's procs do |
| `development?`, `production?`, `test?` | same, `app` first | same (`APP_ENV`/`RACK_ENV`, default development) |
| `erb :name`, `erb "src"`, `locals:`, `layout: false / :name`, `views:` | `erb(app, :name, Hash[locals: Hash[...], layout: false])` | same output (Tilt's Erubi trimming, via `erubi.sake`); template code within Sake's ERB subset (`notes/erb.md`); locals only, no `@ivars`/helpers inside templates except `h`/`u` |
| `template :name do "src" end`, `layout do ... end` | `template(app, :name) { "src" }`, `layout(app) { }` | same (the block's String is kept) |
| `enable :sessions`, `session[...]` | same | differs: cookie `rack.session` = Base64(JSON) + "--" + HMAC-SHA256 hex (Rack: encrypted Marshal); values are JSON values |
| static files from `public_folder` | same (`send_file`: content-type, content-length, last-modified) | same; filters skipped as Ruby |
| `send_file(path, type:, disposition:, filename:)`, `attachment`, `cache_control` | same, options as a Hash | same (no Range requests, no `last_modified`/`etag`/`expires`) |
| Rack::Protection defaults | XSSHeader, FrameOptions (html only), PathTraversal | same headers; HttpOrigin, JsonCsrf, IPSpoofing, RemoteToken not ported |
| default 404 page `<h1>Not Found</h1>` + `x-cascade: pass`, 500 `<h1>Internal Server Error</h1>` | same | same (production); the development "doesn't know this ditty" page and ShowExceptions: missing |
| `helpers do ... end`, `helpers M` | functions in the app class | differs: write them as `def f(app, ...)` in the class |
| `use Middleware`, `register Extension`, `Sinatra::Application` (classic style), `stream`, `logger`, `IndifferentHash`, `inline_templates`, other template engines | — | missing |

~95 functions (Base 70, Request 7, Response 3, Settings 8, module 3).

## What could not be ported, and why

- **Stored blocks.** Every route, filter, error handler and lazy setting is a stored block in Ruby. Replaced by
  re-running the class body per phase (above). What is lost: route introspection (`App.routes`), adding routes
  at run time, `set :x, proc { }`, `pass { }`, `before`'s `**options`. What it costs: the DSL calls run on every
  request (cheap: a Symbol comparison each).
- **`error SomeClass do`**: a class is not a value. Server-error handlers get the exception and dispatch on it
  with `case e in MyError`. Ruby's lookup through the class's ancestors does not exist.
- **The middleware stack** (`use`, Rack::Builder, ExtendedRack, Rack::Session::Cookie, Rack::Protection as
  separate apps) is done inside `call!` in Ruby's order (session cookie, then Sinatra's finish, then the
  protection headers, then Rack::Head). A user `use` would need middleware as types (Rack's own app shape works:
  wrap `App.new` in a middleware type).
- **Templates see locals only.** Ruby templates run as methods of the app (`@todos`, any helper). Sake's ERB
  interprets a subset with a Hash of values, so pass values as `locals:`; `h()` is built in (Ruby needs
  `helpers ERB::Util`).
- **Sessions are JSON.** Rack's cookie is encrypted Marshal; no Marshal in Sake. JSON keeps the values' types to
  JSON's, so `session(app)["count"]` is a JSON value and the app says which (`n => Integer`).

## Built-ins Sake lacks (requests)

- ~~**`__dir__`** (and `__FILE__`)~~: added 2026-10-13; the test and the demo say `File.join(__dir__, "views")` as
  Ruby's (they said `File.dirname(Kernel.PROGRAM_NAME)`, right only when the app is the program).
- ~~**Binding names in patterns**~~ (`in [Integer => code, String => b]`): added 2026-10-13; `_halt_value` uses it.
- ~~**A rescue of a library's own control-flow exception**~~ in a program that never raises it was a level-1 error
  (`rescue Sinatra::Pass: the begin body never raises Sinatra::Pass`) when the app never calls `pass`; the port
  wrote a bare `rescue => e` + `raise e unless e in Pass`. Since 2026-10-13 that report is the item `unused-rescue`,
  a warning at every level (ko1: defensive rescues are written in apps too, not only in libraries), and `_route`
  says `rescue Pass` again. An app that never passes gets the warning, pointing into sinatra.sake, and runs.
- ~~`Rack::Response#[]` / `[]=`~~: added to rack.sake 2026-10-13 (the port still says `Response.get_header`).
- ~~HMAC~~: `OpenSSL::HMAC` (sakelib/openssl.sake) added 2026-10-13; the session cookie uses it (it had its own
  HMAC-SHA256).
- `Marshal` (for Rack-compatible session cookies) and AES (`Rack::Session::Encryptor`): not needed for Sake-to-Sake.

## 書き心地 (what I wrote → the message → what I wrote instead)

- **The app text survived.** The test app is 120 lines in both languages, line for line; the differences are
  `app` as the first argument of every helper, `Hash[...]` for `{...}`, and `Type.op` calls. `@user` in a before
  filter and a route works as Ruby's instance variable once declared (`attr_accessor user`).
- `params(app)["splat"]` passed to `Array.join` → `Array.join: argument 1 must be Array, but can be nil | String
  | Hash@L200[String => nil | String | Array@L187[...` (a 600-character type; the params Hash comes from
  Rack's nested-query parser) → `splat = params(app)["splat"]` + `splat => Array`. Every non-String use of a
  param needs this line; interpolation (`"#{params(app)["id"]}"`) does not. Ruby's params are just as untyped;
  Sake makes the reader say so. The message should shorten the recursive type.
- Session counter: Ruby's `session["count"] = (session["count"] || 0) + 1` cannot type-check (a JSON value
  plus 1), so I wrote `n = session(app)["count"] || 0` + `n => Integer` at once; the `=>` line reads as a
  statement of what the session holds, which is fine.
- `error(app) do |e| "#{Exception.message(e)}" end` → `Exception.message: argument 1 may be nil (ArgumentError |
  EOFError | ... | Sinatra::NotFound | ... | nil)`: one block param type for status handlers (nil, as Ruby) and
  server-error handlers. Correct; the union listing every exception of the program is long but accurate.
  Wrote `Kernel.inspect(e)` in the test, `case e in MyError` in the notes' example.
- `def set_body(res, v)` in `Sinatra::Response < Rack::Response` (Ruby overrides `body=`) → `` `Sinatra::Response
  .set_body` is a built-in operation and cannot be redefined`` → normalize in `Base.body` and use the generated
  setter. The message is wrong about the cause (it is `attr_accessor body`'s setter); repro
  `experiments/2026-10-12-web/bugs/sinatra_attr_setter_called_builtin.sake`.
- `in [Integer => code, String => b] then ...` → `unsupported pattern 'Integer => code'` → `in [Integer, String]`
  then `code, b = res`.
- `File.join(__dir__, ...)` → ``undefined local variable or function `__dir__` `` →
  `File.dirname(PROGRAM_NAME)` → `` type `PROGRAM_NAME` cannot be used as a value `` → `Kernel.PROGRAM_NAME`
  (the cheat sheet lists it among Kernel's, but not as callable bare).
- `@response["content-type"]` → `Indexable.[]: the receiver is Sinatra::Response@L176#1 | Sinatra::Response@L195#1,
  which cannot be indexed` → `Response.get_header(@response, "content-type")` (19 places, by a regexp).
- Library vs. the whole-program checks: `rescue Pass` (above; now a warning). The same rule caught nothing wrong in the app.
- **What the twins found** (not Sake's issues, but they show the comparison works): the protection headers
  must be added after Sinatra's `finish` (a 204 has no content-type, so no `x-frame-options`); the error
  handlers' lookup in Ruby does not climb from `NotFound` to `Exception`; the development 404 page comes from a
  handler registered at load time by `configure :development`; and the real WEBrick answers a `POST` without
  Content-Length with 411 (Sinatra: 500), where Sake's webrick port reads an empty body; the demo's curl sends
  `-d ""`.
- `puts("port N")` from the server was not seen by `run.sh` until exit → `IO.flush(IO.stdout)` (Ruby:
  `$stdout.sync = true`).
- `--strict` on the first complete run of the test reported only the items above; the 324-line comparison
  then differed in one place (the 204's headers).

## Size

| | Ruby (gem) | Sake |
|---|---|---|
| Sinatra | `lib/sinatra/base.rb` 2173 lines (1536 code) of 2832 in the gem | `sinatra.sake` 824 lines (668 code) |
| Mustermann (sinatra + regular types, AST, pattern) | 1929 lines (1012 code) of 3237 | `mustermann.sake` 198 lines (155 code) |
| test | `sinatra.rb` 241, `mustermann.rb` 42 | `sinatra.sake` 241, `mustermann.sake` 42 |
| demo app | `app.rb` 67 | `app.sake` 67 |
