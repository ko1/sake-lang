# SQLite3::Statement as ActiveRecord's sqlite3 adapter runs a query: prepare, bind, step or read all, columns, types.
require "sqlite3"
db = SQLite3::Database.new(":memory:")
db.execute_batch("create table users (id integer primary key, name varchar(40) not null, born date, score decimal(5, 2), data blob)")
ins = db.prepare("insert into users (name, born, score) values (?, ?, ?)")
[["ann", "1990-01-02", 9.5], ["bob", nil, 7]].each do |name, born, score|
  before = db.total_changes
  ins.reset!
  ins.bind_params([name, born, score])
  p ins.step
  puts "affected #{db.total_changes > before ? db.changes : 0} id #{db.last_insert_row_id}"
end
p ins.column_count
ins.close
sel = db.prepare("select id, name, born, score, data, upper(name) from users where id > ?")
p sel.column_count
p sel.columns
p sel.types
sel.bind_params([0])
p sel.to_a
p sel.done?
p sel.execute(1).to_a
sel.reset!
sel.bind_params([0])
p sel.step
p sel.closed?
sel.close
p sel.closed?
p db.total_changes
begin
  sel.step
rescue SQLite3::Exception => e
  puts e.message
end
begin
  db.prepare("select ?").bind_params([1, 2])
rescue SQLite3::RangeException => e
  puts e.message
end
