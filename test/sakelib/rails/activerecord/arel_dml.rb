gem "activerecord", "8.1.3"
require "active_record"

# INSERT, UPDATE and DELETE statements from Arel's managers, as SQL for SQLite
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
users = Arel::Table.new(:users)
posts = Arel::Table.new(:posts)

puts("-- insert")
im = Arel::InsertManager.new
im.insert([[users[:name], "ann"], [users[:age], 31], [users[:admin], false], [users[:note], nil]])
puts(im.to_sql)
im = Arel::InsertManager.new(users)
im.columns << users[:name]
im.columns << users[:age]
im.values = im.create_values_list([["ann", 31], ["bob", Arel.sql("DEFAULT")]])
puts(im.to_sql)
im = Arel::InsertManager.new(users)
im.columns << users[:name]
im.select(posts.project(posts[:title]).where(posts[:id].lt(3)))
puts(im.to_sql)
im = Arel::InsertManager.new(users)
im.insert("DEFAULT VALUES")
puts(im.to_sql)

puts("-- update")
um = Arel::UpdateManager.new(users)
um.set([[users[:name], "x"], [users[:age], users[:age] + 1]]).where(users[:id].eq(1))
puts(um.to_sql)
um = Arel::UpdateManager.new(users)
um.set(Arel.sql("age = age + 1")).where(users[:age].lt(10)).order(users[:id].asc).take(3)
puts(um.to_sql)
um = Arel::UpdateManager.new(users)
um.set([[users[:flag], true]]).where(users[:age].gt(1)).take(2)
um.key = users[:id]
puts(um.to_sql)
sm = users.project(Arel.star).where(users[:age].gt(20)).order(users[:id].desc).take(5)
um = sm.compile_update([[users[:flag], false]], users[:id])
puts(um.to_sql)
joined = users.join(posts).on(posts[:user_id].eq(users[:id])).where(posts[:title].eq("x"))
um = joined.compile_update([[users[:flag], true]], users[:id])
puts(um.to_sql)

puts("-- delete")
dm = Arel::DeleteManager.new(users)
dm.where(users[:id].eq(3))
puts(dm.to_sql)
dm = Arel::DeleteManager.new(users)
dm.where(users[:age].lt(18)).order(users[:age].desc).take(10)
dm.key = users[:id]
puts(dm.to_sql)
dm = users.project(Arel.star).where(users[:name].matches("a%")).compile_delete
puts(dm.to_sql)
dm = joined.compile_delete(users[:id])
puts(dm.to_sql)
