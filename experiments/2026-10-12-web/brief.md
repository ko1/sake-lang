# Brief: the web in Sake — Sinatra, and a Rails-shaped framework (2026-10-12)

ko1 asked: "Sinatra とかできそう？ ウェブ領域いけるか試して。Rails まで行けるとかっこいいね". The question is
whether Sake (Ruby where types are on operations: `String.upcase(s)`, not `s.upcase`) can carry web
programming: routing, request/response, templates, forms, sessions, a model layer, a real server. Two agents work
at the same time, one per track below. The answer is as much the friction you hit as the code you produce.

Repo: `/home/ko1/app/sake`. What already exists and works:
- `sakelib/rack.sake` (Rack 3: Utils, Request, Response, MockRequest; apps are types including `Rack::App`,
  see `sakelib/notes/rack.md` "The app shape"), `sakelib/rackup.sake` (`Rackup::Handler::WEBrick`),
  `sakelib/webrick.sake` (a real HTTP server on TCPServer + threads, request bodies by Content-Length),
  `sakelib/erb.sake`, `sakelib/json.sake`, `sakelib/net_http.sake` (a client), `sakelib/cgi.sake`,
  `sakelib/pstore.sake`, `sakelib/securerandom.sake`, `sakelib/digest.sake`, `sakelib/base64.sake`,
  `sakelib/logger.sake`, `sakelib/active_support_inflector.sake`, `sakelib/active_support_core_ext.sake`.
- Read first: `docs/cheatsheet.md` (rules and every operation; the most up-to-date summary),
  `sakelib/README.md`, `sakelib/notes/rack.md`, `sakelib/notes/webrick.md`, `sakelib/notes/erb.md`, and one
  port with its test pair (`sakelib/rack.sake`, `test/sakelib/rack.sake`, `test/sakelib/rack.rb`).
  `docs/spec.md` and `docs/manual/ja|en/` have details. `bin/sake --strict FILE` checks and runs;
  `bin/sake --types FILE` shows inferred types.

The central constraint: **Sake keeps no blocks.** A block is passed to a call and run by it; it cannot be stored in
a field, Hash or Array. Sinatra's `get "/" do ... end` and Rails' `before_action :x`/callbacks store code.
You must find the Sake shape for this (types that include a module, functions dispatched by `M.f(x)` on the
value's type, Symbols matched with `case`, ...). Judge designs by how they read for the app author, and say in
the notes what the Ruby code is and what the Sake code became. Do not invent a different framework when the
Ruby one can be followed: follow Ruby's names, nesting, and behavior, and record each place you could not.

Conventions: a Ruby class becomes `class Name` with `attr_reader`/`attr_accessor`; instance methods are
operations with the instance first (`Sinatra::Base.halt(app, 404)`); inside, `@x` is the first argument's field.
`include M` copies M's functions; `M.f(x)` dispatches on x's type among M's includers. Namespaces nest as Ruby's.
No keyword arguments at call sites to Sake functions (take a Record `{a: 1}` or a Hash). `def f = expr` only
for short bodies. Exceptions: a module groups exception classes (`rescue M`); `Exception.backtrace(e)` exists.

## Track A: Sinatra (agent A)

Port Sinatra 4.2.1 (installed: `gem contents sinatra`, also mustermann 3.1.1, tilt 2.9.0, rack-protection) as
`sakelib/sinatra.sake` (plus `sakelib/mustermann.sake` if you port the pattern part separately).
- Commonly used API first: routes for each verb with Mustermann's sinatra patterns (`/hello/:name`,
  `/say/*/to/*`, optional `(.:format)?`, regexps), `params` (path, query, form), `request`, `status`, `headers`,
  `body`, `content_type`, `halt`, `redirect`, `pass`, `not_found`/`error` handlers, `before`/`after` filters
  (with patterns), `erb` templates (inline and from a views dir, with a layout), `json`-style responses, `session`
  (cookie-based, as `enable :sessions`), `settings`/`set`, static files from `public/` if reasonable.
