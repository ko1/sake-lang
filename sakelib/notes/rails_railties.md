# rails_railties: Railties 8.1.3 and the Rails guide's blog (fourth wave, part 12, 2026-10-20)

`railties-8.1.3/lib/rails/` as far as an app needs it, under `sakelib/rails/railties/`: Rails (env, root, logger),
Rails::Application with Engine's request path, the configuration (`config.*` of config/application and
config/environments, every framework's namespace with its Railtie defaults, `load_defaults` 5.0 to 8.1), the
initializers (Initializable with Ruby's before/after order; Bootstrap, the frameworks' railties, Engine's, Finisher),
the default middleware stack, Rails::Rack::Logger, Rails::HealthController, credentials (a fork:
`rails_railties_credentials.md`), the commands of `bin/rails` (server on Rackup/WEBrick, routes, about,
middleware, version, credentials:show, db:migrate/rollback/migrate:status/version/schema:load/schema:dump/seed/
setup/reset/drop), the generators (a fork: `rails_railties_generators.md`), and **the app's boot as one
generate step** (`rails/generate/application.sake`). Then the guide's blog (articles with comments, validations,
the scaffold's views in the application layout, flash, Rails 8's authentication generator with has_secure_password,
sessions and Current) in `examples/apps/rails_blog/`, and its Ruby twin made by the real
`rails new`/`rails generate` in `experiments/2026-10-20-rails-scale/blog_rb/`.

## The result

`examples/apps/rails_blog/walk.sh` walks a running server with curl (26 requests: sign-in failure and
success, the scaffold's CRUD with a failed validation, PATCH and DELETE through `_method`, nested comments, sign-out,
an unauthenticated delete, 404s), replacing CSRF tokens and the port. `examples/apps/rails_blog/run.sh` (WEBrick, `bin/sake --strict
bin/rails.sake server`) and `experiments/2026-10-20-rails-scale/blog_rb/run.sh` (Puma, `bin/rails server`) both start from `db:schema:load db:seed` on
127.0.0.1 and a free port and stop their server. **The two outputs are identical** (status, content-type,
location, and the whole body of every 2xx/3xx/422 response, with the development mode's
`<!-- BEGIN app/views/... -->` annotations) **except the two 404 pages**: Rails' development page is HTML
("Action Controller: Exception caught"), the port's DebugExceptions answers text/plain (its rescue templates are not
ported, actionpack's left-out list). `bin/sake bin/rails.sake routes` prints what `bin/rails routes` prints;
`about` and `middleware` print Rails' formats over the port's stack.

## Check time of the whole blog

`bin/sake -c --strict bin/rails.sake` checks the whole app (every gem, WEBrick, the 3,100 generated lines and the
app's own files) in **60.2 s and about 1.0 GB on sp4** (62.4/60.0/60.2 s, d6fd7ed9;
experiments/2026-10-20-rails-scale/README.md section 4). An injected `String.upcase(42)` in an action and in a
template is reported, so the check reaches the app.

**Withdrawn**: the figures first written here, 18.7 s / 476 MB and before that 7 s, were not whole-app checks. The
checker silently stopped at `ActionDispatch::Response.create` (and before that at the port's own Configuration's
initialize): a function that `initialize` passed the new instance to read its fields empty, so it "never
returned" and nothing after the `new` was analyzed (repros: `bugs/railties_initialize_call_ends_check.sake`,
`bugs/railties_response_create_ends_check.sake` under experiments/2026-10-20-rails-scale/). The checker was fixed
(04cea37b and the commits after it), and what the full check then found was fixed in the ports and the blog
(examples/apps/rails_blog/README.md).

## The shape

### The app's boot is one generate step

Ruby boots by running code: Zeitwerk autoloads app/, class bodies run `has_many`/`before_action`, routes define
helpers, templates compile on first render, `ActiveSupport.on_load` adds modules. Here `config/application.sake` has
`generate "generate"`, and `config/generate.sake` (written by `rails new`) draws the routes and prints
`Rails::Generate.application(root, set)`, which calls every gem's generator on the app's files:

