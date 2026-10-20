gem "activerecord", "8.1.3"
require "active_record"

# default_scope and unscoped, named scopes chained both ways, readonly and strict loading relations,
# sanitize_sql_like, where with LIKE, distinct counts, select of a String
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "scoping_schema.rb")
require_relative "scoping_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:name] == "TRANSACTION" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

class Note
  default_scope { where(archived: false) }
  scope :ranked, -> { where("rank > ?", 0).order(rank: :desc) }
  scope :titled, ->(t) { where("title LIKE ?", "%#{sanitize_sql_like(t)}%") }
end
def titles(rel) = rel.map(&:title)

[["first 100%", false, 3], ["second", false, 0], ["old", true, 5], ["third_x", false, 1]].each do |title, archived, rank|
  Note.unscoped.create!(title: title, archived: archived, rank: rank)
end
SQL.clear

puts("-- default scope")
p(titles(Note.all), Note.count)
p(titles(Note.unscoped.order(:id)), Note.unscoped.count)
p(titles(Note.unscoped.where(archived: true)))
show_sql

puts("-- named scopes")
p(titles(Note.ranked))
p(titles(Note.where(rank: 1..).ranked))
p(titles(Note.titled("100%")), titles(Note.titled("_x")))
p(titles(Note.ranked.titled("i")))
show_sql

puts("-- readonly, distinct, select")
note = Note.readonly.first
begin
  note.update(title: "changed")
rescue ActiveRecord::ReadOnlyRecord => e
  puts("ReadOnlyRecord: #{e.message}")
end
p(Note.distinct.count(:archived), Note.unscoped.distinct.count(:archived))
p(Note.select("title, rank").order(rank: :desc).first.title)
p(Note.where(title: "nope").first, Note.where(title: "nope").pluck(:id))
p(Note.order(:rank).pluck(:rank), Note.order(:rank).last(2).map(&:rank))
show_sql
