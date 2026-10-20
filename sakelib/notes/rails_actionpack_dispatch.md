# rails_actionpack_dispatch: ActionPack 8.1.3, part A: ActionDispatch (2026-10-20)

ActionDispatch on sakelib/rack.sake (Rack 3): Journey (the router: scanner, parser, nodes, visitors, patterns, the
GTG transition table, recognize and generate), routing (the Mapper DSL, RouteSet, url_for, named route helpers as
generated code, polymorphic routes, redirects, `rails routes`), `http/` (Request, Response, Headers, Mime types and
negotiation, parameters, URL, filter_parameters), the middleware (stack, cookies, CookieStore sessions, flash,
show/debug/public exceptions, static, request_id, remote_ip, host authorization, SSL) and `testing/` (integration
sessions and assertions; see its section). Under `sakelib/rails/actionpack/action_dispatch/`; tests in
`test/sakelib/rails/actionpack/` (`ruby -Ilib test/test_sakelib.rb -n /rails_actionpack_/`), each `.sake` printing
what its `.rb` prints on the real gem.

```ruby
require "rails/actionpack/action_dispatch/routing"            # RouteSet, Mapper, url_for, inspector (+ journey, http/request)
require "rails/actionpack/action_dispatch/routing/polymorphic_routes"   # needs a record type (PolymorphicRoutes::Model)
require "rails/actionpack/action_dispatch/middleware/stack"   # MiddlewareStack and every middleware
```

ActionController is a later part: `action_controller/metal/exceptions.sake` (all of Rails' file) is here because
routing and http/ raise its exceptions first. Written by one agent with three forks (http/, middleware/,
testing/); the per-area sections below keep who found what.

## The one decision everything else follows: the Request goes down the stack

Rails keeps a request's state in the Rack env (`env["action_dispatch.request.path_parameters"]`, the cookie jar,
the session, the flash), and every middleware makes its own `ActionDispatch::Request.new(env)` that sees it. Sake's
Rack env is a Hash of String => String (sakelib/rack.sake), so the state is fields of `ActionDispatch::Request`
(one private field per env key, the key in its comment) and the one Request is passed down: a middleware or
endpoint includes `ActionDispatch::App` and defines `call(app, req)` returning Rack's triple (app.sake).
`ActionDispatch::RackApp` is the Rack app in front (it makes the Request from the env, as RouteSet#call and every
middleware do in Rails); a mounted Rack app gets `Request.env(req)`. `class Request < Rack::Request` pastes Rack's
request, which is Rails' `include Rack::Request::Helpers`. The app's `env_config` (secret_key_base, cookie salts,
parameter filters, show_exceptions) is `Request.env_config(req)`, a Hash with Rails' key names.

## What is ported

Code lines = lines that are not blank or comments. The Ruby column counts the whole Ruby file (a `partial:` header
says what is left out). Journey and routing:

| Ruby (actionpack-8.1.3/lib/) | Sake (sakelib/rails/actionpack/) | Ruby | Sake |
|---|---|---:|---:|
| action_dispatch/journey/scanner.rb | action_dispatch/journey/scanner.sake | 60 | 67 |
| action_dispatch/journey/parser.rb | action_dispatch/journey/parser.sake | 86 | 66 |
| action_dispatch/journey/nodes/node.rb | action_dispatch/journey/nodes/node.sake | 157 | 123 |
| action_dispatch/journey/visitors.rb (no Dot) | action_dispatch/journey/visitors.sake | 219 | 98 |
| action_dispatch/journey/path/pattern.rb | action_dispatch/journey/path/pattern.sake | 160 | 105 |
| action_dispatch/journey/route.rb | action_dispatch/journey/route.sake | 153 | 103 |
| action_dispatch/journey/routes.rb | action_dispatch/journey/routes.sake | 70 | 47 |
| action_dispatch/journey/router.rb | action_dispatch/journey/router.sake | 99 | 76 |
| action_dispatch/journey/router/utils.rb | action_dispatch/journey/router/utils.sake | 65 | 36 |
| action_dispatch/journey/formatter.rb | action_dispatch/journey/formatter.sake | 176 | 149 |
| action_dispatch/journey/gtg/builder.rb | action_dispatch/journey/gtg/builder.sake | 125 | 155 |
| action_dispatch/journey/gtg/transition_table.rb (no visualizer) | action_dispatch/journey/gtg/transition_table.sake | 159 | 62 |
| action_dispatch/journey/gtg/simulator.rb | action_dispatch/journey/gtg/simulator.sake | 55 | 46 |
| action_dispatch/journey.rb | action_dispatch/journey.sake | 3 | 5 |
| action_dispatch/routing/mapper.rb | action_dispatch/routing/mapper.sake | 1354 | 907 |
| action_dispatch/routing/route_set.rb | action_dispatch/routing/route_set.sake | 701 | 353 |
| action_dispatch/routing/url_for.rb | action_dispatch/routing/url_for.sake | 67 | 31 |
| action_dispatch/routing/polymorphic_routes.rb | action_dispatch/routing/polymorphic_routes.sake | 212 | 107 |
| action_dispatch/routing/redirection.rb | action_dispatch/routing/redirection.sake | 129 | 91 |
| action_dispatch/routing/endpoint.rb | action_dispatch/routing/endpoint.sake | 14 | 28 |
| action_dispatch/routing/inspector.rb (Sheet only) | action_dispatch/routing/inspector.sake | 275 | 112 |
| action_dispatch/routing.rb | action_dispatch/routing.sake | 14 | 2 |
| (Sake only) the named route helpers' source | action_dispatch/routing/generate/url_helpers.sake | | 37 |
| (Sake only) the App protocol, RackApp | action_dispatch/app.sake | | 12 |
| action_dispatch/middleware/remote_ip.rb | action_dispatch/middleware/remote_ip.sake | 85 | 57 |
| action_dispatch/http/filter_parameters.rb | action_dispatch/http/filter_parameters.sake | 57 | 52 |
| action_dispatch/http/content_security_policy.rb (no Proc sources) | action_dispatch/http/content_security_policy.sake | 267 | 166 |
| action_dispatch/http/permissions_policy.rb (no Proc sources) | action_dispatch/http/permissions_policy.sake | 138 | 72 |
| **journey + routing + the four above** | | **4,900** | **3,165** |

