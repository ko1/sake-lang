gem "activerecord", "8.1.3"
gem "actionview", "8.1.3"
gem "actionpack", "8.1.3"
require "active_record"
require "action_view"
require "action_dispatch"
require "action_controller"
require "bcrypt"
require_relative "view_records_fixtures/routes_ruby"

# Records of ActiveRecord as ActionView's records: the Rails 8.1 scaffold's templates for articles with comments
# (index, show with the comments and a nested comment form, the form with errors after a failed save, edit, new)
# rendered from rows of a sqlite3 :memory: database, and has_secure_password with authenticate_by.
# Rails' on_load(:active_record) for ActionView: the models include ActionView::ModelNaming::Record (protocols=).
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Migration.verbose = false
ActionView::Helpers::FormHelper.form_with_generates_ids = true
ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
BlogView = ActionView::Base.with_empty_template_cache
BlogView.include VIEW_RECORDS_ROUTES.url_helpers
load File.join(__dir__, "view_records_schema.rb")
require_relative "view_records_models"
ActiveModel::SecurePassword.min_cost = true

def view_for(articles, article)
  view = BlogView.with_view_paths(["view_records_views_rb"], { articles: articles, article: article })
  view.lookup_context.prefixes = ["articles"]   # an ArticlesController's _prefixes
  view
end

puts("-- a failed save: the form with errors")
article = Article.new(title: "", body: "short")
p(article.save)
p(article.errors.full_messages)
puts(view_for([], article).render(template: "articles/new"))

puts("-- saved, with comments")
article.title = "Hello Rails"
article.body = "I am on Rails & Sake!"
p(article.save)
article.comments.create(commenter: "matz", body: "<b>nice</b>")
article.comments.create(commenter: "ko1", body: "thanks")
Article.create(title: "Second", body: "Another article body")
articles = Article.all.to_a
puts(view_for(articles, nil).render(template: "articles/index"))
shown = Article.find(article.id || 0)
puts(view_for([], shown).render(template: "articles/show"))
puts(view_for([], shown).render(template: "articles/edit"))

puts("-- an update that fails: the edit form keeps the values")
shown.body = "tiny"
p(shown.save)
puts(view_for([], shown).render(template: "articles/edit"))

puts("-- has_secure_password and authenticate_by")
user = User.new(email_address: "one@example.com", password: "secret", password_confirmation: "other")
p(user.save)
p(user.errors.full_messages)
user.password_confirmation = "secret"
p(user.save)
p(user.authenticate("wrong"))
p((u = User.authenticate_by(email_address: "one@example.com", password: "secret")) ? u.email_address : nil)
p(User.authenticate_by(email_address: "one@example.com", password: "wrong"))
p(User.authenticate_by(email_address: "nobody@example.com", password: "secret"))
p(User.authenticate_by(email_address: "one@example.com", password: ""))
begin
  User.authenticate_by(email_address: "one@example.com")
rescue ArgumentError => e
  puts(e.message)
end
p(user.password_digest.start_with?("$2"), user.password == "secret")
