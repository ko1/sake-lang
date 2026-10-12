# A Rails-shaped framework in Sake (Track B, 2026-10-12)

Rails 8.1.3's names and behaviour, the part that makes a Rails app a Rails app, and the Rails guide's blog
(posts with comments, CRUD, validations, flash, a layout) on it, served by the real server (`Rackup::Handler::WEBrick`).

```
rails/
  active_support.sake    SafeBuffer (html_safe as a type), ERB::Util.h
  active_model.sake      ActiveModel::Name, Error, Errors, Model (validates presence/length, valid?, to_param, ...)
  active_record.sake     ActiveRecord::Base (all/find/find_by/where/order/build/create/save/update/destroy,
                         timestamps), Relation (where/order/find over an Array), Schema DSL, JSON table store
  action_dispatch.sake   RouteSet, Mapper (root, get/post/..., resources + nesting + only/except), recognize,
                         `rails routes` table
  action_controller.sake Base (process, before_action, render, redirect_to, head, flash, content_for, session),
                         Parameters (require_/permit/expect, params[:id]), Flash, session store
  action_view.sake       helpers: tag, content_tag, link_to, button_to, url_for, form_with + label/text_field/
                         text_area/hidden_field/password_field/submit, pluralize, dom_id,
                         distance_of_time_in_words, time_ago_in_words, raw, h
  rails.sake             Rails::Application (a Rack::App: MethodOverride, router, session, errors → 404/400, log)
  rails_generate.sake    bin/rails generate / routes, and the ERB → Sake template compiler
  blog/                  the app, laid out as a Rails app (see below)
  compare.rb/.sake       helper HTML, route helpers, routes table, model errors: identical output (67 lines)
  run.sh, run.out        the demo: the real server on 127.0.0.1:<free port>, curl through the scenario
```

```
blog/config/routes.sake  db/schema.sake  app/models/{application_record,post,comment}.sake
blog/app/controllers/{application,posts,comments}_controller.sake
blog/app/views/layouts/application.html.erb  app/views/posts/{index,show,new,edit,_form,_post}.html.erb
blog/app/views/comments/{_comment,_form}.html.erb
blog/bin/rails.sake (generate, routes)  bin/server.sake (rails server)  config/application.sake (the require list)
blog/test/requests.sake (the scenario through Rack::MockRequest, no server)
blog/tmp/generated/*.sake (written by bin/rails generate)
```

Run: `./run.sh` (prints the routes, generates, starts the server, 16 requests (restarting the server halfway), the database files, the server log,
stops the server; `run.out` is a run). `bin/sake --strict compare.sake` and `ruby compare.rb` print the same.

## The three Ruby mechanisms Rails stands on, and what each became

Rails is three things Sake does not have: blocks run with `instance_exec` on a DSL object, methods defined while
booting (`define_method`, `send`, templates compiled with `eval`), and code stored as data (`before_action :x`,
callbacks, `has_many` options). Each got one Sake shape:

| Ruby mechanism | Where Rails uses it | Sake shape |
|---|---|---|
| `routes.draw do ... end` (`instance_exec` on a Mapper); `Schema.define do ... end` | config/routes.rb, db/schema.rb | **a function of the DSL class.** The app reopens `ActionDispatch::Routing::Mapper` and writes `def draw(map)`; inside, `resources map, :posts do ... end` is a bare call of the Mapper's own function, as the Ruby block's bare calls are the Mapper's. The DSL object is the first argument instead of `self`. Same for `ActiveRecord::Schema.define(s)`. |
| `define_method` per named route; attribute methods from the table; `send(action_name)`; `const_get("PostsController")`; ERB compiled to a method with `eval` | url_helpers, models, AbstractController, the dispatcher, ActionView::Template | **a generation step**, `bin/sake bin/rails.sake generate`, writes these as Sake source into `tmp/generated/` (routes 30 lines, models 114, views 183, controllers 47), which `config/application.sake` requires. Rails does this at boot; Sake does it before the program exists, and then the checker checks the result, templates included. |
| `before_action :set_post, only: %i[...]`; `has_many :comments, dependent: :destroy`; `validates :title, presence: true` | controllers and models' class bodies | **a hook function the framework calls**, written by the app: `def before_action(c, action)` with a `case` over the actions, `def validate(post)` with `validates post, :title, {...}` lines, `def before_destroy(post)`, `def comments(post) = Comment.where({post_id: @id})`. Rails' declaration is data the framework interprets; here it is the code that declaration would run. |

