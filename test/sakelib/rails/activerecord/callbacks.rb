gem "activerecord", "8.1.3"
require "active_record"

# Model callbacks in Rails' order (initialize/find, validation, save/create/update/destroy, around, commit and
# rollback), halting with throw :abort, conditions, uniqueness with a scope, on: :update validations
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "callbacks_schema.rb")
require_relative "callbacks_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

class Post
  def trace_initialize = puts("  after_initialize")
  def trace_find = puts("  after_find")
  def trace_before_validation = puts("  before_validation")
  def trace_after_validation = puts("  after_validation")
  def trace_before_save = puts("  before_save")

  def trace_around_save
    puts("  around_save {")
    yield
    puts("  } around_save")
  end

  def trace_after_save = puts("  after_save")
  def trace_after_save_again = puts("  after_save again")

  def make_slug
    puts("  before_create")
    self.slug = title.downcase.tr(" ", "-")
  end

  def trace_around_create
    puts("  around_create {")
    yield
    puts("  } around_create")
  end

  def trace_after_create = puts("  after_create")
  def trace_before_update = puts("  before_update")
  def trace_after_update = puts("  after_update")

  def check_locked
    puts("  before_destroy")
    throw :abort if locked
  end

  def trace_after_destroy = puts("  after_destroy")
  def trace_commit = puts("  after_commit")
  def trace_create_commit = puts("  after_create_commit")
  def trace_update_commit = puts("  after_update_commit")
  def trace_destroy_commit = puts("  after_destroy_commit")
  def trace_rollback = puts("  after_rollback")
end

class Account
  def frozen_balance? = balance > 100

  def check_frozen
    puts("  balance is frozen")
    throw :abort
  end
end

puts("-- new")
post = Post.new(title: "Hello World")
puts("-- create")
p(post.save)
p(post.slug)
show_sql
puts("-- update")
post.title = "Hello again"
p(post.save)
show_sql
puts("-- update with a condition (unless: :locked?)")
p(post.update(locked: true))
show_sql
puts("-- find")
found = Post.find(post.id)
puts("-- invalid")
p(Post.new(title: "").save)
show_sql
puts("-- destroy halted by throw :abort")
p(found.destroy)
p([found.destroyed?, Post.count])
show_sql
puts("-- destroy")
found.update_column(:locked, false)
p(found.destroy.destroyed?)
p(Post.count)
show_sql
puts("-- rollback")
Post.transaction do
  Post.create(title: "Doomed")
  raise ActiveRecord::Rollback
end
p(Post.count)
show_sql

puts("-- uniqueness with a scope")
a = Account.create(email: "a@example.com", org_id: 1)
p(a.persisted?)
b = Account.new(email: "a@example.com", org_id: 1)
p([b.valid?, b.errors.full_messages])
c = Account.new(email: "a@example.com", org_id: 2)
p(c.valid?)
show_sql
puts("-- on: :update")
d = Account.new(email: "d@example.com", balance: -5)
p(d.save)
d.balance = -10
p([d.save, d.errors.full_messages])
show_sql
puts("-- if: condition halting before_save")
a.balance = 500
p(a.save)
p(a.reload.balance)
show_sql