http/ (fork A), middleware/ (fork B) and testing/ (fork C) have their own tables below. ActionDispatch's lib is
17,532 Ruby lines with comments (about 11,000 code lines); the port read about 9,900 Ruby code lines (4,900 here,
about 2,350 in http/, 2,330 in middleware/ with the Rack parts it needed, 930 in testing/ with rack-test's jar)
and is about 6,900 Sake code lines (`sakelib/rails/actionpack/`, testing/ included).

Tests of journey and routing (all identical to the gem's output; `-c --strict` time and memory):

| test | what | check |
|---|---|---|
| journey | parser + String visitor + Format over 6 paths, kinds of nodes, Ast names, pattern sources (anchored, unanchored, requirements with groups), MatchData, Router::Utils | 1.75 s 84 MB |
| routing_mapper | `rails routes` for 62 routes of most of the DSL (concerns, member/collection/on:, shallow, singular resources, path/controller/as/param/path_names/only/except, namespace, scope module/path/as/defaults, optional segments with constraints, request constraints, match via, globs, format: false, redirects, mount), filters `-c`/`-g`, route details, 7 DSL errors with Rails' messages, and every route the router finds for 21 paths | 3.83 s 140 MB |
| routing_generate | 26 generated helper calls (`*_path`/`*_url`, records' to_param, query params, format, anchor, host/port/protocol, url_options of a context), route_for, url_for/path_for with controller/action, `_recall`, extra_keys, recognize_path, and the errors | 8.33 s 199 MB (the generator is checked too) |
| routing_dispatch | RouteSet as the app: controller dispatch, 404 x-cascade, requirements, subdomain constraints, both redirect kinds, a mounted Rack app's SCRIPT_NAME/PATH_INFO, HEAD, named constraint objects/lambdas | 3.04 s 116 MB |
| routing_polymorphic | polymorphic_path/url with records, new records, nesting, namespaces, Symbols, options, the errors | 3.35 s 121 MB |
| routing_helpers_source | prints the generated helpers (no .rb) | |
| integration | ShowExceptions + DebugExceptions + Cookies + CookieStore + Flash + RouteSet + a controller stand-in: a post/redirect/get with flash and session over the cookie, 400, 404 | 3.01 s 130 MB |
| remote_ip, filter_parameters | RemoteIp with proxies and the spoofing check; filtered params/path/env | 1.4 s, 1.7 s |
| content_security_policy, permissions_policy | policies built from the initializer's block, copies, every kind of directive, errors, the middlewares (nonce from the session id, report-only, an existing header, 304) | 5.1 s, 4.2 s (on a loaded machine) |

## How Rails' metaprogramming got a Sake shape

### The routes block (`instance_exec`)

```ruby
# Rails                                         # Sake
Rails.application.routes.draw do                class ActionDispatch::Routing::Mapper
  resources :posts, only: [:index] do             def blog_routes(map)
    resources :comments                             resources map, :posts, only: Any[:index] do
    get :preview, on: :member                         resources map, :comments
  end                                                 get map, :preview, on: :member
  namespace :admin do                               end
    resources :users                                namespace map, :admin do
  end                                                 resources map, :users
  get "about", to: "pages#about"                    end
end                                                 get map, "about", to: "pages#about"
                                                  end
                                                end
                                                RouteSet.draw(set) { |map| Mapper.blog_routes(map) }
```

The routes are a function of the reopened Mapper, so its calls are bare as in the Ruby block; the Mapper is the
first argument instead of `self`. Keyword options are Sake keyword parameters, as in Rails 8.1's own signatures
(`def get(m, *path_or_actions, as: :__default__, to: nil, ..., **mapping)`), so `only: Any[:index]`,
`constraints: Hash.of(id: /\d+/)` and `id: /\d+/` (into `**mapping`) read like Rails. (The brief says call-site
keywords are not available; they are, for Sake functions with keyword parameters.)

### Code stored by the routes: concerns, constraint objects

```ruby
# Rails                                         # Sake: the routes as a Routing::Draw type
concern :commentable do                         class BlogRoutes
  resources :comments                             include ActionDispatch::Routing::Draw
end                                               def draw(r, map) = Mapper.blog_routes(map)
resources :posts, concerns: :commentable          def concern_for(r, map, name, options)
constraints(AdminOnly) { get "secret", ... }        case name
get "beta", to: "pages#beta",                       in :commentable then Mapper.blog_concern(map, name, options)
  constraints: ->(req) { req.host =~ /beta/ }       end
                                                  end
                                                  def constraint_matches?(r, name, req)
                                                    case name
                                                    in :admin_only then ...
                                                    in :beta_host then String.start_with?(Request.host(req) || "", "beta")
                                                    end
                                                  end
                                                end
                                                RouteSet.draw_with(set, BlogRoutes.new)
```

`concern map, :commentable` declares the name (Rails' "No concern named nope was found!" stays); a constraint
object or lambda is a Symbol, kept in the Scope's `blocks` or the route's `constraints:`, and Mapper::Constraints
asks `Draw.constraint_matches?(drawer, name, req)`. Railties will generate the Draw type from config/routes.

### `define_method` per named route: generated helpers

`Routing::Generate.url_helpers(set, "ShopUrlHelpers")` prints a mixin with `post_path(t, *args, **options)` and
`post_url` per named route, `route_for(t, name, *args, **options)` (a `case` over the names: Rails'
`public_send("#{name}_url")`), and `ShopUrlHelpers::Proxy`, Rails' `url_helpers` called on the module itself.
`direct` helpers get the same pair. Each helper is one line calling `RouteSet::NamedRouteCollection::UrlHelper.call(t, :post, :path, args, options)`,
which is Rails' UrlHelper/OptimizedUrlHelper#call. `t` is a `Routing::UrlFor` includer (`_routes(t)`,
`url_options(t)`): a controller, a view, an integration session, the Proxy. The test's generator program
(`routing_helpers_source.sake`) draws the routes in its own run; `generate "routing_helpers_source",
"ShopUrlHelpers"` joins its output. Input: a drawn RouteSet (its named routes) and the module name.

```ruby
# Rails                                         # Sake (generated)
helpers.post_path(post, format: :json)          ShopUrlHelpers.post_path(ctx, post, format: :json)
                                                def post_path(t, *args, **options) = ...UrlHelper.call(t, :post, :path, args, Hash.empty?(options) ? nil : options)
```

### Other shapes

| Rails | Sake |
|---|---|
| `req.controller_class` (constantize "PostsController"), `controller.dispatch(action, req, res)` | the RouteSet holds a `Routing::Controllers` includer (railties generates it: a `case` over the controller names), and Dispatcher#serve calls `Controllers.dispatch(c, controller, action, req)` |
| a route's app is anything with `serve`/`call` (Dispatcher, redirects, Rack apps, Constraints) | the `Routing::Endpoint` mixin; `to.respond_to?(:call)` is `to in Endpoint`; a mounted Rack app is wrapped in `Mounted` |
| visitors dispatch with `send(DISPATCH_CACHE[node.type], node)` | a `case` over the node classes (`in Nodes::Cat`) |
| Node class hierarchy (Terminal < Node, Symbol < Terminal, ...) | one class per node type including the mixin `Nodes::Node` (type, name, each, find_all, to_s) |
| `VerbMatchers` classes made with `class_eval` per verb | `VerbMatchers::Matcher` Struct of the verbs |
| `send("merge_#{option}_scope", ...)` over Scope::OPTIONS | one line per option in `_enter_scope` |
| `Scope` frames: a Hash per frame merged with the parent's | `Mapper::Scope` with a field per option, `child` copies it |
| `SingletonResource < Resource` overriding 10 methods | one `Resource` with a `singleton` flag |
| `DEFAULT = Object.new` | `:__default__` |
| GTG keyed by object identity (`compare_by_identity` on nodes and state Arrays) | the trees are copied into numbered `GTG::Position`s; states are numbers, sets of positions Arrays |
| `TransitionTable#regexp_states` keyed by Regexp | a list of [regexp, state] pairs (a Regexp cannot be a Hash key) |
| `public_send("#{prefix}#{model_name.singular_route_key}_path")` (polymorphic) | `UrlHelper.call(t, :post, :path, ...)` by the route's name; the record includes `PolymorphicRoutes::Model` (route_key, singular_route_key, persisted?) and `ToParam` |
| `Object#to_param` / ActiveModel's | `Journey::Formatter.to_param`: a `Routing::ToParam` includer's, else to_s |
| `DIRECTIVES.each { define_method(name) { \|*sources\| ... } }` (CSP, permissions policy) | 22 one-line functions written out (`def script_src(p, *sources) = directive(p, "script-src", sources)`) |
| `config.content_security_policy do \|policy\| ... end`; `nonce_generator = ->(request) { request.session.id.to_s }` | a function receiving the policy; the generator is a Symbol (:session_id, :random) |

## Left out, and why

- **Engines** (mount of a Rails::Engine, define_generate_prefix, RoutesProxy, mounted helpers): no engines yet.
- **`resolve`** (polymorphic mappings, a stored block). `direct` is ported: `direct map, :homepage` declares it,
  the routes' `direct_for(r, t, name, args, options)` is the block (a `case` over the names, returning a URL or
  url_for options), and the generator writes `homepage_url`/`homepage_path` calling RouteSet::CustomUrlHelper.
- **`draw(:name)`** (instance_eval of config/routes/name.rb), route source locations, `--unused`, the Expanded and
  HTML inspector formatters, the Dot visitor and the GTG visualizer.
- The deprecated Hash forms of `get "x" => "c#a", as:`... (Rails 8.1 warns; `match "path" => "c#a"` works),
  constraint lambdas with arity 2 (params, request): constraint names receive the request.
- `recognize_path` does not check that the controller class exists (Rails' constantize): controllers are found by
  generated code.
- RemoteIp computes the address in the middleware (Rails: lazily at the first `remote_ip`), so a spoofing
  error comes from the middleware; there is no `Forwarded` header in sakelib's Rack.
- `full_url_for(record)` / `url_for(record)` (handle_model_call): use polymorphic_url; polymorphic_routes.sake is
  not required by routing.sake because a `case ... in PolymorphicRoutes::Model` is rejected when no type includes
  the module.

## Built-ins and checker requests

- **Regexp as a Hash key** (Ruby: by source and options). The GTG groups transitions by regexp; it now groups by
  the regexp's spelling. Found at run time (`TypeError: Array.group_by: Regexp cannot be a Hash key`), not by the
  checker.
- (fork B) PBKDF2 or a native HMAC: Rails' 1000-iteration key derivation takes 2 min in Sake; a cipher (AES-GCM)
  for encrypted cookies and Rails' default session store; an exception's class name.
- **Check time of block-heavy code** (see friction 9): the Mapper written as Rails writes it took 125 s to check.

## Bugs (repros in experiments/2026-10-20-rails-scale/bugs/)

- `actionpack_dispatch_toplevel_shadows_module_function.sake`: a mixin's bare call to a function only its
  includers define resolves to a top-level function of the same name when one exists (a test's `def
  request(app, method, path, cookie)` broke middleware/cookies.sake: "wrong number of arguments for request").
- (fork A) `actionpack_dispatch_include_loses_to_paste.sake`, `actionpack_dispatch_module_function_bare_call_to_includer.sake`.
- (fork B) `actionpack_dispatch_ipaddr_unused_rescue.sake`.

## Friction (journey and routing): what I wrote first → the message → what I wrote instead

1. `attr_accessor ... module, controller` in Mapper::Scope (Rails' `:module` key) → `syntax error: unexpected
   constant path after module` → `module_name`. Rails' own code calls its local `modyoule`.
2. `class Router` in router/utils.sake (Rails nests Utils in Router) read before router.sake's `attr_accessor
   routes` → `the fields of ActionDispatch::Journey::Router are declared in its first class` → the field moved to
   utils.sake. The same with url_for.sake reopening RouteSet before route_set.sake: fields belong to whichever file
   is read first, so the require order decides where a class's fields may be written.
3. `URI.write_field(uri, :scheme, ...)` (Rails' `uri.scheme ||= req.scheme`) → `field scheme of URI cannot be
   written (attr_reader or private) outside class URI` → the location String is built from its parts.
4. `case value in Routing::ToParam then ...` in the formatter → `no type includes ActionDispatch::Routing::ToParam`
   → a Sake-only includer `ToParam::Param` (a parameter given as is). A library's extension point needs a dummy
   includer until an app provides one.
5. `match_via(...) { yield }` into `match_all`, which yields nothing (Rails passes `&block` along and ignores it)
   → `does not take a block (it has no yield)` → dropped; the checker is right that the block went nowhere.
6. `resources(m, r, concerns: c, **options)` with `options` a Hash → `` `**` passes on only the keywords the function
   collected with its own `**` parameter `` → the public DSL functions are thin keyword wrappers over internal
   functions taking the Hash (`_resources(m, singleton, names, concerns, options)`).
7. RouteSet.new with the formatter set afterwards (the formatter needs the set) → level 2: `RouteSet.formatter may
   be nil` at every use → `def formatter(rs) = @_formatter || raise(...)`, written once with write_field.
8. `mk & Hash.keys(constraints)`, `kept | required_parts` → `Bitwise.&: ... which the left operand's type does not
   support` → `Array.intersection`, `Array.union` (Array has no `&`/`|`).
9. **Check time.** The Mapper written as Rails writes it: each scope helper takes a block and restores `@scope` in
   an `ensure` (`with_scope_level(:resources) { resource_scope(res) { controller(c) { yield } } }`), `decomposed_match`
   recurses through `nested { decomposed_match(...) }`, and `apply_common_behavior_for` calls `resources` again with
   `{ yield }` inside `shallow`/`nested`/`scope` blocks. `bin/sake -c --strict` of a file drawing 30 routes: **2 min
   5 s**; one `resources`: 14.7 s; one `get`: 2.0 s; running it: 1.2 s. Rewritten with `_enter_*` functions (push a
   frame, return the old scope; the caller restores it) so that only the public DSL functions yield, and with
   apply_common_behavior_for as frames entered one after the other: **2.9 s**, 2.1 s, same output. A synthetic file
   with the same nesting of yields did not reproduce the blow-up (0.7 s), so I could not isolate the cause; the
   before/after above is the evidence. This is the measure the whole effort is about: Rails-shaped code with blocks
   passed down through helpers can cost the checker far more than its size suggests.
10. A chain step `RoutesInspector.make(...).Routing::RoutesInspector.format(...)` at the top level → `undefined type
    or module Routing::RoutesInspector` → the full `ActionDispatch::Routing::RoutesInspector` (a step's type is
    resolved from the top level).
11. The test's concern function `case name in :commentable then ... end` → `case/in: no in branch matches :nope`:
    the checker followed `concerns: :nope` from the error test into the concern function (Rails raises "No concern
    named nope" first). Added an `else raise`; a fair catch.
12. GTG: `Array.group_by(s) { |pos| symbol_of(b, pos) }` (Rails groups by String or Regexp) → at run time `TypeError:
    Array.group_by: Regexp cannot be a Hash key` → group by `"/#{options}/#{source}"`.
13. The first GTG builder kept `root`/`ast` nil until the copy was made → `Position.kind: argument 1 may be nil` at
    every recursion → build the copy first, then the Builder.

What read well: `resources map, :posts, only: Any[:index] do ... end` and `get map, :preview, on: :member` are
Rails' lines with `map,` added; the inspector, recognition, generation and the polymorphic paths matched the gem
on their first full run once they type-checked (`rails routes` for 62 routes, 26 helper calls, 21 recognitions
through the GTG). The checker's level 2 made the nil cases of Rails' generation (missing keys, unmatched
constraints) explicit where Rails leans on `to_param`/`present?`.


## http/: Request, Response, Mime, parameters, URL (fork A)

### Ported

Ruby lines: non-blank, non-comment lines of actionpack-8.1.3; Sake lines likewise.

| Ruby file | Sake file | Ruby | Sake |
|---|---|---:|---:|
| http/request.rb (+ the instance half of url.rb and of cache.rb) | http/request.sake | 345 | 269 |
| http/parameters.rb | http/parameters.sake | 77 | 42 |
| http/mime_negotiation.rb | http/mime_negotiation.sake | 120 | 109 |
| http/url.rb (module functions) | http/url.sake | 197 | 138 |
| http/cache.rb | in response.sake (Response half), request.sake (Request half) | 236 | (~110) |
| http/headers.rb | http/headers.sake | 79 | 56 |
| http/mime_type.rb | http/mime_type.sake | 276 | 203 |
| http/mime_types.rb | http/mime_types.sake | 36 | 37 |
| http/response.rb | http/response.sake | 389 | 360 |
| http/param_builder.rb | http/param_builder.sake | 132 | 106 |
| http/query_parser.rb | http/query_parser.sake | 38 | 35 |
| http/param_error.rb | http/param_error.sake | 20 | 13 |
| http/content_disposition.rb | http/content_disposition.sake | 35 | 29 |
| request/utils.rb | request/utils.sake | 94 | 36 |
| action_controller/metal/exceptions.rb | action_controller/metal/exceptions.sake (all of it; written here because http/ raises BadRequest/UnknownHttpMethod first) | 73 | 46 |

Tests (each `.sake` prints what the `.rb` on the real gem prints): `request` (85+9 lines: methods, paths, host/port/
domain, headers, params from query/form/JSON, formats/accepts/negotiate_mime, errors, forwarded host, conditional
GET), `response` (49: content type/charset, status symbols, headers, body, cookies, ETag/Last-Modified/Cache-Control,
Content-Disposition), `mime` (42: lookup, ==/===, parse with q-ordering and the text/xml rules, register/alias/
unregister), `url` (31: url_for/path_for options, domains), `params` (22: QueryParser, ParamBuilder edge cases and
its errors). `bin/sake -c --strict`: request.sake 2.2 s / 77 MB, response 1.6 s, mime 1.8 s, params 1.7 s, url 1.2 s.

### Request's API used by the other parts

`Request.new(env)` (env from `Rack::MockRequest.env_for`); the fields keep Rails' env state (see the header of
http/request.sake). Readers: `request_method`, `method`, `request_method_symbol`, `get? post? put? patch? delete?
head? options?`, `path_info`, `script_name`, `path`, `fullpath`, `original_fullpath`, `url`, `original_url`,
`base_url`, `protocol`, `host`, `port`, `host_with_port`, `standard_port`, `optional_port`, `port_string`,
`domain(req, tld=1)`, `subdomain`, `subdomains`, `ip`, `remote_ip`, `user_agent`, `accept`, ... (all 25 ENV_METHODS),
`headers(req)` (Http::Headers: `h["Content-Type"]`), `xhr?`, `ssl?`, `local?`, `content_mime_type`, `media_type`,
`content_length`, `raw_post`, `body`, `form_data?`, `query_parameters`/`GET`, `request_parameters`/`POST`,
`path_parameters`, `parameters`/`params` (String keys), `formats`, `format` (a Mime::Type; Mime.NullType when none),
`accepts`, `variant`, `negotiate_mime(req, types)`, `should_apply_vary_header?`, `request_id`, `fresh?(req, res)`,
`if_none_match_etags`, `if_modified_since`, `inspect`. Writers: `set_path_parameters`, `set_request_method`,
`set_script_name`, `set_path_info`, `set_request_id`, `set_remote_ip`, `set_format`, `set_formats`, `set_variant`,
`set_request_parameters`, `set_header`, `add_header`, plus `route`/`set_route`, `routes`/`set_routes`.
Response: `Response.new(status, headers, body)`, `Response.create(...)`, `status`/`set_status(:created)`,
`get_header`/`set_header`/`[]`/`[]=` (downcased), `set_content_type(:json | "text/plain")`, `content_type`,
`media_type`, `charset`/`set_charset`, `set_body`, `body`, `write`, `body_parts`, `location`/`set_location`,
`message`, `code`, `set_cookie`, `delete_cookie`, `cookies`, `set_etag`, `set_last_modified`, `committed?`,
`to_a` (the Rack triple, body an Array of String), the status predicates.

### How Rails' shapes became Sake

| Rails | Sake |
|---|---|
| state in env keys (`@env["action_dispatch.request.formats"]`) | a private field per key (`@_formats`), declared in the first `class ActionDispatch::Request < Rack::Request` |
| `include Rack::Request::Helpers` | `class Request < Rack::Request` (a paste of sakelib's Rack request) |
| `include Http::URL` (instance methods override Rack's host/port/url) | the instance methods written in request.sake itself: an included function loses to a pasted one (bug repro below) |
| `include MimeNegotiation`, `include Parameters` | the same includes (no name clashes with Rack, except `params`, defined in request.sake) |
| `ENV_METHODS.each { class_eval "def #{...}" }` | 25 one-line readers written out |
| `Mime::SET`, `LOOKUP`, `EXTENSION_LOOKUP` (constants filled by `register`) | `Mime.SET` etc.: functions returning one mutable value (`once`), filled by mime_types.sake's top-level `register` statements |
| `Mime[:json]` | `Mime.[](:json)` (`Mime[...]` is an Array literal of the module's includers) |
| `class AllType < Type; include Singleton`, `NullType` with method_missing | `Mime.ALL`, `Mime.NullType`: Type values with a private `kind` flag, so a list of formats has one element type |
| `format.json?` (method_missing) | `Mime::Type.symbol(f) == :json` |
| `DEFAULT_PARSERS = { json: ->(raw) { ... } }` | `Parameters.parse_with(symbol, raw_post)`, a `case` over the MIME symbol |
| `class ParamError < Parameters::ParseError`; three subclasses | module `ParamError` that the three include; `rescue ParseError` does not catch them (it does in Rails) |
| `ActionControllerError` base class | module included by every ActionController exception |
| HashWithIndifferentAccess params | Hash with String keys |
| `mattr_accessor :tld_length`, `cattr_accessor :default_charset` | `URL.tld_length`/`set_tld_length`, `Response.default_charset`/`set_default_charset` over a `once` Hash |
| writers `x=` | `set_x` (Sake's writer names) |
| Response::Buffer/RackBody objects as the Rack body | the Rack body is the Array of the parts |

```ruby
# Rails (mime_negotiation.rb)                      # Sake
def formats                                        def formats(req)
  fetch_header("action_dispatch.request.formats") do |k|   cached = @_formats
    v = if params_readable?                          return cached if cached
      Array(Mime[parameters[:format]])               v = if params_readable?(req)
    elsif use_accept_header && valid_accept_header       f = Mime.fetch(Kernel.to_s(parameters(req)["format"]))
      accepts.dup                                        f ? Mime::Type[f] : Mime::Type[]
    ...                                                ...
```

### Left out, and why

- `controller_class` / `controller_class_for`: constantize of "PostsController"; no class values (routing's
  dispatch finds controllers by generated code). Encoding templates (CustomParamEncoder) need it too.
- `route_uri_pattern` (needs Journey; belongs next to journey/route.sake); `reset_session`, `session`,
  `cookie_jar`, `commit_flash`, `commit_cookie_jar!` (middleware part: they reopen Request in their files).
- FilterParameters (needs ActiveSupport::ParameterFilter, not there yet), FilterRedirect, UploadedFile and
  multipart (sakelib Rack parses no multipart), ContentSecurityPolicy, PermissionsPolicy, rack_cache,
  CacheControlDirectives, `send_file`/FileBody and streaming (await_commit's condition variable), `send_early_hints`.
- `body` is the raw String, not an IO. `ip` is REMOTE_ADDR (Rack's trusted-proxy walk is not in sakelib's Rack).
- ETag digests use MD5 (ActiveSupport::Digest's default outside an app); `expand_cache_key` of String/Integer/Array only
  (no `cache_key` objects).

### Bugs (repros in experiments/2026-10-20-rails-scale/bugs/)

- `actionpack_dispatch_include_loses_to_paste.sake`: a function from an `include`d module loses to the one
  `class B < A` pasted (Ruby: the include wins). Worked around by defining URL's request functions in Request.
- `actionpack_dispatch_module_function_bare_call_to_includer.sake`: inside a `module_function` function of a
  module that is also a mixin, a bare call resolves to the includer's function of that name (here Request's private
  field reader `_config`): "wrong number of arguments for ActionDispatch::Request._config (given 0, expected 1)".
  Worked around by renaming (`url_config`, `negotiation_config`).

### Friction (what I wrote first → the message → what I wrote instead)

1. `request/utils.sake` with `module ActionDispatch; class Request; module Utils` → `` `<` goes on the first `class
   Request` `` (the file is read before request.sake, since request.sake's requires are read first) →
   `module ActionDispatch::Request::Utils`, which names Request without opening it. The rule for everyone adding
   to Request: require http/request.sake, and never be required by it.
2. `LOOKUP[string]` inside `module Mime` → `undefined type or module LOOKUP` → `Mime.LOOKUP[string]`.
   `Mime["html"]` → `Mime[]: element 1 must be a type including Mime` → `Mime.[]("html")` / `Mime.fetch`.
3. `Regexp.escape("!#$&-^_.+")` (Rails has single quotes; I wrote double) → `Sake has no global variables ($&)`:
   the message found an interpolation (`#$&`) I had not seen → single quotes.
4. `Array.index(list) { |item| ... }` → `Array.index does not take a block` → `Array.find_index`.
5. `success &&= not_modified?(...)` → `unsupported syntax: local variable and write` → `success = success && ...`.
6. Mixed `host` from `include Http::URL` and Rack's pasted `host` → `Arithmetic.+: the operands may be nil
   ([String, nil | String])` at `protocol(req) + host_with_port(req)`: the nil came from Rack's host_with_port, which
   had silently won. The "reached by ... rack.sake:505" hint is what showed which function was called.
7. `Response` with `attr_accessor request` first → Response.new(404) would have set `request`; fields are the
   positional arguments in declaration order, so `status, headers` come first and the body goes through a private
   `_initial_body` field (`stream` holds the Buffer: one field cannot hold the Array and then the Buffer).

What read well: the side-by-side tests matched Ruby on the first full run for request, mime and url (after the
checker errors); level 2 forced every `@env[...]` read (String|nil) to be handled, which is where Rails relies on
`.to_s`/`.presence`.

## Middleware (fork B)

### Ported files

| Ruby (code lines) | Sake (code lines) | test (Sake / Ruby lines) |
|---|---|---|
| middleware/stack.rb (139) | middleware/stack.sake (127) | middleware_stack (43 / 43) |
| middleware/cookies.rb (437) | middleware/cookies.sake (249) + cookies_signed.sake (86) + cookies_encrypted.sake (39, not tested) | cookies (61 / 59), cookies_signed (38 / 34) |
| middleware/session/abstract_store.rb (91) + rack-session abstract/id.rb (359, the Persisted/PersistedSecure/SessionId parts) | middleware/session/abstract_store.sake (128) | session (93 / 84) |
| middleware/session/cookie_store.rb (70) | middleware/session/cookie_store.sake (65) | cookie_store (59 / 50) |
| request/session.rb (197) | request/session.sake (207) | session, flash |
| middleware/flash.rb (179) | middleware/flash.sake (149) | flash (96 / 89) |
| middleware/show_exceptions.rb (57) | middleware/show_exceptions.sake (63) | show_exceptions (52 / 49) |
| middleware/exception_wrapper.rb (282) | middleware/exception_wrapper.sake (82) | show_exceptions |
| middleware/public_exceptions.rb (41) | middleware/public_exceptions.sake (39) | show_exceptions |
| middleware/debug_exceptions.rb (167) | middleware/debug_exceptions.sake (59) | show_exceptions (the cascade → RoutingError path) |
| middleware/static.rb (114) + rack/files.rb (155, GET/HEAD/OPTIONS/304 part) + rack/mime (table subset) | middleware/static.sake (156) | static (24 / 25) |
| middleware/request_id.rb (27) | middleware/request_id.sake (25) | request_id (21 / 21) |
| middleware/host_authorization.rb (121) | middleware/host_authorization.sake (97) | host_authorization (26 / 27) |
| middleware/ssl.rb (94) | middleware/ssl.sake (77) | ssl (19 / 18) |

Ruby total ≈ 2,330 code lines read (1,816 of actionpack + the rack/rack-session parts); Sake 1,650 code lines.
All 11 tests print the same as the real gem (`ruby -Ilib test/test_sakelib.rb -n /rails_actionpack_.../`: 11 runs, 0
failures), signed cookies byte for byte (the same secret gives the same `user=eyJfcmFpbHMi...--c483d3...`). `bin/sake -c --strict` of each test: 1.5–2.2 s, 63–92 MB (largest: session.sake 2.16 s 86 MB,
middleware_stack.sake 2.41 s 91 MB once CookieStore joined the build `case`, which reaches every middleware).

### Shapes

| Rails | Sake |
|---|---|
| `stack.use ActionDispatch::Cookies`; `klass.new(app, *args, &block)` | `MiddlewareStack.use(stack, "ActionDispatch::Cookies")`; `Middleware.build` is a `case` over the class names this port knows (no class values, no `new` on a value). An app's own middleware is one more branch (railties can generate it). Args are an `Any` Array; each branch takes them apart with `=>`. |
| a middleware is `call(env)`, reading state with `Request.new(env)` | `call(mw, req)` with the one Request passed down (app.sake); Rack apps in front via `ActionDispatch::RackApp` |
| `ActiveSupport.on_load(:action_dispatch_request) { include RequestCookieMethods }`, `prepend Flash::RequestMethods` | the middleware file reopens `class ActionDispatch::Request` and adds `cookie_jar`, `flash`, `commit_flash`, `session`, ...; the fields were declared in http/request.sake |
| env keys `"action_dispatch.secret_key_base"`, `"...cookies_same_site_protection"` (a lambda), `"action_dispatch.show_detailed_exceptions"` | `Request.env_config(req)`: a Hash with Rails' key names on the request (Sake's env holds only Strings); same_site protection is a value, not a lambda |
| `class MyStore < ActionDispatch::Session::AbstractSecureStore` (over `Rack::Session::Abstract::Persisted`), overriding `find_session/write_session/delete_session` | `include ActionDispatch::Session::AbstractStore` (a module with the three as required functions); the store declares Persisted's fields (`app, default_options, key, same_site, cookie_only`) and its initialize calls `AbstractStore.setup(s)`; Rails' `@by.send(:load_session, @req)` is `AbstractStore.load_session(@by, @req)` (dispatch on the store's type) |
| `CookieStore::DEFAULT_SAME_SITE = proc { \|request\| request.cookies_same_site_protection }` | CookieStore overrides `same_site_for(s, req)` |
| `cattr_accessor :rescue_responses, default: Hash.new(:internal_server_error).merge!(...)` | `def rescue_responses = once { Hash.of(...) }` (an app can still add to it); the default via `\|\| :internal_server_error` |
| `exception.class.name` (rescue_responses' key) | parsed from `Kernel.inspect(e)` (`"#<ActionController::RoutingError: ...>"`), the one reflection on an exception's type |
| `body.respond_to?("to_#{format}")` then `public_send` (PublicExceptions) | a `case` over the format's Symbol (`:json` → JSON.generate, else the HTML page) |
| `Flash.new(app)` returns app (`def self.new(app) app; end`) | the build branch returns `app` |
| `cookies[:a]`, `session[:user_id]`, `flash[:notice]`, `options[:renew]` | `include Indexable` on CookieJar, Session, Session::Options, FlashHash, FlashNow: `flash[:notice] = "x"` reads as Rails' |

### Left out, and why

- **The encrypted jar** (`cookies_encrypted.sake`) is written against Rails' MessageEncryptor names and required by
  nothing: activesupport has no MessageEncryptor yet (no cipher). So `signed_or_encrypted` is the signed jar, and
  CookieStore keeps the session signed (Rails does this only without secret_key_base). Signed cookies and the
  CookieStore run on activesupport B's KeyGenerator and MessageVerifier (which arrived during this part). Rails' jars
  give the verifier a NullSerializer, for which ActiveSupport writes its pre-7.1 envelope
  (`{"_rails":{"message":base64,"exp":null,"pur":"cookie.NAME"}}`); sakelib's verifier writes only the 7.1 one
  (`"data"`), so the jar builds that envelope itself and uses `MessageVerifier.sign_encoded`/`extract_encoded` for the
  signature (a request for activesupport: a NullSerializer / legacy-metadata mode). No key rotations, no legacy
  AES-CBC upgrade, the :json cookie serializer only (no Marshal). Sessions are also tested with a store kept in
  memory, written the same way in both tests (as Rails' own tests do).
- DebugExceptions' HTML/text pages are ActionView templates (DebugView): a browser request gets the header lines
  of diagnostics.text.erb; the API JSON has no traces; no interceptors, no logging. ExceptionWrapper: no source
  extracts, no backtrace cleaner, no template source maps.
- HostAuthorization: no `exclude:` lambda, no `response_app:`; the detailed page is the text template's text.
- SSL: no `exclude` lambda (`redirect: false` turns redirects off, Rails' default exclude).
- Static: no byte ranges (Rack::Files' 206/416), Rack::Mime is a table of common extensions.
- Not ported: CacheStore/MemCacheStore (ActiveSupport::Cache), Executor/Reloader/Callbacks,
  ActionableExceptions, ServerTiming, AssumeSSL, DebugLocks, the InstrumentationProxy. (RemoteIp was ported
  afterwards: remote_ip.sake, in the stack's `case`.)

(ShowExceptions' header used to say that Rails' `request.dup` shares the env; it does not (`r.dup.env.equal?(env)` is
false), and the port now renders from `Request.copy(req)`.)

### Built-ins asked for

- PBKDF2 (`OpenSSL::PKCS5.pbkdf2_hmac`) or a native HMAC: cookies_signed.sake with Rails' 1000 iterations ran
  **2 min 14 s** (two key derivations, one per request since each request builds its CachingKeyGenerator in the
  test; Ruby: 0.6 s for the whole test); the tests use `iterations: 2` on both sides. An app derives each key once
  per process, but 1 minute at boot per salt is not usable.
- A cipher (AES-256-GCM) for MessageEncryptor, hence encrypted cookies and Rails' default CookieStore.
- An exception's class name (`Exception.class_name(e)` or similar) instead of parsing `Kernel.inspect`.

### Friction (what I wrote first → the message → what I wrote instead)

0. Our shared scratchpad: another fork wrote its `rb.out` over mine while a 2-minute run was going, and the diff
   showed Arel's SQL against my cookies — the measurement was fine, the comparison file was not (now `rbB.out`).
1. In the test's store, `def call(s, req) = ActionDispatch::Session::AbstractStore.call(s, req)` (to make the module's
   `call` the store's) → no static message; at run time `SystemStackError: stack level too deep` in TestStore.call:
   the module's `call` is already copied into the class, my definition replaced it, and the module dispatch then
   found the class's own `call` → deleted the line. A check that a function only calls itself through a dispatch
   would have caught it.
2. Session::Options kept the session id in its options Hash (Rails' `@delegate[:id]`) → `Rack::Session::SessionId.public_id:
   argument 1 must be Rack::Session::SessionId, but can be true|false | String [mixed]` with the hint that
   `Session.id_was holds Boolean and String`: the Hash's values are httponly/path/... → the id is its own field
   (`sid`, `sid_known`), `to_hash` puts it back under `:id`.
3. `options[:drop]` on a Session::Options → `Indexable.[]: the receiver is ...Options@L36 | ...Options@L43, which cannot
   be indexed` → `include Indexable` (Rails' Options defines `[]`); then the same for Session, CookieJar, FlashHash.
4. Rails' class method `Session.delete(req)` and instance `session.delete(key)` → `ActionDispatch::Request::Session.delete
   is already defined` → the class one is `delete_from(req)` (one name is one function).
5. `PermanentCookieJar.new(jar)` → `wrong number of arguments ... (given 1, expected 5)` (the memo fields
   `_permanent`, `_signed`, ... are fields too) → an `initialize`, which makes trailing fields optional.
6. `r = @redirect; r => Hash` where the field is Hash|false → `` `=> Hash`: the value is true|false, which does not match ``
   (a static error, not a runtime check) → `return redirect_to_https(mw, req, r) if r in Hash`.
7. `FlashHash.new(flashes, discard)` (Rails' new(flashes = {}, discard = [])) → the constructor takes fields → a
   `build(flashes, discard)` function, as `Static.new_static` and `HostAuthorization.build` for Rails' `new` with work in it.
8. My first `request_id.sake` reopened Request with `request_id`/`set_request_id` → `already defined at line 205`: the
   http/ part had written them → removed mine (two parts adding to one class meet at the name, which is good).
9. Ruby side, not Sake: `20.years.from_now` needs `active_support/all`; HostAuthorization's DefaultResponseApp needs
   ActionView loaded (`uninitialized constant ...ActionView`); `Rack::MockRequest.env_for` sets no HTTP_HOST, so
   every host was blocked until the test set it.

What read well: the stores' protocol as a module with three required functions is Rails' subclass contract,
checked; `flash[:notice] = "Saved"` and `session[:user_id]` with Indexable; the checker's `[mixed]` hint pointed at the
exact field (id_was) whose writes mixed. Cookie/session/flash behaviour matched Rails on the first run once it
type-checked, including renew/skip/reset and the domain: :all rules.

### Bug repro

- experiments/2026-10-20-rails-scale/bugs/actionpack_dispatch_ipaddr_unused_rescue.sake: any `IPAddr.new` prints two
  `unused-rescue` warnings from sakelib/ipaddr.sake (IPAddr.== and <=>), so host_authorization and middleware_stack
  print them on stderr.

## testing/: integration sessions and assertions (fork C)

### Ported

Code lines = non-blank, non-comment lines.

| Ruby file | Sake file | Ruby | Sake |
|---|---|---:|---:|
| testing/integration.rb (Session, RequestHelpers, Runner's delegators, IntegrationTest) + test_process.rb (session/flash) | testing/integration.sake | 303 + 33 | 194 |
| rack-test-2.2.0 lib/rack/test/cookie_jar.rb (+ Rack::Test::Session#env_for/process_request, written into Session#process) | testing/rack_test_cookie_jar.sake | 152 (+ ~60) | 103 |
| testing/test_response.rb | testing/test_response.sake | 14 | 10 |
| testing/request_encoder.rb | testing/request_encoder.sake | 44 | 31 |
| testing/assertion_response.rb | testing/assertion_response.sake | 32 | 24 |
| testing/assertions.rb (+ Minitest's message/diff) | testing/assertions.sake | 18 | 19 |
| testing/assertions/response.rb | testing/assertions/response.sake | 76 | 106 |
| testing/assertions/routing.rb | testing/assertions/routing.sake | 202 | 71 |

Tests (each prints what the `.rb` on the real gem prints): `integration_session` (125 / 106 lines: GET with params,
POST with nested params, 422, redirect + follow_redirect! with the Referer, flash and session carried by the cookie
jar, a cookie set by the test, `as: :json` (body and the GET→POST override), `xhr: true`, a header, `host!`,
`https!` and a full URL, url_for through the session, 400 and 404 pages, request_count) and `assertions` (96 / 97:
assert_response with :success/:missing/:redirect/:error, codes, Symbols and a message; assert_redirected_to with a
path, a full URL, `status:`; assert_recognizes/assert_generates/assert_routing passing and failing; the assertion
count, 52 on both sides). Every failure message is Rails'/Minitest's text, byte for byte (backtraces are cut on both
sides). `bin/sake -c --strict`: integration_session 3.65 s / 138 MB, assertions 3.45 s / 129 MB.

### Shapes

| Rails | Sake |
|---|---|
| `class PostsFlowTest < ActionDispatch::IntegrationTest; test "x" do get "/posts"; assert_response :success; end` | `Minitest.test(suite, "x") { \|t\| it = IntegrationTest.make(t, app, routes); IT.get(it, "/posts"); IT.assert_response(it, :success) }`: the test is a value holding the block's Minitest::Test (assertions count against it) and the session |
| Runner: `%w(get post ...).each { module_eval "def #{m}(...) integration_session.#{m}(...)" }` + method_missing | IntegrationTest's one-line delegators, written out |
| `@response`, `@request`, `@routes` read by the assertion modules | ResponseAssertions/RoutingAssertions are mixins with required `minitest(x)`, `response(x)`, `request(x)`, `routes(x)` (IntegrationTest defines them; a controller test can too) |
| `assert test, msg` / `assert_equal` from Minitest::Assertions, a lambda message computed on failure | `Assertions.assert(t, ok, text)`, which counts (`Minitest.count`) and raises Minitest::Assertion as sakelib's Minitest does; the text is built only when `ok` is false; Minitest's `message`/`diff` are ported for one-line values |
| `Session.new(app)` calls `app.call(env)` through Rack::Test, then `Request.new(last_request.env)` sees the flash/session the app left in the env | `Session.make(stack, routes)`: the session makes the Request, calls `ActionDispatch::App.call(stack, req)` and keeps that Request (the state is in its fields, not in a String env) |
| rack-test's CookieJar (`Cookie` objects compared with `<=>`, `expires` via Time.parse) | the same classes; Cookie includes Comparable; `Time.httpdate` |
| `RequestEncoder` objects with lambdas (`-> body { JSON.parse(body) }`) | the encoder is its Symbol (:identity, :html, :json); content_type/accept_header/encode_params/parse are `case`s |
| `TestResponse < Response` | TestResponse is functions over a Response (`parsed_body(res)`); pasting Response into a second class would make every Response function, and Buffer's back reference, take either |
| `RESPONSE_PREDICATES[type]` + `public_send` | a `case` over :success/:missing/:redirect/:error |

### Left out, and why

- with_routing (swaps the app's routes and redefines `call` on a singleton class), open_session, assigns,
  file uploads (multipart), html_document / rails-dom-testing selectors (no HTML parser), parsed_body of HTML (the
  String), register_encoder of other MIME types, assert_recognizes with `method: :all`.
- assert_redirected_to with a Hash goes through the routes' url_for with the request's host (Rails asks the
  controller's url_for); a record (polymorphic_url) is not taken, since polymorphic_routes.sake needs a model type
  in the program. No Regexp argument.
- The "Exception while processing request" part of assert_response's message has no backtrace (Minitest's
  UnexpectedError prints one).
- ShowExceptions changed the request itself (path_info "/500", method GET) where Rails renders with a copy;
  Session#process puts PATH_INFO and the method back after the call. (Fixed afterwards in show_exceptions.sake:
  `Request.copy(req)`, Rails' `request.dup`, which copies the env; the restore is now a no-op.)

### Friction (what I wrote first → the message → what I wrote instead)

1. `def []=(jar, name, value) = merge(...)` → `syntax error: invalid method name; a setter method cannot be defined in
   an endless method definition` (Ruby's rule, kept) → a `def ... end` body.
2. The assertions test ended its Minitest.test block with `Minitest.assert(t, true)` so that minitest.sake's
   `rescue Minitest::Assertion` is reached → still `warning: rescue Minitest::Assertion: the begin body never raises`
   (with a literal `true` the raise is unreachable, which the checker sees) → `Minitest.assert(t, assertions > 0)`.
   Before that, every assertion in the block was inside my own `check { }` rescue, so the warning was right.
3. The first runs differed only after ShowExceptions: `GET /400 -> 400` where Ruby printed `DELETE /posts/1 -> 400`:
   the request had been rewritten by the error page (see Left out).
4. Assertion counts differed by 4 (48 vs 52): Rails' assert_redirected_to calls assert_operator, which first counts
   an assert_respond_to → one more `Minitest.count`. Without the side-by-side count this would not show.
5. Ruby side, not Sake: Rails' ExceptionWrapper needs ActionView loaded; recognize_path needs the controller
   constants (`action_encoding_template`); the session needs `include set.url_helpers` for url_for.

What read well: the cookie jar, the session cookie, flash across a redirect and the JSON/xhr paths matched Rails on
the first run that type-checked; Minitest's exact message formats (`msg.\nExpected: 404\n  Actual: 200`) were a
few lines once ported.