The controller is also the view context: a template is compiled into a function of its controller class, so `@post`
in a template is the controller's field, as Rails' copied instance variables are. The helpers are a mixin
(`ActionView::Helpers`) that `ActionController::Base` includes, so `link_to "Show", post` is a bare call in the
template exactly as in Rails.

## Side by side

### config/routes

```ruby
# Rails                                         # Sake (blog/config/routes.sake)
Rails.application.routes.draw do                class ActionDispatch::Routing::Mapper
  resources :posts do                             def draw(map)
    resources :comments, only: [:create, :destroy]  resources map, :posts do
  end                                                 resources map, :comments, {only: Array[:create, :destroy]}
  root "posts#index"                                end
end                                                 root map, "posts#index"
                                                  end
                                                end
```

`bin/rails.sake routes` prints the same table as `rails routes` (checked in compare: same names, verbs, patterns,
order, column widths). Generated helpers: `def post_comment_path(post_id, id) = "/posts/#{_to_param(post_id)}/comments/#{_to_param(id)}"`,
and `polymorphic_path(record)` as a `case` over the resource models (`in Post`, `in [Post, Comment]`), which
`link_to "Show", post`, `button_to ..., [comment.post, comment]` and `form_with model:` use.

### a controller

```ruby
# Rails 8.1 scaffold                            # Sake (blog/app/controllers/posts_controller.sake)
class PostsController < ApplicationController   class PostsController < ApplicationController
                                                  attr_reader posts, post
  before_action :set_post,                        def before_action(c, action)
    only: %i[ show edit update destroy ]            case action
                                                    in :show | :edit | :update | :destroy then set_post(c)
                                                    else
                                                    end
                                                  end
  def index                                       def index(c)
    @posts = Post.all                               @posts = Post.order({created_at: :desc})
  end                                             end
  def new                                         def new_(c)
    @post = Post.new                                @post = Post.build
  end                                             end
  def create                                      def create(c)
    @post = Post.new(post_params)                   post = Post.build(post_params(c))
    if @post.save                                   @post = post
      redirect_to @post,                            if Post.save(post)
        notice: "Post was successfully created."      redirect_to c, post, {notice: "Post was successfully created."}
    else                                            else
      render :new, status: :unprocessable_content     render c, :new, {status: :unprocessable_content}
    end                                             end
  end                                             end
  private                                         # private
    def set_post                                  def set_post(c)
      @post = Post.find(params.expect(:id))         @post = Post.find(@params[:id])
    end                                           end
    def post_params                               def post_params(c) = ActionController::Parameters.expect(@params, {post: Array[:title, :body]})
      params.expect(post: [ :title, :body ])
    end
end                                             end
```

Differences, each forced: the controller is the first argument `c` and keyword options are a Record
(`{notice: ...}`); instance variables are declared fields; `new` is Sake's constructor, so the action is `new_` and
`Post.new(params)` is `Post.build(params)` (ActiveRecord 8.1 has `build` as an alias of `new`); `post.save` is
`Post.save(post)`. `post = ...; @post = post` instead of `@post = ...; @post.save`: a local keeps its type, while
`@post` read back is `Post|nil` to the checker (a field is narrowed only until the next call).

### a model

```ruby
# Rails                                         # Sake (blog/app/models/post.sake)
class Post < ApplicationRecord                  class Post
  has_many :comments, dependent: :destroy         def comments(post) = Comment.where({post_id: @id})
                                                  def before_destroy(post) = Enum.each(comments(post)) { |c| Comment.destroy(c) }
  validates :title, presence: true,               def validate(post)
    length: { minimum: 5 }                          validates post, :title, {presence: true, length: {minimum: 5}}
  validates :body, presence: true                   validates post, :body, {presence: true}
end                                               end
                                                end
```

`class Post < ApplicationRecord` with the columns is in `tmp/generated/models.sake`, written from `db/schema.sake`
(the first `class Post` declares the fields, so the model file can only add functions to it; a second `< ApplicationRecord`
is rejected: "`<` goes on the first `class Post`"). So, as in Rails, the model file does not list its columns.

### a template

