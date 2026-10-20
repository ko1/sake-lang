gem "activerecord", "8.1.3"
require "active_record"

# The model layer on a :memory: database: attributes from the schema, create/find/update/destroy, dirty
# tracking, validations, callbacks, and the SQL each step runs
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
load File.join(__dir__, "base_schema.rb")
require_relative "base_models"
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] unless payload[:name] == "SCHEMA" }
def show_sql
  SQL.each { |sql| puts("  sql: #{sql}") }
  SQL.clear
end

class Post
  def normalize_title
    self.title = title.strip
  end

  def body_is_not_shouting
    errors.add(:body, "is shouting") if body && body == body.upcase
  end

  def log_create
    puts("  created #{id}")
  end
end

puts("-- attributes")
p(Post.table_name, Post.primary_key, Post.column_names)
post = Post.new(title: " Hello ")
p([post.title, post.views, post.published, post.new_record?, post.persisted?, post.id])
p([post.changed?, post.changed, post.title_changed?, post.title_was])
post.views = "12"
p([post.views, post.views_before_type_cast, post.views_changed?])
show_sql

puts("-- create")
p(post.save)
p([post.id, post.title, post.new_record?, post.persisted?, post.changed?, post.previous_changes.keys])
show_sql
second = Post.create(title: "Second post", body: "plain words", views: 3, published: true)
p([second.id, second.title, second.published])
show_sql

puts("-- find")
found = Post.find(1)
p([found.id, found.title, found.views, found.published, found.created_at.class.name])
show_sql
p(Post.find_by(title: "Second post")&.id)
p(Post.find_by(title: "nope"))
show_sql
begin
  Post.find(99)
rescue ActiveRecord::RecordNotFound => e
  puts("RecordNotFound: #{e.message}")
end
show_sql
p(Post.where(published: true).map(&:title))
p(Post.where("views > ?", 5).order(title: :desc).map(&:id))
p(Post.order(:title).first.title, Post.count, Post.pluck(:title))
p(Post.exists?(title: "Hello"), Post.where(published: false).count)
show_sql

puts("-- update")
found.title = "Hello again"
p([found.changes, found.save, found.saved_changes.keys])
show_sql
p(found.update(views: 20))
p(found.update(title: ""))
p(found.errors.full_messages)
show_sql
found.reload
p([found.title, found.views])
show_sql

puts("-- validations")
bad = Post.new(title: "x", body: "LOUD")
p([bad.valid?, bad.errors.full_messages, bad.errors[:title]])
p(bad.save)
begin
  bad.save!
rescue ActiveRecord::RecordInvalid => e
  puts("RecordInvalid: #{e.message}")
end
begin
  Post.create!(title: nil)
rescue ActiveRecord::RecordInvalid => e
  puts("RecordInvalid: #{e.message}")
end
show_sql

puts("-- destroy")
p(second.destroy.destroyed?)
p([Post.count, Post.exists?(second.id)])
p(Post.where(id: [1, 2]).pluck(:id))
show_sql
p(Post.new(title: "abc").inspect)

puts("-- ActiveModel")
n = Post.model_name
p([n.name, n.human, n.route_key, n.param_key, Post.i18n_scope])
p([Post.human_attribute_name("created_at"), Post.human_attribute_name(:title)])
p(Post.validators_on(:title).map(&:kind))
p(Post.validators.map { |v| [v.kind, v.options] })
kept = Post.first
p([kept.to_key, kept.to_param, kept.to_model.equal?(kept), kept.to_partial_path, Post.new.to_param])
long = Post.new(title: "")
long.valid?
p(long.errors.details)
p(long.errors.to_hash(true))
p(long.errors.messages)
I18n.backend.store_translations(:en, activerecord: { attributes: { post: { title: "Headline" } }, errors: { models: { post: { attributes: { title: { blank: "is missing" } } } } } })
long.valid?
p(long.errors.full_messages)
p(kept.serializable_hash(only: [:id, :title]))
p(kept.as_json(except: [:created_at, :updated_at]))
puts(kept.to_json(only: [:id, :views], methods: [:title]))
copy = Post.new.from_json('{"title":"From JSON","views":3}')
p([copy.title, copy.views, copy.changed])
show_sql

puts("-- an ActiveModel form in the same program")
require_relative "base_form"
form = PostForm.new(title: "A title that is long", post_id: kept.id)
p([form.valid?, form.errors.full_messages, PostForm.model_name.i18n_key, PostForm.i18n_scope, form.persisted?])
form.title = kept.title
p([form.valid?, Post.find(form.post_id).title == form.title])
show_sql
