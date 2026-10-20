# SQLite3::Database

SQLite3::Database は SQLite のデータベースへの接続の型です（Ruby の sqlite3 gem の `SQLite3::Database`。下で動いているのは gem そのものなので、振る舞いとメッセージは gem のものです）。`SQLite3::Database.new(path)` がファイル `path` を開くか作り、`":memory:"` ならこの接続の中だけにあるデータベースを作ります。`SQLite3::Database.execute(db, sql, binds)` が SQL 文を 1 つ実行して行を返します（[組み込み](../09-builtins.md)）。リテラルはありません。組み込みなので require は要りません。ネイティブバックエンド（`sabic`、`ceec`）は対応していません。

行は、文が並べた順の列の値の Array で、値はそれぞれ `Integer`（INTEGER）、`Float`（REAL）、`String`（TEXT は UTF-8。BLOB はバイナリの String で、エンコーディングは `ASCII-8BIT`）、`nil`（NULL）です。`execute` の結果はそういう行の Array なので、行から読んだ値の型をチェッカは `Integer | Float | String | nil` とします。1 つの型を取る操作に渡す前に絞ります（`v => Integer`、`case v in String`）。行は Tuple ではなく Array なので `in [a, b]` には当たりません。ブロックの `|id, name|` は他の Array と同じく行を分解します。

binds は Array（`Any[...]`。Tuple の `[...]` ではありません）で、要素が文の `?`（と `?1`、`?2`）を順に埋めます。bind に渡せるのは `Integer`、`Float`、`String`、`nil` で、それ以外の型（`true`、Symbol、Array など）は静的な `type` の問題、チェッカに見えない所では `TypeError`（`can't prepare Symbol`）です。プレースホルダより bind が少なければ残りは NULL、多ければ `SQLite3::RangeException` です。名前付きパラメタ（`:name` と Hash）、`results_as_hash`、gem の型変換の設定はありません。プリペアドステートメントは、各列の宣言された型も分かるもので、[SQLite3::Statement](SQLite3-Statement.md) です（`SQLite3::Database.prepare`）。

エラーは gem の例外クラスで、メッセージも gem のものです: `SQLite3::SQLException`（構文の誤り、無い表や列）、`SQLite3::ConstraintException`（UNIQUE、NOT NULL、CHECK、FOREIGN KEY）、`SQLite3::BusyException`、`SQLite3::LockedException`、`SQLite3::ReadOnlyException`、`SQLite3::MisuseException`、`SQLite3::RangeException`、`SQLite3::CantOpenException`、ほかに gem の残り（`SQLite3::MismatchException`、`NotADatabaseException`、`IOException`、`FullException`、`TooBigException`、`AbortException`、`InterruptException`、`PermissionException`、`CorruptException`、`InternalException`、`MemoryException`、`NotFoundException`、`ProtocolException`、`EmptyException`、`SchemaChangedException`、`AuthorizationException`、`FormatException`、`UnsupportedException`）。どれも `SQLite3::Exception` の下にあるので、`rescue SQLite3::Exception` で全部を捕まえられます。`Math::DomainError` と同じく入れ子の名前なので、`rescue`（と `raise`）に書き、メッセージは `Exception.message(e)` で読みます（[例外](Exceptions.md)）。閉じたデータベースへの操作は、gem と同じく `ArgumentError`（`prepare called on a closed database`）です。

データベースに使える演算子は `==`、`!=` だけです（同じ接続なら等しい）。

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

データベースのファイル `path` を開き（無ければ作り）、SQLite3::Database を返します。`":memory:"` はメモリ上の空のデータベースで、この接続だけのものです。同じファイルへの 2 つの接続は、互いがコミットした書き込みを読めます。開けないファイル（ディレクトリが無い、権限が無い）は `SQLite3::CantOpenException` です。

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

SQL 文 `sql` を、プレースホルダを `binds` で埋めて実行し、行を返します。結果は `Integer | Float | String | nil` の Array の Array です（`insert` のように行を返さない文では空）。`sql` の最初の文だけが実行されます。複数の文は `execute_batch` で実行します。bind は `?` を順に、または `?1`、`?2` を番号で埋めます。64 ビットに収まらない Integer は、gem と同じく Float として入ります。

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

