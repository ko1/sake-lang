# Rails 8.1.3 part 3: Arel, the SQLite3 adapter, and the types under it (2026-10-20)

Arel (`activerecord-8.1.3/lib/arel/`), ActiveRecord's connection adapter layer for SQLite3
(`active_record/connection_adapters/`), ActiveRecord::Result, ActiveRecord::Type and ActiveModel::Type with
ActiveModel::Attribute, ported file by file. Programs reach it as `require "rails/activerecord/active_record"`
(ActiveModel::Type alone: `require "rails/activemodel/active_model/type"`). The model layer (Base,
persistence, Relation, associations) is a later part; the adapter follows Rails' interfaces so it can sit under
it (`connection.select_all(arel)`, `insert(arel)`, `transaction { }`, `columns(table)`, `lookup_cast_type`).

Tests (each prints the same as its `.rb` on the real gems, `ruby -Ilib test/test_sakelib.rb -n "/rails_activerecord|rails_activemodel/"`):

| test | what | check time (`bin/sake -c --strict`) |
|---|---|---|
| `test/sakelib/rails/activerecord/arel_select.sake` | 67 statements: predications, values, joins, aggregates, set operations, CASE, windows, CTE, literals with binds, prepared binds | 3.4 s, 131 MB |
| `test/sakelib/rails/activerecord/arel_dml.sake` | InsertManager, UpdateManager, DeleteManager, compile_update/compile_delete with keys and joins (SQLite's UPDATE ... FROM) | 2.7 s, 98 MB |
| `test/sakelib/rails/activerecord/sqlite3_adapter.sake` | a real `:memory:` database: create_table/add_index/add_column, tables, columns, indexes, primary_key, insert/select/update/delete through Arel, prepared binds, transactions (lazy BEGIN, savepoints, ActiveRecord::Rollback), error translation, the type map; the SQL the adapter runs, compared with Rails' `sql.active_record` notifications | 3.2 s, 121 MB |
| `test/sakelib/rails/activemodel/type.sake` | ActiveModel::Type cast/serialize/deserialize for every type, ActiveModel::Attribute | 1.2 s, 54 MB |

## What is ported

Lines are code lines (no blanks, no comments). The Ruby column counts the whole Ruby files the Sake file names
(left-out parts included).

| Ruby (activerecord-8.1.3/lib, activemodel-8.1.3/lib) | Sake (sakelib/rails/...) | Ruby | Sake |
|---|---|---|---|
| arel.rb (Arel.sql/star; the require lists) | activerecord/arel.sake | 103 | 111 |
| arel/nodes/*.rb (55 files, about 100 node classes) | activerecord/arel/nodes/*.sake (38 files) | 1,294 | 932 |
| arel/visitors/to_sql.rb, visitor.rb | activerecord/arel/visitors/to_sql.sake | 876 | 938 |
| arel/visitors/sqlite.rb | activerecord/arel/visitors/sqlite.sake | 79 | 85 |
| arel/predications, expressions, math, factory_methods, alias/order/window/filter predications | activerecord/arel/*.sake | 335 | 217 |
| arel/table.rb, attributes/attribute.rb | table.sake, attributes/attribute.sake | 108 | 98 |
| arel/select_manager, tree_manager, insert/update/delete_manager, crud | *.sake | 423 | 334 |
| arel/collectors/*.rb (5), arel/errors.rb | collectors/*.sake, errors.sake | 140 | 146 |
| connection_adapters/abstract_adapter.rb, abstract/savepoints, database_limits | connection_adapters/abstract_adapter.sake | 906 | 176 |
| abstract/database_statements.rb | abstract/database_statements.sake | 425 | 180 |
| abstract/quoting.rb, sqlite3/quoting.rb | abstract/quoting.sake, sqlite3/quoting.sake | 255 | 114 |
| abstract/schema_statements.rb, sqlite3/schema_statements.rb | abstract/schema_statements.sake, sqlite3/schema_statements.sake | 941 | 231 |
| abstract/schema_definitions.rb, sqlite3/schema_definitions.rb | abstract/schema_definitions.sake | 548 | 216 |
| abstract/schema_creation.rb, sqlite3/schema_creation.rb | abstract/schema_creation.sake | 159 | 96 |
| abstract/transaction.rb | abstract/transaction.sake | 549 | 275 |
| sqlite3_adapter.rb, sqlite3/database_statements.rb | sqlite3_adapter.sake, sqlite3/database_statements.sake | 769 | 266 |
| column.rb, sqlite3/column.rb, sql_type_metadata.rb | column.sake, sql_type_metadata.sake | 193 | 65 |
| active_record.rb, result.rb, errors.rb (part), type.rb, type/*.rb, type_caster/connection.rb, relation/query_attribute.rb | active_record.sake, result.sake, errors.sake, type.sake, type/type_map.sake, type_caster.sake, relation/query_attribute.sake | 1,268 | 293 |
| active_model/type.rb, type/*.rb, type/helpers/*.rb (20 files) | activemodel/active_model/type.sake, type/*.sake (14 files) | 873 | 516 |
| active_model/attribute.rb | activemodel/active_model/attribute.sake | 221 | 153 |
| **total** | 97 Sake files | **10,465** | **5,442** |

Arel is nearly whole (what is left out is below); the adapter is the part an app's requests reach (queries,
inserts, updates, deletes, transactions, schema reading, create_table/add_column/add_index for a schema).

## How Ruby's shapes became Sake

**Class hierarchies → a module per Ruby superclass, the fields written in each class.** Arel's ~100 node
classes inherit from Node, NodeExpression, Binary, Unary, Nary, Function, InfixOperation, Join, Ordering.
`class B < A` in Sake is a paste, not a subtype, and `Binary.left(o)` must dispatch, so each Ruby superclass is a
module with required readers, and each node declares its fields:

```ruby
# Ruby                                         # Sake
class Binary < NodeExpression                  module Binary
  attr_accessor :left, :right                    include NodeExpression
end                                              def left(o) = raise(NotImplementedError)
class Equality < Binary                          def right(o) = raise(NotImplementedError)
  include FetchAttribute                       end
  def equality?; true; end                     class Equality
  def invert                                     attr_accessor left, right
    NotEqual.new(left, right)                    include Binary
  end                                            def equality?(o) = true
end                                              def invert(o) = NotEqual.new(@left, @right)
                                               end
```

`attr_accessor left, right` satisfies the module's required `left`/`right`. The same shape is used for
ActiveModel::Type::Value (a module; `ActiveModel::Type::Value.cast(type, v)` dispatches; Ruby's plain
`Value.new` is `ActiveModel::Type::DefaultValue`), ActiveModel::Attribute (FromDatabase, FromUser, ...),
ConnectionAdapters::Column, Transaction (Real/Savepoint/RestartParent), AbstractAdapter (a module SQLite3Adapter
includes with SQLite3::Quoting, SchemaStatements, DatabaseStatements, in Ruby's order: the module included last
wins, as Ruby's ancestors). Classes that Ruby makes in a loop (`%w{Bin Group Limit ...}.each { const_set(name,
Class.new(Unary)) }`) are written out.

**The visitor's `send("visit_#{class}")` → a `case` over the classes**, calling the same `visit_Arel_Nodes_X`
functions. `class SQLite < ToSql` pastes ToSql, so SQLite's own `visit_Arel_Nodes_Lock` replaces ToSql's in
the pasted dispatcher, which is Ruby's override. **No `super`**: where SQLite's method calls super, ToSql keeps
the body also under `super_<name>` (`super_visit_Arel_Nodes_SelectStatement`, `super_prepare_update_statement`,
`super_quote`, `super_type_cast`, `super_add_column_options!`, `super_cast`). One subtle Ruby detail survived
only because the test caught it: `alias :prepare_delete_statement :prepare_update_statement` binds ToSql's
method, so SQLite's override does not change DELETEs; in Sake that is an explicit call of the super_ body.

**Stored blocks → data plus a function with the block's body.**

| Ruby | Sake |
|---|---|
| `BIND_BLOCK = proc { "?" }`, `collector.add_bind(v, &bind_block)` | `def bind_block(v, i) = "?"`, `Collector.add_bind(c, v) { |i| bind_block(v, i) }` |
| HomogeneousIn#proc_for_binds (a lambda making an Attribute per value) | the attribute name the lambda closed over; Bind.add_binds makes the Attributes |
| TypeMap `register_type(/int/i) { |t| Integer.new(limit: extract_limit(t)) }` | `Registration(key, kind: :limit, klass: :integer)`; `AbstractAdapter::ClassMethods.build_registered_type` is the blocks' bodies |
| `ActiveModel::Type.register(:integer, Integer)` (a Hash of blocks) | `ActiveModel::Type.lookup(symbol, options)`, a `case`; ActiveRecord::Type.lookup puts SQLite3's `:integer` override first |
| AcceptsMultiparameterTime (a Module subclass that define_methods with the defaults closed over) | a mixin whose includer defines `multiparameter_defaults(t)` |
| `send(method_id, expr)` in grouping_any | `Predications.predicate(a, method_id, ...)`, a `case` over the Symbols |
| `klass = Nodes::InnerJoin` passed as a value | a Symbol (`:inner`, `:outer`, `:string`); `Nodes.build_join` |

**Ruby's keyword options → a Hash (DSL options) or a Record (fixed options).** `t.string :title, null: false`
is `TableDefinition.string(t, :title, Hash.of(null: false))`; `transaction(requires_new: true)` is
`transaction(conn, {requires_new: true, isolation: nil, joinable: true})`. Internal keyword parameters
(`prepare:, allow_retry:, materialize_transactions:`) are positional in Ruby's order. `Model.new(precision: 5)`
works unchanged because `new` takes fields by keyword.

**Constructors that compute** (Ruby's `initialize(table = nil)` builds the AST): the argument is the first
field (private) and `initialize` builds the rest, so the call is Ruby's: `Arel::SelectManager.new(users)`,
`Arel::InsertManager.new`. For nodes whose subclass passes a constant to super (`Multiplication.new(l, r)` is
`InfixOperation.new(:*, l, r)`), initialize fills the operator.

**Globals.** `Arel::Table.engine` (a class-level accessor) is a holder made with `once`:
`Arel::Table.set_engine(connection)`. The engine is the connection itself here (Rails' is ActiveRecord::Base,
with `with_connection`), and `Arel::Nodes::Node.to_sql(node)` uses its visitor.

**Driver.** Ruby prepares statements and reads `stmt.columns`, `stmt.types`; Sake's SQLite3 built-in has
`execute2` (column names, then rows), so `perform_query` builds the Result from it. The adapter connects
lazily on the first query, as Rails does; `PRAGMA foreign_keys = ON` is the one default pragma applied.

**SQL log.** Rails' `log` instruments `sql.active_record`; ActiveSupport::Notifications is part 2's, so the
adapter keeps `[name, sql]` in `query_log` when the config has `log: true` (Sake only), appended when the
query ends, as the notification is (so a lazy `BEGIN` comes before the statement that materialized it). The
test compares it with a Ruby subscriber.

## Left out, and why

- Arel: Visitors::Dot, PostgreSQL and MySQL visitors; Cube/RollUp/GroupingSet/Lateral/DistinctOn/Regexp nodes
  (no SQLite SQL); `fetch_attribute` (the model layer's; a dispatched function must take a block in every
  includer or none, and Node's default has none); hash/eql? (Sake's `==` compares fields); `~@`.
- Adapter: connection pool/handler, query cache, schema cache (columns are read from the database each time),
  statement pool, retries/reconnect logic, advisory locks, `alter_table` (the SQLite table copy behind
  remove_column/change_column/rename_column/foreign keys/check constraints), schema dumper, explain,
  insert_all/upsert (`build_insert_sql`), fixtures, transaction record callbacks (commit/rollback of records:
  the model layer), ActiveRecord::Transaction (the block gets the adapter's transaction object), multi-thread
  locking (`@connection.lock.synchronize`).
- Types: Serialized, UnsignedInteger, ActiveSupport time zones (times are UTC, Rails' default without
  `config.time_zone`), `Date._parse` fallbacks (ISO formats only).
- `ActiveRecord.default_timezone` is fixed to `:utc`.

## Built-ins Sake lacks (requests)

- `SQLite3::Database.total_changes` (Ruby's perform_query compares it before and after): landed; since the third
  wave perform_query calls it as Ruby does (the first wave asked `SELECT total_changes()`, one more statement per query).
- The declared column types of a result (`stmt.types`), so that `Result#column_types`/`cast_values` can use the
  type map as Rails does; without it a result's columns use Type.default_value.
- Prepared statements (`prepare`/`bind`/`step`) for the statement pool (not needed for correctness).

## Bugs found (repros in experiments/2026-10-20-rails-scale/bugs/)

- `arel_empty_array_of_arrays_index.sake`: a field once given `Array[]` (an empty Array of Arrays) makes
  `row[i]` on its elements fail: "the receiver is Array, which cannot be indexed; defined for (Array,
  Integer)". Workaround: `Any[]` in `ActiveRecord::Result.empty_result`.
- `arel_p_of_date_or_bigdecimal.sake`: at `--strict` only, `p(x)` with x `Date | BigDecimal` fails inside
  date.sake (Date#<=> given a BigDecimal, no `in` branch). The same message came from `x == nil` on values
  whose union holds both (ActiveModel::Type casting a column default); `(x in nil)` avoided it in
  value.sake/helpers.sake/integer.sake.
- `arel_block_over_columns.sake`: at `--strict` only, any block over the Columns the adapter read failed the
  same way while SQLite3::Column cast its default in initialize into a field; casting it when read
  (`Column.default`) avoided it. The test prints columns one call each for that reason. No standalone repro.

## Friction (what I wrote first → the message → what I wrote instead)

- `def visit(o, c) ... c << " = "` on a collector class → "Bitwise.<<: ... does not include Bitwise" →
  `include Bitwise` in the collectors' module. `<<` is the most natural Arel collector call and it works once
  the module is included.
- `ActiveModel::Type::Integer` and friends live in `module ActiveModel::Type`, so every `String.strip`,
  `Float.nan?`, `Time.utc`, `Integer.abs` there resolved to the type classes ("undefined function
  `ActiveModel::Type::String.strip`"). Ruby has the same trap and writes `::String`; so did I (a script rewrote
  60 calls). The hint names the right one, which helps.
- A Ruby class with a reader `value` and an instance method `value` (ActiveModel::Attribute's `@value` and
  `#value`): `private attr_accessor value` made a reader that silently won over the module's `value`, so
  QueryAttribute's value was always nil. Found by printing; the fields are `cast_value`/`database_value` now.
  A warning when a field reader shadows an included function would have saved half an hour.
- A Ruby class method and an instance method of one name (`Attribute.with_cast_value(name, v, type)` and
  `attribute.with_cast_value(v)`) → "wrong number of arguments (given 3, expected 2)" → the instance one is
  `with_cast_value_of`.
- `SelectStatement.new(cores, Any[])` put the orders into `limit` (the field order is cores, limit, orders):
  the SQL got a stray space and lost `LIMIT -1`. Keywords (`orders: Any[]`) are the safe form for any class
  with several fields; positional `new` is not checked against the field order (the spec says so).
- `case default in /^null$/i` → "unsupported pattern" → `if String.match?(...)`/`elsif (m = String.match(...))`.
- `rel => Nodes::JoinSource` after `if has_join_sources?(v, o)` → "the value is Arel::Table | ... which does
  not match": the checker does not know what the predicate tested. A function returning the JoinSource or nil
  (`join_source(v, o)`) gives it the type; I would write that in Ruby too.
- `def union(m, operation, other = nil)` with `if other ... else operation => SelectManager` → the assertion is
  checked against the `:all` call too. A `case operation in SelectManager / in :all` says it directly.
- `Array.any?(xs)` without a block → "requires a block" (six places); `!Array.empty?(xs)`.
- `String.scan` with a group gives Tuples; `Array.flatten` leaves them whole (the message says so and gives the
  fix, `Array.flat_map { |t| Tuple.to_a(t) }`).
- The checker's precision paid off: it found that `SelectManager#on` could be given a Table (the SQLite UPDATE
  rewrite puts Tables into the join list), that a savepoint's parent could be the NullTransaction, and that
  `comment(m)` with no values returned the manager (my bug: Ruby's reader form) — the last one printed `(SELECT
  ...)` at the end of every compiled UPDATE until the comparison caught it.
- Typing on operations is heavy here: `Arel::Table.project(users, users[:id]).Arel::SelectManager.where(
  Arel::Attribute.eq(users[:name], "x")).order(...)` against Ruby's `users.project(users[:id]).where(
  users[:name].eq("x"))`. Chains help; `users[:name]` (Indexable) and `posts[:score] + 1` (Arithmetic) read as
  Ruby. The test files are about 1.6x Ruby's characters.
- The check of the largest test is 3.4 s; Arel's ~100 node classes, all included modules copied into each
  (Predications alone is ~40 functions × ~60 classes copied), cost nothing until called.
