# Rails generators (railties fork, part 12): `rails new` and `bin/rails generate` writing a Sake app

`rails new`, and `rails generate` for scaffold, model, migration, controller, resource, scaffold_controller, helper
and resource_route, ported from railties-8.1.3/lib/rails/generators/ and activerecord's
lib/rails/generators/active_record/. They write the app's files in the Sake layout of
experiments/2026-10-20-rails-scale/blog/: config/*.sake, a model's class body as Rails writes it
(app/models/article.rb, which the boot generator reads), Sake migrations, a controller as its class body
(articles_controller.rb: `before_action` lines) plus its actions (articles_controller.sake), helpers as Sake
modules, and the scaffold's views in Sake ERB. Logs are Thor's (`      create    app/models/article.rb`), in Rails'
order.

```
bin/sake --strict sakelib/rails/railties/rails/generators/cli.sake new my_blog
cd my_blog
bin/sake --strict ../sakelib/rails/railties/rails/generators/cli.sake generate migration CreateArticles title:string body:text
bin/sake --strict bin/rails.sake db:migrate
bin/sake --strict ../sakelib/rails/railties/rails/generators/cli.sake generate scaffold Article title:string body:text --no-migration
bin/sake -c --strict bin/rails.sake        # the whole app checks
```

`generate` is a separate program (cli.sake, on sakelib/thor.sake: `new`, `generate`/`g`, `--force`,
`--[no-]migration`, `--destination`): generating needs no booted app here, and `bin/rails.sake generate` would
first check the whole app (about 7 s), which the generated files may not satisfy yet.

## Tests

| test | what | check (`bin/sake -c --strict`) |
|---|---|---|
| railties/generators (with .rb) | scaffold, model with references, add_/remove_ migrations with an index, controller with actions, resource, model with `password:digest` and `:uniq`; the log, the files written and the model files, against `Rails::Generators.invoke` on the real gems in a temp app. The extensions .rb and .sake are dropped in both outputs and a repeated line is dropped (a controller is one .rb in Rails, a .rb and a .sake here); migration numbers are TIMESTAMP | 1.1 s, 59 MB |
| railties/generators_app (no twin) | `new` (its log and config/application.sake), a migration, `db:migrate` (a separate `bin/sake`), `scaffold --no-migration`, the generated Sake files, then `bin/sake -c --strict bin/rails.sake` of the generated app (OK) and `bin/rails.sake routes` | runs in about 21 s (three runs of the app: each checks it, about 7 s) |

cli.sake itself checks in 1.2 s (68 MB). The new app (no models) checks in 6.8 s; with the scaffold, 6.9 s.

## What is ported

| Ruby (8.1.3) | Sake | Ruby code lines | Sake code lines |
|---|---|---:|---:|
| railties generators/base.rb, actions.rb (route), thor actions/create_file.rb, empty_directory.rb, shell say_status | generators/base.sake | 587 (≈90 used) | 76 |
| generators/generated_attribute.rb | generators/generated_attribute.sake | 224 | 106 |
| generators/named_base.rb, resource_helpers.rb, model_helpers.rb | generators/named_base.sake | 282 (≈60 used) | 25 |
| generators/migration.rb, activerecord generators/active_record/migration.rb | generators/migration.sake | 87 | 29 |
| activerecord migration/migration_generator.rb + its two templates | activerecord/rails/generators/active_record/migration_generator.sake | 134 | 81 |
| activerecord model/model_generator.rb + model.rb.tt | activerecord/rails/generators/active_record/model_generator.sake | 91 | 36 |
| generators.rb, commands/generate/generate_command.rb | rails/generators.sake | 263 (≈30 used) | 26 |
| rails/model, rails/resource, rails/scaffold generators | generators/rails/model_generator.sake (three small files: each is its parent plus hooks) | 46 | 31 |
| rails/scaffold_controller generator + controller.rb.tt | generators/rails/scaffold_controller_generator.sake | 86 | 68 |
| erb/scaffold generator + its six templates | generators/erb/scaffold_generator.sake | 109 | 126 |
| rails/controller generator + template, erb/controller generator + template | generators/rails/controller_generator.sake | 63 | 39 |
| rails/helper generator + template | generators/rails/helper_generator.sake | 19 | 13 |
| rails/resource_route generator | generators/rails/resource_route_generator.sake | 10 | 13 |
| rails/app/app_generator.rb, app_base.rb, app_name.rb + the templates the Sake app has | generators/rails/app_generator.sake (+ templates/public, templates/config/locales/en.yml copied) | 1,182 (≈150 apply) | 207 |
| (Sake only) the command line | generators/cli.sake | | 37 |

About 1,100 Ruby code lines that apply (generators and templates) → 913 Sake code lines.

## The shape

- **A generator is a module with `run(g, ...)`.** Ruby's generator is a Thor::Group subclass whose public methods
  run in definition order, and `hook_for :orm`/`:template_engine` invokes another generator class found by name.
  Sake has neither class values nor reflection, so the hooks are explicit calls in Rails' order, inside
  `Base.invoke(g, "erb") { ... }` (which prints `invoke  erb`, indents, and runs each name once, as Thor's
  invocations do: scaffold's second `invoke resource_route` prints the line and does nothing, as Rails'). `g`
  (Rails::Generators::Base) holds what Thor's instance holds: destination_root, the shell's padding, --force,
  the last migration number.
- **Templates are heredocs.** Rails' .tt files are ERB run with the generator as `self`; here each is a function
  returning a `<<~SAKE` (or `<<~ERB`) heredoc with `#{}`. For the views that means ERB inside a Sake heredoc
  without Rails' `<%%` escaping, which reads better than the .tt.
- **The Sake forms written:**

  ```ruby
  # Ruby (scaffold_controller/templates/controller.rb.tt)     # Sake (articles_controller.sake)
  @article = Article.new(article_params)                       article = Article.build_with(ActionController::Parameters.to_hash(article_params(c)))
  if @article.save                                             @article = article
                                                               if Article.save(article)
  params.expect(article: [ :title, :body ])                    ActionController::Parameters.expect(params(c), article: Any[:title, :body])
  t.references :article, null: false, foreign_key: true        T.references(t, :article, Hash.of(null: false, foreign_key: true))
  route "resources :articles"                                  `resources map, :articles` after `def application_routes(map)` (the log shows Ruby's line)
  ```
- **Migration numbers** are Rails': the larger of `Time.now.utc` (`%Y%m%d%H%M%S`) and the last number + 1, so
  migrations made in the same second are consecutive; a second migration of the same name is Rails' error.
- **Credentials in `new`** are Rails': a new master key (EncryptedFile.generate_key) and config/credentials.yml.enc
  with Rails' template and a new secret_key_base, through the credentials fork's EncryptedConfiguration.

## Left out

- Namespaced names (`Admin::Post`: class_path), `destroy`/revoke, --pretend, --skip, prompts on a conflict (a
  different existing file is skipped; --force overwrites), templates from lib/templates.
- The test_unit/system test hooks (tests are not generated), jbuilder, the API controller (--api), join-table
  migrations, `--parent`/`--database` models, `authentication` (the blog's was written by hand from Rails' output),
  `generator`, `job`, `mailer`, `channel`, `benchmark`, `task`, `integration_test`, `devcontainer`.
- `rails new`'s Gemfile, Rakefile, config.ru, bin/setup/dev/ci, Dockerfile, .gitignore, PWA views, and
  `allow_browser versions: :modern` in ApplicationController (not ported in actionpack), the content_security_policy
  and inflections initializers (Rails writes them all-comment).
- GeneratedAttribute's dangerous_name? check (it asks a loaded ActiveRecord::Base).

## Found on the way (for the lead; not in my files)

- **A scaffold cannot be migrated before the app checks.** `generate scaffold` then `bin/rails.sake db:migrate`
  fails at the boot generator: "app/models/article.rb:1: Article's table articles is not in the schema"
  (active_record/generate/model.sake:155), because db:migrate is part of the program that is checked, and the
  model's attribute methods come from db/schema.rb. Rails defines them on first use. The tests go around it
  (migration, db:migrate, then `scaffold --no-migration`); the boot generator could skip (or generate without
  attributes) a model whose table is not in the schema yet.

## Friction (what I wrote first → the message → what I wrote instead)

1. `def generate(name, args)` in the test, called `generate("scaffold", ...)` → "generate takes string literals,
   as in `generate "gen", "arg"`": `generate` at the top level is the code-generation statement, even as a call
   with parentheses → `run_generator`. A reserved word with no reserved look.
2. `DIR = Dir.mktmpdir` (the Ruby test's constant) → "Sake has no value constants ... define a function instead"
   → a local `dir` passed around; the Ruby twin keeps `DIR` for its class body and uses `dir` elsewhere.
3. `a = Rails::Generators::GeneratedAttribute` then `a.reference?(x)` (a short name for a long namespace) → a
   namespace is not a value → a module-level alias `A = Rails::Generators::GeneratedAttribute` (allowed: a
   constant may name a type). `b = Base` in the app generator, the same.
4. GeneratedAttribute's class method `reference?(type)` and instance method `reference?` → one name is one
   function in Sake, and both take one argument → `reference_type?(type)` for the class's.
5. `Open3.capture2e(sake, ..., chdir: root)` → "Open3.capture2e takes no keyword arguments" →
   `Open3.capture2e("sh", "-c", "cd #{root} && ...")`.
6. `Erb::ScaffoldGenerator.run` from `Rails::Generators` → "undefined type or module `Erb::ScaffoldGenerator`;
   did you mean `Erb::Generators::ScaffoldGenerator`?" (Ruby's constant lookup would not find it either; the hint
   was exactly right).

What read well: the Ruby twin and the Sake test printed the same 98 lines on the first run that checked; the
generated app checked on its first try (both the empty `new` app and the scaffolded one), so the templates had to
be right only once, and the checker is what told me so (a misspelled helper in a generated view would be a check
error at the .erb line).
