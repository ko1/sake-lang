# webapp: a CGI-style web framework in Sake (usability report)

Files: `lib.sake` (framework), `client_todo.sake` (todo list), `client_shorten.sake` (URL shortener),
`client_selftest.sake` (the library without a server, 26 checks), `build.sh`, `serve.rb` (TCPServer,
one `bin/sake` process per request), `curl_session.sh` / `curl_session.txt` (end-to-end transcript),
`bug_*.sake` (repros). Data files are written to `data/` at run time.

Run: `./build.sh && ruby serve.rb client_todo 18431` (default level 3), then `./curl_session.sh`.

## API sketch

- `Request` (`reader: [verb, path, query, headers, cookies, form, body]`, `accessor: [params]`):
  `Request.param(r, name)` (route param, then form, then query; String or nil), `param_or(r, name, default)`,
  `int_param(r, name)` (Integer, or raises `HttpError` 404/400), `header`, `cookie`.
- `Response` (`reader: [headers]`, `accessor: [status, body]`): `add_header`, `set_cookie`,
  `delete_cookie`, `to_http`.
- `HttpError = Exception.new(:status)`: raised by a handler to stop with an error page (Sinatra's `halt`).
- `SafeHtml` (`reader: [source]`, `+`): HTML that is already safe. `Html.raw(s)`, `Html.escape(x)`,
  `Html.render(tmpl, Hash[name => value])` (`{{name}}` is escaped unless the value is SafeHtml),
  `Html.each(xs) { |x| SafeHtml }`, `Html.page(title, body)`.
- `Web.run(routes) { |handler, req| Response }`: reads stdin, routes, handles 404/405/HttpError,
  writes the response to stdout. `routes` is an Array of `[verb, "/todos/:id", handler]` Tuples, where
  the handler is any value (a Symbol, or a handler Struct).
  `Web.html(status, SafeHtml)`, `Web.json(status, value)`, `Web.text`, `Web.redirect(location)`,
  `Web.url_decode` / `url_encode` / `parse_pairs` / `match_path` / `dispatch`.
- `Json.encode(v)` (nil, Boolean, Integer, Float, String, Symbol, Array, Hash); `Tsv.load(path)` /
  `Tsv.save(path, rows)` (tab-separated rows with `\t \n \\` escapes).

## Routing without stored blocks

Sinatra stores a block per route (`get "/todos/:id" do ... end`). Sake has no block values, but a
function can still `yield`, so the framework keeps **one** block: the one given to `Web.run`. The routes
table maps to a *value*, and the app turns that value into code. I tried two designs:

1. **Symbols + `case/in`** (`client_todo.sake`): `["GET", "/todos/:id", :show]`, then
   `Web.run(routes) { |route, req| case route in :show then ... end }`. All handlers sit in one
   `case`. It reads like a Sinatra file with the `get` lines moved into a table. The table and the
   `case` can drift apart: a Symbol in the table with no branch is a `NoMatchingPatternError` at run
   time. A branch with no route is dead code that nothing reports.
2. **Handler values + mixin dispatch** (`client_shorten.sake`): `module Handler; def call(h, req) =
   raise(NotImplementedError); end`, one Struct per handler (`class Follow < {reader: [store]}; include
   Handler; def call(h, req) ... end`), `["GET", "/s/:code", Follow.new(store)]`, and
   `Web.run(routes) { |h, req| Handler.call(h, req) }`. This is Rack's "object that responds to
   `call`". It is checked better: a handler type without `call` is a static error ("Home includes Handler
   but does not define call, which Handler requires"). Dependencies (the store) go in the handler's
   fields instead of globals. It costs a class per route (5 lines each).

How it felt: (1) is quick to write and (2) is easier to trust. Neither needed a framework feature beyond
`yield`, and the framework code (`Web.dispatch`, `Web.run`) was the same for both. The one thing a
block per route would give is the route and its code on the same line.

## Request data (all Strings) meeting typed operations

- Every input is a String or nil: Hash lookups of query/form/cookies/headers. The library has one
  place where a String becomes an Integer, `Request.int_param` (a regex check, then `String.to_i`, else
  `HttpError` 404). A Ruby app would write `params[:id].to_i` and get 0 for "abc".
- **At the recommended level 2, a missing field is not reported statically.**
  `String.upcase(Request.param(req, "missing"))` runs and fails while serving (a 500). Hash lookup is
  `index-nil`, which is level 3. For a web app, nearly every value comes from `h[k]`, so level 2
  checks the least where the risk is highest. I made all three programs level-3 clean, and `serve.rb`
  runs level 3 by default. Reaching it cost 5 rewrites in the template scanner (`String.[](s, i, n)`
  → `String.partition`, which gives a Tuple of three Strings and no nil) and 1 workaround for a false
  report (below). The apps were already clean, because I had written `param_or(req, "title", "")` and
  `if code && url && hits` out of habit.
- Destructuring a stored row (`id, done, title, created = row`) gives nil-able locals. One
  `next unless id && done && title && created` covers them all, which reads fine.
- Percent-decoding UTF-8 was the hardest part. Sake has no `pack`, `force_encoding`, or
  `Integer#chr(Encoding)`. `Integer.chr(227)` gives a BINARY String, and joining it with UTF-8
  **crashes the interpreter** (`bug_chr_concat.sake`). I wrote a 30-line UTF-8 decoder that builds each
  character with `format("%c", codepoint)`, which happens to produce UTF-8.

## HTML building and escaping

The best part of the experiment. `SafeHtml` is a type, and `Web.html(status, page)` reads
`SafeHtml.get_source(page)`. So **passing a plain String as a page is rejected before running**:
`SafeHtml.get_source: argument 1 must be SafeHtml, but is String [type]`. `Html.render` escapes every
value that is not SafeHtml, so there is no `{{{raw}}}` syntax to misuse. `Html.raw` is the only way
to get unescaped HTML, and it is easy to grep for. Ruby needs `html_safe`-style runtime flags on String
to get this, while Sake gets it from "the type is on the operation". The transcript shows
`<b>bold?</b>` escaped in titles, flash cookies, and form values (`value="{{title}}"`).

Templates are heredocs with `{{name}}` and a `Hash["name" => value]`. Values of mixed types (Integer,
String, SafeHtml) in one Hash were fine. A misspelled name is only found at run time
(`template: no value for {{nope}}`), because templates are Strings. There is no `gsub` with a block or
a Hash, so `render` scans with `String.partition`.

## State across requests

Each request is a new process, so state lives in `data/*.tsv`, loaded and rewritten whole on each
request (`Tsv.load` / `Tsv.save`). The flash message and "my links" live in cookies. This was
straightforward: `File.read` / `File.write` / `File.exist?` are enough. There is no locking, and none
is needed because `serve.rb` serves one request at a time. TSV rows come back as Arrays of String
(`Tsv.load` cannot give them an element type: there is no "Array of `String[]`"), and each client
converts them into its record type (`Todo`, `Link`).

## Sinatra side by side (the toggle handler)

```ruby
# Ruby / Sinatra
post "/todos/:id/toggle" do
  todos = Todos.all
  t = todos.find { _1.id == params[:id].to_i } or halt 404, "no todo"
  t.done = !t.done
  Todos.save(todos)
  redirect "/todos/#{t.id}", 303
end
```

```ruby
# Sake / webapp: the route is a row of the table, the code a branch of the one block
["POST", "/todos/:id/toggle", :toggle],
...
in :toggle
  t = Todos.find(todos, Request.int_param(req, "id"))   # raises HttpError 404 if missing or not a number
  Todo.set_done(t, !Todo.get_done(t))
  Todos.save(todos)
  Web.redirect("/todos/#{Todo.get_id(t)}")
```

The handler is about the same length. The differences are the separate table row, `Todo.get_done(t)`
in place of `t.done`, and returning the Response instead of the framework's implicit one.

## Friction log

- [missing-builtin] `Integer.chr(b)` for percent-decoded bytes, joined with UTF-8 text → Ruby
  backtrace `incompatible character encodings: UTF-8 and BINARY (ASCII-8BIT)
  (Encoding::CompatibilityError)` → no → a UTF-8 decoder using `format("%c", cp)` → 3 (probing what
  exists).
- [bug] the same crash is a Ruby exception escaping the interpreter, not a Sake error
  (`bug_chr_concat.sake`).
- [type-check-false-report] `while (l = gets)` then `String.chomp(l)` → `String.chomp: argument 1 may
  be nil (nil | String) [nil]` (level 2) → partly (the hint lists `while x`, which is what I wrote) →
  `while true; l = gets; break unless l` → 2.
- [ruby-habit] `Integer.max(m, id)` → `undefined function Integer.max`, hint: `max is defined in
  Array.max, Range.max, Set.max` → yes → see next → 1.
- [type-check-false-report] `Array.max(ids + Integer[0]) + 1` → `Arithmetic.+: the operands may be nil
  ([Integer | nil, Integer]) [nil]` → yes (it is right that `max` may be nil in general) →
  `Array.reduce(todos, 0) { |m, t| m > id ? m : id }` → 1.
- [type-check-false-report] (level 3) `String.[](rest, 0, i)` after `i = String.index(...)` checked
  non-nil → `may be nil, because x[k] ... gives nil` ×5 → yes → rewrote with `String.partition` → 1.
- [bug] (level 3) `case v in true ... in false ... in Integer ...` → `case/in: no in branch matches
  some values of true|false [exhaustive]`. Also with `in true | false` → no → an `else raise` branch
  → 2 (`bug_bool_exhaustive.sake`).
- [message] a handler branch returning a String instead of a Response → 5 errors, all inside the
  library's `Response.to_http` (`Response.get_status: argument 1 must be Response, but can be String`),
  hint `reached by the call at line 458 → line 373`. That points to `Web.run(...)`, not to the wrong
  branch → partly → found by reading the branches.
- [language-limit] no block values: a route cannot carry its code (see Routing). Workable, and in the
  handler-value form arguably better.
- [language-limit] `Request.new` takes 8 positional arguments, 5 of them Hashes of the same type, so
  swapping `query` and `form` would not be caught. No keyword arguments. Only `read_request` (and the
  selftest) call it.
- [missing-builtin] no `String#<<`, no `gsub` with a block or Hash, no `pack`: every builder is
  `String[]` + `Array.push` + `Array.join`. It works, but costs about 10 lines in `render`, `escape`,
  and `Tsv`.
- [ruby-habit] `def path = "data/todos.tsv"` and `def alphabet = ...` instead of constants. Fine
  once known (the tutorial says so).
- [tooling] concatenated files: errors in the library are reported at `out/X.sake:350`, and I
  subtract 376 (`build.sh` prints the offset) to find client lines. The pkill-by-pattern pitfall when
  stopping servers was mine, not Sake's.

## What felt good

- `SafeHtml` as a type: the XSS rule "never emit an unescaped String" became a static check with no
  framework magic (see above). The same check verified that every case branch returns a Response,
  even though the message points at the wrong place.
- Mixin dispatch for handlers: forgetting `call` is a static error naming the type.
- The library, the selftest, and the shortener all ran clean at `--strict` on the **first** run (I
  injected wrong calls to confirm the checker was really on: they were rejected). Shorten was even
  level-3 clean from the start.
- `Tuple[]` routes table with `|verb, pattern, handler|` destructuring, and `return` from inside
  `Array.each` in `dispatch`, read just like Ruby.
- Heredoc templates plus `Hash[...]` of mixed-type values needed no ceremony.

## What felt bad (top 3)

1. **Bytes and encodings**: about 25 minutes and 30 lines for UTF-8 percent-decoding, plus an
   interpreter crash on the way. Every web framework needs this.
2. **Level 2 does not check Hash lookups**, which is all of the input in a web app. Level 3 does, at
   the cost of 6 rewrites and 1 false report (about 15 minutes).
3. **No string builder or `gsub` with a block**: the template engine, escaping, JSON, and TSV are each
   written as a char loop with `Array.join` (about 40 lines in all that Ruby would write in about 8).

## Library design under Sake

- No per-route blocks: a routes **table** whose third column is a value, plus one block on `Web.run`.
  In Ruby I would expose `get/post` DSL methods with stored blocks.
- `SafeHtml` instead of tagging Strings at run time. In Ruby, `ERB::Util.h` everywhere or Rails'
  `html_safe` (a runtime flag). Here the type is on the operation (`Web.html` takes SafeHtml).
- Errors as `HttpError` raised from anywhere (Sinatra's `halt` uses throw/catch, which Sake does not
  have). This worked well with Sake's listed rescues.
- No `params` with indifferent access: Strings only, with `param` / `param_or` / `int_param`. In Ruby,
  `params` would be a Hash and `.to_i` would be scattered through the handlers.
- Response headers are a `Tuple[]` of pairs (Set-Cookie repeats), with no `Hash` and its key casing.

## Numbers

- Lines: `lib.sake` 376, `client_todo.sake` 111, `client_shorten.sake` 131, `client_selftest.sake`
  49, `serve.rb` 45.
- Static errors before running clean at level 2: lib + selftest 0; todo 2 (1 my mistake
  `Integer.max`, 1 false report `Array.max` nil); shorten 0. During probing: 1 false report
  (`while (l = gets)`).
- Going to level 3: 6 reports (5 `index-nil` on `String.[]`, rewritten; 1 false report from the
  Boolean `exhaustive` bug, worked around). No level-2 report was left unremoved. All three programs
  now pass `--strict=3`. Level 4 reports only the deliberate `raise`s that `Web.run` cannot see
  rescued (3 in each app: the template's two ArgumentErrors and `Json.encode`'s else). The selftest also
  gets `int_param`'s HttpError, because it calls it outside `Web.run`.
- `--types` on the todo app: `proven=350 partial=6 error=2 unknown=0` (before the level-3 rewrite).
  The 2 "error" lines are `raise arg ArgumentError: want a rescue`, i.e. unrescued raises, which reads
  oddly under the label "the check always fails".
- Per-request time, informal (local machine shared with other jobs, load 9–12, 5 runs each):
  `--strict=0` ≈ 255 ms, `--strict=1` and `--strict=2` ≈ 440 ms; `ruby -e 1` ≈ 120 ms. Through
  `serve.rb` at level 3: 460–600 ms. **The static check is about 40% of each CGI request**; a server
  that checks once and runs many times would remove it.
- Time: about 75 minutes.

## Suggestions

1. **Bytes → UTF-8 String** (e.g. `String.from_bytes(Integer[])`, or `Integer.chr(cp)` returning
   UTF-8 for any code point), and make encoding errors Sake errors, not interpreter crashes. Ties
   to: Integer.chr friction and `bug_chr_concat.sake`.
2. **Fix Boolean exhaustiveness**: `in true` + `in false` (or `in true | false`) should cover
   `true|false` (`bug_bool_exhaustive.sake`).
3. **Narrow `while (x = expr)`** like `if x` does, since it is the Ruby way to read lines (the
   `gets` friction).
4. **Report a block's result type at the block**: when `yield`'s value fails inside the callee,
   name the block's line (or the branch that produced the wrong type) and report it once, not once per
   use in the callee (the to_http message friction).
5. **A level between 2 and 3, or `index-nil` for Hash only**: for input-driven programs the Hash
   lookup is where nil comes from, while `String.[]` / Array index reports are mostly noise (the level-3
   friction). Alternatively, a `--check-once` mode / cached check for programs run per request (40%
   of each request here).
