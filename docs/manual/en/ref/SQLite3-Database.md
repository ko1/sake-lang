# SQLite3::Database

SQLite3::Database is the type of a connection to an SQLite database (Ruby's sqlite3 gem, `SQLite3::Database`; the gem is what runs underneath, so its behavior and messages are the gem's). `SQLite3::Database.new(path)` opens or creates the file `path`, or with `":memory:"` a database that lives only in this connection; `SQLite3::Database.execute(db, sql, binds)` runs one SQL statement and returns its rows ([Built-ins](../09-builtins.md)). There is no literal, and nothing needs to be required: it is built in. The native backends (`sabic`, `ceec`) do not support it.

A row is an Array of the column values in the order the statement names them, each an `Integer` (INTEGER), a `Float` (REAL), a `String` (TEXT, in UTF-8; a BLOB is a binary String, encoding `ASCII-8BIT`), or `nil` (NULL). The result of `execute` is an Array of such rows, so the checker gives a value read from a row the type `Integer | Float | String | nil`: narrow it (`v => Integer`, `case v in String`) before an operation that takes one type. A row is an Array, not a Tuple, so `in [a, b]` does not match it; `|id, name|` in a block destructures it, as for any Array.

The binds are an Array (`Any[...]`, not a Tuple `[...]`) whose elements fill the statement's `?` (and `?1`, `?2`) in order. A bind is an `Integer`, a `Float`, a `String` or `nil`; any other type (`true`, a Symbol, an Array, ...) is a static `type` problem, and a `TypeError` (`can't prepare Symbol`) where the checker cannot see it. Fewer binds than placeholders leave the rest NULL; more is a `SQLite3::RangeException`. Named parameters (`:name` with a Hash), `results_as_hash`, prepared statements (`SQLite3::Statement`) and the type translation options of the gem are not available.

The errors are the gem's exception classes, with its messages: `SQLite3::SQLException` (a syntax error, a missing table or column), `SQLite3::ConstraintException` (UNIQUE, NOT NULL, CHECK, FOREIGN KEY), `SQLite3::BusyException`, `SQLite3::LockedException`, `SQLite3::ReadOnlyException`, `SQLite3::MisuseException`, `SQLite3::RangeException`, `SQLite3::CantOpenException`, and the rest of the gem's (`SQLite3::MismatchException`, `NotADatabaseException`, `IOException`, `FullException`, `TooBigException`, `AbortException`, `InterruptException`, `PermissionException`, `CorruptException`, `InternalException`, `MemoryException`, `NotFoundException`, `ProtocolException`, `EmptyException`, `SchemaChangedException`, `AuthorizationException`, `FormatException`, `UnsupportedException`). They are all under `SQLite3::Exception`, so `rescue SQLite3::Exception` catches every one of them. Like `Math::DomainError` these are nested names: they are written in `rescue` (and `raise`), and their message is read with `Exception.message(e)` ([Exceptions](Exceptions.md)). An operation on a closed database is an `ArgumentError` (`prepare called on a closed database`), as in the gem.

The only operators on databases are `==` and `!=` (equal for the same connection).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table people (id integer primary key, name text not null unique, age integer)")
SQLite3::Database.execute(db, "insert into people (name, age) values (?, ?)", Any["ann", 31])
SQLite3::Database.execute(db, "insert into people (name, age) values (?, ?)", Any["bob", nil])
rows = SQLite3::Database.execute(db, "select id, name, age from people order by id")
p(rows)                             # => [[1, "ann", 31], [2, "bob", nil]]
Array.each(rows) { |id, name, age|
  age => Integer | nil
  puts("#{name}: #{age ? age + 1 : "?"}")   # => ann: 32
                                            # => bob: ?
}
begin
  SQLite3::Database.execute(db, "insert into people (name) values ('ann')")
rescue SQLite3::ConstraintException => e
  puts(Exception.message(e))        # => UNIQUE constraint failed: people.name
end
```

## new

`SQLite3::Database.new(String)`

Opens the database file `path`, creating it when it does not exist, and returns a SQLite3::Database. `":memory:"` is a new, empty database in memory, private to this connection. Two connections to the same file see each other's committed writes. A file that cannot be opened (its directory does not exist, no permission) is a `SQLite3::CantOpenException`.

```ruby
db = SQLite3::Database.new(":memory:")
p(db)                               # => #<SQLite3::Database>
p(SQLite3::Database.execute(db, "select 1 + 1"))   # => [[2]]
a = SQLite3::Database.new("app.db")
SQLite3::Database.execute(a, "create table kv (k text, v text)")
SQLite3::Database.execute(a, "insert into kv values ('lang', 'sake')")
b = SQLite3::Database.new("app.db")
p(SQLite3::Database.execute(b, "select * from kv"))   # => [["lang", "sake"]]
```

```ruby error
SQLite3::Database.new("no/such/dir/x.db")   # !> SQLite3::CantOpenException: SQLite3::Database.new: unable to open database file
```

## execute

`SQLite3::Database.execute(x, String, [Array])`

