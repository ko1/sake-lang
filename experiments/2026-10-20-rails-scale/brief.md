# Brief: porting Rails 8.1.3 to Sake (2026-10-20)

ko1 heard that Spinel (matz's whole-program Ruby AOT compiler) needs about ten hours to analyze a Rails-sized
program, and asked how long Sake takes: "Rails 規模のウェブアプリを作れるまで準備して、それを解析してみて", then
"Rails やりましょう". A Rails-shaped framework of 1,359 lines (experiments/2026-10-12-web/rails/) exists, but
Rails 8.1.3's lib/ is 108,000 lines of code. So we port Rails itself, gem by gem, following its source, and then
write a large app on it and measure the analysis. Several agents work at the same time, each on one part.
The port is the deliverable, and so is what it was like to write: Sake is "Ruby where the type is written on the
operation" (`String.upcase(s)`, not `s.upcase`), and Rails is the most metaprogrammed Ruby there is.

## What exists

- Repo `/home/ko1/app/sake`. Read first: `docs/cheatsheet.md` (every rule and operation; the most up-to-date
  summary), `sakelib/README.md`, then one port with its test pair (`sakelib/rack.sake`, `test/sakelib/rack.sake`,
  `test/sakelib/rack.rb`). Details: `docs/spec.md`, `docs/manual/ja|en/`. `bin/sake --strict FILE` checks and
  runs; `bin/sake -c --strict FILE` only checks; `bin/sake --types FILE` shows inferred types.
- Ports you build on (sakelib/): rack, rackup, webrick, erb, erubi, json, i18n, concurrent_ruby, logger,
  securerandom, digest, openssl (HMAC only), base64, cgi, uri, time, date, bigdecimal, pstore, yaml, mustermann,
  active_support_inflector, active_support_core_ext, active_support_number_helper, builder? (check), and more
  (`ls sakelib`). Their notes are in `sakelib/notes/NAME.md`.
- The 10-12 Rails-shaped framework and blog: `experiments/2026-10-12-web/rails/` with `notes.md` (how routes,
  controllers, views and models were given a Sake shape; read it: it solved problems you will meet), and its
  copy `experiments/2026-10-20-rails-scale/rails/`. Treat it as a sketch: the port follows Rails' files, not it.
- Rails' source: `~/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems/<gem>-8.1.3/lib/` for activesupport,
  activemodel, activerecord, actionpack, actionview, railties (and activejob, actionmailer, ...). sqlite3 2.9.5,
  rack 3.2, i18n 1.15, tzinfo, concurrent-ruby, erubi, builder, nokogiri are installed for the Ruby side.

## Where the port goes

- `sakelib/rails/<gem>/` mirrors the gem's `lib/`: Rails' `activesupport-8.1.3/lib/active_support/inflector/methods.rb`
  becomes `sakelib/rails/activesupport/active_support/inflector/methods.sake`. One Sake file per Ruby file you port;
  several small Ruby files may share one Sake file when Sake needs them together (say which, in its header).
  Within the tree, `require` with paths relative to the requiring file. Programs reach it as
  `require "rails/activesupport/active_support/inflector/methods"` (require falls back to sakelib/).
- **Every Sake file starts with a header** naming what it ports, so the port can be measured file by file:
  ```
  # Port of activesupport-8.1.3/lib/active_support/inflector/methods.rb (partial: no transliterate)
  ```
  `(partial: ...)` says what of that file is left out. `(Sake only)` marks a file with no Ruby counterpart.
- Tests: `test/sakelib/rails/<gem>/NAME.sake` and `NAME.rb`, the same program once in Sake on your port and once in
  Ruby on the real gem (`gem "activesupport", "8.1.3"` before the require, so the version is pinned), printing
  identical output. Write the two line by line in parallel (same order, names, comments): ko1 reads them side by
  side. Run with `ruby -Ilib test/test_sakelib.rb -n /rails_<gem>/` (each test runs in its own directory with
  `--strict`, i.e. level 2). Cover what you port: a port without its comparison is not done.
- Notes: `sakelib/notes/rails_<gem>.md` (or `rails_<gem>_<part>.md` if your part is one of several): what is
  ported (a table of Ruby files → Sake files, with Ruby code lines → Sake code lines), how Rails' metaprogramming
  was given a Sake shape (show the Ruby and the Sake side by side), what could not be ported and why, built-ins
  Sake lacks, friction as "what I wrote first → the message → what I wrote instead". This is the 利用感レポート
  ko1 asks for whenever AI writes Sake: be concrete and honest, good and bad.

## How to port

- **Follow Rails.** Same module and class nesting, same method names, same behavior, same messages. Port the code
  path by path from the Ruby source; do not design a different framework. Where Sake forces a different shape,
  keep it as close as Sake allows and record it. A Ruby instance method becomes an operation with the instance
  first: `ActiveSupport::Duration.ago(d, t)`; inside, `@x` is the first argument's field.
- **Sake's rules you will hit** (the cheatsheet has all of them):
  - Blocks are not values: no `proc`, `lambda`, stored blocks, `define_method`, `send`, `method_missing`,
    `instance_exec`, `class_eval`, `eval`. Rails stores code everywhere (callbacks, `delegate`, attribute methods,
    `has_many`, `scope`, `before_action`, routes). The Sake shapes so far: a module the app's types include, with
    required functions (`def f(x) = raise NotImplementedError`) that the includer defines; a function with a `case`
    over Symbols (`def before_action(c, action)`); and **generated code**: `generate "gen", "arg"` runs a Sake
    program at load time and joins what it prints into the program (`docs/spec.md`, "generate"; the 10-12
    framework uses it for models, route helpers, compiled templates and dispatch). If your part needs generated
    code (attribute methods from a schema, association readers, route helpers, compiled templates, callback
    dispatch), write the generator side as functions that take the declarations and return Sake source, in your
    gem's tree (e.g. `sakelib/rails/activerecord/active_record/generate/*.sake`, `(Sake only)`), with a test that
    prints the generated source. Railties will call them later.
  - No inheritance: `class B < A` pastes A's functions into B (each copy is checked in B). Rails' deep class
    hierarchies (`ActiveRecord::Base` with ~40 modules, `ActionController::Base` with ~30) become `include`s.
    Pasting multiplies code: a big base pasted into many subclasses is checked once per subclass. Prefer modules
    and dispatch (`M.f(x)` dispatches on x's type among M's includers) over pasting large bases.
  - Types are on operations: `Array.map(xs) { }`. A chain step continues with the type the chain names last:
    `String.strip(s).downcase` is `String.strip(s).String.downcase`; write the type where the value's type changes
    (`Array.group_by(xs) { }.Hash.keys`).
  - Keyword arguments work at call sites of Sake functions (`resources map, :posts, only: Any[:index] do`).
  - `def f = expr` only for short bodies (about 50 characters, no blocks), as in Ruby.
  - A module groups exception classes (`rescue M`).
- **Breadth over depth, by use.** Port what a Rails app exercises first, with the code paths a typical app runs:
  the size that matters is the code a real app's requests reach. Do not stub with fakes that just return
  constants; a part not ported is left out and listed in the notes.
- Keep `bin/sake -c --strict` of your tests clean (level 2), and note how long the check of your largest test
  takes (`/usr/bin/time -f "%es %MKB" bin/sake -c --strict FILE`): the analysis time is what this whole effort
  measures.

## Rules

- Do NOT change `lib/`, `docs/`, `bin/`, `tools/`, `test/test_*.rb`, `sakelib/README.md`, `sakelib/prelude.sake`,
  or files outside your part (other agents work in parallel; the lead fixes the interpreter and checker).
  Existing flat `sakelib/active_support_*.sake` ports: the activesupport parts may move their code into the tree
  and leave the flat file as a `require` of the tree, as long as `test/sakelib/active_support_*` still pass.
- If you find an interpreter or checker bug, or a missing built-in that blocks you, keep a minimal repro as
  `experiments/2026-10-20-rails-scale/bugs/<part>_<what>.sake` with a comment (what happens, what Ruby does), work
  around it if you can, and list it in your reply. Ask for built-ins rather than writing slow substitutes for
  things Ruby does natively (hashing, compression, time zones' data).
- Shell commands need `dangerouslyDisableSandbox: true`. The machine is shared: do not run the whole test suite;
  run your own tests. Servers bind 127.0.0.1 with a random free port only, and every server you start must be
  stopped by your script (check with `ps` at the end).
- Do not run `git commit` or `git push`; leave the files in the working tree.
- Budget: about 4 hours of work. When it runs short, stop adding API and finish the tests and the notes.
- When done, reply in under 500 words: what is ported (Ruby files and code lines → Sake lines), what is left out
  and why, the generated-code pieces and their inputs, bugs and built-in requests (with repro paths), the check
  time of your largest test, and the friction worth telling ko1 about.

## The parts (first wave)

Each agent gets one. They are chosen to depend little on each other; the second wave (activerecord's model layer,
actionview, actioncontroller, railties) builds on them.

1. **activesupport A**: inflector (all of `inflector/`), `core_ext/` (string, array, hash, object, enumerable,
   integer, numeric, module/delegation as far as it has a Sake shape, date/time/date_time calculations), duration,
   time_with_zone and TimeZone (tzinfo data: ask for a built-in if needed), number_helper, `json/` (encoding and
   decoding), `core_ext/string/output_safety` (SafeBuffer, `html_safe`, ERB::Util), string_inquirer,
   array_inquirer, ordered_hash/ordered_options, hash_with_indifferent_access.
2. **activesupport B**: callbacks (`define_callbacks`/`set_callback`/`run_callbacks` and conditions; the Sake shape
   of stored callbacks is the core question), concern (what it means without `included do`), class_attribute,
   configurable, notifications and instrumentation (subscribers without stored blocks), log_subscriber, logger,
   broadcast_logger, tagged_logging, cache (Store, MemoryStore, FileStore, NullStore, Entry), message_verifier,
   message_encryptor, key_generator, parameter_filter, current_attributes, deprecation, error_reporter,
   lazy_load_hooks, rescuable, i18n integration (on sakelib/i18n), executor/reloader if reasonable.
3. **arel and the SQLite adapter**: `activerecord/lib/arel/` (nodes, visitors to SQL for SQLite, the Table/
   attribute DSL, predications, SelectManager/InsertManager/UpdateManager/DeleteManager) and
   `active_record/connection_adapters/` for sqlite3 (abstract adapter, schema statements, quoting, column/
   type map, the sqlite3 adapter, database statements, transactions), plus `active_record/type/` and
   `active_model/type/` if the adapter needs them first (coordinate by name: activemodel is a later part; put
   ActiveModel::Type under `sakelib/rails/activemodel/` and say so). A SQLite built-in is being added to the
   interpreter right now by another agent: `SQLite3::Database.new(path)`, `.execute(db, sql, binds)`,
   `.execute2`, `.last_insert_row_id`, `.changes`, `.close`, `.transaction(db) { }`; until it lands, write and test
   the SQL generation (Arel's `to_sql`) against real Arel (`Arel::Table.new(:users)` works without a database)
   and the adapter's statements as strings, then run them when the built-in exists (`bin/sake` with
   `SQLite3::Database` defined).
4. **actionpack A: ActionDispatch**: journey (the router: parser, nodes, formatter, visitors, the route set's
   recognize and generate), `routing/` (mapper DSL: resources/resource/namespace/scope/member/collection/
   concerns/root/match/get/post/...; RouteSet; url_for and named route helpers, which need generated code),
   `http/` (Request, Response, Headers, MimeType/MimeNegotiation, parameters, URL), middleware: cookies
   (signed/encrypted jars need activesupport B's MessageVerifier/Encryptor: use the existing sakelib/openssl HMAC
   and say what is missing), session (CookieStore), flash, params parser, show/debug exceptions, static,
   host authorization as reasonable, request_id, the MiddlewareStack. Compare `rails routes` output and
   recognize/generate results with the real gem (`ActionDispatch::Routing::RouteSet.new` runs without an app).

A fifth agent adds the SQLite3 built-in to the interpreter (its own brief).

## Second wave (2026-10-20)

What the first wave built is committed: `sakelib/rails/activesupport/` (notes `rails_activesupport_{a,b}.md`),
`sakelib/rails/actionpack/action_dispatch/` (`rails_actionpack_dispatch.md`), `sakelib/rails/activerecord/arel`
and the sqlite3 adapter with `sakelib/rails/activemodel/active_model/type*` (`rails_arel.md`), and the SQLite3
built-in (`docs/manual/en/ref/SQLite3-Database.md`). Read the notes of the parts you build on before you start.

Lessons from the first wave:
- **Callbacks**: ActiveSupport::Callbacks keeps the chain as data with method names as Symbols, and the class body's
  `define_callbacks`/`set_callback` lines live in a declarations file that `generate/active_support.sake` turns into
  dispatch functions (see `rails_activesupport_b.md`). Build `before_save`, `before_validation`, `before_action`,
  `around_*`, `after_commit` on it rather than inventing a second mechanism.
- **No `super`**: keep an overridden body as `super_<name>` and call it (`rails_arel.md`).
- **Shadowing is silent**: inside `module ActiveModel::Type`, a bare `String` is the type class (write `::String`),
  and a field named like an included function (`value`) makes a reader that quietly wins. Check names.
- **Generated code** must not reopen a class the program declares (`def Post.f(p)` instead), because generated
  source is read before the file with the `generate` line.
- **Check time is the measurement.** Write Rails' shape. If a check takes more than about 30 s, keep that version as
  a repro (`bugs/<part>_slow_check_<what>/`, with the timing) before you restructure: the first ActionDispatch
  Mapper (block-taking scope helpers recursing through `nested { }`) took 2 min 5 s for 30 routes; that shape is
  what Rails is made of, and the lead is looking at the checker for it.
- You may split your part among forks of yourself (the ActionDispatch agent did); you remain responsible for the
  whole part, the notes and the tests.

The parts:

5. **activemodel**: the rest of `activemodel-8.1.3/lib/active_model/` on the ported types: Model, API, the attributes
   API and AttributeMethods (generated from `attribute :name, :type` declarations), AttributeAssignment, Validations
   (every validator, `validates`/`validate`/`validates_with`, conditions, contexts) on ActiveSupport::Callbacks,
   Errors and Error (full messages, details, i18n), Naming, Translation, Conversion, Dirty, Callbacks
   (define_model_callbacks), Serialization and JSON, SecurePassword (ask for a bcrypt built-in), Validations::Callbacks.
6. **activerecord** (the model layer; the largest part, split it among forks): Base and its modules as includes (core,
   model_schema and attributes from the schema through generated code, persistence, querying, Relation with
   query/finder methods, calculations, spawn/merge, batches, scoping and named scopes, inheritance if reasonable,
   timestamps, callbacks, validations integration with uniqueness, transactions per record, enum, store, secure_token,
   counter_cache, readonly, locking optimistic), associations (belongs_to, has_one, has_many, has_many :through,
   has_and_belongs_to_many, reflection, preloading/includes/eager_load, autosave, dependent, nested attributes,
   inverse_of), migrations (Migration DSL, Schema.define, the schema dumper, the migrator with schema_migrations),
   fixtures if time allows. It sits on the committed Arel and sqlite3 adapter (extend them where needed, in their files,
   with tests). Rails' generated readers (`post.title`, `post.comments`) become generated functions from the schema and
   the model's declarations; follow the 10-12 framework's experience (`experiments/2026-10-12-web/rails/notes.md`).
7. **actionview**: template handlers (ERB through Erubi, compiled to Sake functions by generated code, with Rails'
   strict locals), the LookupContext and file resolver, rendering (templates, partials, collections with counters and
   spacers, layouts, `yield`/`content_for`/`provide`), and the helpers: tag/content_tag/tag builder, url (link_to,
   button_to, url_for through ActionDispatch's routes, mail_to, current_page?), form_with/form_for/FormBuilder and
   form tag helpers, form_options, number, text (pluralize, truncate, simple_format, cycle, highlight, excerpt),
   date (time_ago_in_words, distance_of_time_in_words, date selects), sanitize (rails-html-sanitizer is Loofah over
   Nokogiri: write the allowlist sanitizer in Sake or ask), asset tag/url, capture, output safety, translation,
   record identifier (dom_id), csrf/csp meta tags. Compare HTML with real ActionView, which runs without an app.
8. **actionpack B: ActionController and AbstractController**: Metal, Base and API with their modules as includes
   (rendering with ActionView, redirecting, head, StrongParameters, callbacks `before_action`/`around_action` with
   only/except/if on ActiveSupport::Callbacks, rescue_from, flash, cookies, request forgery protection, MimeResponds
   `respond_to`, conditional GET/ETag, data streaming `send_data`/`send_file`, HTTP basic/token auth, default headers,
   instrumentation, ParamsWrapper), on the committed ActionDispatch. The action dispatch `send(action_name)` becomes
   generated code; ActionController::TestCase / integration tests if time allows.
9. **built-ins** (the interpreter; the only part that changes `lib/`): see its own brief.
