gem "activerecord", "8.1.3"
require "active_record"

# Transactions: the value of the block, nesting (joined and requires_new), ActiveRecord::Rollback, an exception
# rolling back and propagating, save! inside a transaction, the records' state and callbacks after each
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "transactions_schema.rb")
require_relative "transactions_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

class Account
  def trace_commit = puts("  committed #{name}")
  def trace_rollback = puts("  rolled back #{name}")
end

def transfer(from, to, amount)
  Account.transaction do
    from.update!(balance: from.balance - amount)
    to.update!(balance: to.balance + amount)
  end
end

puts("-- the block's value")
p(Account.transaction { 42 })
alice = Account.create(name: "alice", balance: 100)
bob = Account.create(name: "bob", balance: 10)
show_sql
puts("-- a transfer")
transfer(alice, bob, 30)
p([alice.reload.balance, bob.reload.balance])
show_sql
puts("-- a failed transfer (RecordInvalid propagates)")
begin
  transfer(alice, bob, 500)
rescue ActiveRecord::RecordInvalid => e
  puts("RecordInvalid: #{e.message}")
end
p([alice.reload.balance, bob.reload.balance])
show_sql
puts("-- a joined inner transaction")
Account.transaction do
  alice.update(balance: 1)
  Account.transaction do
    bob.update(balance: 2)
  end
end
p(Account.pluck(:balance))
show_sql
puts("-- destroy rolled back")
Account.transaction do
  bob.destroy
  raise ActiveRecord::Rollback
end
p([bob.destroyed?, Account.count])
show_sql