```erb
<%# Rails: app/views/posts/index.html.erb %>     <%# Sake %>
<p style="color: green"><%= notice %></p>        <p style="color: green"><%= notice(view) %></p>
<% content_for :title, "Posts" %>                <% content_for view, :title, "Posts" %>
<% @posts.each do |post| %>                      <% Array.each(@posts) do |post| %>
  <%= render post %>                               <%= render post %>
  <%= link_to "Show this post", post %>            <%= link_to "Show this post", post %>
<% end %>                                        <% end %>
<%= link_to "New post", new_post_path %>         <%= link_to "New post", new_post_path %>

<%# posts/_form.html.erb %>
<%= form_with(model: post) do |form| %>          <%= form_with({model: post}) do |form| %>
  <% if post.errors.any? %>                        <% if ActiveModel::Errors.any?(Post.errors(post)) %>
    <% post.errors.each do |error| %>                <% ActiveModel::Errors.each(Post.errors(post)) do |error| %>
      <li><%= error.full_message %></li>               <li><%= ActiveModel::Error.full_message(error) %></li>
  <%= form.label :title, style: "display: block" %>  <%= label form, :title, {style: "display: block"} %>
  <%= form.text_field :title %>                    <%= text_field form, :title %>
```

Templates are Sake code inside ERB tags, compiled by `bin/rails generate` into functions (`def PostsController._view_posts_index(view)`,
partials into `ApplicationController`) and type-checked with the program. Three Rails forms are recognised by the compiler
and turned into calls: `render "form", post: @post` (the partial `posts/_form`, keyword locals), `render x` (the
partial named by x's class: `_render_object`, a `case` over the models), and the layout's bare `yield` (→ `yield(nil)`,
see friction). Partials declare their locals with Rails 7.1's strict-locals comment `<%# locals: (post:) -%>`,
which becomes the function's keyword parameters. Escaping is Rails': `<%= %>` escapes unless the value is an
`ActiveSupport::SafeBuffer`, which is a type here, so the checker knows which values are HTML. Statement tags alone on
a line take the line with them (Erubi's trim mode).

## Storage: why JSON files

Sake has no SQLite binding (no C extensions), so the choice was between a SQL subset written in Sake and records in
memory persisted to files. Rails apps write `where`/`order`/`find`, not SQL; a SQL layer would put a parser and a type
mapping in front of the same rows. So each model's table is a `Hash id => record` loaded on first use from
`db/<env>/<table>.json` (`DATABASE_DIR`) and written back after every change, under a Mutex. `run.sh` restarts the
server in the middle of the scenario and the posts and comments come back. ids are max+1 (Rails' SQLite tables are
AUTOINCREMENT and never reuse an id: a difference after deleting the last row).

## Compared with Rails (compare.rb / compare.sake, identical, 67 lines)

The `rails routes` table; `root_path`, `posts_path`, `new_post_path`, `post_path(1)`, `edit_post_path`, nested
`post_comments_path`, `post_comment_path`, `post_path(record)`, `polymorphic_path(record)` and
`polymorphic_path([post, comment])`; `content_tag` (escaped text, and a block giving a SafeBuffer), `tag.br`, `link_to`
(with options, with a record), `button_to` (with `method: :delete`, Rails 7+'s `<button>`), `pluralize` (incl.
person → people), `ERB::Util.h`, `dom_id` (persisted, new, with a prefix), `distance_of_time_in_words` over ten
distances (less than a minute … about 2 years, with the leap-day rule), `valid?`, `errors.count`,
`full_messages`, `full_messages_for`, `errors[:body]`, `errors.each` with `full_message`, and four `form_with`
forms (new record, persisted record → PATCH via `_method`, nested `[post, Comment.new]`, `url:` + `method: :get`).
The Ruby side uses ActionView/ActiveModel outside an app with the four `load_defaults 8.1` settings an app has
(form ids on, no remote forms, no utf8 input, button_to as `<button>`) and no forgery protection.

## What is missing, and why

- **CSRF** (`authenticity_token` in forms, `protect_from_forgery`): not done (time); the session exists, it is the
  usual HMAC that is missing (no HMAC in sakelib).
- **The session** is a server-side store keyed by a random cookie (Rails' default is the encrypted CookieStore: no
  cipher/HMAC built-in); it is lost when the server restarts.
- **respond_to / JSON** (`format.json`, jbuilder): not done (time). `render c, {json: s}` and `{plain: s}` exist.
- **Callbacks** other than `before_action` and `before_destroy` (`after_action`, `around_action`, `before_save`,
  ...): each would be one more hook function in the same shape; `skip_before_action` has no counterpart (a subclass
  writes its own `before_action`).
- **Associations** are the functions `has_many`/`belongs_to` would define, written by hand
  (`def comments(post) = Comment.where({post_id: @id})`); `@post.comments.create(...)`/`.build` (the foreign key set
  for you) is `Comment.build(...)` + `comment.Comment.post_id = ...`.
- **Validations**: presence and length; `uniqueness`, `format`, `numericality`, `allow_blank`, custom validators and
  i18n messages are missing. belongs_to's "must exist" is written in `Comment.validate`.
- **Querying** is eager over Arrays (a relation is an Array of records): `where` (equality), `order` (Symbol or
  `{col: :desc}`, several keys, nil first), `find`, `find_by`, `first`, `last`, `count`, `limit`. No lazy
  relation, no `includes`, no SQL fragments.
- **Migrations**: only the schema (as `db/schema.rb` after `db:migrate`).
- **Params**: `expect`, `require_` (+`permit`) for flat scalars; nested arrays/hashes in `permit` are not taken.
- **Views**: `link_to` with a block, `content_for?`, `data: {turbo_confirm: ...}` (nested option Hashes),
  `select`/`check_box`, collection-partial counters, layouts other than `application`, and `respond_to` are missing.
- **A twin Rails app** was not built; compare.rb covers the helper HTML exactly, and the scaffold/guide code is the
  reference for the controller and views.
- **Concurrency**: requests run one at a time (Rack::Lock's shape) because the session store and tables are shared
  plain Hashes.

## Friction (what I wrote first → the message → what I wrote instead)

1. `class ActiveRecord::Base` with `def to_param(r) = "#{@id}"` (the field comes from the model) → `ARBase has no field
   id` (a class is checked on its own; its subclasses' fields do not exist there) → the framework calls functions the
   generated model defines (`_id(r)`), declared as required functions (`raise NotImplementedError`) of a module
   `Base` includes. Rails' "the base class calls what the subclass will have" needs that module every time.
2. `def new(c)` (the `new` action) → `` `PostsController.new` is a built-in operation and cannot be redefined `` →
   `new_` (the generated `send_action` maps `:new` to it). Same reason: `Post.new(params)` → `Post.build(params)`.
3. `attr_accessor post` and the scaffold's `def set_post(c)` → `` `PostsController.set_post` is a built-in operation and
   cannot be redefined `` and `wrong number of arguments for PostsController.set_post (given 1, expected 2)`: Sake's
   writer for `post` is named `set_post`, the name of Rails' conventional callback → `attr_reader post` (the
   functions still write `@post`).
4. `def require(p, key)` in `ActionController::Parameters` → `require must be a statement at the top level of a file`
   → `require_` (`params.require(:post)` cannot keep its name; Rails 8's `expect` can and is what the scaffold uses).
5. `def initialize(es) = @errors = Error[] if @errors == nil` → rejected, with the hint that Ruby reads the `if` as a
   conditional definition → a `def ... end` body.
6. `def draw(map) = raise(NotImplementedError)` in the framework's `Mapper` class and `def draw(map)` in the app's
   routes → `ActionDispatch::Routing::Mapper.draw is already defined` (a class, unlike a module, cannot declare a
   function for later) → no declaration; the framework just calls `Mapper.draw`.
7. `in {presence: true}` → `only Record patterns that bind fields are supported` → `in {presence:}` then `if presence`.
   And `opts = {}` as a default → `` `{}` is an empty Record, not a Hash `` → `opts = nil`.
8. `ActiveRecord::Relation` as a class holding `records`, built in `Relation.where` → warnings `Comment.id: argument 1
   must be Comment, but can be Post ... [mixed]` with `CommentsController.comment holds Post`: one place that builds
   a class gives one field type, so Post and Comment relations met → relations are Arrays and `Relation` a module of
   functions over them. The hint chain made the cause clear; the fix lost Rails' `Post.where(...).order(...)` chain
   (it is `Post.where(...).ActiveRecord::Relation.order(...)`).
9. A generator bug the checker caught: `def Post._from_row(row)` with `@title = ...` → `Post.set_title: argument 1
   must be Post, but is Hash[...]` (`@x` is a field of the first argument, here the row) → `Post.set_title(r, v)`.
10. The layout's `<%= yield %>` with the block `{ |name| ... }` (for `yield :title`) → at run time `block takes 1
    parameter(s) but was given 0` (Sake's blocks are strict about arity, Ruby's are not) → the compiler turns a bare
    `yield` into `yield(nil)`.
11. `polymorphic_path` with `in Post` and `in [Post, Comment]` only → `case/in: no in branch matches nil | [nil | Post,
    Comment]` (from `form_with({model: [post, ...]})` where `post` may be nil) → an `in nil` branch with Rails' own
    message ("Nil location provided. Can't build URI.").
12. `SafeBuffer` with `def +(a, b)` → `Arithmetic.+: ActiveSupport::SafeBuffer does not include Arithmetic` with the
    exact fix as a hint → `include Arithmetic`.
13. `class Post < ApplicationRecord` in the model file after the generated one → `` `<` goes on the first `class Post` ``
    → the model file says `class Post`, and the generated file carries Rails' first line.
14. `ActionView::OutputBuffer.append(_buf, dom_id comment)` in generated code (a template's paren-less call inside an
    argument list) → parenthesize every template expression: `append(_buf, (dom_id comment))`, as Rails' compiled
    templates do.
15. The server's "Listening on ..." line never reached `run.sh`: stdout to a file is buffered (as in Ruby) →
    `IO.flush(IO.stdout)`.
16. `Time.utc(2026, 10, 12, 12, 0, 0)` → `wrong number of arguments for Time.utc (given 6, expected 1)` →
    `Time.new(2026, 10, 12, 12, 0, 0, "UTC")`.

What read well: paren-less calls (`link_to "Show this post", post`, `resources map, :posts do`, `validates post,
:title, {...}`) make templates, routes and validations look like Rails; `@params[:id]` and `@flash[:notice] = x` work
through `include Indexable`; option Records with `case opts in {notice:}` are Rails' option Hashes with a checked
shape; the generated code is ordinary Sake that the checker reads, so a template calling `Post.titel(post)` is
an error before the server starts (`undefined function Post.titel / hint: did you mean Post.title?`) where Rails finds
it on the first request. The message points at `tmp/generated/views.sake:95`, not at the template's line (the
function's comment names the .html.erb file); Rails' error page shows the template line.

### --strict

`bin/sake --strict -c test/requests.sake` (the whole app reached from requests): **8 reports, all `nil`**, all one
Rails idiom: an instance variable set by an earlier step (a `before_action`, or the action before the template) and
read later (`@post` in show/edit templates and `update`, `@posts` in index, `Post.created_at(post)` of a record that
might be unsaved). The checker cannot follow "before_action ran set_post, so @post is set". At the default level
(1) the app has none; compare.sake passes `--strict`. In Rails the same nil is a `NoMethodError` on the request.

## Built-ins Sake lacks (requests)

- **A class's fields as data**: `T.fields` (names) and a reader/writer by Symbol (`T.read_field(x, :title)`, typed as
  the union of the fields). Half of `models.sake` (`read_attribute_for_validation`, `_to_row`, `_from_row`) is that.
- **A supported generation step** (or compile-time macros): `bin/rails generate` writes Sake that a later program
  requires; nothing tells the checker that `tmp/generated/` is stale after a template changes (run.sh always
  regenerates). Rails' boot-time metaprogramming has no other honest translation.
- **HMAC / a cipher** (OpenSSL::HMAC, `ActiveSupport::MessageVerifier`): needed for Rails' cookie session store and
  CSRF tokens.
- `Time.utc(y, m, d, h, mi, s)` (and `Time.gm`).
- (Checker) a way to say "this field is set before this function runs" (Rails' before_action → action → template
  chain), or narrowing a field across a call when the callee does not write it; otherwise level 2 asks every template
  to check `@post`.

## Sizes

| | Rails 8.1.3 (lib/*.rb lines) | Sake |
|---|---|---|
| ActionPack (dispatch, controller) | 28,132 | action_dispatch 186 + action_controller 234 + rails 76 |
| ActionView | 19,780 | action_view 232 + template compiler (in rails_generate) ~110 |
| ActiveRecord | 67,692 | active_record 250 |
| ActiveModel | 8,655 | active_model 135 |
| ActiveSupport (used part) | — | active_support 39 (+ sakelib's inflector) |
| Railties (generators, commands) | 15,325 | rails_generate ~240 |
| **total** | ~140,000 | **1,362** |

The blog: 393 lines of Sake and ERB (controllers 103, models 43, views 137, routes 15, schema 29, config/bin 32,
test 34); the generator writes 374 more. The same app in Rails (scaffold + guide, without jbuilder) is roughly 250 lines; the
difference is the `Ruby:` comments, the declared fields, and the explicit `before_action`/`validate` bodies.
