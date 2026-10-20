# rails_actionview: ActionView 8.1.3 (2026-10-20)

ActionView on the first wave's ActiveSupport (SafeBuffer, ERB::Util, inflector, NumberHelper, Duration/TimeWithZone)
and ActionDispatch (routes, url_for, polymorphic routes, Request): the view (Base, Context, buffers, flows), the
template system (Template, the ERB handler on sakelib/erubi, resolver, PathSet, LookupContext, the renderers), the
template compiler as generated code, and the helpers (tag, capture, output safety, url, form/form tag/form options/
Tags, text, number, sanitize (with rails-html-sanitizer and Loofah's HTML4 scrubbing written in Sake), javascript,
date, translation, asset tag/url, csrf, csp, record identifier, rendering). Under `sakelib/rails/actionview/`;
`require "rails/actionview/action_view"` (= `action_view/base`). Tests: `test/sakelib/rails/actionview/`
(`ruby -Ilib test/test_sakelib.rb -n /rails_actionview/`: 16 runs, all pass; 12 pairs compared with the real gem).
Written by one agent with three forks (forms; text/number/sanitize; date/i18n/assets): their sections follow.

## The shape

```ruby
# Rails                                              # Sake
view = ActionView::Base.empty                        view = ActionView::Base.empty
view.content_tag(:p, "Hi", class: "x")               ActionView::Base.content_tag(view, :p, "Hi", class: "x")
view.tag.div("x", data: { id: 1 })                   T.div(ActionView::Base.tag(view), "x", data: Hash.of(id: 1))
<%= link_to "Show", post %>                          <%= link_to view, "Show", post %>
<%= form_with model: post do |form| %>               <%= form_with view, model: post do |form| %>
  <%= form.text_field :title %>                        <%= FormBuilder.text_field form, :title %>
<%= render "form", post: @post %>                    <%= render "form", post: @post %>        (compiled to a typed call)
<%= render @posts %>                                 <%= render @posts %>
<% content_for :title, "Posts" %>                    <% content_for view, :title, "Posts" %>
<%= yield %> / <%= yield :title %>                   <%= yield %> / <%= yield(:title) %>
```

- **The view is the first argument** of every helper (Rails' instance methods), named `view` in templates; `@post`
  in a template is the view's field, as Rails' assigns are its instance variables.
- **ActionView::Base is a class** with Rails' instance variables as fields (lookup_context, view_renderer,
  output_buffer, view_flow, virtual_path, current_template, tag_builder, _cycles, routes, request) that includes
  Helpers, Context and RoutingUrlFor. An app's view class is `class BlogView < ActionView::Base` with the assigns as
  fields and the compiled templates as functions; `generate/view_class.sake` writes it (Rails builds it at run time:
  `with_empty_template_cache`, `Template#compile` with module_eval).
- **Helper modules are mixins that read no fields.** A mixin that another module includes cannot use `@x`
  ("ActionView::Helpers::TagHelper is not a class with field output_buffer"), so Rails' `@output_buffer`,
  `@view_flow`, `@tag_builder` are the view's readers, declared as required functions
  (`def output_buffer(v) = raise(NotImplementedError)`) and called bare; Base's attr_accessor readers answer them.
  Pure helpers (Rails' `module_function :build_tag_values`) come after `module_function` at the end of the module.
- **Records** are values of a type including `ActionView::ModelNaming::Model` (Sake only): ActionDispatch's
  PolymorphicRoutes::Model and ToParam, plus to_key, param_key, read_attribute_for_validation(r, name) (Rails'
  public_send; the name is a String), and defaults for to_partial_path, model_name_human, human_attribute_name,
  errors_for. ActiveModel's Conversion/Naming should include it (ActiveModel was ported at the same time; the tests
  use small types of their own, `test/sakelib/rails/actionview/fixtures/records.sake`).
- **Controller-provided helpers** (protect_against_forgery?, form_authenticity_token, request_forgery_protection_token,
  url_options, button_to_generates_button_tag, ...) are view functions with Rails' defaults for a view without a
  controller; a controller's view class overrides them (`def protect_against_forgery?(v) = true`).

## Templates: compiled before the program, found at run time

Rails: `render` → LookupContext finds a Template (resolver, details: locale/formats/variants/handlers) →
`Template#render` compiles it once (ERB → Ruby, module_eval) → `view._run(method_name, ...)` → `public_send`.
Sake keeps the run-time half (LookupContext, FileSystemResolver with Rails' PathParser, TemplateDetails sorting,
PathSet, MissingTemplate's message, TemplateRenderer with layouts, PartialRenderer, ObjectRenderer,
CollectionRenderer with PartialIteration and spacers, Base#_run's save/restore) and moves compilation before the
program: `generate "rails/actionview/action_view/generate/view_class", "BlogView", "views=app/views",
"records=Post,Comment", "include=BlogUrlHelpers", "assigns=post,posts"` compiles every template under the view paths
with Rails' Erubi subclass (`class Erubi < ::Erubi::Engine`, its add_text/add_expression/add_code overrides write
Sake statements; newline_pending, BLOCK_EXPR and `safe_expr_append` for `<%==` are Rails') into functions named as
Rails names them (`_views_posts_index_html_erb`, without the hash and object id). `# sake-origin:` lines point
check and run-time errors at the .erb line.

```ruby
# views/posts/_form.html.erb: <%# locals: (post:, title: "Edit") -%> ... (generated)
def _views_posts__form_html_erb(view, local_assigns, output_buffer, post:, title: "Edit")
  @virtual_path = "posts/_form"
  ActionView::OutputBuffer.safe_append(output_buffer, "<h3>")
  ActionView::OutputBuffer.append(output_buffer, (title))
  ActionView::OutputBuffer.append(output_buffer, (form_with view, model: post do |form|
    ...
  end))
  output_buffer
end
```

**Locals are the hard part.** Rails passes a locals Hash; a Sake Hash has one value type, so a partial reading
`post` from it would get Post|String|... . Rails' strict locals (`locals: (post:)`) are keyword parameters, and so
are a non-strict partial's locals: it is compiled once per set of locals its render calls pass (Rails also builds one
Template per locals set). A template's `<%= render ... %>` with literal arguments becomes a call of a generated
function per call site, which goes through Rails' renderer (lookup at run time) and, in the renderer's block,
calls the compiled function the lookup found, with typed keywords (the generated `case` is Rails' public_send):

```ruby
# <%= render "form", post: post %>  (posts/show.html.erb:4)
def _views_posts_show_html_erb_render_2(view, post:)
  ActionView::PartialRenderer.render(view, "form", Symbol[:post]) do |template, buffer|
    case ActionView::Template.method_name(template)
    in "_views_posts__form_html_erb" then _views_posts__form_html_erb(view, Hash.of(post: post), buffer, post: post)
    else ActionView::Template.not_compiled(template)
    end
  end
end
```

Forms read: `render "name", k: v`, `render partial: "name", locals: {k: v}`, `collection:` (+ `as:`,
`spacer_template:`, counters and iterations), `object:`, `render record` / `render records` (the record's
to_partial_path; a generated `case` over the record types given as `records=`), `render template:`. The
checker's per-call-site analysis keeps the element type through the library's yield (`render_collection_with_partial`
yields Post for one call and Comment for another), so the renderers stay library code. Without locals (an action's
template, a layout, a spacer, `render(view, partial: "x")` from Sake code) the run-time path ends in the generated
`_compiled(view, method_name, buffer)`; a layout's function gets the block `{ |name| _layout_for(view, name) }`.

Test `rendering`: posts/index and posts/show with the application layout (content_for/yield :title, render of a
collection of records, a partial collection with as:/spacer/counter/iteration, a strict-locals form partial with
form_with, an object, an empty collection, a partial without locals), plain:/html:, lookup and MissingTemplate:
identical to ActionView 8.1.3 rendering the same templates written in Ruby (`views_rb/`).

## What is ported (Ruby code lines → Sake code lines; blank and comment lines not counted)

| Ruby (actionview-8.1.3/lib/action_view/) | Sake | Ruby | Sake |
|---|---|---:|---:|
| base.rb, helpers.rb, context.rb | base, helpers, context | 192 | 117 |
| buffers.rb, flows.rb (no streaming) | buffers, flows | 173 | 74 |
| template.rb + template/{types,handlers,text,html}.rb, template/error.rb (MissingTemplate) | template, template/error | 407 + 60 | 87 |
| template/handlers/erb.rb, erb/erubi.rb | template/handlers/erb (+ render call reading) | 172 | 173 |
| template/resolver.rb, path_set.rb, lookup_context.rb, template_path.rb, template_details.rb, unbound_template.rb | the same names | 594 | 250 |
| renderer/{renderer,abstract,template,partial,object,collection}_renderer.rb | renderer/* | 519 | 183 |
| routing_url_for.rb, record_identifier.rb, model_naming.rb | the same names | 114 | 93 |
| helpers/{tag,capture,output_safety,url,controller,rendering}_helper.rb | helpers/* (+ generated TagBuilder elements) | 787 | 554 |
| (Sake only) generate/templates.sake, view_class.sake, tag_builder_elements.sake | | — | 243 |
| forms (fork A: form_helper, form_tag_helper, form_options_helper, active_model_helper, tags/*) | | 1,894 | 1,456 |
| text, number, sanitize, javascript (fork B) + rails-html-sanitizer, loofah html4 | | 356 + 1,552 | 317 + 526 |
| date, translation, asset tag/url, csrf, csp (fork C) | | 1,101 | 1,019 |
| **total** | 63 Sake files | **≈7,900** | **5,061** |

Check times (`bin/sake -c --strict`, two runs each, load ≈2.5): rendering 9.3 / 9.0 s (263 MB), form_helper 9.4 /
9.9 s, url_helper 8.4 / 8.3 s, date_helper 4.9 s, tag_helper 1.8 s. Every test requires all of ActionView::Base;
the routes (ActionDispatch) are most of the difference between 2 s and 8 s. Nothing reached 30 s; the lead's fix of
yielding functions (d2a1beb8) landed while this was written.

## Left out, and why

- ActionView::Layouts and ActionView::Rendering (the controller-side modules: `layout "x"`, `_default_layout`,
  render_to_body): they belong with ActionController's rendering, which was ported at the same time.
- Template locals passed as a Hash at run time (`render template: "x", locals: {...}` from code), `render layout:
  "x" do ... end`, partial layouts, `render_in` objects, Inline/RawFile/Renderable templates, streaming
  (StreamingBuffer, StreamingFlow: a Fiber and stored blocks), collection caching, digests, dependency tracking,
  template annotations, instrumentation, the DidYouMean corrections of MissingTemplate.
- Template::Types is ActionView's own list (Rails uses Mime::SET once ActionDispatch is loaded, so MissingTemplate
  prints more formats: the test compares the message up to " with ").
- An object render of a record whose partial reads `<name>_counter` raises at run time (Rails: NameError) instead of
  being compiled; only the collection variant is compiled for it.
- A Class as a record (`dom_id(Post)`, `polymorphic_path(Post)`): a Class is not a value.

## Friction (what I wrote first → the message → what I wrote instead)

1. `include CaptureHelper` in TagHelper with `@output_buffer` in CaptureHelper → `ActionView::Helpers::TagHelper is
   not a class with field output_buffer` → readers declared as required functions; then `needs output_buffer, which
   ActionView::Helpers::TagHelper does not define` until each module declares them. Rails' helper modules are
   all about shared instance variables; every one of them became a required reader.
2. `FormBuilder = ActionView::Helpers::FormBuilder` in Base, used by a subclass's template → `undefined type or
   module FormBuilder`: aliases are not pasted by `class B < A` → the generator writes the alias into the view class.
3. `class Template` reopened in template/error.sake (Rails nests Template::Error there), required first → `the fields
   of ActionView::Template are declared in its first class` → Template::Error moved into template.sake. The same in
   the generator program, where handlers/erb.sake (class Template::Handlers::ERB) came before template.sake.
4. `ActiveSupport::SafeBuffer.presence(buffer)` (Rails' `buffer.presence`) → undefined; Object.blank? does not know
   SafeBuffer → a small `presence_of`.
5. `requested_details = key || details` (Rails' resolver) → `Requested.formats_idx: argument 1 must be Requested,
   but can be LookupContext::Details`: correct; the resolver takes the Requested only.
6. In url_for's Array branch, `Array.pop(components) if last in Hash` left Hash in the element type →
   `case/in: no in branch matches Hash` deep in polymorphic_routes → components built with a `case` that drops the
   Hash (Rails' extract_options!).
7. A `.rb` fixture beside a `.sake` fixture is run as a comparison test → the Ruby fixtures are `*_ruby.rb`.
8. Rails' own quirks the Ruby side hit: `prefix_tag_option` needs bigdecimal and core_ext/object/json loaded;
   `merge_prefix_into_object_path` crashes when the lookup context has no prefixes (a view without a controller),
   so both tests set `prefixes = ["posts"]` as a PostsController would.

What read well: `<%= render "form", post: post %>`, `render @posts` and `link_to view, "Show", post` are Rails'
lines (with `view,`); the generated templates are ordinary Sake, so `Post.titel(post)` in a template is a check
error at the .erb line, and the checker caught a partial reading its counter in an object render (friction-worthy:
Rails finds that on the request). Most helpers matched Rails on the first full run once they type-checked (tag_helper
and url_helper with no output difference at all).

## Forms (fork A): FormHelper, FormBuilder, Tags, FormTagHelper, FormOptionsHelper, ActiveModelHelper

Tests (each `.sake` beside a `.rb` on the real gem, identical output): `form_tag_helper` (78 lines), `form_helper`
(89 lines: form_with/form_for with models, routes and `_method`, every FormBuilder field, select/collection
helpers through the builder, fields_for/fields, error wrapping), `form_options_helper` (88 lines). The Ruby side sets
the load_defaults 8.1 values the defaults need (`form_with_generates_remote_forms = false`,
`form_with_generates_ids = true`, `multiple_file_field_include_hidden = true`, `default_enforce_utf8 = false`).

| Ruby (actionview-8.1.3/lib/action_view/helpers/) | Sake | Ruby code lines | Sake code lines |
|---|---|---:|---:|
| form_helper.rb (FormHelper + FormBuilder) | form_helper.sake | 423 | 377 |
| form_tag_helper.rb | form_tag_helper.sake | 292 | 269 |
| form_options_helper.rb | form_options_helper.sake | 174 | 158 |
| active_model_helper.rb (ActiveModelInstanceTag) | active_model_helper.sake | 42 | 34 |
| tags.rb | tags.sake | 43 | 9 |
| tags/base.rb | tags/base.sake | 113 | 88 |
| tags/translator.rb | tags/translator.sake | 33 | 18 |
| tags/{text_field,placeholderable,password_field,hidden_field,file_field,number_field,range_field,color_field,search_field,tel_field,url_field,email_field}.rb | tags/text_field.sake | 191 | 117 |
| tags/{datetime_field,date_field,datetime_local_field,time_field,month_field,week_field}.rb | tags/datetime_field.sake | 115 | 62 |
| tags/text_area.rb | tags/text_area.sake | 18 | 25 |
| tags/label.rb | tags/label.sake | 61 | 38 |
| tags/{check_box,checkable,radio_button}.rb | tags/check_box.sake | 103 | 71 |
| tags/{select,select_renderer,collection_select,grouped_collection_select}.rb | tags/select.sake | 137 | 93 |
| tags/{collection_helpers,collection_check_boxes,collection_radio_buttons}.rb | tags/collection_helpers.sake | 149 | 97 |
| **total** | 14 files | **1,894** | **1,456** |

Check times (`bin/sake -c --strict`, machine load ≈1.3, single runs): form_helper **8.4 s / 240 MB**,
form_tag_helper 2.9 s / 145 MB, form_options_helper 2.8 s / 145 MB (tag_helper alone 2.5 s). form_helper is the
one that builds every Tags class; each `class X < Base` is a paste, checked per class (17 tag classes).

### Shapes

| Ruby | Sake |
|---|---|
| `Tags::TextField.new(object_name, method, self, options).render`; `class HiddenField < TextField` with `def render; ...; super; end` | `Tags::TextField.render(Tags::TextField.new(object_name: n, method_name: m, template_object: v, options: o))`: keywords fill the fields, Base's `initialize` does what Ruby's does with them (strip `[]`, take `:object`, auto index). `class HiddenField < TextField` pastes; the parent's body is kept as `super_render` and the child calls it. `Placeholderable#initialize` (`super` then the placeholder) is an `after_initialize` hook that Base's initialize calls. |
| `self.class.field_type` (class name minus "Field", downcased) | `def field_type(t) = "tel"` per class |
| `include ActiveModelInstanceTag` overriding `tag`/`content_tag` (`super` + `error_wrapping`) | the same mixin: its `tag(t, ...)` calls `TagHelper.tag(template_object(t), ...)` and wraps; `field_error_proc` (a Proc in a cattr, `instance_exec`'d on the view) is a view function `field_error_proc(v, html_tag, instance)` |
| Tags include TagHelper/FormTagHelper and build tags themselves | a tag calls the view's helpers: `FormTagHelper.field_name(@template_object, ...)`, `FormTagHelper.label_tag(...)` |
| `object.public_send(@method_name)`; `item.public_send(value_method)` | `ModelNaming::Model.read_attribute_for_validation(object, name)` (ActiveModel's alias of `send`) |
| FormBuilder's 18 field helpers defined by `CodeGenerator` over `field_helpers` | written out, one line each: `def text_field(f, method, options = nil, **kw) = FormHelper.text_field(@template, @object_name, method, objectify_options(f, FormTagHelper.with_keywords(options, kw)))` |
| `f.text_field :title, class: "x"` (an implicit trailing Hash) | `F.text_field(f, :title, class: "x")`: `**kw` merged into the positional options; for select/collection_select, `FormOptionsHelper.fill_with_keywords` puts the keywords in the first of options/html_options not given, which is where Ruby's implicit Hash goes |
| `form_with(**options)` from form_for; `fields(record_name, **options)` from fields_for | `**` passes on only a function's own keywords, so `form_with_options(v, model, scope, url, format, options)` / `fields_with(...)` take the Hash and the keyword forms call them |
| `form_with(model: @post) do \|form\| ... end` (capture(builder, &block)) | `form_with(view, model: post) { \|f\| ... }`: `capture(v) { yield(builder) }` |
| `SelectRenderer`, `CollectionHelpers` mixins | the same mixins; their bare calls reach the tag's pasted functions |
| `CheckBoxBuilder < Builder`, `RadioButtonBuilder < Builder` | one `Builder` with a kind |
| I18n `helpers.submit.create` ("Create %{model}") | the en strings written in submit_default_value; labels/placeholders use the model's human_attribute_name (what Rails gives when the app has no helpers.label keys) |

### Left out, and why

- The object from the view's instance variable (`text_field(:post, :title)` reading `@post`: `instance_variable_get`):
  pass `object:` (FormBuilder always does).
- Nested attributes in `fields_for :comments` (`respond_to?("comments_attributes=")`, `public_send(association)`),
  custom builder classes (`builder:` is a Class), Proc values for `checked:`/`selected:`/`disabled:`, `time_zone_select`,
  `weekday_select` (weekday_options_for_select is ported, English day names), date/time selects (DateHelper's),
  direct uploads, `image_submit_tag`'s asset path (the source as given), SearchField's `autosave: true` (needs the
  request's host), the I18n lookups (see above).
- `DateTime.parse` of a String min/max is `Time.parse`.

### Bugs

- `bugs/actionview_date_in_mixed_container.sake`: an Array or Hash holding a sakelib `Date` and a value of any other
  class is rejected (`date.sake:59: case/in: no in branch matches P`, reached from `Date.<=>`), though nothing
  compares them. Found as soon as a form's options Hash held a record (`object:`) and a Date attribute's value; the
  test's date fields use Time instead. A Rails app's records with Date columns will meet it in every form.
- Run time `BUG: unknown node Sake::AST::Splat` (interpreter.rb:228) when FormBuilder's `field_id(f, method,
  *suffixes, namespace: @options[:namespace], index: @options[:index])` passed `*suffixes` on to the view's
  `FormTagHelper.field_id(@template, ..., *suffixes, namespace:, index:)`. Small programs with the same shape ran fine
  and I could not reduce it in the time; the checker accepted it. Worked around: FormBuilder calls module functions
  taking the Array (`FormTagHelper.field_id_of(object_name, method, suffixes, index, namespace)`).

### Friction (what I wrote first → the message → what I wrote instead)

1. `include SelectRenderer` in `class Select < Base`, with the renderer's needs declared as required functions
   (`def value(t) = raise(NotImplementedError)`) → `Select includes SelectRenderer but does not define value`: the
   include's required stub replaced the function pasted from Base. → declare only what the class itself defines
   (field readers, its own functions); bare calls to pasted functions need no declaration.
2. `if model != false` before `polymorphic_path(v, model, ...)` (model: false | record | Array) → `case/in: no in
   branch matches true|false` in polymorphic_routes.sake: `!= false` does not narrow. → `case model in Array |
   ModelNaming::Model ... else`. The same for `url_for_options == false` → `case url_for_options in false then ...`.
3. Every value read from an options Hash is the union of everything any caller ever put in it (`options[:as]` may
   be the `html:` Hash, `options[:url]` may be `true`) → `param_key dispatches on its first argument, which is
   Hash@L68[...]`. → narrow at each read: `as = options[:as]; (as in String | Symbol) ? as : ...`. Rails' options
   Hashes are the heaviest part of the port for the checker: one value type per Hash, so `object:` (a record) and
   `parent_builder:` (a FormBuilder) end up in the type of every option.
4. `F.select(f, :category, choices, { prompt: "Pick one" }, class: "sel")` → `` `{}` is an empty Record, not a Hash ``
   → `Hash.of(prompt: "Pick one")`, `Hash.new`.
5. `options_for_select(view, xs, disabled: "x")` → `takes no keyword arguments` (Ruby's implicit Hash) → a `**kw`
   that becomes `selected` when it is not given.
6. `Tuple` vs Array for choices: `[["Dollar", "$"]]` is a Tuple of Tuples; option_text_and_value needs
   first/last → the tests write `Any[Any["Dollar", "$"]]`.

What read well: once the checker was satisfied, all three tests matched Rails on their first full run (the only
run-time differences were a test model computing errors before `valid?`); `F.text_field(f, :title, class: "wide",
maxlength: 30)` reads like the template line it replaces.

## Text, number, sanitize and JavaScript helpers, and the sanitizer (fork B)

### What is ported

Code lines here means lines that are neither blank nor comments.

| Ruby | Sake | Ruby lines | Sake lines |
|---|---|---:|---:|
| actionview helpers/text_helper.rb | action_view/helpers/text_helper.sake | 187 | 159 |
| actionview helpers/number_helper.rb | action_view/helpers/number_helper.sake | 79 | 101 |
| actionview helpers/sanitize_helper.rb | action_view/helpers/sanitize_helper.sake | 42 | 25 |
| actionview helpers/javascript_helper.rb | action_view/helpers/javascript_helper.sake | 48 | 32 |
| rails-html-sanitizer-1.7.0 rails/html/sanitizer.rb | rails/html/sanitizer.sake (HTML4 vendor only) | 249 | 53 |
| rails-html-sanitizer-1.7.0 rails/html/scrubbers.rb | rails/html/scrubbers.sake | 133 | 81 |
| loofah-2.25.1 html5/scrub.rb + html5/safelist.rb (tables used), plus (Sake only) a stand-in for Nokogiri's HTML4 fragment parser and libxml2's serializer | loofah/html4.sake | 1,170 (safelist is mostly tables) | 392 |

The version actually loaded is rails-html-sanitizer 1.7.0 with loofah 2.25.1 and libxml2 2.13.9 (packaged with Nokogiri). 1.6.2 is also installed, but `require "action_view"` loads 1.7.0, so the port follows 1.7.0.

Tests are in test/sakelib/rails/actionview/. Each pair below gives identical output:
- `text_helper`: 60 lines. Covers truncate, highlight, excerpt, pluralize, word_wrap, simple_format, cycle, concat and safe_concat, and the JavaScript helpers.
- `number_helper`: 35 lines. Covers all seven helpers, escaping, `html_safe?` and `raise: true`.
- `sanitize_helper`: 193 lines. 48 inputs go through sanitize, strip_tags and strip_links, plus `tags:`/`attributes:` and sanitize_css.

Check time for each test with `bin/sake -c --strict`: about 2.7 s and 120–130 MB. They all require the whole `action_view/base`, so the four cost about the same. Running sanitize_helper takes 3.2 s.

### Shapes

| Rails | Sake |
|---|---|
| `number_to_currency(n, options = {})`, which symbolizes and escapes the options, then calls `ActiveSupport::NumberHelper.public_send(method, number, options)` | One function per helper. It takes ActiveSupport's keywords with their en defaults, escapes the same options (format, negative_format, separator, delimiter, unit unless html_safe, units), and calls the ActiveSupport function by name. `raise: true` is an ordinary keyword parameter called `raise`, and Sake accepts that name. |
| `options.delete(:raise)` → `InvalidNumberError.new(number)` | `InvalidNumberError.new("InvalidNumberError", number)`: the message comes first, then the `number` field. |
| `Float(number, exception: false)` | A `case` over Integer, Float, Rational and String, with `Float(s) rescue nil`. |
| `self.class.safe_list_sanitizer` (memoized per class through a class attribute) | `SanitizeHelper.safe_list_sanitizer = once { Rails::HTML4::SafeListSanitizer.make }`, so one sanitizer per program. |
| Sanitizer classes built from concerns (`include ComposedSanitize, Parser::HTML4, Scrubber::SafeList, Serializer::UTF8Encode`) | Each class writes its composed `sanitize` out: `Sanitizer.composed(html) { \|fragment\| Loofah::Scrubber.scrub!(scrubber, fragment) }`. |
| `class PermitScrubber < Loofah::Scrubber`; `TargetScrubber < PermitScrubber` overriding `allowed_node?` and `scrub_attribute?` with `!super` | The scrubbers include the mixin `Loofah::Scrubber` (traverse, scrub!). `class TargetScrubber < PermitScrubber` pastes the class and redefines the two functions. `!super` is written as the negated body, because there is no super. |
| `scrub` returning `CONTINUE` or `STOP` constants | The Symbols `:continue` and `:stop`. |
| Nokogiri `node.before(node.children)`, `node.remove`, attribute nodes | `Loofah::Node` (kind, name, content, attrs, children, parent) and `Loofah::Attr`. Nodes are removed by identity (`Kernel.equal?`), because `==` on a Sake class compares fields, so two equal sibling text nodes would otherwise both be deleted. |
| `@_cycles ||= {}` (`defined?`) | The view's `_cycles` field, read and written through the required functions `_cycles(v)` and `set__cycles(v, h)` (the mixin cannot read the field). |
| `cycle("odd", "even", name: "x")` (extract_options!) | `cycle(v, first_value, *values, name: "default")`. |
| `simple_format(text, html_options = {}, options = {})` | `simple_format(v, text, html_options = nil, wrapper_tag:, sanitize:, sanitize_options:)`. The html options are a Hash argument, and Rails' second options Hash is keywords. |
| `highlight(text, phrases) { \|m\| ... }` (`gsub!(pattern, &block)`) | `String.gsub(s, pattern) { \|m\| yield(m) }`. |
| `JS_ESCAPE_MAP` constant | `JavaScriptHelper.js_escape_map = once { Hash.of(...) }`. |

### The sanitizer: how Loofah over Nokogiri is approximated, and where it can differ

`loofah/html4.sake` contains a tokenizer and tree builder:
- start tags with attributes in double, single or no quotes; a duplicate attribute keeps the first value
- end tags: a stray one is ignored, and one that matches closes everything above it
- comments, `<!...>` and `<?...>`, which are skipped
- `script` and `style` content kept as a CDATA node, as libxml2 does. That CDATA node is why strip_tags drops script text while sanitize keeps it escaped, exactly as Rails does.
- libxml2's HTML4 void elements
- implied end tags: p is closed by block starts, and li, dt/dd, option, tr and td/th close their siblings
- entities: about 60 named ones plus numeric references. An unknown or unterminated reference stays as text, so `&amp b` becomes `&amp;amp b`, as libxml2 does.

The serializer copies libxml2 2.13's `htmlNodeDumpFormatOutput`:
- text escapes `&`, `<` and `>`, and leaves non-ASCII raw
- attribute values are escaped the same way. They are double-quoted, or single-quoted when the value holds `"` but no `'`; when it holds both, double quotes with `&quot;`.
- boolean attributes are written bare
- newlines around non-inline elements follow libxml2's rules: only when there is more than one child, never directly after a text node, and never inside an element whose name starts with "p" (libxml2 checks `name[0] != 'p'`)
- the list of non-inline elements was taken from libxml2 by probing Nokogiri; unknown elements get no newlines

Loofah's URI check, `force_correct_attribute_escaping!` (`%20`/`%22` in href/src/action, and in name on `<a>`) and the protocol and data-mediatype allowlists are ported as they are.

`scrub_css` uses a small tokenizer in place of Crass. It splits declarations at `;` outside parentheses and strings, and splits values into whitespace, string, url, function, ident and other tokens. The filtering is Loofah's: properties, SVG properties, shorthand keywords, allowed functions and `!important`. The keyword list holds the CSS keywords plus the 16 basic colour names; Loofah's full list adds about 130 more colour names, which this port drops in shorthand properties.

Where it can differ from Nokogiri:
- **Error recovery.** Misnested tags are handled by popping to the matching open element; libxml2 has priority tables for this. An unclosed `<table>` or `<select>`, inline content around block elements, and `<p>` inside inline elements may build a different tree.
- **Whitespace.** libxml2 drops blank text nodes in some element contexts (between `<ul>` and `<li>` with `areBlanks`); this port keeps all text.
- **`<html>`, `<head>` and `<body>`** inside a fragment are kept as elements; libxml2 drops them.
- **Entities.** Named entities outside the table are left undecoded, though libxml2 knows all 253 HTML4 ones. Control characters from numeric references are not rejected.
- **CSS.** Crass's grammar is far fuller: escapes, comments, nested functions more than two levels deep, `url(` spelled with escapes.
- **This is not the HTML5 parser** (Rails::HTML5::Sanitizer, Nokogiri's gumbo). The HTML5 parser would differ on implied `<tbody>`, foster-parenting in tables, `<textarea>`/`<title>` as RCDATA, and serialization quoting. ActionView's default vendor is HTML4, and HTML4 is what was compared.

### Left out

- `:scrubber` in sanitize, because Rails passes it a scrubber object.
- `sanitizer_vendor` (HTML5): there is no HTML5 parser.
- Loofah's fallback safelist when tags or attributes are nil. Rails' sanitizers always set both, so this path is never taken.
- SVG `xlink:href` and local-ref scrubbing.
- `locale:` in pluralize and the number helpers. ActiveSupport's port covers en only, so `locale:` is accepted and ignored.
- `javascript_tag` with `nonce: true` / `auto_include_nonce`, because the nonce comes from the controller.
- A cycle receiving its builder in the block.

### Friction (what I wrote first → the message → what I wrote instead)

- `String.match(m, pattern)&.[](1)` → `method call on a value ... is not allowed` (with a list of hints) → I used `String.gsub(text, pattern, "\\1#{break_sequence}")`, as Rails does.
- `[String.length(part) - radius, 0].max` → `method call on a value` (hint: `Tuple.max([...])`) → `Integer.clamp(...)`.
- The number helpers: Rails escapes some options and passes the Hash on, but Sake's `**` only passes on a function's own keyword parameter, unchanged. So each helper lists ActiveSupport's keywords and their defaults again. That is why the Sake file (101 lines) is longer than the Ruby one (79).
- Good: the keyword parameter named `raise` (Rails' `raise: true` option) works and does not shadow the `raise` used inside helper bodies. Paste-and-redefine (`TargetScrubber < PermitScrubber`) worked the first time. The 1,000-line scrubbing and serializing path gave 193 lines identical to Nokogiri on its first run that type-checked. Most of the effort went into reading libxml2's behaviour, not into Sake.
- Probing Rails turned up a Rails quirk: `content_tag(..., data: {count: 3})` raises `NameError BigDecimal` unless bigdecimal and `active_support/core_ext/object/json` are loaded. The tag test's .rb requires both, as an app would have them.

## Date, translation, asset, CSRF and CSP helpers (fork C)

| Ruby (actionview-8.1.3/lib/action_view/) | Sake (sakelib/rails/actionview/action_view/) | Ruby lines | Sake lines |
|---|---|---:|---:|
| helpers/date_helper.rb, helpers/tags/{date_select,time_select,datetime_select}.rb | helpers/date_helper.sake | 543 | 514 |
| helpers/translation_helper.rb + activesupport's html_safe_translation.rb | helpers/translation_helper.sake | 125 | 130 |
| helpers/asset_tag_helper.rb | helpers/asset_tag_helper.sake | 263 | 206 |
| helpers/asset_url_helper.rb | helpers/asset_url_helper.sake | 142 | 125 |
| helpers/csrf_helper.rb | helpers/csrf_helper.sake | 15 | 17 |
| helpers/csp_helper.rb (+ the controller's content_security_policy?/nonce helper methods) | helpers/csp_helper.sake | 13 | 24 |
| action_view.rb's `on_load(:i18n) { I18n.load_path << "locale/en.yml" }`, active_support/i18n.rb's | locale.sake (Sake only), locale/en.yml (actionview's file), locale/active_support_en.yml (a copy of activesupport's) | — | 3 |

Tests (each identical to the real gem): `date_helper` (1146 lines: distance_of_time_in_words over 21 distances with and
without include_seconds, Dates, Integers, the error; time_ago/relative_time_in_words; time_tag; every select_* with
order/prefix/field_name/discard_*/prompt (String, true, Hash)/include_blank/use_month_numbers/add_month_numbers/
use_short_month/month_format_string/use_two_digit_numbers/ampm/start_hour/minute_step/with_css_classes/namespace/
disabled/index/discard_type/max_years_allowed; date_select/time_select/datetime_select of a record), `translation_helper`
(25 lines: interpolation, locales, `_html` keys with escaped values and html_safe Arrays, count, Arrays of keys,
missing spans with their titles, default: String/Symbol/Array/nil, raise: true/false, `.relative` keys from the
virtual path (template and partial), the block form, the no-path error, l/localize), `asset_tag_helper` (71 lines: every
*_path/*_url, host:/protocol:/extname:, config.asset_host with `%d` (CRC32), relative_url_root, the request's protocol,
javascript_include_tag/stylesheet_link_tag with nonce/crossorigin/type: module, auto_discovery_link_tag, favicon,
preload_link_tag with as/type/crossorigin/fetchpriority and the request's nonce directives, image_tag with size/srcset
(Hash, Array, String), picture_tag, video_tag, audio_tag, csrf_meta_tags, csp_meta_tag).

Check times (`bin/sake -c --strict` on the full ActionView::Base, single runs): date_helper 4.25 s / 176 MB, asset_tag_helper
3.32 s / 148 MB, translation_helper 3.13 s / 137 MB. Earlier, on a view class that includes only these helpers
because the full helpers.sake did not check while the form fork was mid-edit): date_helper 3.75 s / 154 MB,
asset_tag_helper 3.00 s / 137 MB, translation_helper 2.68 s / 122 MB.

### Shapes

| Rails | Sake |
|---|---|
| `I18n.with_options locale:, scope: do \|locale\| case distance_in_minutes when 0..1 ... locale.t(:x_minutes, count:)` | `DateHelper.distance_words(...)`: the same ladder as `if`/`return`s, `tr(key, count, scope, locale)` for `locale.t` |
| `%w(sec min hour day month year).each { define_method(m) { case @datetime when Hash ... else @datetime.send(m) } }` | one `part(s, name)` with a `case` over Hash / Integer / nil / Time / TimeWithZone / Date, and six one-line readers |
| `public_send("select_#{type}")` in build_selects_from_types | a `case type in :year then select_year(s) ...` |
| `Tags::DateSelect.new(object_name, method, self, options, html_options).render` (select_type from the class name, value by `object.public_send(method)`, error_wrapping) | `DateHelper.tags_render(v, :date, ...)`; the record is `options[:object]` narrowed with `in ModelNaming::Model`, read with `read_attribute_for_validation`, errors through `errors_for` and the view's `field_error_proc` |
| DateTimeSelector `include TagHelper` | it holds the view (`template`) and calls `TagHelper.content_tag(@template, ...)`: a TagHelper includer must have the view's fields |
| `MISSING_TRANSLATION = -(2**60)` passed as I18n's default to detect a miss | a strict lookup (`I18n.translate_with(..., strict = true)`) and `rescue I18n::MissingTranslationData` |
| `I18n.translate(key, **options)` | the options Hash taken apart: locale, scope, count, separator, the rest are interpolation values |
| `mattr_accessor :image_loading`, `config.asset_host`, `config.relative_url_root`, helper_methods from the controller | functions of the view with Rails' defaults (nil / false), overridden by a view class (the test's `class AppView < ActionView::Base`) |
| `Template::Types[ext]` | `Mime.[](ext)` from ActionDispatch (Rails' value once actionpack is loaded) |
| `Zlib.crc32(source) % 4` for `assets%d.example.com` | a bitwise CRC32 in Sake (`AssetUrlHelper.crc32`): Sake's Zlib has no crc32 |

### Left out

- `:day_format` / `:year_format` lambdas (stored blocks); a Proc `asset_host` (same).
- Preload Link headers (`send_preload_links_header`): the view has no response, Sake's Request has no early hints.
  (`preload_links_header` is nil outside an app, so only preload_link_tag would send one.)
- Records as asset sources (`polymorphic_url`), `auto_discovery_link_tag` with a Hash of url_options (url_for on the
  routes): a String URL only.
- `TranslationHelper.raise_on_missing_translations=` (a function returning false), the I18n exception_handler call.
- FormBuilder#date_select & co. delegations: the FormBuilder's file (they call `date_select(@template, @object_name,
  method, objectify_options(options), html_options)`).

### Built-ins / checker requests

- `Zlib.crc32` (written in Sake for the asset host's `%d`).
- (activesupport) an i18n railtie: ActionView needs activesupport's locale/en.yml (date names, formats, order); a copy
  is shipped as locale/active_support_en.yml.

### Friction (what I wrote first → the message → what I wrote instead)

- `raise StandardError, "..."` → `` `raise T, message` needs an exception type, got `StandardError` `` → `RuntimeError`
  (Rails raises StandardError itself; Sake has no StandardError value).
- TranslationHelper calling `content_tag(v, "span", ..., class: "translation_missing", title: title)` without
  `include TagHelper` → `keyword arguments go only to functions with keyword parameters` — the real cause was that the
  module did not know content_tag at all; the message pointed at the keywords. → `include TagHelper` (as Rails does).
- CsrfHelper declaring `def protect_against_forgery?(v) = raise(NotImplementedError)` → `ActionView::Base includes
  CsrfHelper but does not define protect_against_forgery?`: ControllerHelper (included earlier into Helpers) defines
  it, and the later include's required declaration hides it — Ruby's order (a later include wins), so not a bug, but a
  required declaration is not a neutral "I need this". → `include ControllerHelper` in CsrfHelper, `include CspHelper`
  in AssetTagHelper.
- `options[:object]` used directly as the record → `ModelNaming::Model.read_attribute_for_validation dispatches on its
  first argument, which is Integer | true|false | Array | Date ...`: every value of the options Hash flows there. →
  `o = options[:object]; object = (o in ModelNaming::Model) ? o : nil`. The message listed the whole union, which made
  the cause obvious.
- Rails' own quirks the twins hit: `prefix_tag_option` needs BigDecimal loaded; `time_tag` needs core_ext
  (`reverse_merge`), so the `.rb` requires `active_support/core_ext`; with core_ext a String has to_time, so the
  "can't be converted" error is shown with a Symbol; `asset_url` without a request crashes on `nil.protocol`, and
  `preload_link_tag` with a nonce but no request crashes too, so the test gives AppView a request.
- Good: the 1146-line date test and the asset test matched Rails on their first complete run once checked; the
  options Hash of mixed values (`Hash.of(order: Any[:month, :day], prompt: Hash.of(day: "..."), start_year: 2024)`)
  went through with one `(x in Integer) ? x : default` per numeric option.
