gem "activerecord", "8.1.3"
require "active_record"

# Relation: where (Hash, String, binds), where.not, or, rewhere, order, limit, select, group with
# calculations, pluck, finders, exists?, batch, bulk updates, merge, none, scopes as class methods, and the SQL
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "relation_schema.rb")
require_relative "relation_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:name] == "TRANSACTION" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

class Item
  scope :active_ones, -> { where(active: true) }
  scope :cheap, -> { where("price < ?", 100) }
end
def names(rel) = rel.map(&:name)

[["apple", "fruit", 50, 10, true], ["banana", "fruit", 30, nil, true], ["carrot", "veg", 80, 5, false],
 ["durian", "fruit", 300, 1, true], ["eggplant", "veg", 120, 0, true]].each do |name, category, price, stock, active|
  Item.create!(name: name, category: category, price: price, stock: stock, active: active)
end
SQL.clear

puts("-- where")
p(names(Item.where(stock: nil)))
p(names(Item.where(category: ["veg", "meat"])))
p(names(Item.where(price: 40..100)))
p(names(Item.where(price: 100..)))
p(names(Item.where(price: ...80)))
p(names(Item.where("price > ? AND category = ?", 60, "fruit")))
p(names(Item.where("price > :min", min: 100)))
p(names(Item.where.not(category: "fruit")))
p(names(Item.where(category: "veg").or(Item.where(price: 30))))
p(names(Item.where(category: "fruit").rewhere(category: "veg")))
p(names(Item.where(active: true).invert_where))
p(names(Item.where(id: Item.where(category: "veg").select(:id))))
show_sql

puts("-- order, limit, select")
p(names(Item.order(price: :desc).limit(2)))
p(names(Item.order(:category, :name).offset(3)))
p(names(Item.order("price DESC").reorder(:name).limit(2)))
p(names(Item.order(:price).reverse_order.limit(1)))
p(Item.select(:category).distinct.order(:category).map(&:category))
p(Item.where(category: "veg").to_sql)
show_sql

puts("-- calculations")
p(Item.count, Item.where(active: true).count, Item.count(:stock))
p(Item.sum(:price), Item.where(category: "veg").sum(:price), Item.maximum(:price), Item.minimum(:price))
p(Item.average(:price).to_f)
p(Item.group(:category).count)
p(Item.group(:category).sum(:price))
p(Item.group(:category).having("SUM(price) > ?", 300).count)
p(Item.order(:id).pluck(:name, :price).first(2))
p(Item.where(category: "veg").ids, Item.order(:price).pick(:name))
show_sql

puts("-- finders")
p(Item.first(2).map(&:name), Item.last.name, Item.take.name)
p(Item.find_by(name: "durian").price)
begin
  Item.find([1, 99])
rescue ActiveRecord::RecordNotFound => e
  puts("RecordNotFound: #{e.message}")
end
begin
  Item.where(category: "meat").first!
rescue ActiveRecord::RecordNotFound => e
  puts("RecordNotFound: #{e.message}")
end
p(Item.exists?, Item.exists?(3), Item.exists?(name: "fig"), Item.where(category: "veg").exists?)
p(Item.where(category: "veg").any?, Item.where(category: "meat").empty?, Item.where(category: "fruit").many?)
show_sql

puts("-- create through a relation")
fig = Item.where(category: "fruit").create_with(price: 70).find_or_create_by(name: "fig")
p([fig.name, fig.category, fig.price])
p(Item.find_or_create_by(name: "fig").id == fig.id)
p(Item.where(category: "veg").new(name: "leek").category)
show_sql

puts("-- bulk")
p(Item.where(category: "veg").update_all(hits: 7))
p(Item.where(hits: 7).count)
Item.update_counters(1, hits: 2)
p(Item.find(1).hits)
p(Item.where(name: "fig").delete_all)
p(Item.where(name: "eggplant").destroy_all.map(&:name))
p(Item.count)
show_sql

puts("-- batches, merge, none, scopes")
Item.find_each(batch_size: 2) { |i| print(i.name, " ") }
puts
Item.find_in_batches(batch_size: 3) { |batch| p(batch.map(&:id)) }
show_sql
p(names(Item.where(category: "fruit").merge(Item.where(active: true)).order(:name)))
p(names(Item.order(:name).where(category: "fruit").except(:order)))
p(Item.none.to_a, Item.none.count, Item.where(category: "fruit").none.exists?)
p(names(Item.active_ones.cheap.order(:name)))
p(names(Item.cheap.where(category: "veg")))
rel = Item.where(category: "fruit")
p([rel.loaded? == true, rel.size, rel.load.loaded?, rel.size, rel.length])
p(Item.where(price: 30).inspect)
show_sql
