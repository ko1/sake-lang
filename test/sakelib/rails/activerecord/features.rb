gem "activerecord", "8.1.3"
require "active_record"

# enum, store, has_secure_token, attr_readonly, the attributes API, readonly records, optimistic locking,
# pessimistic locking, timestamps and touch, counters, update_columns, and transactions
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "features_schema.rb")
require_relative "features_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

puts("-- enum")
order = Order.create(code: "A1", color: "red")
p([order.status, order.pending?, order.shipped?])
order.shipped!
p([order.status, order.shipped?, Order.statuses, Order.shipped.count, Order.not_shipped.count])
order.priority = :high
p([order.priority, order.priority_high?, order.priority_low?, Order.priorities])
p(Order.where(status: :shipped).pluck(:code))
begin
  order.status = :lost
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
show_sql

puts("-- store")
p([order.color, order.gift_note, order.settings])
order.gift_note = "happy"
order.save
p(Order.find(order.id).settings)
show_sql

puts("-- secure token")
p([order.token.size, order.token.match?(/\A[0-9a-zA-Z]{24}\z/)])
old = order.token
order.regenerate_token
p(order.token != old)
show_sql

puts("-- attr_readonly and the attributes API")
order.update(code: "B2")
p([order.code, Order.find(order.id).code, order.discount, Order.new.discount])
begin
  order.update_column(:code, "C3")
rescue ActiveRecord::ActiveRecordError => e
  puts("ActiveRecordError: #{e.message}")
end
show_sql

puts("-- readonly")
ro = Order.find(order.id)
ro.readonly!
begin
  ro.save
rescue ActiveRecord::ReadOnlyRecord => e
  puts("ReadOnlyRecord: #{e.message}")
end
p(Order.readonly.first.readonly?)
show_sql

puts("-- optimistic locking")
doc = Doc.create(title: "v1")
a = Doc.find(doc.id)
b = Doc.find(doc.id)
a.title = "v2"
p([a.save, a.lock_version])
b.title = "v3"
begin
  b.save
rescue ActiveRecord::StaleObjectError => e
  puts("StaleObjectError: #{e.message}")
end
p(a.destroy.destroyed?)
show_sql

puts("-- pessimistic locking")
c = Order.find(order.id)
c.lock!
c.with_lock { c.update(paid: false) }
show_sql

puts("-- counters")
c.increment!(:items_count)
c.increment!(:items_count, 2)
c.decrement!(:items_count)
c.toggle!(:paid)
p([c.items_count, c.paid, Order.find(c.id).items_count])
show_sql

puts("-- timestamps")
note = Note.create(body: "x")
p([note.created_at, note.updated_at])
c.reload
c.touch
p(c.updated_at.class.name)
p(c.update_columns(paid: true, items_count: 0))
show_sql

puts("-- transactions")
Order.transaction do
  Order.create(code: "T1")
  Order.transaction(requires_new: true) do
    Order.create(code: "T2")
    raise ActiveRecord::Rollback
  end
end
p(Order.pluck(:code))
t3 = Order.new(code: "T3")
Order.transaction do
  t3.save
  raise ActiveRecord::Rollback
end
p([t3.new_record?, t3.id, Order.count])
show_sql
