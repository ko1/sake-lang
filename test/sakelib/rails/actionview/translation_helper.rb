gem "actionview", "8.1.3"
require "action_view"

I18n.backend.store_translations(:en, {
  hello: "Hello %{name}",
  greeting_html: "<b>Hi %{name}</b>",
  list_html: ["<i>one</i>", "<i>two</i>"],
  apples: { one: "1 apple", other: "%{count} apples" },
  posts: { index: { title: "All posts", heading_html: "<h1>Posts</h1>" }, form: { submit: "Save" } },
  fallback: "Fallback text" })
I18n.backend.store_translations(:ja, { hello: "こんにちは %{name}" })
I18n.available_locales = [:en, :ja]
view = ActionView::Base.empty
V = view

puts V.t(:hello, name: "<Ann>")
puts V.t("hello", name: "Bob", locale: :ja)
puts V.t(:greeting_html, name: "<Ann>")
p V.t(:greeting_html, name: "x").html_safe?
p V.t(:list_html)
puts V.t(:apples, count: 1), V.t(:apples, count: 3)
p V.t([:hello, :fallback], name: "Z")
puts V.t(:missing)
puts V.t(:missing, name: "<x>", scope: :foo)
puts V.t(:missing, default: "Default text")
puts V.t(:missing, default: [:also_missing, :fallback])
puts V.t(:missing, default: [:also_missing, "Literal %{name}"], name: "N")
p V.t(:missing, default: nil)
puts V.t(:missing, raise: false)
begin
  V.t(:missing, raise: true)
rescue I18n::MissingTranslationData => e
  puts "raised"
end
V.instance_variable_set(:@virtual_path, "posts/index")
puts V.t(".title")
puts V.t(".heading_html")
puts V.t(".nope")
V.instance_variable_set(:@virtual_path, "posts/_form")
puts V.t(".submit")
V.t(:hello, name: "blk") { |translation, key| puts "#{key}: #{translation}" }
V.instance_variable_set(:@virtual_path, nil)
begin
  V.t(".title")
rescue RuntimeError => e
  puts e.message
end
puts V.l(Date.new(2026, 10, 20))
puts V.l(Time.utc(2026, 10, 20, 9, 5, 0), format: :short)
puts V.localize(Date.new(2026, 10, 20), format: :long)
