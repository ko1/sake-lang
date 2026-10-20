gem "activerecord", "8.1.3"
require "active_record"
require "active_record/connection_adapters/sqlite3_adapter"

# The SQLite3 adapter on a :memory: database: schema statements, queries through Arel, transactions, errors
conn = ActiveRecord::ConnectionAdapters::SQLite3Adapter.new(adapter: "sqlite3", database: ":memory:")
log = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| log << payload[:sql] unless payload[:name] == "SCHEMA" }
def show_log(log)
  log.each { |sql| puts("  sql: #{sql}") }
  log.clear
end

puts("-- schema")
conn.create_table(:posts) do |t|
  t.string :title, null: false
  t.text :body
  t.integer :views, default: 0
  t.boolean :published, default: false
  t.decimal :score, precision: 5, scale: 2
  t.references :author
  t.timestamps
end
conn.add_index(:posts, :title, unique: true)
conn.create_table(:tags, id: false) { |t| t.string :name; t.integer :post_id }
conn.add_column(:tags, :color, :string, default: "red")
show_log(log)
p(conn.tables)
p([conn.table_exists?(:posts), conn.table_exists?(:nope), conn.data_source_exists?("tags")])
p(conn.primary_key("posts"))
p(conn.primary_key("tags"))
# One call per column: a block over the Columns is rejected at --strict (experiments/2026-10-20-rails-scale/bugs/arel_block_over_columns.sake)
def show_column(c) = p([c.name, c.sql_type, c.type, c.null, c.has_default?, c.limit, c.precision, c.scale])
cols = conn.columns("posts")
show_column(cols[0])
show_column(cols[1])
show_column(cols[2])
show_column(cols[3])
show_column(cols[4])
show_column(cols[5])
show_column(cols[6])
show_column(cols[7])
show_column(cols[8])
conn.indexes("posts").each { |i| p([i.name, i.columns, i.unique]) }
p(conn.index_exists?(:posts, :title))

puts("-- insert and select")
posts = Arel::Table.new(:posts)
now = Time.utc(2026, 10, 20, 12, 0, 0)
["first", "second", "third"].each_with_index do |title, i|
  im = Arel::InsertManager.new
  im.insert([[posts[:title], title], [posts[:views], i * 10], [posts[:published], i.odd?], [posts[:created_at], now], [posts[:updated_at], now]])
  p(conn.insert(im))
end
show_log(log)
r = conn.select_all(posts.project(posts[:id], posts[:title], posts[:views], posts[:published]).order(posts[:id]))
p(r.columns)
p(r.rows)
p(r.to_a.first)
p(conn.select_value(posts.project(posts[:id].count)))
p(conn.select_values(posts.project(posts[:title]).where(posts[:views].gt(5))))
p(conn.select_rows("SELECT title, created_at FROM posts WHERE id = 1"))
bind = Arel::Nodes::BindParam.new(ActiveRecord::Relation::QueryAttribute.new("views", "10", ActiveModel::Type::Integer.new))
p(conn.select_all(posts.project(posts[:title]).where(posts[:views].eq(bind))).rows)
p(conn.exec_query("SELECT id FROM posts WHERE title = ?", "SQL", ["third"]).rows)
show_log(log)

puts("-- update and delete")
um = Arel::UpdateManager.new(posts)
um.set([[posts[:views], posts[:views] + 1]]).where(posts[:published].eq(true))
p(conn.update(um))
dm = Arel::DeleteManager.new(posts)
dm.where(posts[:title].eq("first"))
p(conn.delete(dm))
p(conn.select_rows("SELECT id, title, views FROM posts ORDER BY id"))
show_log(log)

puts("-- transactions")
conn.transaction do
  conn.execute("UPDATE posts SET views = 100 WHERE id = 2")
end
conn.transaction do
  conn.execute("UPDATE posts SET views = 200 WHERE id = 2")
  raise ActiveRecord::Rollback
end
conn.transaction do
  conn.execute("UPDATE posts SET views = 300 WHERE id = 3")
  conn.transaction(requires_new: true) do
    conn.execute("UPDATE posts SET views = 400 WHERE id = 3")
    raise ActiveRecord::Rollback
  end
end
conn.transaction { p(conn.open_transactions) }
p(conn.select_rows("SELECT id, views FROM posts ORDER BY id"))
show_log(log)

puts("-- errors")
begin
  conn.execute("INSERT INTO posts (title, created_at, updated_at) VALUES ('second', '2026-01-01', '2026-01-01')")
rescue ActiveRecord::RecordNotUnique => e
  puts("RecordNotUnique: #{e.message}")
end
begin
  conn.execute("INSERT INTO posts (body, created_at, updated_at) VALUES ('x', '2026-01-01', '2026-01-01')")
rescue ActiveRecord::NotNullViolation => e
  puts("NotNullViolation: #{e.message}")
end
begin
  conn.execute("SELECT nope FROM posts")
rescue ActiveRecord::StatementInvalid => e
  puts("StatementInvalid: #{e.message}")
end
log.clear

puts("-- types")
["varchar(255)", "integer", "INTEGER", "bigint", "boolean", "decimal(5,2)", "decimal(10)", "datetime(6)", "date", "text", "blob", "float", "json", "whatever"].each do |sql_type|
  t = conn.lookup_cast_type(sql_type)
  p([sql_type, t.type, t.limit, t.precision, t.scale])
end
col = cols[7]
v = col.fetch_cast_type(conn).deserialize("2026-10-20 12:00:00")
v => Time
puts(v.inspect)
col = cols[4]
p(col.fetch_cast_type(conn).type)
conn.drop_table(:tags)
p(conn.tables)
show_log(log)