- The app is a type (Ruby's `class MyApp < Sinatra::Base`). It must be a Rack app (`Rack::App`) so
  `Rackup::Handler::WEBrick` can serve it.
- Tests: `test/sakelib/sinatra.sake` and `test/sakelib/sinatra.rb`: the same app and requests, once in Sake on
  your port and once in Ruby on the real gem (drive both with `Rack::MockRequest`), printing identical output.
  Write the two programs line by line in parallel (same order, names, comments): ko1 reads them side by side.
  `ruby test/test_sakelib.rb -n /sinatra/` checks it (the .sake runs with `--strict`).
- A demo in `experiments/2026-10-12-web/sinatra/`: a small app (e.g. a todo list or URL shortener with a form,
  a JSON endpoint, a session counter) served by the real server on 127.0.0.1 with a random port, and a script
  `run.sh` that starts it, makes requests with curl (GET, POST form, redirect, 404, cookie), prints the
  responses, and stops it. Keep the Ruby twin of the demo next to it (`app.rb`) and show both give the same
  responses.
- Notes: `sakelib/notes/sinatra.md` in the format of the other notes (API table Ruby → Sake, same/differs/missing,
  what could not be ported and why, built-ins Sake lacks, friction as "what I wrote first → the message → what I
  wrote instead", size: gem lines ported vs Sake lines).

## Track B: Rails-shaped (agent B)

Rails cannot be ported whole. Build the part that makes a Rails app a Rails app, following Rails 8.1.3's names
and behavior (installed: actionpack, actionview, activerecord, activemodel, activesupport 8.1.3, sqlite3 2.9.5),
and write a small blog with it: posts with comments, CRUD, validations, flash, a layout.
- Where: `experiments/2026-10-12-web/rails/` (the framework as `.sake` files there, e.g. `action_dispatch.sake`,
  `action_controller.sake`, `action_view.sake`, `active_record.sake`, `active_model.sake`, and the app in
  `blog/` laid out as a Rails app: `config/routes.sake`, `app/controllers/`, `app/models/`, `app/views/` with
  `.html.erb` files, `db/`). `require` takes paths relative to... check how `require` resolves in Sake
  (`docs/spec.md`); `require_relative` may be what you need.
- Parts, in order of value: routing (`resources :posts do resources :comments end`, `root`, named route
  helpers like `posts_path`/`post_path(p)`, `rails routes`-like listing), controllers (actions, `params` with
  `require`/`permit`, `render`, `redirect_to`, `before_action`, `flash`, `respond_to` for HTML/JSON if
  reasonable), views (ERB with layout, `yield`, partials `render @post.comments`, helpers `link_to`,
  `form_with`, `button_to`, `h`/escaping, `pluralize`, `time_ago_in_words` optional), models (attributes,
  `validates :title, presence: true, length: {minimum: 5}`, `errors.full_messages`, `has_many`/`belongs_to`,
  `find`/`where`/`order`/`create`/`update`/`destroy`, timestamps).
- Storage: Sake has no SQLite binding. Choose and justify: an in-memory store persisted with PStore or JSON, or
  a SQL subset written in Sake. Rails' `where`/`order` API matters more than SQL.
- Compare with real Rails where it is cheap and exact: the HTML that `link_to`, `form_with`, `button_to`,
  `content_tag`, `pluralize`, `errors.full_messages`, route helpers produce (ActionView/ActiveModel can run
  outside an app: write `experiments/2026-10-12-web/rails/compare.rb` + `compare.sake` with identical output).
  A whole twin Rails app is optional (`rails new` may need the network; do not fight it).
- Serve the blog with the real server (`Rackup::Handler::WEBrick`) on 127.0.0.1 and a random port; a `run.sh`
  that starts it, walks a scenario with curl (index, new post with a validation error, create, show, add a
  comment, edit, delete), prints the responses, and stops it.
- Notes: `experiments/2026-10-12-web/rails/notes.md`: what of Rails is there and how the Sake code reads next
  to the Rails code (show pairs: a Rails controller/model/route file and the Sake one), what could not be done
  and why, built-ins Sake lacks, friction as "what I wrote first → the message → what I wrote instead", sizes.

## Rules (both)

- Do NOT change `lib/`, `docs/`, `bin/`, `tools/`, `test/test_*.rb`, `sakelib/README.md`, `sakelib/prelude.sake`,
  or existing `sakelib/*.sake` files (another agent works in parallel; the lead fixes the interpreter). If an
  existing port lacks something you need (e.g. rack, webrick), write it in your own files if reasonable, and record
  the request. Track B may `require` Track A's sinatra only if it exists and is useful; normally don't.
- If you find an interpreter or checker bug, keep a minimal repro as `experiments/2026-10-12-web/bugs/<track>_*.sake`
  with a comment (what happens, what Ruby does), work around it, and mention it in your reply.
- Shell commands need `dangerouslyDisableSandbox: true`. The machine is shared: do not run the whole test suite;
  run your own tests. Servers bind 127.0.0.1 with a random free port only, and every server you start must be
  stopped by your script (no stray processes; check with `ps` at the end).
- Do not run `git commit` or `git push`; leave the files in the working tree.
- Budget: about 3 hours. If time runs short, stop adding API and finish the demo, the tests and the notes.
- When done, reply in under 400 words: what works (with the demo's request list), what is missing and why, sizes
  (Ruby vs Sake lines), the top built-in requests, bugs found (with repro paths), and the friction worth telling
  ko1 about — usage notes are part of the deliverable.