| input | generator | output |
|---|---|---|
| db/schema.rb, app/models/*.rb (the Ruby class bodies; for a model with no methods, the very file Rails has) | ActiveRecord::Generate (with ActionView's record protocol as an on_load include) | the model classes, relations, attribute and association methods, callbacks, validators |
| app/models/*.rb `< ActiveSupport::CurrentAttributes` | ActiveSupport's class-attribute/callbacks/rescuable/current-attributes generators, Delegation for `delegate :user, to: :session` | Current's instance, defaults, delegation |
| the drawn RouteSet | Routing::Generate.url_helpers | `BlogUrlHelpers` |
| app/controllers/**/*.rb, concerns' `included do`/`class_methods do`, + Base's `protect_from_forgery with: :exception` | ActionController::Generate.source (the expanded bodies are written to tmp/sake/controllers.rb, so origins point at a readable file) | callbacks, rescue_from, actions, ControllerSet, helper_method |
| app/views/**/*.erb, controllers' fields | ActionView::Generate.view_class (+ annotate_rendered_view_with_filenames read from the environment's file) | `BlogView` with every template, plus config.action_view's settings as view functions |
| app/**/*.sake, db/migrate/*.sake, db/seeds.sake | printed with a `# sake-origin: FILE:N` per line (Ruby autoloads them) | the app's own code |
| config/application.sake's `module Blog; class Application < Rails::Application` | railties | `def Rails.application`, draw_routes, migrations (from the file names), load_schema, load_seed, `Rails.configure/config/routes/initialize!` |

### Ruby's class-level DSLs and their Sake form

```ruby
# Ruby                                              # Sake
module Blog                                         module Blog
  class Application < Rails::Application              class Application < Rails::Application   (the same; `<` pastes)
    config.load_defaults 8.1                          end
  end                                               end
end                                                 Rails.application.configure do |config|
                                                      config.Rails::Application::Configuration.load_defaults(8.1)
                                                    end
Rails.application.configure do                      Rails.application.configure(:development) do |config|
  config.enable_reloading = true                      config.Rails::Application::Configuration.enable_reloading = true
  config.action_controller.perform_caching = false    config.Rails::Application::Configuration.action_controller[:perform_caching] = false
end   (config/environments/development.rb)          end   (only the current environment's block runs: Ruby loads one file)
Rails.application.routes.draw do                    class ActionDispatch::Routing::Mapper
  resources :articles do                              def application_routes(map)
    resources :comments, only: [:create, :destroy]      resources map, :articles do
  end                                                     resources map, :comments, only: Any[:create, :destroy]
end                                                 ...
initializer "active_record.initialize_database" do  Initializable.add(list, :"active_record.initialize_database", :active_record)
  ...                                               + ActiveRecord::Railtie.run(config, name): a `case` over the names
end
```

`Rails.application.configure do ... end` reads as Ruby because the generated `def Rails.configure(app, env = nil, &b)`
forwards to the app's class: railties cannot name Blog::Application, so `Rails.application`, `configure`, `config`,
`routes`, `initialize!` are generated. Top-level statements run in require order, so config/environment.sake
requires application, environments/*, initializers/* and then calls `initialize!`, the order Ruby gets from its
initializers. The concern's `allow_unauthenticated_access only: %i[ new create ]` (a class method that calls
`skip_before_action`) is expanded by the boot generator from `class_methods do def m(**options)`, as
ActiveSupport::Concern would run it.

### Who can call the app

Rails::Application's functions are pasted into Blog::Application, so a railties module given the app (Bootstrap,
the Finisher, the railties) would be given a type it cannot name. They take the Configuration (one class), and what
needs the app is in Application itself (`run_initializer` runs the Finisher's session store, middleware stack and
routes reloader). The commands are a mixin Application includes (`Rails::Commands.invoke(Rails.application, ARGV)`
dispatches to Blog's copy). Middleware that ActionDispatch's `case` cannot name (Rails::Rack::Logger, the Executor)
are built by builders registered in MiddlewareStack (a `once` list of a Builder module's includers).

## What is ported

| Ruby (railties-8.1.3/lib/) | Sake (sakelib/rails/railties/) | Sake code lines |
|---|---|---:|
| rails.rb (partial) | rails.sake | 35 |
| rails/version.rb, gem_version.rb | rails/version.sake | 10 |
| rails/all.rb | rails/all.sake | 15 |
| rails/application.rb, engine.rb (partial) | rails/application.sake | 179 |
| rails/application/configuration.rb, engine/configuration.rb, railtie/configuration.rb, configuration.rb's MiddlewareStackProxy (partial) | rails/application/configuration.sake | 307 |
| rails/paths.rb (partial) | rails/paths.sake | 57 |
| rails/initializable.rb | rails/initializable.sake | 51 |
| rails/application/bootstrap.rb, finisher.rb (partial) | bootstrap.sake, finisher.sake | 49 + 29 |
| rails/application/default_middleware_stack.rb | default_middleware_stack.sake | 53 |
| rails/railtie.rb + engine's initializers; i18n_railtie.rb | rails/railtie.sake | 84 |
| rails/rack/logger.rb; actionpack middleware/executor.rb | rails/rack/logger.sake | 54 |
| rails/health_controller.rb | health_controller.sake (+ its class body .rb) | 24 |
| rails/commands.rb, command.rb, commands/{server,routes,about,middleware,version,credentials}, info.rb; activerecord databases.rake | rails/commands.sake | 174 |
| (Sake only) the app's boot | rails/generate/application.sake | 303 |
| application.rb credentials parts, credentials_command (fork) | rails/application/credentials.sake | 67 |
| generators (fork; see its notes) | rails/generators*.sake (12 files) | 913 |

`ruby coverage.rb` counts the railties tree as 5,302 Ruby lines read → 2,287 Sake lines (with the generators).
In the other gems' trees: the framework railties (`active_support/railtie.sake`, `active_model/railtie.sake`,
`active_record/railtie.sake`, `action_dispatch/railtie.sake`, `action_controller/railtie.sake`,
`action_view/railtie.sake`, ~180 lines), `active_support/environment_inquirer.sake`, and Rack's MethodOverride,
Head, ConditionalGet, ETag and Runtime on ActionDispatch's protocol (`action_dispatch/middleware/rack_middleware.sake`).

### Changed in the other gems (their tests: see the reply)

- actionpack: MiddlewareStack builds the Rack middleware and asks registered builders for other names; RemoteIp's
  proxies narrowed to IPAddr (the stack's args are one Array type for all middleware); HostAuthorization's
  sanitize_hosts raises for an unknown host type; ActionController's generator finds `helper_method`s in included
  modules (a concern's), and SakeClass records includes.
- activesupport: class_body.sake reads `%i[ a b ]` / `%w[ ]` (Rails' generators write them).
- activerecord: `update_with(r, hash)` and CollectionProxy `create_with_hash(p, hash)` (Ruby's `update(params)`,
  `comments.create(params)`); the fork added primary_abstract_class, has_secure_password, authenticate_by and the
  record protocol for views.
- actionview: `annotate_rendered_view_with_filenames` (the ERB handler's preamble/postamble), set by the generator.

## Left out, and why

- `bin/rails runner` (the code would have to be part of the program before it is checked), console, dbconsole, rake.
- Engines and plugins, autoloaders/Zeitwerk and reloading (Sake reads every file before the program runs; a code
  change needs a restart), the executor beyond resetting CurrentAttributes, Rails.cache (ActiveSupport::Cache is not
  ported), the error/event reporters, BroadcastLogger and log tags, `config.x`'s method_missing (it is an
  OrderedOptions read with `[]`), `Rails.application.config_for`, database.yml's ERB and YAML anchors (sakelib's YAML has
  neither: `rails new` writes each environment out), multiple databases.
- Middleware: Rack::Sendfile, ServerTiming, ActionableExceptions, Reloader, Callbacks, TempfileReaper, Rack::Lock/
  Cache, AssumeSSL, ActiveRecord's CheckPending (so `bin/rails middleware` lists 17 where Rails lists 26).
- In the blog: `allow_browser` (needs the useragent gem), `rate_limit` (needs Rails.cache and a lambda),
  `normalizes` (a lambda), PasswordsController (needs Action Mailer); the twin drops them too, as listed in
  `examples/apps/rails_blog/README.md`.
- A model generated but not migrated: the boot generator leaves it out (a warning) because its attributes come from
  db/schema.rb; its controller then fails the check until `db:migrate`. Ruby defines attributes lazily.

## Friction (what I wrote first → the message → what I wrote instead)

1. `def Blog::Application.hook(app)` in generated code → `syntax error: expected a delimiter to close the parameters`
   → `module Blog` + `def Application.hook(app)` (inside a module, `def C.f` defines Blog::C.f).
2. Railties' Bootstrap/Finisher/railtie modules taking `app` → (would be) "argument 1 must be Rails::Application,
   got Blog::Application": `<` is a paste, not a subtype → the modules take the Configuration, the app's own
   functions do the rest, the commands are a mixin.
3. `class Application` opened by application/configuration.sake (required first) → "the fields of
   Rails::Application are declared in its first `class Rails::Application`" → the sub-files require
   `../application` and rails/all.sake requires them after it.
4. `def enable_reloading=(c, value) = ...` → `a setter method cannot be defined in an endless method definition`
   (Ruby's rule) → block form.
5. `Array.push(h[:k] => Array, *xs)` → `unexpected * splat argument after a ** keyword splat` (`=>` in an argument
   list is a keyword pair) → a local and `if x in Array`.
6. Decl lines with a trailing comment (`before_action :x   # from Authentication`) → "a callback is a method name"
   → comments on lines of their own.
7. `Authentication` with required stubs `def cookies(c) = raise(NotImplementedError)` → at run time
   NotImplementedError: the module, included after Base's modules, wins over ActionController::Cookies' function
   (Ruby's MRO would too, if the module defined it) → no stubs: a mixin's bare call reaches the includer's function.
8. `@article = Article.new` (Rails' scaffold) → at run time "Indexable.[]: nil cannot be indexed": `new` is Sake's
   constructor (every field nil) → `Article.build`.
9. `Article.build(article_params(c))` → "wrong number of arguments (given 1, expected 0)": `build(**attributes)`;
   a Hash cannot be spread → `build_with(ActionController::Parameters.to_hash(...))`, and I added `update_with` and
   `create_with_hash` for `update(params)`, `comments.create(params)`. `to_h` gives a HashWithIndifferentAccess,
   which is not a Hash here → `to_hash`.
10. `cookies.signed.permanent[:session_id] = ...` → no `permanent` on the signed jar in the port →
    `PermanentCookieJar.signed(CookieJar.permanent(cookies(c)))` (the same cookie).
11. POST with `_method=patch` → "No route matches [PATCH]": the port's Request memoizes request_method, read by an
    earlier middleware → MethodOverride calls `set_request_method`.
12. Signing out did nothing → Current.session survived the request: Rails resets CurrentAttributes in the executor →
    an Executor middleware calling the generated `Rails.clear_current_attributes`.
13. Development hosts as Strings ("0.0.0.0/0") → 403 for everything → IPAddr, which then failed the check because
    IPAddr's include? was reached with Strings too (through the stack's shared args) → a Regexp of IP literals.
14. database.yml with `<<: *default` → "YAML::SyntaxError: mapping values are not allowed" → written out.
15. The check said OK in 7 s → it was not checking the app (above). The most expensive lesson: an "OK" needs an
    injected error to mean anything.

What read well: once it ran, the blog matched Rails byte for byte on the first comparison except the view settings
of load_defaults (button_to's `<button>`, hidden fields without autocomplete), the view annotations and two
middleware behaviors (method override, CurrentAttributes reset), each found by the diff and fixed in a few lines. The
gems' generators composed: models, Current, routes, controllers with a concern, views and Rails' own HealthController
came out of one generator program of 300 lines, and the routes table, the SQL and the HTML are Rails'.