Runs the SQL statement `sql` with `binds` filling its placeholders, and returns its rows: an Array of Arrays of `Integer | Float | String | nil` (empty for a statement that gives no rows, such as `insert`). Only the first statement of `sql` runs: use `execute_batch` for several. A bind value fills `?` in order, or `?1`, `?2` by number; an Integer too large for 64 bits is stored as a Float, as by the gem.

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (n integer, x real, s text, b blob)")
p(SQLite3::Database.execute(db, "insert into t values (?, ?, ?, x'00ff')", Any[1, 2.5, "a"]))   # => []
p(SQLite3::Database.execute(db, "select * from t"))   # => [[1, 2.5, "a", "\x00\xFF"]]
p(SQLite3::Database.execute(db, "select ?1 || ?1, ?2", Any["ab", nil]))   # => [["abab", nil]]
p(SQLite3::Database.execute(db, "select ?, ?", Any[1]))   # => [[1, nil]]
p(SQLite3::Database.execute(db, "select count(*), avg(x) from t where n > ?", Any[5]))   # => [[0, nil]]
```

```ruby error
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "select ?", Any[:sym])   # !> a bind value must be Integer|Float|String|Nil, but is :sym [type]
```

```ruby error
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "selec 1")   # !> SQLite3::SQLException: SQLite3::Database.execute: near "selec": syntax error
```

## execute2

`SQLite3::Database.execute2(x, String, [Array])`

As `execute`, with the column names first: the result's first element is an Array of Strings (the names the statement gives its columns, `as` included), and the rows follow. The names come even when there is no row.

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (id integer primary key, name text)")
SQLite3::Database.execute(db, "insert into t (name) values ('a'), ('b')")
p(SQLite3::Database.execute2(db, "select id, name as label from t"))   # => [["id", "label"], [1, "a"], [2, "b"]]
head, *rows = SQLite3::Database.execute2(db, "select name from t where id > ?", Any[5])
p(head, rows)                       # => ["name"]
                                    # => []
```

## execute_batch

`SQLite3::Database.execute_batch(x, String)`

Runs every statement of `sql` (separated by `;`) in order and returns nil; the rows they give are dropped. It takes no binds. A statement that fails raises its error, and the statements before it stay done.

```ruby
db = SQLite3::Database.new(":memory:")
p(SQLite3::Database.execute_batch(db, <<~SQL))   # => nil
  create table t (n integer);
  insert into t values (1);
  insert into t values (2);
SQL
p(SQLite3::Database.execute(db, "select sum(n) from t"))   # => [[3]]
begin
  SQLite3::Database.execute_batch(db, "insert into t values (3); insert into nowhere values (4)")
rescue SQLite3::SQLException => e
  p(SQLite3::Database.execute(db, "select count(*) from t"))   # => [[3]]
end
```

## last_insert_row_id

`SQLite3::Database.last_insert_row_id(x)`

The rowid (an `integer primary key` column is it) of the row most recently inserted on this connection, an Integer; 0 before any insert.

```ruby
db = SQLite3::Database.new(":memory:")
p(SQLite3::Database.last_insert_row_id(db))   # => 0
SQLite3::Database.execute(db, "create table t (id integer primary key, name text)")
SQLite3::Database.execute(db, "insert into t (name) values (?)", Any["a"])
SQLite3::Database.execute(db, "insert into t (name) values (?)", Any["b"])
p(SQLite3::Database.last_insert_row_id(db))   # => 2
```

## changes

`SQLite3::Database.changes(x)`

The number of rows the most recent `insert`, `update` or `delete` changed, an Integer (a statement of another kind leaves it as it was).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute_batch(db, "create table t (n integer); insert into t values (1), (2), (3);")
p(SQLite3::Database.changes(db))    # => 3
SQLite3::Database.execute(db, "update t set n = n * 10 where n > ?", Any[1])
p(SQLite3::Database.changes(db))    # => 2
SQLite3::Database.execute(db, "select * from t")
p(SQLite3::Database.changes(db))    # => 2
```

## transaction

`SQLite3::Database.transaction(x) { }`

Begins a transaction, calls the block with the database, and commits; the result is the block's value. When the block raises, the transaction is rolled back and the error is raised again; leaving the block by `break`, `next` or `return` commits, as in Ruby. A transaction inside another is a `SQLite3::SQLException` (`cannot start a transaction within a transaction`).

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (n integer unique)")
v = SQLite3::Database.transaction(db) { |d|
  SQLite3::Database.execute(d, "insert into t values (1)")
  SQLite3::Database.changes(d)
}
p(v)                                # => 1
begin
  SQLite3::Database.transaction(db) { |d|
    SQLite3::Database.execute(d, "insert into t values (2)")
    SQLite3::Database.execute(d, "insert into t values (1)")
  }
rescue SQLite3::ConstraintException => e
  puts(Exception.message(e))        # => UNIQUE constraint failed: t.n
end
p(SQLite3::Database.execute(db, "select n from t"))   # => [[1]]
```

## close, closed?

`SQLite3::Database.close(x)`

`SQLite3::Database.closed?(x)`

`close` closes the connection and returns nil; closing again does nothing. `closed?` tells whether it is closed. Any other operation on a closed database is an `ArgumentError`.

```ruby
db = SQLite3::Database.new(":memory:")
p(SQLite3::Database.closed?(db))    # => false
p(SQLite3::Database.close(db))      # => nil
p(SQLite3::Database.closed?(db))    # => true
p(SQLite3::Database.close(db))      # => nil
```

```ruby error
db = SQLite3::Database.new(":memory:")
SQLite3::Database.close(db)
SQLite3::Database.execute(db, "select 1")   # !> ArgumentError: SQLite3::Database.execute: prepare called on a closed database
```

## ==, !=

`SQLite3::Database.==(x, Any)`

`SQLite3::Database.!=(x, Any)`

Two values are equal when they are the same connection (`!=` is the negation). Every `SQLite3::Database.new` is a different value, even for the same file. A value that is not a database is never equal.

```ruby
a = SQLite3::Database.new(":memory:")
b = SQLite3::Database.new(":memory:")
p(a == a)                           # => true
p(a == b)                           # => false
p(a != b)                           # => true
p(SQLite3::Database.==(a, 1))       # => false
```
