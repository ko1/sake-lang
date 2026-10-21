# sakelib/rails: Rails 8.1.3 in Sake

A port of Ruby on Rails 8.1.3, gem by gem, laid out as each gem's `lib/`:

| Directory | Gem | What is there |
|---|---|---|
| `activesupport/` | activesupport | core extensions, inflector, Callbacks, Notifications, MessageVerifier/Encryptor, KeyGenerator, TimeWithZone, SafeBuffer, HashWithIndifferentAccess, JSON encoding, encrypted configuration, ... |
| `activemodel/` | activemodel | API, attributes and types, dirty tracking, validations (with I18n messages), callbacks, naming, conversion, serialization, SecurePassword |
| `activerecord/` | activerecord, arel | Base, persistence, finders, Relation (where/order/limit/joins/group/...), associations (belongs_to, has_many, has_one, through), validations incl. uniqueness, transactions, migrations and schema, the SQLite3 adapter, Arel |
| `actionpack/` | actionpack | ActionDispatch (Rack request/response, middleware stack, routing and Journey, cookies incl. signed/encrypted, sessions, flash, CSRF, SSL, host authorization), ActionController (Base/API/Metal, callbacks, strong parameters, rendering, redirects, respond_to, TestCase) |
| `actionview/` | actionview | ERB templates, layouts and partials, lookup, the helpers (tag/url/form/form_with and FormBuilder, text, number, date, sanitize ...) |
| `railties/` | railties | Rails, Application and Engine, configuration and `load_defaults`, initializers, the default middleware stack, `bin/rails` commands (server, routes, about, middleware, credentials:show, db:*), generators (new, scaffold, model, migration, controller, resource) |

`ruby experiments/2026-10-20-rails-scale/coverage.rb` counts it from the file headers ("# Port of
<gem>-8.1.3/lib/...rb (partial: ...)"): 55,846 lines of Rails' Ruby (whole files; 288 of the 481 files are
partial ports) as 34,770 lines of Sake, against 95,825 lines in these gems' `lib/` (code lines: not blank, not a
comment only). Left out: ActiveJob, ActionMailer, ActionCable, ActiveStorage, ActionText, other databases than
SQLite, the asset pipeline, console, engines as plugins, reloading, Rails.cache; what each gem leaves out is in
its notes.

## How it is used

An application is laid out as `rails new` lays it out; [examples/apps/rails_blog/](../../examples/apps/rails_blog/README.md)
is the Rails guide's blog on it, and runs request for request as the same app on real Rails 8.1.3 does.
`bin/sake bin/rails.sake server|routes|db:migrate|...` is `bin/rails`.

Rails builds most of an application while it boots: class bodies run `has_many`, `validates`, `before_action`;
routes define helpers; templates compile on first render. Sake has no code that runs before the program is
checked, except **generate** steps: a Sake program that reads declarations and prints Sake source, which is joined
into the program and checked with it. The app's `config/application.sake` has one, `generate "generate"`, and
`Rails::Generate.application` (`railties/rails/generate/application.sake`) runs every gem's generator over:

- `db/schema.rb`, the models' class bodies (`app/models/*.rb`, the very files Rails has for a model without
  methods), the controllers' class bodies, the routes, the views (ERB);
- and prints the attribute readers and writers, associations, validations and callbacks as data, url helpers,
  the controllers' filter chains, and each template as a function.

`bin/sake --dump=generated bin/rails.sake` shows what was generated. A class's own functions are written in Sake
next to its class body (`articles_controller.sake` beside `articles_controller.rb`).

Differences from Ruby on Rails that an application sees (each with its reason in the notes): `Article.build` for
`Article.new` (`new` is Sake's raw constructor), `build_with(params.to_hash)` for `new(params)`, a function's subject
first (`Article.save(article)`), `link_to view, ...` in Sake ERB, `<` copies a class's functions rather than
subclassing, no `super` (an overridden body is kept as `super_<name>`), callbacks named by Symbol.

## Tests

`test/sakelib/rails/<gem>/NAME.sake` (run with `--strict`) must print what `NAME.rb`, the same program on the real
Rails 8.1.3 gems, prints (`ruby -Ilib test/test_sakelib.rb`).

## Notes

`sakelib/notes/rails_*.md`: one per part of the port (activesupport A/B, activemodel, activerecord, arel,
actionpack dispatch, actioncontroller, actioncontroller with views, actionview, railties, its credentials and
generators): what was ported, how Rails' shapes map onto Sake, what was left out and why, and the bugs found
on the way. How the port was made, and how long a whole application takes to check (60 s on the blog), is in
[experiments/2026-10-20-rails-scale/](../../experiments/2026-10-20-rails-scale/README.md).
