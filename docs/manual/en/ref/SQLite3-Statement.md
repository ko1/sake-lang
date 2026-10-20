# SQLite3::Statement

SQLite3::Statement is a prepared SQL statement (the sqlite3 gem's `SQLite3::Statement`): compiled once by `SQLite3::Database.prepare(db, sql)` (or `SQLite3::Statement.new(db, sql)`), then bound with values, run, reset and run again. ActiveRecord's sqlite3 adapter runs every query this way, and reads two things only a statement tells: the column names and the **declared types** of the columns (`columns`, `types`), from which it picks the type that casts each value. Like [SQLite3::Database](SQLite3-Database.md) it is built in and the gem runs underneath; the native backends do not support it.

A row is an Array of `Integer | Float | String | nil`, as `SQLite3::Database.execute` gives, and the binds are an Array of those types (any other is a static `type` problem). An operation on a closed statement raises `SQLite3::Exception` (`cannot use a closed statement`); the errors are those of [SQLite3::Database](SQLite3-Database.md). The only operators are `==` and `!=` (the same statement).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table posts (id integer primary key, title varchar(255), score real)")
SQLite3::Database.execute(db, "insert into posts (title, score) values ('a', 1.5), ('b', null)")
st = SQLite3::Database.prepare(db, "select id, title, score, upper(title) from posts where id >= ?")
p(SQLite3::Statement.columns(st))   # => ["id", "title", "score", "upper(title)"]
p(SQLite3::Statement.types(st))     # => ["integer", "varchar(255)", "real", nil]
p(SQLite3::Statement.execute(st, Any[1]))   # => [[1, "a", 1.5, "A"], [2, "b", nil, "B"]]
p(SQLite3::Statement.execute(st, Any[2]))   # => [[2, "b", nil, "B"]]
SQLite3::Statement.close(st)
```

## new

`SQLite3::Statement.new(SQLite3::Database, String)`

The same as `SQLite3::Database.prepare(db, sql)`: the first statement of `sql`, compiled for `db`.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Statement.new(db, "select 1 + ?")
p(SQLite3::Statement.execute(st, Any[41]))   # => [[42]]
```

## bind_params

`SQLite3::Statement.bind_params(x, Array)`

Fills the placeholders (`?`, `?1`, ...) with the values of `binds`, in order, and returns the statement. Values stay bound until the next `bind_params`; `reset!` does not clear them. Binding again after a `step` needs a `reset!` first (otherwise `SQLite3::MisuseException`, as in the gem). More values than placeholders is a `SQLite3::RangeException`.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select ? || ?")
SQLite3::Statement.bind_params(st, Any["sa", "ke"])
p(SQLite3::Statement.step(st))      # => ["sake"]
SQLite3::Statement.reset!(st)
begin
  SQLite3::Statement.bind_params(st, Any[1, 2, 3])
rescue SQLite3::RangeException => e
  puts(Exception.message(e))        # => column index out of range
end
```

## step

`SQLite3::Statement.step(x)`

Runs the statement up to its next row and returns that row, or nil when no row is left (then `done?` is true). A statement that gives no rows (`insert`) runs to its end at the first `step`, which returns nil.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1 union all select 2")
while (row = SQLite3::Statement.step(st))
  p(row)                            # => [1]
                                    # => [2]
end
p(SQLite3::Statement.done?(st))     # => true
```

## to_a

`SQLite3::Statement.to_a(x)`

The rows that are left, read to the end (the gem's `to_a` through `each`).

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1, 'a' union all select 2, 'b'")
p(SQLite3::Statement.to_a(st))      # => [[1, "a"], [2, "b"]]
p(SQLite3::Statement.to_a(st))      # => []
```

## execute

`SQLite3::Statement.execute(x, [Array])`

Resets the statement, binds `binds` when given, runs it, and returns all its rows. The gem returns a `ResultSet` to read them from; here they are read at once (its `execute(...).to_a`).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (n integer)")
ins = SQLite3::Database.prepare(db, "insert into t values (?)")
Array.each(Any[1, 2, 3]) { |n| SQLite3::Statement.execute(ins, Any[n]) }
sel = SQLite3::Database.prepare(db, "select sum(n) from t")
p(SQLite3::Statement.execute(sel))  # => [[6]]
```

## reset!

`SQLite3::Statement.reset!(x)`

Rewinds the statement to before its first row, so that it runs again from the start with the same binds; returns the statement.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 7")
p(SQLite3::Statement.step(st))      # => [7]
p(SQLite3::Statement.step(SQLite3::Statement.reset!(st)))   # => [7]
```

## columns

`SQLite3::Statement.columns(x)`

The column names of the statement's result, an Array of Strings (`as` names; an expression is named by its text). Empty for a statement that gives no rows.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1 as one, 2 + 3")
p(SQLite3::Statement.columns(st))   # => ["one", "2 + 3"]
```

## types

`SQLite3::Statement.types(x)`

The declared type of each result column, as written in `create table` (`"integer"`, `"varchar(255)"`, `"datetime"`), or nil for a column that is an expression or was declared without a type. ActiveRecord looks each one up in its type map to cast the column's values.

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (id integer primary key, at datetime, x)")
st = SQLite3::Database.prepare(db, "select id, at, x, count(*) from t")
p(SQLite3::Statement.types(st))     # => ["integer", "datetime", nil, nil]
```

## column_count

`SQLite3::Statement.column_count(x)`

The number of result columns, an Integer: 0 for a statement that gives no rows (ActiveRecord tells a query from a write by it).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (a, b)")
p(SQLite3::Statement.column_count(SQLite3::Database.prepare(db, "select a, b from t")))   # => 2
p(SQLite3::Statement.column_count(SQLite3::Database.prepare(db, "delete from t")))        # => 0
```

## done?

`SQLite3::Statement.done?(x)`

True once `step` has run the statement to its end (until `reset!`).

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1")
p(SQLite3::Statement.done?(st))     # => false
SQLite3::Statement.to_a(st)
p(SQLite3::Statement.done?(st))     # => true
```

## close, closed?

`SQLite3::Statement.close(x)`
`SQLite3::Statement.closed?(x)`

`close` frees the statement and returns nil (closing it again does nothing); `closed?` tells whether it is closed. A closed statement cannot be used again.

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1")
SQLite3::Statement.close(st)
p(SQLite3::Statement.closed?(st))   # => true
begin
  SQLite3::Statement.step(st)
rescue SQLite3::Exception => e
  puts(Exception.message(e))        # => cannot use a closed statement
end
```

## ==, !=

`SQLite3::Statement.==(x, Any)`
`SQLite3::Statement.!=(x, Any)`

Two statements are `==` when they are the same statement.

```ruby
db = SQLite3::Database.new(":memory:")
a = SQLite3::Database.prepare(db, "select 1")
b = SQLite3::Database.prepare(db, "select 1")
p(a == a, a == b)                   # => true
                                    # => false
```
