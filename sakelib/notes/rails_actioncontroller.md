# rails_actioncontroller: ActionPack 8.1.3, part B: ActionController and AbstractController (2026-10-20)

AbstractController (Base, Callbacks, Rendering, Translation, Logger) and ActionController (Metal, Base, API and
their modules) on the committed ActionDispatch (`rails_actionpack_dispatch.md`) and ActiveSupport
(`rails_activesupport_{a,b}.md`). Under `sakelib/rails/actionpack/{abstract_controller,action_controller}/`; tests
in `test/sakelib/rails/actionpack/controller_*` (`ruby -Ilib test/test_sakelib.rb -n /rails_actionpack_controller_/`),
each `.sake` printing what its `.rb` prints on the real gem. Written by one agent with three forks (StrongParameters;
forgery protection, HTTP auth and ParamsWrapper; the log subscriber and six tests); their sections are below.

```ruby
require "rails/actionpack/action_controller"            # Base and API with every module ported
generate "rails/actionpack/action_controller/generate/controllers", "controllers_decl.rb", "app/controllers.sake"
set.ActionDispatch::Routing::RouteSet.controllers = ActionController::ControllerSet.new   # generated
```

## The shape: a controller class, its class body as data, and generated reflection

```ruby
# Ruby                                            # Sake
class PostsController < ApplicationController     class PostsController < ApplicationController
  before_action :set_post, only: [:show]            attr_reader post
  rescue_from NotFound, with: :not_found            def index(c) = render c, plain: "all posts"
  def index = render plain: "all posts"             def show(c) = render c, json: Hash.of("id" => @post)
  def show = render json: { "id" => @post }         def create(c) = redirect_to c, "/posts/1", status: :see_other
  def create = redirect_to "/posts/1",              # private
    status: :see_other                              def set_post(c) = @post = Kernel.to_s(Parameters.expect(params(c), :id))
  private                                         end
  def set_post = @post = params.expect(:id).to_s
end                                               # controllers_decl.rb (Ruby requires it; the generator reads it)
                                                  class PostsController < ApplicationController
                                                    before_action :set_post, only: [:show]
                                                    rescue_from NotFound, with: :not_found
                                                  end
```

- **The class hierarchy is Rails'**: `AbstractController::Base` (fields `_response_body`, `_action_name`,
  `_formats`), `ActionController::Metal < AbstractController::Base` (Rails' attr_internal state: `_request`,
  `_response`, `_params`, ...), `ActionController::Base < Metal` and `API < Metal` including the modules in
  Rails' order (the last included wins, as in Ruby). An app's `ApplicationController < ActionController::Base`
  pastes all of it; its own fields follow (`attr_reader post`). Rendering, redirecting, head, flash, ... are
  mixin functions with the controller first: `render c, json: post, status: :created`, `head c, :no_content`,
  `redirect_to c, url, notice: "Saved"` keep Rails' keywords (Sake keyword parameters).
- **The class body's lines** live in a Ruby file of class bodies, as ActiveSupport's generators do: `before_action`,
  `after_action`, `around_action`, `prepend_*`, `append_*`, `skip_*`, `rescue_from`, `protect_from_forgery`,
  `skip_forgery_protection`, `http_basic_authenticate_with`, `wrap_parameters`. Any other line (`helper_method`,
  `layout`, a block callback) is an error at the `generate` line naming the file and line.
- **What Ruby finds by reflection is generated** (`generate/controller.sake`, printed by `controller_generate.sake`):

