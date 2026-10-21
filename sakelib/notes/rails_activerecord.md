# Rails 8.1.3 part 6: ActiveRecord's model layer (2026-10-20)

Base and its modules, attributes from the schema, persistence, Relation and querying, callbacks, validations,
transactions, timestamps, locking, enum/store/secure_token, associations, and migrations, on the committed Arel
and SQLite3 adapter (rails_arel.md) and ActiveSupport (rails_activesupport_{a,b}.md). Programs reach it as
`require "rails/activerecord/active_record"` and generate their models with

```ruby
generate "rails/activerecord/active_record/generate/active_record", "db/schema.rb", "app/models.rb"
```

The core (Base's modules, persistence, a first Relation, the generator, the stand-ins) was written first; then
four forks took relation, associations, features and migrations; their notes are the last four sections. The third
wave (part 10) put the model layer on part 5's ActiveModel and removed the stand-ins: see "ActiveModel" below.

## Summary

About 14,000 Ruby code lines of activerecord-8.1.3 (lib/active_record: core, model_schema, persistence,
attribute_methods/*, attribute_assignment, connection_handling, errors, validations (+uniqueness), callbacks,
transactions, timestamp, locking/*, counter_cache, enum, store, secure_token, relation.rb and relation/*,
querying, sanitization, scoping/*, associations.rb and associations/* with reflection, autosave and
nested_attributes, migration.rb and migration/*, schema, schema_migration, internal_metadata, schema_dumper,
translation, integration (to_param), serialization) are ported in about 4,250 Sake code lines, of which about 1,050
are the generators (`active_record/generate/`, Sake only). Code lines exclude blanks and comments; the Ruby side
counts whole files, left-out parts included. Per-part tables are in the sections below. (Until the third wave 290
more lines were stand-ins for ActiveModel; they are gone, and ActiveModel's own modules run.)

Tests (`ruby -Ilib test/test_sakelib.rb -n /rails_activerecord/`: 13 runs, 0 failures, generate.sake has no twin).
Each `.sake` prints what its `.rb` prints on the real gem against sqlite3 `:memory:`, with the SQL each step runs
(a `sql.active_record` subscriber on both sides):

| test | what | check (`bin/sake -c --strict`, load ~2-3; the third wave's numbers are in "ActiveModel" below) |
|---|---|---|
| base | attributes from the schema, build/save/create/find/where/order/count/pluck/exists?, dirty tracking, update, reload, validations, callbacks, destroy, inspect; (third wave) model_name, human_attribute_name, validators, to_key/to_param, errors' details/messages with i18n overrides, serializable_hash/as_json/to_json/from_json, a plain ActiveModel form in the same program | 8.3 s, 234 MB |
| relation | where (Hash, nil, Array, Range, subquery, ?/named binds), where_not/or/and/rewhere/invert_where, order/reorder/reverse_order, limit/offset, select/distinct, group/having and grouped calculations, pluck/pick/ids, first/last/take, find_some, exists?, find_or_create_by, create_with, update_all/delete_all/destroy_all, update_counters, batches, merge/except/only, none, readonly, to_sql, inspect | 16.5 s, 319 MB |
| scoping | named scopes as functions, default_scope, unscoped | 10.8 s, 266 MB |
| associations | belongs_to, has_one, has_many (a CollectionProxy class per model), :through, habtm, includes/preload, joins/left_joins, where(author: record), dependent (5 kinds), counter_cache, autosave, nested attributes, inverse_of, "must exist" | **80.0 s, 592 MB** (bugs/activerecord_slow_check_associations/; 25.5 s after the lead's db3ea041, 33 s on ActiveModel) |
| callbacks | every model callback kind in Rails' order, around, throw :abort, conditions, commit/rollback callbacks, uniqueness with scope/on | 11.9 s, 300 MB |
| features | enum, store, secure token, attr_readonly, attribute API, readonly!, optimistic and pessimistic locking, counters, touch, record_timestamps, update_columns, savepoints | 24.1 s, 400 MB |
| transactions | Post.transaction, Rollback, RecordInvalid rolling back, joined transactions, state restored, commit/rollback callbacks | 8.0 s, 235 MB |
| migrations | change/up/down/reversible/revert, the verbose output, migrate/rollback/to a version, status, irreversible, the alter_table copies | 5.9 s, 177 MB |
| schema_dumper | db/schema.rb loaded, dumped back byte for byte, changed by a migration, dumped again | 5.6 s, 180 MB |
| generate | prints the generated source for base's schema and models (no twin) | |

The check time grows with the models: each model gets its own copies of the Base modules and of Relation (and of
CollectionProxy/AssociationRelation per association target), so associations' 7 models are 80 s where base's one
model is 8 s. That is the measurement this effort is after; the repro keeps the generated source.

## The shape of a model

Ruby's model is a class with ~40 modules (`class Post < ApplicationRecord`), class-level state in the class
object, attribute methods defined from the table at first use, and class-body lines that store code
(`validates`, `before_save`, `has_many`). Four Sake facts decided the shape:

1. **Only a class has fields, and a module that includes a module cannot give it fields.** `module Base;
   include Core; end` with Core using `@new_record` is rejected ("Base is not a class with field new_record",
   repro `bugs/activerecord_module_in_module_fields.sake`). So ActiveRecord::Base is Rails' *include list*,
   and the generated model includes those modules itself, in Rails' order, then its abstract parents:

   ```ruby
   # Ruby                                   # generated (generate/model.sake)
   class ApplicationRecord < ActiveRecord::Base   module ApplicationRecord
     self.abstract_class = true                   end
   end
   class Post < ApplicationRecord             class Post
     validates :title, presence: true           attr_accessor attribute_set, new_record, ..., errors_or_nil, ...
     before_save :normalize_title               include ActiveRecord::Core
   end                                          include ActiveRecord::Persistence
                                                ... (Rails' Base list) ...
                                                include ApplicationRecord
                                                def initialize(r)
                                                  init_internals(r, true)
                                                end
                                              end
   ```
   The class body is a file both sides read (`base_models.rb`: Ruby requires it, the generator parses it), and
   the program reopens `class Post` for its own methods (`def normalize_title(post)`), as the 10-12 framework did.
   An abstract class is a module (Arel's "a Ruby superclass is a module"); STI is rejected by the generator.

2. **No class objects.** Rails' per-class state (@table_name, @columns_hash, @attribute_types,
   @default_attributes, @arel_table, reflections, enum mappings, ...) is one value of `ActiveRecord::ModelClass`
   (Sake only) per model, the generated `def Post.__model = once do ... end`; the class methods are mixin
   functions without an instance (`def table_name = ModelClass.table_name(__model)`), copied into each model, so
   `Post.table_name`, `Post.where(...)`, `Post.find(1)` read as Ruby.

3. **A container has one element type per site.** A generic Relation holding records would mix Posts and
   Comments. Rails itself makes a relation class per model (`Post::ActiveRecord_Relation`,
   relation_delegate_class); the generator does too, with `Post[]` records and `instantiate_row` calling
   `Post.instantiate`. ActiveRecord::Relation is the module those classes include, with QueryMethods,
   FinderMethods, Calculations, SpawnMethods, Batches. `Post.where(published: true)` is
   `Relation.where(Post.all, ...)`, and the chain names the module: `Post.where(...).ActiveRecord::Relation.order(...)`.
   Ruby's `@values` Hash (where_clause, order_values, limit_value, ...) is the class Relation::Values.

4. **Attribute values are one union.** Rails keeps attributes in an ActiveModel::AttributeSet of
   ActiveModel::Attribute (FromDatabase/FromUser with lazy casting and the original for dirty tracking): ported
   as such, and dirty tracking is ActiveModel::Dirty's (an AttributeMutationTracker over the set, and the one of
   the last save for `saved_changes`; `changes` is a HashWithIndifferentAccess, as in Ruby). The value of any Attribute is the union of every type's cast
   (Integer|String|Time|Date|BigDecimal|Hash|...), so the generated reader narrows to the column's type:

   ```ruby
   def Post.title(r)                      # Ruby: define_method(:title) { _read_attribute("title") }
     v = Post._read_attribute(r, "title")
     case v
     in String then v
     in nil then nil
     else raise TypeError, "Post#title is #{Kernel.inspect(v)}"
     end
   end
   def Post.title=(r, value)              # post.Post.title = "x" calls it
     Post._write_attribute(r, "title", value)
     value
   end
   def Post.title_changed?(r) = Post.attribute_changed?(r, "title")   # and ?, _was, _change, _in_database,
                                                                        # saved_change_to_*?, will_save_change_to_*?, ...
   ```
   and the union is what made the type ports fragile (below).

## The super chain without super

Rails' save is `Transactions#save > Validations#save > Persistence#save`, create_or_update is
`Callbacks#create_or_update > Persistence`, `_create_record` is `Timestamp > Callbacks > AttributeMethods::Dirty >
Locking::Optimistic > CounterCache > Persistence`. Each module's body has its own name and calls the next one in
Base's order, which Ruby resolves at run time and the port writes down:

```ruby
# Ruby (each in its module)                    # Sake
def save(**options)  # Transactions            def save(r, validate: true, context: nil) = save_with(r, validate, context)
  with_transaction_returning_status { super }  def save_with(r, validate, context)
end                                              with_transaction_returning_status(r) { validations_save(r, validate, context) } == true
def save(**options)  # Validations             end
  perform_validations(options) ? super : false def validations_save(r, validate, context)
end                                              perform_validations(r, validate, context) ? persistence_save(r) : false
def _create_record   # Callbacks               end
  _run_create_callbacks { super }              def callbacks__create_record(r) = _run_create_callbacks(r) { dirty__create_record(r) }
end
```

Callbacks are ActiveSupport::Callbacks (part B): the generator writes Rails' `define_model_callbacks` lines and
maps each `before_save :x, if: :y` to `set_callback :save, :before, :x, if: :y`, then calls
`ActiveSupport::Callbacks::Generate.class_source`, so `_run_save_callbacks`, halting with `throw :abort`, around
callbacks and conditions are part B's code. `validates :title, presence: true, length: {minimum: 3}` goes to
ActiveModel's generator (`ActiveModel::Validations::Generate.expand`), which makes validator objects
(`def Post.__validator_0 = once { ActiveModel::Validations::PresenceValidator.new(Hash.of(attributes: Any[:title], class: "Post")) }`)
run as `:validate` callbacks (`__validate_0`) in their order with `validate :method` lines, which is how Rails
orders them; `on: :create` becomes a generated condition `__on_create?`.

## The SQL is Rails'

The adapter's `log` now instruments `sql.active_record` through ActiveSupport::Notifications (and still keeps
query_log), so each test subscribes a listener in Sake and a block in Ruby and both print the statements: the
INSERT with partial inserts and `RETURNING "id"`, `BEGIN immediate TRANSACTION`/`COMMIT TRANSACTION` around
saves, the UPDATE of the changed columns and updated_at, `LIMIT ?` binds, `SELECT 1 AS one ... LIMIT ?` for
exists?, `IN (?, ?)`, string conditions as `(views > ?)` with BoundSqlLiteral.

## ActiveModel (third wave: integrated)

Until the third wave the model layer ran on stand-ins (`active_record/stand_in/`: Errors, Error, Name, the
validators, AttributeSet); now the generated model includes part 5's ActiveModel as Rails' Base does, and one
program can require ActiveRecord and define plain ActiveModel classes next to the records (base.sake's
`PostForm`, generated by ActiveModel's generator from `base_form.rb`). What changed:

| Ruby | Sake now |
|---|---|
| `class Base; include ActiveModel::API` (AttributeAssignment, Validations with Naming/Translation, Conversion) | `include ActiveModel::API` first in the model (base_modules) |
| `extend Translation` (i18n_scope :activerecord, lookup_ancestors) | translation.sake, included after API so its two functions win |
| AttributeMethods::Dirty `include ActiveModel::Dirty` | `include ActiveModel::Dirty` before ActiveRecord::AttributeMethods; ActiveRecord's dirty.rb part (saved_change_to_attribute?, attribute_in_database, will_save_change_to_attribute?, changes_to_save, ...) on its two trackers |
| ActiveRecord::Callbacks `include ActiveModel::Validations::Callbacks` | included after ActiveRecord::Callbacks (run_validations! inside the :validation chain) |
| Serialization `include ActiveModel::Serializers::JSON` | both included, Serializers::JSON first (as_json, to_json, from_json, serializable_hash minus the inheritance column) |
| Integration#to_param, `self.param_delimiter = "_"` | integration.sake (partial: to_param) over ActiveModel::Conversion |
| `@errors`, `@context_for_validation`, `@attributes`, `@mutations_from_database`, `@mutations_before_last_save` | the record fields `__errors`, `__context_for_validation`, `__attributes`, `__mutations_from_database`, `__mutations_before_last_save` (ActiveModel's names for them) |
| `validates ...`, `validate :m`, `validates_*_of` | ActiveModel's generator (`Validations::Generate.expand/source`) on an `ActiveModel::Generate::Info` that generate/model.sake builds per model; its new field `validator_namespaces` puts `ActiveRecord::Validations` (uniqueness) before ActiveModel's validators, Ruby's const_get from an ActiveRecord class |
| UniquenessValidator < ActiveModel::EachValidator | the same (`class UniquenessValidator < ActiveModel::EachValidator`), with Rails' error options (`value:` among them) |
| `send(name)` (read_attribute_for_validation, `%{value}`, serializable_hash's methods:) | generated `__send`: the columns, the singular associations, the names the validations read |
| RecordInvalid.new(record) through I18n, en.yml (`must exist`, `has already been taken`, restrict_dependent_destroy) | validations.sake and `active_record/locale/en.yml` (copied), loaded with ActiveModel's at the first record (`ActiveRecord.load_locale`) |
| belongs_to required: `validates_presence_of name, message: :required` | the generated check adds `:blank, message: :required` (details say `error: :blank` as Ruby's) |
| `errors.add(:base, :"restrict_dependent_destroy.has_many", record:)` | the same key through I18n |
| ActiveRecord::UnknownAttributeError = ActiveModel::UnknownAttributeError | the same alias; the generated `_assign_attribute` (Ruby's public_send of the setter, which ActiveModel::AttributeAssignment requires; it was `__assign`) ends in `attribute_writer_missing` |

ActiveModel got what ActiveRecord needs, each as Ruby has it: AttributeSet::Builder (the set of a row; eager, no
LazyAttributeSet) and a public `attributes` reader (Ruby's protected one), `super_valid?` and
`super_serializable_hash` (the no-super names that ActiveRecord's overrides call).

**ActiveRecord::Result** now carries the column types as Rails': perform_query prepares a SQLite3::Statement,
binds, steps or reads the rows, and maps `SQLite3::Statement.types` through the type map, so
`select_all(...).cast_values` casts a `boolean` column to true/false and `datetime(6)` to Time (the adapter test
prints both), and pluck falls back to the result's column type for a non-attribute column. No statement cache
(Ruby's `@statements[sql]` when prepared statements are on): each query prepares and closes.

**Check time** (`bin/sake -c --strict`, the same checker (after the lead's db3ea041), load ~1; "stand-in" is HEAD's
code with `stand_in/` restored, "ActiveModel" the integrated tree):

| test | stand-in | ActiveModel |
|---|---|---|
| base (+ the new ActiveModel section and the form) | 7.0 s, 244 MB | 9.0 s, 298 MB |
| relation | 9.4 s, 304 MB | 10.0 s, 317 MB |
| scoping | 7.2 s, 249 MB | 8.0 s, 263 MB |
| associations | 25.5 s, 449 MB | 33.1 s, 537 MB |
| callbacks | 9.3 s, 274 MB | 11.5 s, 318 MB |
| features | 16.7 s, 391 MB | 18.6 s, 424 MB |
| transactions | 6.2 s, 239 MB | 7.1 s, 263 MB |

Repeated (four runs each, alternating): associations 25.2-26.3 s (stand-in) against 31.9-33.1 s (ActiveModel),
features 16.5-17.6 s against 18.1-18.8 s.

So ActiveModel's modules cost about 10-30 % more check time. Why is a guess, not measured: its Errors/Error ask the
record's class through module dispatch (human_attribute_name_of, model_name_of, read_attribute_for_validation), whose
subject is the union of every model, and the trackers and HashWithIndifferentAccess are more code than the stand-in's
reads of the set. Checking without Dirty, or without the i18n message path, would tell these apart.

**Friction of the integration**
- `module ActiveRecord::Translation; include ActiveModel::Translation; end` (Rails' shape) → "ActiveRecord::Translation.lookup_ancestors
  needs `__model` from a namespace that includes ActiveRecord::Translation": the included module's functions are checked
  in the including module, which has no model → the model includes ActiveModel's module itself (through API) and
  ActiveRecord's module defines only its two functions. The same for Serialization over Serializers::JSON. Rails'
  `include` inside a concern becomes "the class includes both, in Ruby's order" every time a module needs the includer.
- `Post.previous_changes(post).Hash.keys` → "Hash.keys: argument 1 must be Hash, but is ActiveSupport::HashWithIndifferentAccess"
  once Dirty was ActiveModel's → `.ActiveSupport::HashWithIndifferentAccess.keys` (Ruby's HWIA is a Hash; Sake's is a class).
- `ActiveModel::AttributeSet.attributes(set)` from ActiveRecord → "field `attributes` of S is private" → made public
  (Ruby's is protected; Sake has no protected).
- `select_all(...).cast_values.first.map { }` → "Array.map: argument 1 must be Array, but can be true|false | Float | ..."
  (cast_values of one column is the values) → `row => Array` first.
- A shared git index: `git rm -r stand_in` staged the deletion, and another agent's commit (db3ea041) took it along,
  so HEAD has active_record.sake requiring the deleted files until this wave is committed. Use plain `rm` when others
  commit from the same tree.

What read well: the swap was mostly deletions (the stand-ins, ActiveRecord's own validator generator and dirty
functions), and every test printed what Rails prints on the first run after it compiled, the new ActiveModel
section of base (validators, errors' details, i18n overrides, JSON) included.

## Built on, and changed in, the first wave's files

- `relation/query_attribute.sake`: `class Relation` became `module Relation` (ActiveRecord::Relation is the
  module the per-model relation classes include).
- `connection_adapters/abstract_adapter.sake`: `log` instruments `sql.active_record`; `sqlite3`'s Column has
  `raw_default_value` (the default as the database gives it, which `_default_attributes` deserializes as Rails).
- `errors.sake`: RecordNotFound with Rails' fields, RecordNotSaved, RecordNotDestroyed, ReadOnlyRecord,
  UnknownAttributeError, ...; Ruby raises ActiveRecordError itself, a module here, so `PlainActiveRecordError`.
- ActiveModel::Type (activemodel/active_model/type/*): `a == b` and `value == ""` on attribute values went through
  Date's `<=>` with a non-Date (date.sake:59, fixed by the lead in 23307e9a); the comparisons now use
  `ActiveModel::Type.same_value?` and `(v in ::String) && v == ""`; the multiparameter Hash keys and values
  are narrowed; Integer's deserialize no longer calls `Arithmetic.to_i` on any value.

## Left out (core; the parts' own lists are below)

- STI (`class Admin < User`, the inheritance column): the generator rejects a non-abstract parent. A model would be
  a class including the parent's modules, and `User.all` would have to instantiate either class: one function, two
  result types.
- Ruby's one-name-two-forms methods: `Post.update(id, attrs)`, `Post.destroy(id)`, `Post.delete(id)` (the instance
  forms keep the names), `find(1, 2)` (find_some), `first(3)` (first_n), `count` on a grouped relation
  (group_count), `where.not` (where_not), `ActiveRecord::Base.transaction` (a model's `Post.transaction`).
- Block-taking class methods that would store the block: `scope :x, -> {}`, `default_scope { }`, callbacks given as
  blocks or objects, `extending`; they are named functions instead.
- Connection pools, handlers, multiple databases, the query cache, the schema cache, async queries, explain,
  encryption, signed ids, token_for, normalizes, suppressor, no_touching, marshalling, fixtures (time).
- validates_associated and validates_with (no AssociatedValidator yet), as_json/to_json of records.

## Friction (what I wrote first → the message → what I wrote instead)

1. `module Base` including Core, Persistence, ... (Rails' Base) → "`include ActiveRecord::Core` in
   ActiveRecord::Base: ... uses `@new_record`, but ActiveRecord::Base is not a class with field `new_record`", 60
   such lines → the model includes the modules itself (generated). The design decision of the whole part.
2. `def create(**attributes) = (r = build(**attributes); save(r))` in Persistence (build is Core's, defined in
   the includer) → "keyword arguments go only to functions with keyword parameters" → positional `build_with(Hash)`
   and `save_with(r, validate, context)` for every module-internal call; the keyword forms are kept for callers
   (repro `bugs/activerecord_mixin_keyword_call_to_includer.sake`).
3. A field `errors` (Ruby's @errors) and the Validations function `errors(r)` → the field's reader silently won,
   so `Post.errors(post)` could be nil at --strict ("ActiveModel::Errors.errors: argument 1 may be nil") → the
   field is `errors_or_nil`. Same trap as part 3's `value`; a warning for a field that shadows an included function
   would save the hunt.
4. `def find(*ids)` returning a record or an Array (Rails) → 60 errors "Post.attribute_set: argument 1 must be
   Post, but can be Array" across every module → `find(id)` and `find_some(ids)`. Ruby's "one method, two result
   types" is the most common Rails idiom that has no Sake form.
5. `ActiveRecord::Relation` was already a `class` (a namespace for QueryAttribute in part 3) → `module`.
6. `def []=(r, name, value) = write_attribute(...)` → "a setter method cannot be defined in an endless method
   definition" (Ruby's own rule) → def ... end. Same for the generated `title=`.
7. `post.Post.title = "x"` works with a generated `def Post.title=(r, value)`: the field-writer syntax reaches a
   user-defined setter, which made the attribute writers read as Ruby.
8. `BigDecimal(str)` (Kernel-style) inside a mixin → "needs `BigDecimal`, which ActiveRecord::Relation does not
   define" → `BigDecimal.parse` / `BigDecimal.of`.
9. The Date union: once records, relations and validators exist, every Attribute holds every type's value, and
   the first-wave type code (written against narrower values) failed in date.sake through `==`. Finding the
   comparison took the longest: the "reached by" chain ended at a validator's call, and the failing `==` was
   several calls further. Fixed at the source by the lead; the port uses `same_value?` meanwhile.
10. `Post.find(1)` in the Sake test, `Post.new(...)` → `Post.build(...)` (Rails 8.1's alias; `new` is Sake's
    constructor), `post.save` → `Post.save(post)`, `post.errors.full_messages` →
    `ActiveModel::Errors.full_messages(Post.errors(post))`, `Post.where(...).order(...)` →
    `Post.where(...).ActiveRecord::Relation.order(...)`: the test files are about 1.4x Ruby's characters.

What read well: the generated class body is ordinary Sake that the checker reads with the program, so a
`before_save :normalise_title` typo is an error at base_models.rb's line before anything runs; the SQL matched
Rails' on the first run of the base test (partial inserts, lazy BEGIN, RETURNING); dirty tracking is Rails'
AttributeSet/Attribute code, not a re-implementation.

## Relation, querying and scoping (relation fork)

ActiveRecord::Relation with its query, finder, calculation, spawn/merge and batch methods, the predicate builder,
WhereClause, Querying (the class-level delegation), Sanitization and Scoping, on the committed Arel and SQLite3
adapter. Under `sakelib/rails/activerecord/active_record/`. Merged into `rails_activerecord.md` by the lead.

Tests (each `.sake` prints what its `.rb` prints on the real gem, the SQL included, through `sql.active_record`):

| test | what | check (`bin/sake -c --strict`) |
|---|---|---|
| `test/sakelib/rails/activerecord/relation.sake` | where (nil, Array, Range incl. endless/beginless, String with `?` and `:name` binds, where_not, or, rewhere, invert_where, a Relation as subquery), order/reorder/reverse_order, limit/offset, select/distinct, to_sql, count/sum/average/minimum/maximum, grouped count/sum with having, pluck/pick/ids, first/last/take, find_some's message, first!'s, exists? (4 forms), any?/empty?/many?, create_with + find_or_create_by, build on a relation, update_all, update_counters, delete_all, destroy_all, find_each, find_in_batches, merge, except, none, scopes chained, size/length/load, inspect | 16.5 s, 319 MB |
| `test/sakelib/rails/activerecord/scoping.sake` | default_scope and unscoped, named scopes with arguments and chained, sanitize_sql_like, readonly relation (ReadOnlyRecord), distinct count, select of a String, empty finders | 10.8 s, 266 MB |

### What is ported

Code lines (no blanks, no comments). The Ruby column counts whole files, left-out parts included.

| Ruby (activerecord-8.1.3/lib/active_record/) | Sake | Ruby | Sake |
|---|---|---|---|
| relation.rb | relation.sake | 714 | 213 |
| relation/query_methods.rb | relation/query_methods.sake | 1,076 | 370 |
| relation/finder_methods.rb | relation/finder_methods.sake | 344 | 88 |
| relation/calculations.rb | relation/calculations.sake | 409 | 125 |
| relation/spawn_methods.rb, merger.rb | relation/spawn_methods.sake | 190 | 40 |
| relation/batches.rb | relation/batches.sake | 227 | 22 |
| relation/where_clause.rb | relation/where_clause.sake | 175 | 67 |
| relation/predicate_builder.rb + predicate_builder/*.rb | relation/predicate_builder.sake | 355 | 64 |
| querying.rb, relation/delegation.rb | querying.sake | 187 | 75 |
| sanitization.rb | sanitization.sake | 132 | 22 |
| scoping.rb, scoping/default.rb, scoping/named.rb | scoping.sake | 248 | 9 |
| **total** | 11 files | **4,057** | **1,095** |

### Shapes

**A relation class per model.** Rails makes `Post::ActiveRecord_Relation` (relation_delegate_class) so that a
relation can delegate to its model's class methods. Here the generator writes that class for every model, with
the fields `klass, values, loaded, records_`, and `ActiveRecord::Relation` is the module it includes. So
`Post.where(...)` is a `Post::ActiveRecord_Relation` and `to_a` is `Post[]` to the checker: `Post.title(r)` on
its elements type-checks, which a single Relation class (one type, records of every model) could not give.

**@values → Values.** Ruby's `@values` Hash (`where_clause`, `order_values`, `limit_value`, ...) is the class
`Relation::Values` with those keys as fields; `spawn` copies it (each multi-value Array copied).

**Query methods.** Each is Ruby's pair (`where` = `spawn.where!`), written with the relation first:

```ruby
## Ruby                                              # Sake
Post.where(published: true).order(title: :desc)     Post.where(published: true).ActiveRecord::Relation.order(title: :desc)
Post.where("views > ?", 5)                          Post.where("views > ?", 5)
Post.where("price > :min", min: 100)                Post.where("price > :min", Hash.of(min: 100))
Post.where.not(category: "fruit")                   Post.where_not(category: "fruit")
Post.group(:category).count                         Post.group(:category).R.group_count
Post.find([1, 2])                                   Post.find_some(Any[1, 2])
Post.first(2)                                       Post.first_n(2)
Post.where(...).new(name: "x")                      R.build(Post.where(...), name: "x")
scope :cheap, -> { where("price < ?", 100) }        def cheap(rel = Item.all) = R.where(rel, "price < ?", 100)
Item.active_ones.cheap                              Item.cheap(Item.active_ones)
default_scope { where(archived: false) }            def default_scope(rel) = R.where(rel, archived: false)
```

Keyword arguments are the Hash form (`**conds`), a positional Hash and a String with binds the other forms.
`where.not` is a WhereChain object in Ruby; one chain class would be one type for all models, so `where_not`.
Named binds need the Hash positional: a keyword after a String would be a column condition.

**One result type per function.** Ruby's `find` gives a record or an Array, `count` an Integer or (grouped) a Hash,
`first` a record or (with n) an Array. Each became two functions: `find`/`find_some`, `count`/`group_count` (and
`group_sum`, `group_average`, `group_minimum`, `group_maximum`, `group_calculate`; `count` on a grouped relation
raises and says so), `first`/`first_n`, `last`/`last_n`, `take`/`take_n`.

**Scopes as functions.** A scope's lambda has no Sake form; the scope is the function the lambda would be, with
the relation as an optional last argument defaulting to the model's `all`: `Item.cheap` and
`Item.cheap(Item.where(...))`. default_scope is the model's own `default_scope(rel)`, which replaces Scoping's
default (`= rel`), applied by `all` and not by `unscoped`.

**The SQL** matches Rails' for every statement the tests run: bind `?` for values and LIMIT/OFFSET, `IN (?, ?)`,
`BETWEEN ? AND ?`, `IS NULL`, `!=` for where_not, `(a OR b)`, `IN (SELECT ...)`, grouped aliases
(`COUNT(*) AS "count_all", "items"."category" AS "items_category"`), `LIMIT -1 OFFSET ?`, the many? subquery
(`SELECT COUNT(*) FROM (SELECT 1 AS one ... LIMIT ?) AS subquery_for_count`), inspect's
`/* loading for inspect */ LIMIT ?`, and to_sql with the binds written in.

### Left out, and why

- `scoping { }` blocks (current_scope): Ruby keeps one current scope per class (and thread); a relation of one
  model is its own type, so no place holds "the current scope" of every model without a per-model holder in the
  generated code. Not done (time). A default scope's where values are not applied by `Post.build`.
- `extending` (blocks/modules added to a relation), `in_batches` (BatchEnumerator), `insert_all`/`upsert_all`
  (InsertAll), `explain`, `with`/CTE, `in_order_of`, `excluding`, async_*, `load_async`, `sole`, `second..fifth`,
  `optimizer_hints`, `regroup`, composite primary keys, `find` with a block, `count` with a block: time, or no
  block values.
- Merger: merging a Hash or an Array, and association joins across models (associations part).
- `case_sensitive: false` comparisons, `where` with dot notation (`"comments.id" => 1`) and aggregations.

### Friction (what I wrote first → the message → what I wrote instead)

- `R.new(rel, name: "leek")` (Ruby's `relation.new`) → it built a `Item::ActiveRecord_Relation`: `new` on a
  class is the constructor, and the dispatch reached the class's built-in → `build` (Rails' alias).
- `Relation.count(limit(rel, 2)) > 1` for many? → `Comparable.>: the operands may be (Hash ... | Integer)`: the
  grouped Hash result made every count a union → `count` and `group_count` split, and `limited_count` for
  one?/many? (which is Rails' own SQL anyway).
- `include Enum` in `module ActiveRecord::Relation` → once the features part added `ActiveRecord::Enum` (the
  `enum` declaration), a bare `Enum` meant that module (`ActiveRecord::Enum.defined_enums needs __model`) →
  `include ::Enum` (also in result.sake). The same silent shadowing as `String` inside `ActiveModel::Type`.
- `InfixOperation.new(:+, left, right)` (Ruby's order) → at run time `UnsupportedVisitError: Symbol`: the port's
  fields are `left, right, operator` → keywords (`InfixOperation.new(left: ..., right: ..., operator: :+)`).
  persistence.sake's `update_counters_for` (increment!) has the same call; the lead should fix it there.
- A model without callbacks or associations made generated `case` with no `in` branch ("expected a `when` or
  `in` clause after `case`"): a placeholder branch in generate/model.sake and generate/associations.sake.
- `Item.average(:price).to_s` prints `"116.0"` in Ruby (ActiveSupport's BigDecimal#to_s) but `"0.116e3"` here
  (sakelib's BigDecimal is Ruby's plain one); the test prints `to_f`.

What read well: the per-model relation class made a chain of Relation calls type-check per model with no casts;
the SQL came out identical to Rails' on the first full run except for three details (an alias, a message word, a
field order), which the side-by-side comparison caught immediately.


## Associations (associations fork)

belongs_to, has_one, has_many (with the collection proxy), has_many :through (one through table),
has_and_belongs_to_many, reflection, includes/preload, joins/left_joins of associations, `where(author: record)` and
`where(comments: {...})`, dependent (:destroy, :delete/:delete_all, :nullify, :restrict_with_error,
:restrict_with_exception), counter_cache, autosave of new records, accepts_nested_attributes_for (build, update by
id, `_destroy` with allow_destroy), automatic inverse_of, and belongs_to's "must exist" (`optional: false`).

Test: `test/sakelib/rails/activerecord/associations.sake` / `.rb` (+ `associations_schema.rb`,
`associations_models.rb`, shared with Ruby): 7 models, 102 lines of output including every SQL statement, identical
to ActiveRecord 8.1.3 on sqlite3 `:memory:`. **Check time: 80.0 s, 592 MB** (`bin/sake -c --strict`, load ~4); kept
as `experiments/2026-10-20-rails-scale/bugs/activerecord_slow_check_associations/` (see below). The run itself adds ~2 s.

### What is ported

| Ruby (activerecord-8.1.3/lib/active_record) | Sake | Ruby code lines | Sake code lines |
|---|---|---|---|
| associations.rb, associations/{association, singular_association, collection_association, belongs_to_association, has_one_association, has_many_association, has_many_through_association, through_association, association_scope, collection_proxy, join_dependency, preloader, preloader/*}.rb, reflection.rb, autosave_association.rb | associations.sake | 3,407 | 202 |
| associations/builder/*.rb, nested_attributes.rb (the methods Ruby defines with define_method / class_eval) | generate/associations.sake (Sake only: the generator) | 730 | 398 |
| **total** | | **4,137** (+ 370 of the preloader's branch/batch machinery) | **600** |

The Ruby column counts whole files, much of which is left out (below); the ratio is not a compression ratio. The
generator writes about 60 lines per association (readers, writers, build/create/reload, autosave, dependent, preload).

### How Rails' shapes became Sake

**define_method readers → generated functions; the Association object → owner fields.** Ruby's Builder defines
`post.comments` on a generated module, returning `association(:comments).reader`, an object cached in
`@association_cache`. Here:

```ruby
## Ruby (Builder::HasMany + CollectionAssociation#reader)     # Sake (generated from `has_many :comments, dependent: :destroy`)
def comments                                                  def Post.comments(r)
  association(:comments).reader                                 px = Post.assoc_comments(r)            # a field of Post
end                                                             if px == nil || !Post.association_cached?(r, :comments)
                                                                  px = Comment::ActiveRecord_Associations_CollectionProxy.new(Comment.__model,
                                                                    ActiveRecord::Relation.values(Post.__comments_scope(r)), false, Comment[], r,
                                                                    Post.__reflection_comments, Comment[], Post.id(r))
                                                                  ...
                                                              def Post.__comments_scope(r) = Comment.where(Hash.of(post_id: Post.id(r)))
```

A singular association keeps its target in a field (`assoc_author`, typed `Author | nil` by its writes), so
`Post.author(post)` is `Author | nil` to the checker and `Author.name(Post.author(post))` is checked. The owner's
`association_cache` (Ruby's) records which fields are current, so Persistence#reload (which drops it) drops them.

**CollectionProxy → one class per target model.** Rails makes `Comment::ActiveRecord_Associations_CollectionProxy`
(relation_delegate_class) at run time; here the generator writes it, including ActiveRecord::Relation and then
ActiveRecord::Associations::CollectionProxy (whose records/build/create/concat/size replace the Relation's). Its
`owner` field holds the union of the owners' models (Post | Author | Category for Post's proxy...) and is used only
through module dispatch (`ActiveRecord::AttributeMethods.id(@owner)`).

**Reflection → data.** `AssociationReflection` holds what Ruby derives from the options (foreign keys, the target's
table, the through/join table and its keys, the inverse, the counter cache column), resolved by the generator from
the class bodies; the model's `__model` puts it in `ModelClass.reflections`, where joins and where(...) read it.

**Callbacks Ruby's builders add → callback lines.** `has_many ..., dependent: :destroy` adds
`set_callback :destroy, :before, :__dependent_for_comments` and the autosave `after_create`/`after_update` callbacks at
the association's line in the chain ActiveSupport::Callbacks' generator writes, so they run in Rails' order (the SQL
of `post.destroy` matches: comments, taggings, the habtm join rows, the post). restrict_with_error uses `throw :abort`.

**Preloader → a generated `__preload_associations(rel, records)`** that every relation class calls after loading,
with one function per association: one `WHERE fk IN (...)` query, then each owner's proxy is filled and the inverse
set (so `author.posts.map { _1.author.equal?(author) }` makes no query, as in Rails).

**Inverse_of → `set_inverse_instance_of(record, name, owner)`**, generated per model as a `case` over its belongs_to
names with `owner in Post` narrowing: the generic proxy calls it on its records by module dispatch.

Names, side by side: `post.comments.create(body:)` → `Comments.create(Post.comments(post), body:)` (with
`Comments = Comment::ActiveRecord_Associations_CollectionProxy`); `post.categories << news` →
`...CollectionProxy.concat(Post.categories(post), news)` (`<<` is also defined); `ann.create_profile(bio:)` →
`Author.create_profile(ann, bio:)`; `post.comment_ids` → `Post.comment_ids(post)`; `Post.joins(:comments).where(
comments: {body: "x"})` → `Post.joins(:comments).Rel.where(comments: Hash.of(body: "x"))`;
`Author.create(posts_attributes: [{...}])` → the same with `Any[Hash.of(...)]`.

### Left out, and why

- Association scopes (`has_many :comments, -> { where(...) }`): a lambda has no Sake form; a scope function could be named instead (not done).
- Polymorphic belongs_to / `as:`, has_one :through, nested through chains, source_type: time.
- `comments=` (replace the collection), `delete`/`destroy`/`clear` on a proxy, `<<` on has_many :through, validates_associated: time.
- eager_load builds the LEFT OUTER JOIN and then preloads (two queries; Rails reads the joined rows); preload of
  through and habtm associations is one query per owner (Rails: one per association).
- strict_loading violations, `disable_joins`, `extending`, `size` reading the counter cache column.

### Friction

1. `R = Reflection::AssociationReflection` inside a function → a type cannot be a local value → a constant in the module body (`Refl = ...`).
2. A generated `has_one` `build_profile` that set the target first: Rails' SQL showed the SELECT of the old target *after* the INSERT (create_profile saves, then replace loads) → split into `__build_*_record` and `__set_new_*`, matched byte for byte.
3. `Arel::Nodes::InfixOperation.new(:+, left, right)` (Ruby's order) → `Unsupported argument type: Symbol` at run time: the port's fields are `left, right, operator`. Positional `new` is not checked against the field order (also in the core's `update_counters`/`update_counters_for`, which still pass the operator first).
4. A class name already declared (`AssociationTypeMismatch` in errors.sake) → "`<` goes on the first class": fine, the message names the line.
5. The checker made the shape honest: the proxy's owner is a union, and every use of it had to go through a module's dispatch; a belongs_to writer given the union of all assigned values had to narrow it (`in Author then value ... else raise AssociationTypeMismatch`), which is what Rails' type check does at run time.

### Slow check

80 s for 7 models (12 copies of ActiveRecord::Relation: 7 relation classes and 5 collection proxies), against 10.8 s
for base.sake's one model. The repro directory holds the test and the generated source (2,357 lines).


## Per-record features, callbacks and transactions (features fork)

enum, store, has_secure_token, attr_readonly, readonly records, optimistic and pessimistic locking, timestamps
and touch, counters (increment!/decrement!/toggle!), update_column(s), the attributes API, model callbacks and
transactions, on the model layer of `rails_activerecord.md` (core, persistence, the no-super chain). Tests (each
prints what its `.rb` prints on the real gem, SQL included through `sql.active_record`):

| test | what | check (`bin/sake -c --strict`, load ~2-3) |
|---|---|---|
| `test/sakelib/rails/activerecord/callbacks.sake` | every model callback kind in Rails' order (after_initialize/after_find, validation, save/create/update with around, destroy halted by `throw :abort`, after_commit/after_*_commit/after_rollback), `unless:`/`if:` conditions, uniqueness with `scope:`, `on: :update` | 11.9 s, 300 MB |
| `test/sakelib/rails/activerecord/features.sake` | enum (array and hash, prefix, scopes, `!`, `?`, invalid label), store with JSON coder, secure token, attr_readonly, `attribute :x, :integer, default:`, readonly!, lock_version (StaleObjectError, DELETE with the version), lock!/with_lock, counters, touch, record_timestamps = false, update_columns, nested transactions with savepoints | 24.1 s, 400 MB (the largest) |
| `test/sakelib/rails/activerecord/transactions.sake` | the block's value, a transfer, RecordInvalid rolling back and propagating, a joined inner transaction, destroy rolled back; commit/rollback callbacks | 8.0 s, 235 MB |

### What is ported (code lines, no blanks or comments; the Ruby column is the whole file)

| Ruby (activerecord-8.1.3/lib/active_record/) | Sake | Ruby | Sake |
|---|---|---|---|
| enum.rb | enum.sake + generate/features.sake (enum part) | 211 | 40 + ~45 |
| store.rb | store.sake + generate/features.sake (store part) | 193 | 63 + ~25 |
| secure_token.rb | secure_token.sake + generate/features.sake | 24 | 10 + ~10 |
| locking/optimistic.rb | locking/optimistic.sake | 135 | 39 |
| locking/pessimistic.rb | locking/pessimistic.sake | 31 | 24 |
| timestamp.rb | timestamp.sake | 110 | 43 |
| callbacks.rb | callbacks.sake + the mapping in generate/model.sake (callbacks_body) | 46 | 18 + ~40 |
| transactions.rb | transactions.sake | 238 | 110 |
| readonly_attributes.rb | ModelClass.readonly_attributes + persistence.sake checks | 38 | ~5 |
| persistence.rb (touch, increment!, toggle!, update_column(s)) | persistence.sake (with the core part) | 462 | 183 |
| (Sake only) the features' class-body lines | generate/features.sake | | 136 |

### How Ruby's shapes became Sake

**enum** (Ruby define_methods per label, `scope`s with lambdas, `decorate_attributes` with an EnumType):

```ruby
## models.rb (both)                               # generated
enum :status, [:pending, :shipped, :cancelled]   def Order.statuses = ActiveRecord::ModelClass.defined_enums(Order.__model)["status"] || Hash.new
                                                 def Order.pending?(r) = Order.status(r) == "pending"
                                                 def Order.pending!(r) = Order.update!(r, status: "pending")
                                                 def Order.pending(rel = Order.all) = ActiveRecord::Relation.where(rel, Hash.of("status" => "pending"))
                                                 def Order.not_pending(rel = Order.all) = ActiveRecord::Relation.where_not(rel, ...)
                                                 (in Order.__model) declared_types["status"] = ActiveRecord::Enum::EnumType.new("status", mapping, ActiveRecord::Type.lookup(:integer, :sqlite3))
```

The reader `Order.status(order)` narrows to `String` (the label), not the column's Integer: the model generator
asks `Features.attribute_pattern`. `order.Order.status = :lost` raises Rails' `'lost' is not a valid status`
from EnumType's `assert_valid_value`, which ActiveModel::Attribute already calls on every user write.

**store** `store :settings, accessors: [:color], coder: JSON`: the column's type is `Store::JsonCoderType` (Ruby's
Serialized with the JSON coder, mutable: changes in place are found by comparing the serialized form), and
`color`/`color=` are generated calls of `read_store_attribute`/`write_store_attribute`, which mutate the Hash in
place as Ruby's HashAccessor does. `color` is also a writer `__assign` knows, so `Order.create(color: "red")` works.

**Callbacks** map onto ActiveSupport::Callbacks' generator (generate/model.sake `callbacks_body`): every model
gets Rails' `define_model_callbacks` chains, and `before_save :x, if: :y` is `set_callback :save, :before, :x,
if: :y`. Two Rails details had to be found by comparing output: ActiveModel::Callbacks *prepends* `after_*`
model callbacks (`_define_after_model_callback` sets `prepend: true`), which is why `after_create` runs after
the `around_create` closes; without it the after callback ran inside the around block. after_commit and
after_create_commit kept AS's own order and matched. `throw :abort` is the built-in throw.
has_secure_token adds `set_callback :create, :before, :__secure_token_token` where its line stands
(`Features.callback_declarations`).

**The super chain** (see persistence.sake's header): Locking::Optimistic adds the lock column to the INSERT by
passing extra names down (`counter_cache__create_record(r, ["lock_version"])` → `persistence__create_record`),
Ruby's `attribute_names |= [locking_column]` before `super`.

**Transactions**: the model layer keeps the records of the outermost transaction (Ruby's TransactionManager
does); the outermost `run_transaction` calls `committed!`/`rolledback!` on them, also when an exception
propagates (RecordInvalid from update!). `rolledback!` runs after_rollback only when the record would have had
its commit callbacks (Rails' `trigger_transactional_callbacks?`, checked before the state is restored).

### Left out, and why

- enum `validate:`, `default:`, `instance_methods: false`, `_scopes: false` variants beyond `scopes: false`;
  store's HashWithIndifferentAccess (keys are Strings; Symbol access is not ported), YAML coder, prefix/suffix
  accessors; has_secure_token `on: :initialize`; normalizes; serialization (as_json/to_json) — time.
- `Post.update_counters(id, ...)` is in relation.sake (`Relation.update_counters`, the relation part's): it builds
  `InfixOperation.new(op, l, r)`, whose field order is (left, right, operator), so it fails at run time, and it
  quotes the amount where Rails binds it (`+ ?`). persistence.sake's increment! uses Addition/Subtraction with a
  bind; the same fix belongs there. Not in the test for that reason.
- after_commit with several `on:` actions through Procs; `touch_later`; `no_touching`.

### Friction (what I wrote first → the message → what I wrote instead)

- Record fields named `readonly` and `strict_loading` (Ruby's ivars) → `wrong number of arguments for
  Order.readonly (given 0, expected 1)`: the field reader shadowed the Querying class method `Order.readonly`
  (and `strict_loading`) → fields `readonly_record`, `strict_loading_record`. The silent-shadowing lesson again;
  this time the arity told.
- Generated `in "color" then Order.color=(r, value)` → `syntax error: unexpected write target` → `r.Order.color = value`.
- `def BASE58_ALPHABET = "..."` in a mixin, called `SecureToken.BASE58_ALPHABET` → `is a mixin function: it has
  no subject to dispatch on` → a bare call of `base58_alphabet` (or module_function).
- `JsonCoderType.new` without `initialize` → `given 0, expected 3` (the precision/scale/limit fields) → `def initialize(t) = nil`.
- `Arel::Nodes::InfixOperation.new(:+, l, r)` (Ruby's argument order) → at run time `UnsupportedVisitError:
  Unsupported argument type: Symbol` (positional `new` follows field order, not Ruby's initialize) → Addition/Subtraction.
- `Order.transaction(requires_new: true) { }` with keywords works from the program, but a mixin calling its
  includer's keyword function (`save(r, validate: false)`) is rejected (`keyword arguments go only to functions
  with keyword parameters`); the core part already turned those into positional `save_with`.

### Bugs

None new here; the `==`-on-a-union-with-Date problem of the core part (`ActiveModel::Type.same_value?`) was
used for the store's and enum's comparisons.


## Migrations, Schema and the dumper (migrations fork)

ActiveRecord 8.1.3's migrations on the SQLite3 adapter: Migration (change, up/down, reversible, revert, say,
say_with_time, suppress_messages, the verbose output), the CommandRecorder that inverts `change`, Migrator and
MigrationContext (migrate, migrate to a version up or down, rollback/forward by steps, current_version,
needs_migration?, migrations_status), SchemaMigration and InternalMetadata (the schema_migrations and
ar_internal_metadata tables, built with Arel as Rails does), Schema.define (db/schema.rb, through the
generated loader), the SchemaDumper (db/schema.rb text for SQLite), and the schema statements SQLite needs
alter_table for (remove_column(s), rename_column, change_column, change_column_default, change_column_null,
remove_reference, remove_timestamps: Rails' copy of the table to `a<name>` and back, with its indexes).

Tests (each prints what the real gem prints; `ruby -Ilib test/test_sakelib.rb -n /rails_activerecord_(migrations|schema_dumper)/`):

| test | what | check (`bin/sake -c --strict`) |
|---|---|---|
| migrations.sake | 4 migrations (change, up/down, reversible with say, change_column_default from/to, change_column_null), migrate, status, rollback(2), migrate to a version and back down, an unknown version, an irreversible drop_table; the verbose output (times masked on both sides) and every DDL/DML statement, the alter_table copies included (197 lines, identical) | 5.9 s, 177 MB |
| schema_dumper.sake | a db/schema.rb (limit, null, defaults, decimal precision/scale, date, float, indexes, `id: false`, `primary_key: "key", id: :string`) loaded with Schema.define's verbose output, dumped back, then changed by a migration (rename, remove, add with limit and default) and dumped again (104 lines, identical) | 5.6 s, 180 MB |

### What is ported

Code lines (no blanks or comments). The Ruby column counts the whole files, left-out parts included.

| Ruby (activerecord-8.1.3/lib/active_record/) | Sake | Ruby | Sake |
|---|---|---|---|
| migration.rb (Migration, ReversibleBlockHelper, errors) | migration.sake | 887 (with Migrator, Context, CheckPending, Compatibility...) | 243 |
| migration.rb (Migrator, MigrationContext) | migration/migrator.sake | (above) | 136 |
| migration/command_recorder.rb | migration/command_recorder.sake | 284 | 80 |
| schema.rb | schema.sake | 29 | 24 |
| schema_migration.rb | schema_migration.sake | 81 | 40 |
| internal_metadata.rb | internal_metadata.sake | 124 | 61 |
| schema_dumper.rb, connection_adapters/abstract/schema_dumper.rb, sqlite3/schema_dumper.rb | schema_dumper.sake | 407 | 140 |
| sqlite3_adapter.rb (alter_table, copy_table*, remove/rename/change_column*, disable_referential_integrity) | connection_adapters/sqlite3_adapter.sake (added) | ~150 of 769 | ~125 |
| **total** | | | **~850** |

### How Ruby's shapes became Sake

**A migration class.** Ruby's `class CreatePosts < ActiveRecord::Migration[8.1]` with `def change` whose bare
lines are method_missing on the migration (sent to the connection with `say_with_time`). Here the class
includes the module, declares Ruby's two constructor fields, and the DSL is paren-less calls of Migration's
functions with the migration first:

```ruby
## Ruby                                         # Sake
class CreatePosts < ActiveRecord::Migration[8.1]   class CreatePosts
                                                 attr_reader name, version
                                                 include ActiveRecord::Migration
  def change                                     def change(m)
    create_table :posts do |t|                     create_table m, :posts do |t|
      t.string :title, null: false                   T.string(t, :title, Hash.of(null: false))
      t.timestamps                                   T.timestamps(t)
    end                                            end
    add_index :posts, :title, unique: true         add_index m, :posts, :title, Hash.of(unique: true)
  end                                            end
end                                            end
CreatePosts.new("CreatePosts", 20261020000001) CreatePosts.new("CreatePosts", 20261020000001)
```

Ruby picks change or up/down with `respond_to?(:change)`; here Migration defines `up(m) = change(m)` and
`down(m) = revert(m) { change(m) }`, and a class that writes up/down wins over the module's (include order).
The class's name comes from Ruby's `self.class.name`; Sake has no class names, so the constructor is given it,
as Ruby's tests do (`Migration.new(name, version)`).

**method_missing → one function per command.** Each DSL function builds Ruby's `[command, args]` (the args as
the call gave them, so `format_arguments` prints `add_column(:posts, :views, :integer, {default: 0})` the same)
and either records it or says it with its time and runs it (`execute_command`, a `case` over the names: Ruby's
`connection.send(method, *arguments)`).

**The CommandRecorder without stored blocks.** Ruby runs `change` against the recorder (it *is* @connection
while reverting), keeps `[cmd, args, block]` and replays with `migration.send`. Here the running migration's
state (verbose, the recorder, suppression) is one value (MigrationParts::State; migrations run one at a
time), a Command is data, and replay is `run_command`. A `reversible do |dir| ... end` in a change being
reverted is a stored block in Ruby, run at its place in the reversed replay; here it runs when recorded with
the recorder swapped for a group, and the group (Ruby's execute_block) keeps its place, so
`-- views are gone` comes first on the way down, as in Ruby. `create_table`'s block is not recorded (its
inverse, drop_table, does not need it); a drop_table is therefore reversible only with options, as Ruby says.

**The migration list.** Ruby's MigrationContext reads `db/migrate/*.rb` and makes proxies that `load` the file
and constantize the name; Sake has neither, so MigrationContext.new takes the migration objects (`Any[...]` of
several classes: Migration's functions dispatch on each). The Ruby test does the same by overriding
`migrations`. migrations_status reports "NO FILE" as Ruby does without files. A railtie could generate the
list from db/migrate (not done).

**db/schema.rb.** The generator (generate/schema.sake) turns the file into `SchemaDumperSchema.load`, whose body
is `ActiveRecord::Schema.define(Hash.of(version: ...)) do |s| ActiveRecord::Schema.create_table(s, "posts",
Hash.of(force: :cascade)) do |t| ... end end`; Schema includes Migration, so these are the same verbose DSL
functions, and `define` then records the version (assume_migrated_upto_version) and the environment.

**Output capture (Sake only).** Ruby's tests swap `$stdout` to mask the times; Sake has no `$stdout`, so
`ActiveRecord::Migration.capture_output { }` returns what `write` printed. Both sides mask `\d+\.\d+s`.

### Left out

Foreign keys (add/remove_foreign_key, and alter_table's copy of them; Schema's add_foreign_key is a no-op),
check constraints, change_table (Table), create_join_table, `revert(OtherMigration)`, `run`, the
Compatibility layers other than 8.1, CheckPending middleware, advisory locks, migration files and
copying them between engines, schema_sha1, rename_column's renaming of indexes named after the column
(rename_column_indexes), the dumper's foreign keys/virtual tables/table options/composite keys.

### Friction (what I wrote first → the message → what I wrote instead)

- `transaction(c) do ... end` in alter_table → `warning: rescue ActiveRecord::Rollback: the begin body never
  raises ActiveRecord::Rollback [unused-rescue]` in the adapter's `transaction` (whether a library's rescue is
  used depends on the program: the migrations test raises Rollback nowhere) → `joining_transaction` (join the open
  transaction or begin one through the TransactionManager), used by alter_table and the Migrator.
- `SchemaDumper.new(conn, version)` → `wrong number of arguments (given 2, expected 3)`: a `private attr_accessor`
  field still counts in `new` → pass nil.
- A `class Migration` I first wrote as a namespace next to the mixin `module Migration` (Ruby's Migration is a
  class) → removed; Sake's names are one thing each.
- `Array.sort(Conn.tables(...))` → `elements compared in order may be (Float, nil) ...`: query_values gives the
  union of a row's values → `Kernel.to_s` each first.
- The paren-less DSL (`create_table m, :posts do |t|`) reads like Rails; the table definition does not
  (`T.string(t, :title, Hash.of(null: false))` for `t.string :title, null: false`): the column methods take the
  options as a trailing Hash, as the adapter part wrote them.

What read well: the alter_table copy is Rails' four functions line for line and produced the same 20-statement
sequences on the first run; the dumper matched Rails' text byte for byte on the first run too.

No interpreter bugs found in this part.


## AR records in views (railties fork, fourth wave, 2026-10-20)

What a Rails app's models and views need from ActiveRecord, for railties' blog: the class-body lines of
`rails new` + `rails generate authentication` (`primary_abstract_class`, `has_secure_password`), Rails 8's
`User.authenticate_by`, and records rendered by ActionView (the scaffold's templates).

Test: `view_records.sake`/`.rb` (+ `_schema.rb`, `_models.rb`, `view_records_fixtures/`, `view_records_views/` and
`view_records_views_rb/`): the Rails 8.1 scaffold's articles templates and the guide's comments partials, rendered
from rows of sqlite3 :memory: by a view class without a controller (as actionview's rendering test): a failed save
(the error list, field_with_errors, the textarea keeping the value), index (`render article` per record), show
(`render` of the comments, `button_to [comment.article, comment]`, the nested `form_with model: [article,
article.comments.build]`), edit before and after a failed update; then has_secure_password's confirmation error,
authenticate, and authenticate_by's four outcomes and its ArgumentError. The output is the real gems' byte for byte.
**Check: 37.3 s, 640 MB** (two runs 37.28/37.25 s, HEAD's lib/, load ~1.9); the same program without the view class
and the rendering: 13.3 s. Kept as `bugs/railties_slow_check_view_records/` (a guess at the cause is in its header).

| change | file |
|---|---|
| `primary_abstract_class` is abstract; `has_secure_password` adds the fields password, password_confirmation, password_challenge to the record class, their `_assign_attribute` branches (`set_password` is the generated writer, BCrypt'ing into password_digest), `__send` names, ActiveModel's validate/validates_confirmation_of lines (through ActiveModel::SecurePassword::Generate.expand and Validations::Generate.expand) and its methods (`.source`); every model gets `__authenticate_attribute(r, name, value)` (Ruby's `public_send(:"authenticate_#{name}")`) | generate/model.sake |
| `ActiveRecord::Generate.on_load_includes` (after Base's modules: Rails' `ActiveSupport.on_load(:active_record) { include M }`) and `protocol_includes` (before them), and `includes=A,B` / `protocols=A,B` arguments of the generator program | generate/model.sake, generate/active_record.sake |
| `t.index [...]` inside create_table was read as a column named `["article_id"]` (every dumped schema with an index has it) | generate/schema.sake |
| ActiveRecord::SecurePassword#authenticate_by (Base includes it, last) | active_record/secure_password.sake (new) |
| `read_attribute_for_validation(r, "title")`: Ruby's `send` takes a String; ActionView passes one | activemodel validations.sake |
| ActionView::ModelNaming::Record (Sake only): Model plus errors_for (`errors[attr]`) and model_name_human (`model_name.human`), included before ActiveModel's modules so their functions fulfil Model's | actionview action_view/model_naming/record.sake (new) |
| Model's `human_attribute_name(r, attr)` is now `human_attribute_name_of(r, attr, options = {})`: ActiveModel::Translation's instance form has that name and signature, while its `human_attribute_name(attr, options)` is class-level, and the two clashed in one class | actionview model_naming.sake, helpers/tags/translator.sake |

**How railties wires it**: the generator program pushes `"ActionView::ModelNaming::Record"` to
`ActiveRecord::Generate.protocol_includes` (or passes `protocols=ActionView::ModelNaming::Record`) and requires
`rails/actionview/action_view/model_naming/record` in the app; the view class generator gets `records=Article,Comment`.
Templates read records as `Article.title(article)`, `ActiveModel::Errors.any?(Article.errors(article))`,
`ActiveRecord::Relation.to_a(Article.comments(article))` for `render @article.comments`,
`Comment::ActiveRecord_Associations_CollectionProxy.build(Article.comments(article))` for `article.comments.build`;
`User.authenticate_by(Hash.of(email_address: e, password: p))` (a Hash: `Parameters.to_h` of permitted params).

Left out: password_digest_was for password_challenge (has_secure_password's challenge check reads nil: ActiveModel's
generator asks for an ActiveModel::Dirty include line the AR model's Info does not list), reset tokens
(`generates_token_for`), `normalizes`.

**Friction** (what I wrote first → the message → what I wrote instead)
1. `include ActionView::ModelNaming::Model` after ActiveModel's modules (Rails' on_load order) → "Req.a: K includes Req
   but does not define a, which Req requires": a nearer required stub is not fulfilled by a farther module's function
   (a 15-line test showed it; included first, ActiveModel's to_key/param_key/to_partial_path fulfil it) → the protocol
   goes before Base's modules (`protocol_includes`), and the clash of the two `human_attribute_name`s became a rename.
2. `t.index ["article_id"], name: ...` in schema.rb → `syntax error: unexpected '['; expected a method name` at
   models.rb:10 (the origin of the generated reader `def Comment.["article_id"](r)`) → the schema parser skips index lines.
3. `button_to view, "Destroy Comment", [Comment.article(comment), comment]` → "case/in: no `in` branch matches
   [Article | nil, Comment]" in polymorphic_routes: Ruby's `[a, b]` is a Tuple here, and the routes take an Array →
   `Any[Comment.article(comment), comment]` (also for `form_with model:`).
4. `render "form", article: @article` in new/edit → "Article.__errors: argument 1 must be Article, but is nil" in the
   partial (the field is Article|nil) → `<% article = @article || raise(...) %>` as the first line (trimmed: the output is
   unchanged).
5. The form rendered → at run time `undefined method 'title' for an instance of Article`: ActionView's Tags read
   `read_attribute_for_validation(o, "title")` and the generated `__send` matched only Symbols → ActiveModel converts a
   String, as Ruby's send.
6. `render @article.comments` → a CollectionProxy is not an Array for the view's record rendering →
   `ActiveRecord::Relation.to_a(...)` (Rails calls to_ary).
7. While I worked the lead's lib/ was mid-change (bin/sake rejected every AR test: "Post.build: argument 1 must be Post");
   all checks here ran with HEAD's lib/ (a git archive next to the working sakelib/).

What read well: once it checked, the scaffold's HTML matched Rails on the first run except one blank line (my
template's), I18n's "Title can't be blank" and "Create Article" came through ActiveModel unchanged, and the nested
comment form, dom_id and `button_to` of a nested record needed no ActionView change.
