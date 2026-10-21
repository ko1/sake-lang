# The Rails guide's blog on the Sake port of Rails 8.1.3 (railties, part 12)

Articles with comments, the scaffold's views in the application layout, validations, flash, and Rails 8's
`generate authentication` (User with has_secure_password, Session, Current, the Authentication concern,
SessionsController). Laid out as a Rails app; each class body that Rails runs is in a `.rb` file (for a model
without methods it is the very file Rails has: app/models/*.rb equal blog_rb's), each class's functions in `.sake`.

- `bin/sake --strict bin/rails.sake routes|about|middleware|db:schema:load|db:seed|db:migrate|server -b 127.0.0.1 -p N`
- `./run.sh`: a fresh database, the server (WEBrick) on 127.0.0.1 and a free port, `walk.sh` (26 requests with
  curl), the server stopped; `run.out` is a run. `../../../experiments/2026-10-20-rails-scale/blog_rb/run.sh` does the same on real Rails 8.1.3 (Puma).
  `diff ../../../experiments/2026-10-20-rails-scale/blog_rb/run.out run.out` (`../../../experiments/2026-10-20-rails-scale/walk.diff`): only the two 404 pages differ (Rails' development error page is
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

Check: `bin/sake -c --strict bin/rails.sake` **92 s, 1.0 GB** (two runs 91.8/93.9 s, max RSS 1,026/1,012 MB, local,
load 1.1-1.4; on branch rails-blog-check = main + checker-init-callee, whose checker no longer stops after a
construction). Orientation only: the measurement proper is to be made on sp4. The whole app is checked: an injected
`String.upcase(42)` in ArticlesController#show and in articles/show.html.erb are each reported. Nearly all the time
is the type checker (ruby ../../../experiments/2026-10-20-rails-scale/phases.rb: typer 114 s of 120 s; generate 2.8, resolve 3.8, lower 1.7); in it, a
stackprof sample puts 44% under Sake::Typer#struct_hooks, 10% struct_groups, 9% shape_key, 14% GC.
`./run.sh` now takes ~5.5 min: each of its three `--strict` runs checks the app first (its wait for the server was
raised from 60 s to 10 min, and it makes log/ and storage/, which git does not keep). run.out is unchanged.

Withdrawn: "18.7 s, 476 MB" (and before it 7 s). The checker stopped silently at ActionDispatch::Response.create
(and before that at the Configuration's initialize), so actions, views and the models' code reached from a request
were not analyzed; an injected `String.upcase(42)` said OK. Repros: ../../../experiments/2026-10-20-rails-scale/bugs/railties_initialize_call_ends_check.sake,
../../../experiments/2026-10-20-rails-scale/bugs/railties_response_create_ends_check.sake.

What the full check found (9 errors, all fixed; `rails-blog-check`):
- `@articles.each` in articles/index (`Relation.each(@articles)`, nil in the views of the controllers that never set
  it; any controller's view may render any template to the checker, and Ruby's nil.each raises): now
  `@articles || raise(ArgumentError, "@articles is not set")`, as the other templates already did for @article.
- `article_params` / `comment_params` (Parameters.to_hash of any parameter value): Rails' `expect(article: [...])`
  is a Parameters or raises, but a function's result is one type for every filter; the two say
  `ps => ActionController::Parameters` (../../../experiments/2026-10-20-rails-scale/bugs/blogcheck_expect_result_by_filter.sake).
- User's `password=` (`String.empty?` of any permitted scalar, from authenticate_by's `new(passwords)`): Rails raises
  NoMethodError for a value without empty? (JSON `"password": 5`); ActiveModel::SecurePassword.password_string does.
- AbstractController::Callbacks::ActionFilter#match? on a model (one container site for every class's callback
  chains: ../../../experiments/2026-10-20-rails-scale/bugs/blogcheck_callback_chain_shared.sake): raises NoMethodError unless the target is a controller, as
  Ruby's `controller.action_name` would.
- ActionDispatch::SSL#flag_cookies_as_secure! (String.match? of whatever a header value may be): Ruby's
  `Array(cookies)` and Regexp#match?, so a value other than a String, Symbol or nil is a TypeError.
Warnings left (not new; also in test/sakelib/rails/actionpack/controller_view's check): unused-rescue at
base64.sake:20 and param_builder.sake:34 (neither warns on its own: the order-dependent raise set of
../../../experiments/2026-10-20-rails-scale/bugs/actionpack_controller_unused_rescue_order, presumably), ipaddr.sake:247/257 (../../../experiments/2026-10-20-rails-scale/bugs/actionpack_dispatch_ipaddr_unused_rescue.sake),
cookies_encrypted.sake:88 (true of the port: its verify raises InvalidMessageFormat, not InvalidSignature; the
rescue list is Rails' EncryptedKeyRotatingCookieJar#parse's).
