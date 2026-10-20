gem "actionview", "8.1.3"
require "action_view"
# Rails 8.1 defaults (load_defaults): no utf8 input; ActionView::Base.empty has no forgery protection
ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
view = ActionView::Base.empty


# form_tag
puts view.form_tag("/posts")
puts view.form_tag("/posts", method: :get, class: "search")
puts view.form_tag("/posts/1", method: :delete)
puts view.form_tag("/upload", multipart: true, enforce_utf8: true)
puts view.form_tag("/posts", id: "f") { view.text_field_tag("q") }
# fields
puts view.text_field_tag("name")
puts view.text_field_tag("query", "Enter your search query here")
puts view.text_field_tag("search", nil, placeholder: "Enter search term...", size: 20, disabled: true)
puts view.text_field_tag("post[title]", "<b>")
puts view.hidden_field_tag("token", "VUBJKB23UIVI1UU1VOBVI@")
puts view.hidden_field_tag("token", "x", autocomplete: "on")
puts view.password_field_tag("pass")
puts view.password_field_tag("secret", "Your secret here", class: "form_input")
puts view.file_field_tag("attachment")
puts view.label_tag("name")
puts view.label_tag("name", "Your name")
puts view.label_tag("name", nil, class: "small_label")
puts view.label_tag("post[title]", "Title", for: "custom")
puts view.label_tag("name", class: "x") { "block label" }
puts view.textarea_tag("post")
puts view.textarea_tag("bio", "<p>me</p>")
puts view.textarea_tag("body", nil, rows: 10, cols: 25)
puts view.textarea_tag("body", "x", size: "25x10", escape: false)
puts view.text_area_tag("comment", "Hi", class: "c")
puts view.checkbox_tag("accept")
puts view.checkbox_tag("rock", "rock music")
puts view.checkbox_tag("receive_email", "yes", true)
puts view.check_box_tag("tos", "yes", false, class: "accept_tos")
puts view.radio_button_tag("favorite_color", "maroon")
puts view.radio_button_tag("receive_updates", "no", true)
puts view.radio_button_tag("color", "dark blue", false, disabled: true)
puts view.submit_tag
puts view.submit_tag("Edit this article")
puts view.submit_tag("Save edits", disabled: true)
puts view.submit_tag("Complete sale", data: { disable_with: "Submitting..." })
puts view.submit_tag("Save", data: { disable_with: false })
puts view.submit_tag(nil, class: "form_submit")
puts view.button_tag
puts view.button_tag("Reset", type: "reset")
puts view.button_tag("Button", type: "button", disabled: true)
puts view.button_tag(type: "button") { "<strong>Ask me!</strong>" }
puts view.image_submit_tag("/images/login.png", class: "x")
puts view.field_set_tag
puts view.field_set_tag("Your details") { "<p>inside</p>" }
puts view.field_set_tag(nil, class: "format") { "x" }
puts view.select_tag("people", "<option>David</option>".html_safe)
puts view.select_tag("count", "<option>1</option>".html_safe, include_blank: true)
puts view.select_tag("count", "<option>1</option>".html_safe, include_blank: "Pick")
puts view.select_tag("count", "<option>1</option>".html_safe, prompt: "Select something")
puts view.select_tag("colors", "<option>Red</option>".html_safe, multiple: true, class: "c")
puts view.color_field_tag("color", "#DEF726")
puts view.search_field_tag("search", "q")
puts view.telephone_field_tag("tel")
puts view.phone_field_tag("phone", "0123")
puts view.date_field_tag("d", "2026-10-20")
puts view.time_field_tag("t")
puts view.datetime_field_tag("dt")
puts view.datetime_local_field_tag("dtl")
puts view.month_field_tag("m")
puts view.week_field_tag("w")
puts view.url_field_tag("u", "http://example.com")
puts view.email_field_tag("e", "a@b.c")
puts view.number_field_tag("quantity", nil, in: 1...10)
puts view.number_field_tag("quantity", "5", min: 1, max: 9, step: 2)
puts view.range_field_tag("volume", nil, within: 0..11)
puts view.utf8_enforcer_tag
# field_id / field_name
puts view.field_id(:post, :title)
puts view.field_id("post[author]", :name, :error, index: 1)
puts view.field_id(:post, :published?, namespace: "admin")
puts view.field_name(:post, :title)
puts view.field_name(:post, :tag_ids, multiple: true)
puts view.field_name(:post, :title, :subtitle, index: 3)
puts view.field_name("", :q)
