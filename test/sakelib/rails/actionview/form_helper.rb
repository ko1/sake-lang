gem "actionview", "8.1.3"
gem "actionpack", "8.1.3"
gem "activemodel", "8.1.3"
require "action_view"
require "action_dispatch"
require "action_controller"
require "active_model"
# Rails 8.1 defaults (load_defaults)
ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
ActionView::Helpers::FormHelper.form_with_generates_ids = true
ActionView::Helpers::FormHelper.multiple_file_field_include_hidden = true
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false

class Post
  include ActiveModel::Model
  attr_accessor :id, :title, :body, :published, :category, :kind, :tag_ids, :color, :starts_on
  def persisted? = !id.nil?
  validates :title, presence: true
end
class Tag
  include ActiveModel::Model
  attr_accessor :id, :name
  def persisted? = true
end

routes = ActionDispatch::Routing::RouteSet.new
routes.draw do
  resources :posts
end

view = Class.new(ActionView::Base.with_empty_template_cache) { include routes.url_helpers }.empty
post = Post.new(id: 1, title: "Hello <world>", body: "Body text", published: true, category: "rails", kind: "b", tag_ids: [1, 3], color: "#AABBCC", starts_on: Time.new(2026, 10, 20, 0, 0, 0, "UTC"))
new_post = Post.new(id: nil, title: "", body: nil, published: false, category: nil, kind: nil, tag_ids: [], color: nil, starts_on: nil)
tags = [Tag.new(id: 1, name: "ruby"), Tag.new(id: 2, name: "sake"), Tag.new(id: 3, name: "rails")]

# form_with
puts view.form_with(model: new_post) { |f| f.text_field(:title) }
puts view.form_with(model: post) { |f| f.text_field(:title) }
puts view.form_with(model: post, url: "/custom", method: :put, class: "edit", data: { turbo: false }) { |f| f.submit }
puts view.form_with(scope: :search, url: "/search", method: :get) { |f| f.search_field(:q) }
puts view.form_with(url: "/x", local: false) { |f| "" }
puts view.form_with(model: post, format: :json) { |f| "" }
puts view.form_with(model: post, html: { id: "the-form", multipart: true }) { |f| "" }
puts view.form_with(model: post) { |f| f.file_field(:body) }
puts view.form_with(model: post, skip_enforcing_utf8: false) { |f| "" }
# form_for
puts view.form_for(post) { |f| f.text_field(:title) }
puts view.form_for(new_post) { |f| f.text_field(:title) }
puts view.form_for(post, url: "/p", as: :article, namespace: "admin") { |f| f.text_field(:title) }
puts view.form_for(:search, url: "/s") { |f| f.text_field(:q) }
# FormBuilder fields
view.form_with(model: post) do |f|
  puts f.label(:title)
  puts f.label(:title, "The title", class: "big")
  puts f.label(:title, class: "x")
  puts f.label(:title) { |b| "custom #{b.translation}" }
  puts f.text_field(:title, class: "wide", maxlength: 30)
  puts f.text_field(:title, placeholder: true)
  puts f.text_field(:title, placeholder: "Your title")
  puts f.text_field(:title, value: "override", id: "my-id")
  puts f.password_field(:title)
  puts f.hidden_field(:id)
  puts f.textarea(:body, size: "20x5")
  puts f.text_area(:body, rows: 3)
  puts f.checkbox(:published)
  puts f.checkbox(:published, { class: "c" }, "yes", "no")
  puts f.check_box(:published, { include_hidden: false })
  puts f.checkbox(:tag_ids, { multiple: true }, "3", nil)
  puts f.radio_button(:kind, "a")
  puts f.radio_button(:kind, "b", class: "r")
  puts f.color_field(:color)
  puts f.search_field(:title)
  puts f.telephone_field(:title)
  puts f.phone_field(:title)
  puts f.date_field(:starts_on)
  puts f.date_field(:starts_on, min: "2026-01-01")
  puts f.month_field(:starts_on)
  puts f.week_field(:starts_on)
  puts f.url_field(:title)
  puts f.email_field(:title)
  puts f.number_field(:id, in: 1..10, step: 1)
  puts f.range_field(:id, within: 0..5)
  puts f.submit
  puts f.submit("Go", class: "btn")
  puts f.button
  puts f.button("Click", type: "button")
  puts f.button(:draft)
  puts f.button { |label| "<b>#{label}</b>" }
  puts f.select(:category, ["ruby", "rails", "sake"])
  puts f.select(:category, [["Ruby", "ruby"], ["Rails", "rails"]], include_blank: true)
  puts f.select(:category, ["ruby", "rails"], { prompt: "Pick one" }, class: "sel")
  puts f.select(:tag_ids, [["ruby", 1], ["sake", 2], ["rails", 3]], {}, multiple: true)
  puts f.collection_select(:category, tags, :name, :name)
  puts f.collection_select(:category, tags, :id, :name, { include_blank: "None" }, class: "c")
  puts f.collection_checkboxes(:tag_ids, tags, :id, :name)
  puts f.collection_radio_buttons(:category, tags, :name, :name)
  puts f.field_id(:title)
  puts f.field_name(:title)
  puts f.field_name(:tag_ids, multiple: true)
  puts f.fields_for(:author) { |a| a.text_field(:name) }
  puts f.fields(:meta) { |m| m.text_field(:key) }
end
# errors (field_error_proc)
new_post.valid?
puts view.form_with(model: new_post) { |f| f.label(:title) + f.text_field(:title) }
# fields_for / fields at the top
puts view.fields_for(:person, post) { |f| f.text_field(:title) }
puts view.fields(:comment) { |f| f.text_field(:body) }
puts view.fields(model: post) { |f| f.text_field(:title) }
# the view's helpers with an object
puts view.text_field(:post, :title, object: post)
puts view.text_field("post[]", :title, object: post)
puts view.label(:post, :title, "Name", for: "x")
puts view.hidden_field(:post, :id, object: post)
puts view.radio_button(:post, :kind, "b", object: post)
puts view.datetime_field(:post, :starts_on, object: post)
puts view.time_field(:post, :starts_on, object: post)
puts view.textarea(:post, :body, object: post, placeholder: true)