`execute` と同じですが、列の名前が先に来ます: 結果の最初の要素は String の Array（文が列に付けた名前。`as` も含む）で、行がそれに続きます。行が無くても名前は返ります。

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

`sql` の文（`;` で区切る）をすべて順に実行し、nil を返します。文が返す行は捨てます。bind は取りません。途中の文が失敗するとそのエラーが投げられ、それより前の文は実行済みのまま残ります。

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

この接続で最後に挿入した行の rowid（`integer primary key` の列がそれです）を Integer で返します。まだ挿入していなければ 0 です。

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

最後の `insert`、`update`、`delete` が変えた行の数を Integer で返します（他の種類の文は値を変えません）。接続全体での数は `total_changes` です。

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute_batch(db, "create table t (n integer); insert into t values (1), (2), (3);")
p(SQLite3::Database.changes(db))    # => 3
SQLite3::Database.execute(db, "update t set n = n * 10 where n > ?", Any[1])
p(SQLite3::Database.changes(db))    # => 2
SQLite3::Database.execute(db, "select * from t")
p(SQLite3::Database.changes(db))    # => 2
```

## total_changes

`SQLite3::Database.total_changes(x)`

データベースを開いてからのすべての `insert`、`update`、`delete` が変えた行の数を Integer で返します（gem の `total_changes`）。`changes` は最後に行を変えた文の数を保ったままなので、ActiveRecord は文の前後でこれを比べて、その文が行を変えたかを判断します。

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute_batch(db, "create table t (n integer); insert into t values (1), (2), (3);")
before = SQLite3::Database.total_changes(db)
SQLite3::Database.execute(db, "select * from t")
p(SQLite3::Database.total_changes(db) - before, SQLite3::Database.changes(db))   # => 0
                                                                                  # => 3
SQLite3::Database.execute(db, "delete from t where n = 1")
p(SQLite3::Database.total_changes(db))   # => 4
```

## prepare

`SQLite3::Database.prepare(x, String)`

`sql` の最初の SQL 文をコンパイルし、bind して実行し、何度でも実行し直せる [SQLite3::Statement](SQLite3-Statement.md) として返します。`SQLite3::Statement.new(db, sql)` と同じです。構文の誤りや無い表はここで `SQLite3::SQLException` として投げられます（gem のメッセージは文を次の行に付け加えます）。gem のブロックを取る形（ブロックの後で文を閉じる）はありません。`SQLite3::Statement.close` を呼びます。

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (id integer primary key, name text)")
st = SQLite3::Database.prepare(db, "insert into t (name) values (?)")
Array.each(Any["ann", "bob"]) { |name| SQLite3::Statement.execute(st, Any[name]) }
SQLite3::Statement.close(st)
p(SQLite3::Database.execute(db, "select * from t"))   # => [[1, "ann"], [2, "bob"]]
begin
  SQLite3::Database.prepare(db, "select * from nope")
rescue SQLite3::SQLException => e
  p(Exception.message(e))           # => "no such table: nope:\nselect * from nope"
end
```

## transaction

`SQLite3::Database.transaction(x) { }`

トランザクションを始め、データベースを渡してブロックを呼び、コミットします。結果はブロックの値です。ブロックが例外を投げるとロールバックし、その例外を投げ直します。`break`、`next`、`return`、`throw` でブロックを抜けたときは、gem と同じくコミットします。トランザクションの中で始めるトランザクションは `SQLite3::SQLException`（`cannot start a transaction within a transaction`）です。

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

`close` は接続を閉じて nil を返します。もう一度閉じても何もしません。`closed?` は閉じているかを返します。閉じたデータベースへのそれ以外の操作は `ArgumentError` です。

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

同じ接続なら等しくなります（`!=` はその否定）。`SQLite3::Database.new` はファイルが同じでも毎回別の値です。データベースでない値とは等しくなりません。

```ruby
a = SQLite3::Database.new(":memory:")
b = SQLite3::Database.new(":memory:")
p(a == a)                           # => true
p(a == b)                           # => false
p(a != b)                           # => true
p(SQLite3::Database.==(a, 1))       # => false
```
