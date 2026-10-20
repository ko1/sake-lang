# SQLite3::Database is built in; sqlite3.rb is the same program on Ruby's sqlite3 gem.
require "sqlite3"
db = SQLite3::Database.new(":memory:")
db.execute_batch(<<~SQL)
  create table items (id integer primary key autoincrement, name text not null unique, price real, qty integer default 0, data blob);
  create table log (id integer primary key, msg text);
SQL
[["apple", 1.25, 10], ["bread", 2.5, 3], ["cheese", 7.0, 0]].each do |name, price, qty|
  db.execute("insert into items (name, price, qty) values (?, ?, ?)", [name, price, qty])
  p [db.last_insert_row_id, db.changes]
end
db.execute("insert into items (name) values (?)", ["dates"])
p db.execute("select * from items order by id")
p db.execute("select name, price * qty from items where qty > ? order by name", [0])
p db.execute("select count(*), sum(qty), avg(price), max(name) from items")
p db.execute("select ?, ?, ?, ?, typeof(?)", [1, -2.5, "text", nil, 2 ** 40])
p db.execute("select ?1 || ?1, ?2", ["ab", 3])
p db.execute("select 'x' where 0")
p db.execute2("select id, name as label from items where price < ?", [3])
p db.execute2("select 1 as one where 0")
db.execute("update items set qty = qty + 1 where price is not null")
p db.changes
db.execute("update items set data = x'cafe' where name = ?", ["apple"])
p db.execute("select data, length(data), hex(data) from items where name = 'apple'")
p db.execute("select '日本', length('日本')")

# Errors are the gem's classes, rescuable by name or by the base SQLite3::Exception.
begin
  db.execute("insert into items (name) values (?)", ["apple"])
rescue SQLite3::ConstraintException => e
  puts "ConstraintException: #{e.message}"
end
begin
  db.execute("insert into items (price) values (1)")
rescue SQLite3::Exception => e
  puts "Exception: #{e.message}"
end
begin
  db.execute("select nope from items")
rescue SQLite3::SQLException => e
  puts "SQLException: #{e.message}"
end
begin
  db.execute("select ?", [1, 2])
rescue SQLite3::RangeException => e
  puts "RangeException: #{e.message}"
end
begin
  db.execute_batch("insert into log (msg) values ('a'); insert into nowhere values (1)")
rescue SQLite3::SQLException => e
  puts "SQLException: #{e.message}"
end
p db.execute("select msg from log")

# transaction: the block's value, committed; rolled back when the block raises, and the error raised again.
v = db.transaction do |d|
  d.execute("insert into log (msg) values (?)", ["in"])
  d.execute("select count(*) from log")
end
p v
begin
  db.transaction do |d|
    d.execute("delete from log")
    d.execute("insert into items (name) values ('bread')")
  end
rescue SQLite3::ConstraintException => e
  puts "rolled back: #{e.message}"
end
begin
  db.transaction do |d|
    d.execute("delete from log")
    raise ArgumentError, "stop"
  end
rescue ArgumentError => e
  puts "rolled back: #{e.message}"
end
p db.execute("select id, msg from log")
begin
  db.transaction do |d|
    d.transaction { |_| 1 }
  end
rescue SQLite3::SQLException => e
  puts "nested: #{e.message}"
end

# A file database: what one connection writes, another reads.
path = "sqlite3_test.db"
File.delete(path) if File.exist?(path)
a = SQLite3::Database.new(path)
a.execute("create table kv (k text primary key, v text)")
a.execute("insert into kv values (?, ?)", ["key", "value"])
b = SQLite3::Database.new(path)
p b.execute("select * from kv")
p a.closed?
a.close
b.close
p [a.closed?, a.close.then { nil }]
begin
  a.execute("select 1")
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end
File.delete(path)
begin
  SQLite3::Database.new("no/such/dir/x.db")
rescue SQLite3::CantOpenException => e
  puts "CantOpenException: #{e.message}"
end