| Ruby | Sake (generated per controller) |
|---|---|
| `self.class.name`, `controller_path`, `controller_name`, `_prefixes` | `_class_name(c)`, `controller_path(c)` ("admin/posts"), `controller_name(c)`, `_prefixes(c)` |
| `action_methods` (public instance methods minus internal ones) | the `def name(c)` of the class and its controller parents above a `# private` line (Sake has no `private def`); `new_` is the action "new" (`new` is Sake's constructor) |
| `send(action_name)` | `_send_action(c, name)`: a `case` over the actions (and "default_render") |
| `instance_variables - _protected_ivars` (view_assigns) | `view_assigns(c)` over `K.field_names` / `K.read_field`, the fields not starting with `_` |
| `PostsController.action(:index)` (a lambda) | `action(name)`: an `ActionEndpoint` (Rack::App and ActionDispatch::App) |
| `"posts".camelize.constantize` in the Dispatcher | `class ActionController::ControllerSet` (ActionDispatch's `Routing::Controllers`): `case "posts" then PostsController.dispatch(PostsController.new, action, req, make_response!(req))` |
| callbacks: the class body's lines on ActiveSupport::Callbacks | `__callbacks`, `__callback` (target.send), `__around_callback` (`wrap(t) { yield }`), `__class_callbacks` (the lines, in order, as calls of `AbstractController::Callbacks::ClassMethods.before_action(c, :set_post, {only: Any[:show]})`; a subclass starts from `inherit(Parent.__class_callbacks)`) |
| rescue_from | ActiveSupport::Rescuable::Generate's three functions (with the parents' handlers) |
| class attributes (forgery strategy, wrapper options, basic auth) | `generate/settings.sake` (fork A) |

  A namespaced controller's functions are written inside its modules (`module Admin` + `def PostsController.f`).
  Inputs: the class-body file(s) (.rb) and the controllers' Sake files (.sake).

### `super`: the modules' layers by name

Rails' `process_action`, `render`, `render_to_body`, `redirect_to`, `send_action` go through `super` across a dozen
modules. Sake has no super: an overridden body keeps a second name (`abstract_render`, `rendering_render_to_body`,
`redirecting_redirect_to`, `flash_redirect_to`, `basic_implicit_render_send_action`, ...) and the override calls the
layer below, as Ruby's ancestors would. Layers that wrap are block-taking functions, and Base writes the chain once,
in Rails' ancestor order:

```ruby
# Ruby: ParamsWrapper > Instrumentation > Rescue > Callbacks > Rendering > AbstractController::Base, each `super`
def process_action(c, method_name)                                     # action_controller/base.sake
  params_wrapper_process_action(c, method_name) do
    instrumentation_process_action(c, method_name) do
      rescue_process_action(c, method_name) do
        callbacks_process_action(c, method_name) do                     # run_callbacks(c, :process_action) { yield }
          rendering_process_action(c, method_name) { send_action(c, method_name) }
        end
      end
    end
  end
end
```

### Other shapes

| Rails | Sake |
|---|---|
| `ActionFilter` for `only:`/`except:` (`controller.action_name`) | `AbstractController::Callbacks::ActionFilter` includes `ActiveSupport::Callbacks::Conditionals::Filter`; it asks the controller through the Callbacks mixin (module dispatch) |
| the terminator lambda `->(c, l) { l.call; c.performed? }` | `terminator: :performed?` in `define_process_action` (Callbacks' `included do`) |
| `Renderers.add :json do \|json, options\| ... end` (define_method) | `_render_with_renderer(c, name, value, options)`: a `case` over :json, :js, :xml, :markdown |
| `respond_to do \|format\| format.html { }; format.json { } end` (blocks stored per format, the negotiated one called) | `respond_to(c, :html, :json) { \|format\| case format in :html then ... in :json then ... end }`: the formats are listed, the block is called once with the negotiated format's Symbol (a block cannot be stored) |
| `etag { flash if !flash.empty? }` (EtagWithFlash; class attribute of blocks) | `etaggers_values(c)`: the flash's, overridable |
| `Exception` rescue in Rescue#process_action | `rescue => e`; `rescue_with_handler` or re-raise |
| `exception.class.name` in payloads | ActiveSupport's `Notifications.class_name(e)` (Kernel.class_name is in lib/ now) |
| `mattr_accessor :raise_on_open_redirects` etc. | module functions over a `once` Hash with setters |
| `ActionNotFound#controller` (the object) | the class name (one field type for every controller) |
| `send_file` (Response#send_file streams a FileBody) | reads the file into the body |
| config_accessor :logger | `AbstractController::Logger.set_logger` |

## What is ported

Code lines = not blank and not comments. Ruby counts the whole file (a `partial:` header says what is out).

| Ruby (actionpack-8.1.3/lib/) | Sake (sakelib/rails/actionpack/) | Ruby | Sake |
|---|---|---:|---:|
| abstract_controller.rb | abstract_controller.sake | 29 | 6 |
| abstract_controller/base.rb (+ error.rb's Error, ActionNotFound) | abstract_controller/base.sake, error.sake | 132 | 47 |
| abstract_controller/callbacks.rb | abstract_controller/callbacks.sake | 90 | 110 |
| abstract_controller/rendering.rb | abstract_controller/rendering.sake | 81 | 43 |
| abstract_controller/logger.rb, action_controller/metal/logging.rb | abstract_controller/logger.sake | 21 | 10 |
| abstract_controller/translation.rb | abstract_controller/translation.sake | 25 | 25 |
| abstract_controller/url_for.rb, action_controller/metal/url_for.rb | action_controller/metal/url_for.sake | 57 | 30 |
| abstract_controller/collector.rb, metal/mime_responds.rb (no variants) | metal/mime_responds.sake | 129 | 47 |
| action_controller.rb | action_controller.sake | 61 | 3 |
| action_controller/metal.rb (no per-controller middleware) | action_controller/metal.sake | 166 | 75 |
| action_controller/base.rb | action_controller/base.sake | 101 | 81 |
| action_controller/api.rb, api/api_rendering.rb | action_controller/api.sake | 51 | 56 |
| metal/rendering.rb | metal/rendering.sake | 87 | 71 |
| metal/renderers.rb (no add/remove/use_renderers) | metal/renderers.sake | 98 | 47 |
| metal/head.rb | metal/head.sake | 39 | 32 |
| metal/redirecting.rb (no Proc, allowed_redirect_hosts, :notify) | metal/redirecting.sake | 145 | 129 |
| metal/conditional_get.rb, etag_with_flash.rb (no records, no etag blocks) | metal/conditional_get.sake | 79 | 62 |
| metal/implicit_render.rb, basic_implicit_render.rb | metal/implicit_render.sake | 43 | 43 |
| metal/data_streaming.rb | metal/data_streaming.sake | 43 | 52 |
| metal/instrumentation.rb | metal/instrumentation.sake | 80 | 74 |
| metal/rescue.rb, flash.rb, cookies.rb, default_headers.rb | rescue, flash, cookies, default_headers .sake | 83 | 62 |
| metal/strong_parameters.rb (fork) | metal/strong_parameters.sake | 578 | 497 |
| metal/request_forgery_protection.rb (fork A) | metal/request_forgery_protection.sake | 378 | 227 |
| metal/http_authentication.rb (Basic, Token; fork A) | metal/http_authentication.sake | 209 | 103 |
| metal/params_wrapper.rb (no model; fork A) | metal/params_wrapper.sake | 153 | 95 |
| log_subscriber.rb (fork B) | log_subscriber.sake | 89 | 78 |
| metal/exceptions.rb (written by the ActionDispatch part) | metal/exceptions.sake | 73 | 46 |
| **total** | | **~3,140** | **~2,150** |
| (Sake only) what ActionView answers the controller | metal/view_rendering.sake | | 10 |
| (Sake only) the generator: reflection, callbacks, settings, ControllerSet | generate/controller.sake, settings.sake, controllers.sake | | 335 |

AbstractController + ActionController's lib is ~4,800 code lines; ~3,140 are ported.

Tests (all print what the gem prints; `bin/sake -c --strict` time and memory, load 1-3):

| test | what | check |
|---|---|---|
| controller_base | two controllers through the routes: render plain/json/html (escaped)/body, status, redirect_to, head with headers, around/after/before with only/except/skip, halting with head, rescue_from, DoubleRenderError, implicit render (MissingExactTemplate for a browser, 204 for JSON), respond_to, fresh_when + 304, send_data | 3.0-3.3 s 148 MB |
| controller_api, controller_metal, controller_flash_cookies, controller_conditional_get, controller_redirecting, controller_log_subscriber | fork B's (below) | 2.6-4.0 s |
| controller_strong_parameters | the fork's (below) | 5.1 s 120 MB (the largest) |
| controller_http_authentication, controller_params_wrapper, controller_request_forgery_protection | fork A's (below) | 3.1-3.6 s |
| controller_generate | the generated source for controller_base, and the generator's errors (no .rb) | |

## Left out, and why

- (Third wave: templates, layouts, view_context, helper_method and ActionController::TestCase are ported now; see
  `rails_actioncontroller_view.md`. The two items below are the second wave's state.)
- **Templates.** ActionView is being ported by another part; its renderer and template handlers did not exist when
  this part was written (its renderer/ landed at the very end and is not wired in yet). `ViewRendering` (Sake only) answers
  `template_exists?` false, so `render :edit`/implicit template rendering is not reached; render plain/html/body/
  json and the 204/MissingExactTemplate paths are Rails'. The hooks for ActionView: `view_render_to_body`,
  `template_exists?`, `any_templates?`, `_prefixes`, `view_assigns`. Layouts (ActionView::Layouts) likewise.
- **ActionController::TestCase** (384 lines): not started (time).
- Helpers/helper_method, Caching and fragments, Streaming/Live, RateLimiting, AllowBrowser, ContentSecurityPolicy
  and PermissionsPolicy (the controller side), ParameterEncoding, FormBuilder, EtagWithTemplateDigest, Renderer
  (`ApplicationController.render` outside a request), structured_event_subscriber, the railtie, Digest auth.
- Block callbacks (`before_action { }`), callback objects, `add_renderer`, `etag { }`: no stored blocks.
- Per-class `config` (InheritableOptions): module-wide settings.

## Bugs found (repros in experiments/2026-10-20-rails-scale/bugs/)

- `actionpack_controller_include_lost_in_second_paste.sake`: in C < B < A with B including M, A's pasted function
  won over M's in C (ApplicationController ran AbstractController::Base#send_action: no implicit render). Fixed by
  the lead (23307e9a); Base's explicit overrides were then removed and the tests still pass.
- `actionpack_controller_unused_rescue_order/`: `unused-rescue` for a rescue whose body does raise the type
  (DoubleRenderError through RouteSet → generated ControllerSet → render), depending on which begin body is
  analyzed first; the same body in a function called later does not warn. Not fixed; the test uses `rescue => e`.
  Probably the same cause: `param_builder.sake:34` warns `rescue ArgumentError: never raises` in these tests only.
- (fork) `actionpack_controller_splat_and_double_splat.sake` (fixed in 23307e9a);
  (fork B) `actionpack_controller_generated_def_in_namespace.sake` (fixed in 23307e9a: the generator now writes
  `module Admin` + `def PostsController.f`), `actionpack_controller_required_stub_beats_pasted.sake`.
- (fork A) activesupport's messages/codec.sake used bare `JSON`, which is ActiveSupport::JSON once active_support/json
  is loaded (Base loads it for `render json:`): fixed in place (`::JSON`).

## Friction (what I wrote first → the message → what I wrote instead)

1. `AC::Base.process(PostsC.new(...))` in the first experiment → `AC::Base.set_action_name: argument 1 must be
   AC::Base, but is PostsC`: a class's functions are static (pasted, not inherited) → `PostsC.process(c)`. The
   framework never calls `Base.f(c)` for an app's controller; dispatch goes through a module (Callbacks,
   Routing::Controllers) or generated code.
2. `include Head` in ConditionalGet (Rails' Concern includes) → nine errors `` `include ActionController::Head` in
   ActionController::ConditionalGet: Head.head needs `response_body`, which ConditionalGet does not define `` → the
   module includes are Base's (and API's) instead. A module that includes a module must itself provide what that
   module calls, so Rails' Concern graph (ImplicitRender includes BasicImplicitRender, ActionController::UrlFor
   includes AbstractController::UrlFor includes Routing::UrlFor) is flattened into the class.
3. `module_function :make_response!` in `class Metal` → `module_function is only for modules` → a plain function
   of the class (`Metal.make_response!(req)`), which every controller then has (Rails' class method).
4. No `private def`: the generator would list `wrap`, `authenticate` as actions (and `_send_action` would call
   `wrap(c)` without its block) → a `# private` comment line, which the generator reads as Ruby's `private`.
   A comment with meaning is a smell; `private` for functions would be the real answer (a request).
5. Rails' `super` chains: twelve functions renamed per layer (`abstract_render`, `rendering_render`, ...). The
   chain is explicit and checked, but where a layer is missing (API has no Flash) the class must say so
   (`def flash_redirect_to(c, o, r) = redirecting_redirect_to(c, o, r)` in API).
6. `ActionDispatch::RouteSet.call(set, req)` → `undefined type or module ActionDispatch::RouteSet` with five
   suggestions → `ActionDispatch::App.call(set, req)` (the routes are an App).
7. `request/session.sake` names `ActionDispatch::Session::AbstractStore` without requiring it → `undefined type or
   module` when only flash.sake was required → metal.sake requires `middleware/session/abstract_store` first.
8. send_data's content type had `; charset=utf-8` where Rails has none: Rails sets the type, then
   `sending_file = true` (which drops the charset), then the type again; I had the two in the other order. The
   side-by-side output found it; nothing else would.
9. The unused-rescue warning above cost an hour of bisecting: eight variants of the same `begin` did not warn.

What read well: controller_base matched the gem on its second full run (the first difference was the paste bug,
found by the side-by-side output: 200 where Rails raised MissingExactTemplate). The callback chain from
ActiveSupport B carried before/after/around with only/except/skip unchanged, `performed?` as the terminator
included; `render c, json: x, status: :created` and `redirect_to c, url, notice: "Saved"` read as Rails. The
generated code is ordinary Sake: a misspelled `before_action :set_psot` is an undefined function at the `generate`
line before anything runs (Rails finds it at the first request).


## StrongParameters (fork)

### Ported

| Ruby (actionpack-8.1.3/lib/) | Sake (sakelib/rails/actionpack/) | Ruby code lines | Sake code lines |
|---|---|---:|---:|
| action_controller/metal/strong_parameters.rb (no DeepMergeable, deep_transform_keys, YAML hooks, Date/IO/UploadedFile scalars, DidYouMean) | action_controller/metal/strong_parameters.sake | 578 | 491 |

Test `controller_strong_parameters` (Sake 169 lines / Ruby 133; 103 output lines, identical to the real gem): new
and the lazy nested conversion as `inspect` shows it before and after a read, `[]` with Symbol and String keys,
keys/key?/dig (through Arrays)/fetch (default, block, missing), require (missing, empty, false, a list), permit with
scalars, `tags: []`, `prefs: {}`, `prefs: [:theme]`, Arrays of hashes (implicit and `[[:text]]`), numeric-key nested
attributes, multi-parameter keys (`published_at(1i)`), non-scalars dropped, String filters; to_h (and its
UnfilteredParameters), to_unsafe_h, to_hash, to_query; expect (a Hash, a scalar, two keys, an Array of hashes,
missing, wrong shape) and expect!; action_on_unpermitted_parameters :raise (one/many, controller/action always
permitted) and :log (the notification's keys and context), permit_all_parameters; permit!, slice, except, without,
compact, compact_blank, select, reject, transform_values/keys, merge (Hash and Parameters), reverse_merge, values,
each_pair, each_value, has_value?, values_at, empty?, ==, extract!, delete (with a block), deep_dup, []=, to_s,
extract_value, InvalidParameterKey. Every exception message is Rails'.
`bin/sake -c --strict controller_strong_parameters.sake`: **5.1 s, 120 MB** (3 runs 5.05-5.19 s, load ~1, on HEAD's lib/ because the working tree's lib/ was mid-edit); a program with one `Parameters.new` and the same requires checks in 1.4 s, 64 MB, so ~3.7 s is the permit/expect paths the test reaches (filters are `Any`, so every value is the union of all of them).

### Shapes

| Rails | Sake |
|---|---|
| `@parameters` is a HashWithIndifferentAccess; nested Hashes become Parameters when read (and are written back) | `parameters` is the Hash with String keys that HWIA holds (keys converted on the way in, deep); the same lazy conversion, so `inspect` matches Rails before and after a read; to_h/to_unsafe_h return `ActiveSupport::HashWithIndifferentAccess` |
| `params.require(:post).permit(:title, tags: [])` | `P.permit(P.require(params, :post), :title, tags: Any[])`: Rails' trailing Hash is Sake's `**nested` (`def permit(p, *filters, **nested)`), so the call keeps Rails' keywords; a Hash also works positionally |
| `params.expect(post: [:title, :body])` | `P.expect(params, post: Any[:title, :body])` (returns Parameters, an Array or a scalar, as Rails: narrow with `=> ActionController::Parameters`) |
| `prefs: {}`, `comments: [[:text]]` | `prefs: Hash.new`, `comments: Any[Any[:text]]` |
| `params[:post][:title]` | `include Indexable`: `params[:post]`, then (after `=> P`) `post[:title]` |
| `cattr_accessor :permit_all_parameters, :action_on_unpermitted_parameters, :always_permitted_parameters` | `P.permit_all_parameters` / `P.set_permit_all_parameters(v)` etc. over a `once` Hash |
| `ExpectedParameterMissing < ParameterMissing < KeyError` | both `< KeyError` (copies); `rescue ParameterMissing` does not catch ExpectedParameterMissing, `rescue KeyError` catches both |
| `PERMITTED_SCALAR_TYPES.any? { value.is_a?(type) }` | a `case ... in String \| Symbol \| nil \| Integer \| Float \| Rational \| true \| false \| Time` |
| `converted_arrays` (a Set compared by content) | a list compared by identity (the same effect: a written-back Array is not converted twice) |
| StrongParameters#params: `Parameters.new(request.parameters, {controller:, action:, request:, params: request.filtered_parameters})`; `params=` wraps a Hash | `Parameters.for_request(req, controller_class_name, action_name)`; `Parameters.coerce(value)`: for the controller's `params`/`params=` (the controller module keeps `@_params`) |
| `key.class` in InvalidParameterKey's message | a `case` naming the classes (`Parameters.class_name`) |

### Left out, and why

- DeepMergeable (`deep_merge`), `deep_transform_keys(!)`: rarely reached by an app's request path (time).
- YAML `init_with`/`encode_with`/hook_into_yaml_loading: no YAML object tags in Sake.
- Date, StringIO/IO and UploadedFile as permitted scalars: no multipart uploads in sakelib's Rack; Date would pull
  sakelib/date into every controller.
- `each_pair`/`each_value`/`transform_*` without a block (Enumerators), `hash`/`eql?` for Hash keys, DidYouMean corrections.
- `to_h { |k, v| }` with a block.

### Friction (what I wrote first → the message → what I wrote instead)

1. `def require(p, key)` worked as a definition (the 10-12 note said it cannot; that was a module_function), but the
   bare recursive call `require(p, k)` → `require must be a statement at the top level of a file` → `Parameters.require(p, k)`.
2. `HashWithIndifferentAccess.make(...)` inside `module ActionController` → `undefined type or module
   HashWithIndifferentAccess` → `ActiveSupport::HashWithIndifferentAccess` (Ruby finds it through `ActiveSupport`'s
   constant only because Rails writes the full name too; no surprise, but every call is long).
3. `Array.filter_map(Array.select(object) { |e| e in Parameters }) { |e| yield(e) }` (Rails' `grep(Parameters).filter_map`)
   → a page of `Parameters.parameters: argument 1 must be ActionController::Parameters, but can be nil | String | ...`
   at `keys(p)`, reached through 12 calls: select does not narrow the elements → an `Array.each` with
   `next unless e in Parameters`. Same for `each_nested_attribute`'s `yield(v) if Parameters.nested_attribute?(k, v)`
   (a predicate function does not narrow) → `(v in Parameters) && ...`. The "reached by" chain was what located it.
4. `keys(p)` with an Integer key in the test's `P.new(Hash.of(1 => "x"))` → `Regexp.match: argument 2 must be String,
   but can be Integer`: one test value widened the key type of every Parameters in the program → `Kernel.to_s(k)`.
   (Ruby would raise first; the checker cannot know the constructor raises for that Hash.)
5. `expect!(p, *filters, **nested)` calling `expect(p, *filters, **nested)` → checked fine, then at run time
   `BUG: unknown node Sake::AST::Splat` → both public functions call `expect_filters(p, list)`. Repro below.
6. The Ruby side: real Parameters#deep_dup needs `require "active_support/core_ext/object/deep_dup"` (NoMethodError
   on HashWithIndifferentAccess without it); the test requires it.

What read well: Rails' `permit(:title, tags: [], prefs: {})` keeps its shape thanks to `**nested`; the whole
permit/expect algorithm is line for line, and the output matched the gem on the first run that type-checked (103
lines, inspect strings included).

### Bug

- `experiments/2026-10-20-rails-scale/bugs/actionpack_controller_splat_and_double_splat.sake`: passing a function's
  own `*rest` and `**opts` on in one call (`def f(*xs, **kw) = g(*xs, **kw)`) passes the checker and crashes the
  interpreter (`BUG: unknown node Sake::AST::Splat`, interpreter.rb:228). Each alone works.

## RequestForgeryProtection, HttpAuthentication, ParamsWrapper (fork A)

### Ported

Code lines = lines that are not blank or comments.

| Ruby (actionpack-8.1.3/lib/action_controller/) | Sake (sakelib/rails/actionpack/action_controller/) | Ruby | Sake |
|---|---|---:|---:|
| metal/request_forgery_protection.rb (no custom strategy/storage classes, no CookieStore token storage) | metal/request_forgery_protection.sake | 378 | 227 |
| metal/http_authentication.rb (Basic and Token; no Digest, 88 of the 209 lines) | metal/http_authentication.sake | 209 | 103 |
| metal/params_wrapper.rb (no model: name from the controller name, no attribute_names include) | metal/params_wrapper.sake | 153 | 95 |
| (Sake only) the class-body settings: protect_from_forgery, skip_forgery_protection, http_basic_authenticate_with, wrap_parameters | generate/settings.sake | | 89 |

Tests (each `.sake` prints what its `.rb` prints on the real gem, first full run after the checker was satisfied):

| test | what | `-c --strict` |
|---|---|---|
| controller_http_authentication | http_basic_authenticate_with with `except:`, wrong/right credentials, `authenticate_or_request_with_http_basic("Reports") { }`, a Bearer header on Basic, `authenticate_with_http_token { |token, options| }` with options, `request_http_token_authentication` with a quoted realm, Token/Basic `encode_credentials` | 3.14 s 137 MB |
| controller_params_wrapper | `wrap_parameters format: [:json]` inherited by a subclass, `:person, include:`, `exclude:`, `false`, a form body (not wrapped), a key already present, an API controller (Api::UsersController) wrapping a form body, with request_parameters | 3.33 s 138 MB |
| controller_request_forgery_protection | over Cookies + CookieStore + Flash: :exception without token / with the masked token as a param / as X-CSRF-Token / a fresh token / an old one / another session's / malformed / short / the raw token; the cross-origin JavaScript check (and XHR); skip_forgery_protection only: on a subclass; :null_session (the session is empty for the request, no cookie written); :reset_session; the invalid-strategy message | 3.64 s 157 MB |

### Shapes

| Ruby | Sake |
|---|---|
| `protect_from_forgery with: :exception` sets `config.forgery_protection_strategy = ProtectionMethods::Exception` and runs `before_action :verify_authenticity_token, options` + `append_after_action :verify_same_origin_request` | `Settings.expand` adds the two callback lines to the class body (with the callback keys of the options, `prepend: false` as Rails' reverse_merge), and `class_source` writes `def K.__forgery_protection_strategy = (storage_strategy(:session) && protection_method(:exception))` (a subclass: its parent's) |
| `forgery_protection_strategy.new(self).handle_unverified_request` (three classes) | `handle_unverified_request(c)`: a `case` over :exception, :reset_session, :null_session |
| NullSession: `request.session = NullSessionHash.new(request)` (a Rack SessionHash subclass, enabled? false) | `Session.new(nil, req, delegate: Hash.new, loaded: true, exists: true, enabled: true)` (private fields by keyword) + `skip: true` options; the jar is a new empty CookieJar |
| `SessionStore.new` / `CookieStore.new(:csrf_token)` objects with fetch/store/reset | `csrf_token_fetch/store/reset(c, req)` on the session; `store: :cookie` raises (the encrypted jar is not ported) |
| the token committed by the session middleware: `req.commit_csrf_token` → `controller_instance.commit_csrf_token(self)` | Sake's Request has no controller instance: Base#dispatch calls `commit_csrf_token(c, req)` after the action (before the middleware writes the session); Base#reset_session calls reset_csrf_token as Request#reset_session does |
| `request.env["action_controller.csrf_token"]` | the same key with Request.get_header/set_header (Sake's env holds Strings, and the token is one) |
| `http_basic_authenticate_with name:, password:, except: :x` = `before_action(options) { http_basic_authenticate_or_request_with(...) }` (a block callback) | the block is a generated function named after its line, `def K._http_basic_authenticate_3(c) = http_basic_authenticate_or_request_with(c, name: "dhh", password: "secret", realm: nil)`, and `before_action :_http_basic_authenticate_3, except: :open` is added to the chain |
| `authenticate_or_request_with_http_basic { |name, password| ... }` (the login procedure is a block passed down to Basic.authenticate) | the same blocks, passed down by `{ |n, p| yield(n, p) }` |
| `Basic.authentication_request(controller, realm, message)`, a module function calling `controller.headers`/`status=`/`response_body=` | a controller function `basic_authentication_request(c, ...)` (likewise Token's): a module function could call the controller only through a module every controller includes |
| `Token.token_and_options` returns `[token, Hash[params].with_indifferent_access]` | the options are an ActiveSupport::HashWithIndifferentAccess (`options[:scope]`) |
| `class_attribute :_wrapper_options` holding `Options < Struct(..., :klass, :model)`, `inherited` copying it with the subclass as klass | generated `def K.__wrapper_options = once { ParamsWrapper::ClassMethods.wrap_parameters(Parent.__wrapper_options, "posts", {format: Any[:json]}) }` or `inherit(Parent..., "comments")`; klass is the controller name |

### Left out, and why

- **Digest authentication** (88 Ruby lines): not done (time); it needs MD5 nonces over secret_key_base, which the built-ins now have.
- **Per-class forgery config** (`allow_forgery_protection`, `per_form_csrf_tokens`, `forgery_protection_origin_check`, `log_warning_on_csrf_failure` are `config` per class in Rails): one module-wide setting each (`RequestForgeryProtection.set_per_form_csrf_tokens(true)`); custom strategy and storage classes (`with: MyStrategy`, `store: MyStore.new`): no class values. The cookie token storage (`store: :cookie`) needs the encrypted cookie jar (no MessageEncryptor in ActiveSupport yet).
- **NullCookieJar** (a CookieJar whose `write` does nothing): the null session's jar is an empty CookieJar, so a cookie the action sets after the failed check is still written (Rails drops it).
- **ParamsWrapper with a model** (`wrap_parameters Person`, the default include from `attribute_names`, stored attributes, aliases, nested attributes; `_default_wrap_model`'s constantize): needs ActiveModel types the controller can name; the wrapped key is `controller_name.singularize`, Rails' fallback without a model.
- `helper_method :form_authenticity_token` (views): the view part's.

### Changes to shared files (outside the three new files)

- `action_controller/base.sake`: requires and includes (AbstractController::Translation after AbstractController::Rendering, at the translation part's request; RequestForgeryProtection after Flash; Basic and Token ControllerMethods after DataStreaming; ParamsWrapper last), the field `_marked_for_same_origin_verification`, the `params_wrapper_process_action` layer outermost in process_action, `dispatch` (with commit_csrf_token) and `reset_session`.
- `action_controller/api.sake`: ParamsWrapper (require, include, the outermost layer).
- `action_controller/generate/controller.sake`: `Settings.expand(b)` on every class body before the check of known calls; a scanned `def new_(c)` is the action "new" (it was the action "new_", so `GET /forms/new` was ActionNotFound); namespaced controllers were written through an alias `Api__UsersController = Api::UsersController` (see friction 2); since 23307e9a the generator writes them inside `module Api` instead.
- `generate/settings.sake`: the declarations above (it was a stub).
- `activesupport/active_support/messages/codec.sake`: `JSON.generate`/`JSON.parse` → `::JSON....` (bug, friction 1).

### Friction (what I wrote first → the message → what I wrote instead)

1. A test with the forgery protection, CookieStore and ActionController::Base → `messages/codec.sake:31: undefined function ActiveSupport::JSON.generate`: inside `module ActiveSupport`, a bare `JSON` is ActiveSupport::JSON as soon as active_support/json is loaded (Base loads it for `render json:`), and the codec had only been checked in programs without it → `::JSON`. The "shadowing is silent" lesson again, this time across parts: whether a name means the top-level module depends on what else the program requires.
2. The generator writing `def Api::UsersController._class_name(c)` → `syntax error: expected a delimiter to close the parameters` (reported at the `generate` line, many times over); then inside `module Api`, `def UsersController._class_name(c)` → `` `def UsersController._class_name` inside `Api`: write `def _class_name` (it defines Api._class_name) `` → a top-level alias `Api__UsersController = Api::UsersController` and `def Api__UsersController.f`, which works before the class is declared. A generator that may only write `def C.f` has no direct way to name a namespaced class.
3. `basic = ActionController::HttpAuthentication::Basic` in the test (to shorten calls) → `type ... cannot be used as a value` → a constant `Basic = ActionController::HttpAuthentication::Basic`, which is also Ruby's spelling.
4. The masked token's length: Ruby's `masked_token.length` is a byte count on a binary String; `String.bytesize` is what the port must use (no message: `String.size` would have been wrong only for non-ASCII bytes).

What read well: the three tests matched the gem on the first run after the checker was satisfied (the only output difference was in the Ruby twin: Rails' NullSession calls `request.flash=`, which exists only when ActionDispatch::Flash is loaded, so both stacks now have Flash). `http_basic_authenticate_with`'s block became a named generated function, and the callback chain treats it as any before_action (halting by `performed?`).

### Bugs

- (codec.sake's `JSON`, fixed in place; friction 1.)
- The ipaddr `unused-rescue` warnings (bugs/actionpack_dispatch_ipaddr_unused_rescue.sake) appear in controller_request_forgery_protection's check, because MiddlewareStack's build `case` reaches HostAuthorization.

## LogSubscriber and the tests of the core (fork B)

### Ported

| Ruby (actionpack-8.1.3/lib/) | Sake | Ruby code lines | Sake code lines |
|---|---|---:|---:|
| action_controller/log_subscriber.rb (no fragment-cache events, no verbose redirect source, no backtrace_cleaner) | action_controller/log_subscriber.sake | 89 | 78 |

Tests (each `.sake` prints what its `.rb` prints on the real gem; `bin/sake -c --strict` time and memory, load ~2.5):

| test | what | check |
|---|---|---|
| controller_api | ActionController::API: render json/plain/body with status, location, content_type; head; redirect_to with status; rescue_from; before_action with only/skip, after_action with if:; BasicImplicitRender's 204; params from query, path and a JSON body (`expect`) | 3.59 s 142 MB |
| controller_metal | a bare Metal subclass (response_body=, status=, content_type=, headers) and `K.action(:x)` called as a Rack app; the ActionNotFound message for a private method and an unknown action; controller_path/controller_name/action_methods/available_action? | 2.56 s 111 MB |
| controller_flash_cookies | behind Cookies + CookieStore + Flash: redirect_to notice:/alert:/flash:, the flash on the next request and gone after, flash.now, notice/alert readers, cookies[:x] = (with path/httponly), delete, the session counted by an after_action, reset_session | 4.00 s 153 MB |
| controller_conditional_get | fresh_when with weak/strong etag, last_modified, public, cache_control; 304s; stale? with both validators; EtagWithFlash; expires_in (with extras), expires_now, no_store, must_understand, http_cache_forever | 3.80 s 156 MB |
| controller_redirecting | redirect_to URL/path/url_for Hash (through the routes)/status in options; open redirects (allowed, denied, protocol-relative, raise_on_open_redirects); path-relative (:log, :raise); header-unsafe URL; `\r\n` stripped; nil; redirect_back(_or_to) with own/other referer; url_from | 3.38 s 135 MB |
| controller_log_subscriber | Processing by / Parameters / Completed (with Views) / Redirected to / Filter chain halted / rescue_from handled / Sent data / Unpermitted parameters, written to a log file; ms and the backtrace frame are replaced on both sides | 3.70 s 143 MB |

### Shapes

| Rails | Sake |
|---|---|
| `class LogSubscriber < ActiveSupport::LogSubscriber`, events found with public_methods, `attach_to :action_controller` at load | `include ActiveSupport::LogSubscriber` with `__events`/`__event` (a `case`), `ActionController::LogSubscriber.attach` called by the app |
| LogSubscriber#logger = ActionController::Base.logger | ActiveSupport::LogSubscriber's logger (the test sets both to the same logger, as railties does) |
| rescue_from_callback payload `exception:` the object (class, message, backtrace.first) | `[class name, message]`; the " - frame" part is empty |
| `send_data` → `render` (so Instrumentation measures it: "Views:" in Completed) | `render_with_options(c, action, options)`: the top of the render chain with a Hash, overridden by Instrumentation; `render(c, **options)` and send_data call it (a Hash cannot be passed on as `**`) |

### Left out

- ActionController::TestCase (test_case.rb): its `process` needs `@routes` to assign parameters (extra_keys,
  generated path) and swaps the request/response objects of a controller instance; not started (time).
- Namespaced controllers (`Admin::PostsController`): generated code cannot add functions to them (bug below), so
  controller_metal uses `AdminPostsController`.

### Bugs (repros in experiments/2026-10-20-rails-scale/bugs/)

- `actionpack_controller_generated_def_in_namespace.sake`: no way for generated source to add a function to
  `Admin::PostsController` (`def Admin::PostsController.f` is rejected; `def PostsController.f` inside `module Admin`
  is rejected; opening the class makes it the first one).
- `actionpack_controller_required_stub_beats_pasted.sake`: after the resolver change of ~20:40 (the fix of
  include_lost_in_second_paste?), a module's required stub (`def action_name(c) = raise(NotImplementedError)`) is
  not fulfilled by the function the class pasted from its parent; every controller test died with
  NotImplementedError in AbstractController::Callbacks#action_name. Worked around in callbacks.sake.
- Generator (generate/controller.sake, not changed by me): (1) a controller class with no public action writes
  `case method_name` with only `else` → `syntax error: expected a when or in clause after case` at the class line
  (ApiController); (2) a Metal controller gets the callback/rescue functions, which call `run_callbacks` that Metal
  has not (`undefined function run_callbacks`): controller_metal's HelloController includes Callbacks and Rescue.
- The transient `undefined function ActiveSupport::JSON.generate` in messages/codec.sake (`::JSON.generate`) came
  and went while lib/ was being edited; not reproduced.

### Friction (what I wrote first → the message → what I wrote instead)

1. A test helper `def request(set, ...)` at the top level (as controller_base has) → in controller_api
   `implicit_render.sake:24: wrong number of arguments for request (given 1, expected 3..4)`: ImplicitRender is
   included by no class in an API-only program, so its bare `request(c)` resolved to the test's function →
   `send_request`. A library module's bare call is captured by any program's top-level function of that name.
2. Metal's field `_routes` (Rails' @_routes) → at run time `argument 1 must be ActionDispatch::Routing::RouteSet, got
   nil` for `redirect_to action:`: the field's reader `_routes` silently won over ActionController::UrlFor#_routes
   (the shadowing lesson of the first wave, again) → field `_routes_set`.
3. `ActionDispatch::Flash::FlashHash.[]=(FlashHash.now(f), ...)` (wrong type: now is a FlashNow) → not reported by
   the checker; `TypeError: argument 1 must be ActionDispatch::Flash::FlashHash, got ActionDispatch::Flash::FlashNow`
   at run time → `FlashNow.[]=`.
4. EtagWithFlash: the flash's pairs from `Hash.to_a` → the etag differed: ActionDispatch's expand_cache_key matches
   `in Array`, and a pair is a Tuple, so it printed `["notice", "hi"]` instead of `notice/hi` → `Any[k, v]` pairs.
   An `in Array` pattern does not take Tuples; nothing warns.
5. `fresh_when` without a template, from a browser → MissingExactTemplate in both (Rails is right) → the test asks
   for JSON, where the implicit render is 204.
6. Ruby's Metal subclass with `include AbstractController::Callbacks` lists the modules' public methods
   (`run_callbacks`, `rescue_handlers=`, ...) as actions; Sake lists the class's own `def`s. The Ruby side
   intersects with the two actions.
7. Request inside `"#{payload[:context]}"`: Ruby's to_s is Object's (`#<ActionDispatch::Request:0x...>`), Sake's
   Request defines to_s as its inspect; the test normalizes it.

What read well: the six tests matched the gem after the fixes above, with no change to the parent's core except the
three listed; the flash, cookie, session and etag behaviour came from ActionDispatch's port unchanged.

### Changes to the parent's core files

- metal.sake: field `_routes` → `_routes_set` (url_for.sake's `@_routes` likewise).
- metal/conditional_get.sake: etaggers_values pushes the flash as `[k, v]` Arrays (Rails' cache key "notice/hi").
- metal/rendering.sake: `render_with_options(c, action, options)`; `render` calls it. metal/instrumentation.sake:
  its `render` became `render_with_options`. metal/data_streaming.sake: send_data calls `render_with_options`.
- abstract_controller/callbacks.sake: the three required stubs replaced by `callbacks_action_name`,
  `callbacks_available_action?`, `callbacks_class_name` (ActionFilter dispatches on them).
