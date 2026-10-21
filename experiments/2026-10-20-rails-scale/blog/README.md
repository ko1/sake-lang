# The Rails guide's blog on the Sake port of Rails 8.1.3 (railties, part 12)

Articles with comments, the scaffold's views in the application layout, validations, flash, and Rails 8's
`generate authentication` (User with has_secure_password, Session, Current, the Authentication concern,
SessionsController). Laid out as a Rails app; each class body that Rails runs is in a `.rb` file (for a model
without methods it is the very file Rails has: app/models/*.rb equal blog_rb's), each class's functions in `.sake`.

- `bin/sake --strict bin/rails.sake routes|about|middleware|db:schema:load|db:seed|db:migrate|server -b 127.0.0.1 -p N`
- `./run.sh`: a fresh database, the server (WEBrick) on 127.0.0.1 and a free port, `../walk.sh` (26 requests with
  curl), the server stopped; `run.out` is a run. `../blog_rb/run.sh` does the same on real Rails 8.1.3 (Puma).
  `diff ../blog_rb/run.out run.out` (`../walk.diff`): only the two 404 pages differ (Rails' development error page is
  HTML, the port's DebugExceptions answers text/plain).
- The boot: config/application.sake's `generate "generate"` runs config/generate.sake, which draws the routes and
  prints Rails::Generate.application (sakelib/rails/railties/rails/generate/application.sake); `bin/sake
  --dump=generated bin/rails.sake` shows the 3,100 generated lines; tmp/sake/controllers.rb is the controllers'
  class bodies with the concern's lines expanded.

Changes from what `rails new` + the generators wrote, in both apps (blog_rb has the same):
`allow_browser versions: :modern` (needs the useragent gem), `rate_limit` in SessionsController (needs Rails.cache and
a lambda), `normalizes :email_address` (a lambda), PasswordsController and its views and routes (need Action Mailer),
the guide's comments (CommentsController, _comment/_form, `has_many :comments`, validations), a nav in the layout.
Sake-side differences in form (each forced; see sakelib/notes/rails_railties.md): Sake ERB (`link_to view, ...`),
`Article.build` for `Article.new`, `build_with(params.to_hash)` for `new(params)`, the routes as a function of the
reopened Mapper, `Rails.application.configure(:development)` naming its environment, database.yml without YAML anchors,
the cookie chain `permanent.signed` for `signed.permanent`, migrations in Sake (db/migrate/*.sake), seeds as `def seed`.

Check: `bin/sake -c --strict bin/rails.sake` 18.7 s, 476 MB (two runs 18.7/19.3 s, local, load 0.5-0.8). **Not a
full check**: the checker stops silently at ActionDispatch::Response.create, so actions, views and the models' code
reached from a request are not analyzed (an injected `String.upcase(42)` in an action or a template still says OK);
repros in ../bugs/railties_initialize_call_ends_check.sake and ../bugs/railties_response_create_ends_check.sake.
