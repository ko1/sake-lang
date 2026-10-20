# SQLite3::Statement

SQLite3::Statement はプリペアドステートメント、つまり準備済みの SQL 文です（sqlite3 gem の `SQLite3::Statement`）。`SQLite3::Database.prepare(db, sql)`（または `SQLite3::Statement.new(db, sql)`）で 1 度だけコンパイルし、値を bind して実行し、リセットしてまた実行します。ActiveRecord の sqlite3 アダプタはすべての問い合わせをこの方法で実行し、文からしか分からない 2 つのこと、列の名前と列の**宣言された型**（`columns`、`types`）を読んで、そこから各値を変換する型を選びます。[SQLite3::Database](SQLite3-Database.md) と同じく組み込みで、下で動いているのは gem です。ネイティブバックエンドは対応していません。

行は `SQLite3::Database.execute` が返すのと同じ `Integer | Float | String | nil` の Array で、binds はそれらの型の Array です（それ以外の型は静的な `type` の問題）。閉じた文への操作は `SQLite3::Exception`（`cannot use a closed statement`）を投げます。エラーは [SQLite3::Database](SQLite3-Database.md) と同じです。使える演算子は `==`、`!=` だけです（同じ文なら等しい）。

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

`SQLite3::Database.prepare(db, sql)` と同じです: `sql` の最初の文を `db` 向けにコンパイルします。

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Statement.new(db, "select 1 + ?")
p(SQLite3::Statement.execute(st, Any[41]))   # => [[42]]
```

## bind_params

`SQLite3::Statement.bind_params(x, Array)`

プレースホルダ（`?`、`?1` など）を `binds` の値で順に埋め、文を返します。値は次の `bind_params` まで bind されたままで、`reset!` では消えません。`step` の後でもう一度 bind するには先に `reset!` が要ります（しないと gem と同じく `SQLite3::MisuseException`）。プレースホルダより値が多ければ `SQLite3::RangeException` です。

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

文を次の行まで実行してその行を返します。行が残っていなければ nil です（そのとき `done?` は true）。行を返さない文（`insert`）は最初の `step` で最後まで実行され、nil を返します。

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

残っている行を最後まで読んだものです（gem の `each` による `to_a`）。

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1, 'a' union all select 2, 'b'")
p(SQLite3::Statement.to_a(st))      # => [[1, "a"], [2, "b"]]
p(SQLite3::Statement.to_a(st))      # => []
```

## execute

`SQLite3::Statement.execute(x, [Array])`

文をリセットし、`binds` があれば bind して実行し、すべての行を返します。gem は行を読み出す `ResultSet` を返しますが、ここではその場で読みます（gem の `execute(...).to_a`）。

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

文を最初の行の前まで巻き戻し、同じ bind のまま初めから実行し直せるようにします。文を返します。

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 7")
p(SQLite3::Statement.step(st))      # => [7]
p(SQLite3::Statement.step(SQLite3::Statement.reset!(st)))   # => [7]
```

## columns

`SQLite3::Statement.columns(x)`

文の結果の列の名前で、String の Array です（`as` の名前。式の列はその式の文字列が名前です）。行を返さない文では空です。

```ruby
db = SQLite3::Database.new(":memory:")
st = SQLite3::Database.prepare(db, "select 1 as one, 2 + 3")
p(SQLite3::Statement.columns(st))   # => ["one", "2 + 3"]
```

## types

`SQLite3::Statement.types(x)`

結果の各列の宣言された型で、`create table` に書いたとおりのもの（`"integer"`、`"varchar(255)"`、`"datetime"`）です。式の列や型なしで宣言した列は nil です。ActiveRecord はそれぞれを型の表で引いて、列の値を変換します。

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (id integer primary key, at datetime, x)")
st = SQLite3::Database.prepare(db, "select id, at, x, count(*) from t")
p(SQLite3::Statement.types(st))     # => ["integer", "datetime", nil, nil]
```

## column_count

`SQLite3::Statement.column_count(x)`

結果の列の数を Integer で返します。行を返さない文では 0 です（ActiveRecord はこれで問い合わせと書き込みを見分けます）。

```ruby
db = SQLite3::Database.new(":memory:")
SQLite3::Database.execute(db, "create table t (a, b)")
p(SQLite3::Statement.column_count(SQLite3::Database.prepare(db, "select a, b from t")))   # => 2
p(SQLite3::Statement.column_count(SQLite3::Database.prepare(db, "delete from t")))        # => 0
```

## done?

`SQLite3::Statement.done?(x)`

`step` が文を最後まで実行すると true になります（`reset!` まで）。

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

`close` は文を解放して nil を返します（もう一度閉じても何もしません）。`closed?` は閉じているかを返します。閉じた文はもう使えません。

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

同じ文なら `==` です。

```ruby
db = SQLite3::Database.new(":memory:")
a = SQLite3::Database.prepare(db, "select 1")
b = SQLite3::Database.prepare(db, "select 1")
p(a == a, a == b)                   # => true
                                    # => false
```
