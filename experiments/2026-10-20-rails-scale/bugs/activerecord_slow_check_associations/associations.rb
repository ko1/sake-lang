gem "activerecord", "8.1.3"
require "active_record"

# Associations on a :memory: database: belongs_to, has_one, has_many (with the collection proxy), has_many
# :through, has_and_belongs_to_many, includes/preload, joins, dependent, counter_cache, autosave of new
# records, nested attributes, inverse_of, and the SQL each step runs
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "associations_schema.rb")
require_relative "associations_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:name] == "TRANSACTION" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

puts("-- belongs_to and has_many")
ann = Author.create(name: "Ann")
post = Post.create(title: "Hello", author: ann)
p([post.author_id, post.author.name])
show_sql
c1 = post.comments.create(body: "first")
c2 = post.comments.build(body: "second")
p([c1.post_id, c2.post_id, c2.new_record?])
p(c2.save)
show_sql
post.reload
p([post.comments_count, post.comments.map(&:body), post.comments.count])
p(post.comment_ids)
show_sql
p(post.comments.where(approved: false).pluck(:body))
show_sql
c = Comment.find(c1.id)
p([c.post.title, c.post.equal?(c.post)])
show_sql

puts("-- has_one")
profile = ann.create_profile(bio: "writes")
p([profile.author_id, ann.profile.bio])
ann2 = Author.find(ann.id)
p(ann2.profile.bio)
p(Profile.first.author.name)
show_sql

puts("-- through and habtm")
ruby = Tag.create(name: "ruby")
sake = Tag.create(name: "sake")
Tagging.create(post: post, tag: ruby)
Tagging.create(post: post, tag: sake)
p(post.tags.map(&:name))
p(ruby.posts.map(&:title))
show_sql
news = Category.create(name: "news")
post.categories << news
p(post.categories.map(&:name))
p(news.posts.map(&:title))
show_sql

puts("-- includes and joins")
second = Post.create(title: "Second", author: ann)
second.comments.create(body: "third")
posts = Post.includes(:comments).order(:id).to_a
show_sql
p(posts.map { |x| [x.title, x.comments.map(&:body)] })
show_sql
p(Post.preload(:author).map { |x| x.author&.name })
show_sql
p(Post.joins(:comments).where(comments: { body: "third" }).pluck(:title))
p(Post.left_joins(:comments).where(comments: { id: nil }).pluck(:title))
p(Post.joins(:tags).where(tags: { name: "sake" }).count)
p(Post.where(author: ann).count)
show_sql

puts("-- inverse_of")
author = Author.includes(:posts).find(ann.id)
p(author.posts.map { |x| x.author.equal?(author) })
show_sql

puts("-- nested attributes")
bob = Author.create(name: "Bob", posts_attributes: [{ title: "Bob's first" }, { title: "Bob's second" }])
p(bob.posts.map(&:title))
show_sql
first_id = bob.posts.first.id
last_id = bob.posts.last.id
bob.update(posts_attributes: [{ id: first_id, title: "Bob's renamed" }, { id: last_id, _destroy: true }])
p(bob.reload.posts.map(&:title))
show_sql

puts("-- dependent")
p(ruby.destroy != false)
p(ruby.errors.full_messages)
show_sql
post.destroy
p([Comment.count, Tagging.count, Post.exists?(post.id)])
show_sql
ann.destroy
p([Profile.count, Post.where(author_id: nil).count])
show_sql

puts("-- validation")
orphan = Comment.new(body: "x")
p([orphan.valid?, orphan.errors.full_messages])
