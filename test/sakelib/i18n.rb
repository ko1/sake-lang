require "i18n"
require "i18n/backend/fallbacks"
require "date"
require "tmpdir"

def en_data
  { foo: { bar: "Bar", baz: "Baz" },
    hi: "Hi %{name}",
    both: "%{a} and %{b}",
    apples: { zero: "none", one: "%{count} apple", other: "%{count} apples" },
    cats: { one: "a cat" },
    list: ["a", "b"],
    answer: 42,
    date: { formats: { default: "%Y-%m-%d", short: "%b %d", long: "%B %d, %Y" },
            day_names: %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday],
            abbr_day_names: %w[Sun Mon Tue Wed Thu Fri Sat],
            month_names: [nil] + %w[January February March April May June July August September October November December],
            abbr_month_names: [nil] + %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec] },
    time: { formats: { default: "%a, %d %b %Y %H:%M:%S %z", short: "%d %b %H:%M", long: "%B %d, %Y %H:%M" }, am: "am", pm: "pm" } }
end

def ja_data = { foo: { bar: "バー" }, apples: { one: "りんご%{count}個", other: "りんご%{count}個" },
                date: { formats: { default: "%Y年%m月%d日" } } }

def t0 = Time.new(2024, 7, 1, 13, 5, 9, "+09:00")

puts "-- store and look up"
I18n.backend.store_translations(:en, en_data)
I18n.backend.store_translations(:ja, ja_data)
I18n.backend.store_translations(:en, { "str" => { "k" => "v" }, foo: { qux: "Qux" } })
p I18n.t("foo.bar")
p I18n.t(:"foo.bar")
p I18n.t(:bar, scope: :foo)
p I18n.t("bar", scope: "foo")
p I18n.t(:bar, scope: [:foo])
p I18n.t("str.k")
p I18n.t("foo")
p I18n.t("list")
p I18n.t("answer")
p I18n.t("nope")
p I18n.t("foo.nope.x")
p I18n.t("foo.bar.baz")
p I18n.t(nil)
p I18n.t("foo..bar")
p I18n.t(".foo.bar.")
p I18n.t("foo|bar", separator: "|")
p I18n.t([:"foo.bar", :hi], name: "z")
p I18n.exists?("foo.bar")
p I18n.exists?("zz")
p I18n.exists?("foo.bar", :ja)
p I18n.exists?("hi", :ja)
begin
  I18n.t("")
rescue I18n::ArgumentError => e
  puts "argument error"
end
begin
  I18n.t!("zz")
rescue I18n::MissingTranslationData => e
  puts e.message
end
p I18n.t!("foo.bar")

puts "-- interpolation"
p I18n.t(:hi, name: "Bob")
p I18n.t(:hi)
p I18n.t(:hi, name: nil)
p I18n.t(:hi, name: 3)
p I18n.t(:hi, name: "%{name}")
p I18n.t(:both, a: 1, b: :two)
begin
  I18n.t(:hi, other: 1)
rescue I18n::MissingInterpolationArgument => e
  puts e.message
end
p I18n.t("foo.bar", count: 2)

puts "-- pluralization"
p I18n.t(:apples, count: 0)
p I18n.t(:apples, count: 1)
p I18n.t(:apples, count: 2)
p I18n.t(:apples, count: 1.0)
p I18n.t(:apples, count: 0.0)
p I18n.t(:apples)
p I18n.t(:apples, count: nil)
p I18n.t(:cats, count: 1)
begin
  I18n.t(:cats, count: 3)
rescue I18n::InvalidPluralizationData => e
  puts e.message
end

puts "-- defaults"
p I18n.t("zz", default: "dflt")
p I18n.t("zz", default: :"foo.bar")
p I18n.t("zz", default: [:"a.b", :"foo.bar"])
p I18n.t("zz", default: [:"a.b", "last"])
p I18n.t("foo", default: "x")
p I18n.t(:apples, count: 3, default: "d")
p I18n.t("zz", default: "%{name}!", name: "N")
p I18n.t(:zz, default: :apples, count: 1)
p I18n.t(:zz, default: "a %{count}", count: 5)
p I18n.t(:"foo.bar", default: nil)
p I18n.t(:zz, default: 42)
p I18n.t(:zz, default: :bar, scope: :foo)

puts "-- locales"
p I18n.available_locales
p I18n.locale
p I18n.default_locale
p I18n.t("foo.bar", locale: :ja)
p I18n.t("hi", locale: :ja, name: "x")
p I18n.t("apples", locale: :ja, count: 3)
I18n.with_locale(:ja) do
  p I18n.locale
  p I18n.t("foo.bar")
end
p I18n.locale
I18n.locale = :ja
p I18n.locale
p I18n.t("foo.bar")
I18n.locale = :en
begin
  I18n.locale = :fr
rescue I18n::InvalidLocale => e
  puts e.message
end
begin
  I18n.t("foo.bar", locale: :fr)
rescue I18n::InvalidLocale => e
  puts e.message
end
p I18n.enforce_available_locales
I18n.enforce_available_locales = false
p I18n.t("foo.bar", locale: :fr)
I18n.enforce_available_locales = true

puts "-- fallbacks"
p [:ja]
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
I18n.fallbacks = [:en]
p I18n.fallbacks[:ja]
p I18n.fallbacks[I18n.locale]
p I18n.t("hi", locale: :ja, name: "x")
p I18n.t("zz", locale: :ja)
p I18n.t("foo.bar", locale: :ja)
p I18n.t("foo", locale: :ja)
p I18n.t("apples", locale: :ja, count: 1)
p I18n.exists?("hi", :ja)
I18n.locale = :ja
p I18n.t("hi", name: "y")
I18n.locale = :en

puts "-- localize"
p I18n.l(t0)
p I18n.l(t0, format: :short)
p I18n.l(t0, format: :long)
p I18n.l(t0, format: "%H:%M %p %P %-d %^a %^B")
p I18n.l(Date.new(2024, 7, 1))
p I18n.l(Date.new(2024, 7, 1), format: :long)
p I18n.l(Date.new(2024, 7, 1), format: :short)
p I18n.l(Date.new(2024, 7, 1), locale: :ja)
p I18n.l(t0, format: "%Y/%m/%d", locale: :ja)
begin
  I18n.l(t0, format: :nope)
rescue I18n::MissingTranslationData => e
  puts e.message
end
begin
  I18n.l(t0, locale: :ja)
rescue I18n::MissingTranslationData => e
  puts e.message
end
begin
  I18n.l(nil)
rescue I18n::ArgumentError => e
  puts e.message
end

puts "-- yaml"
Dir.mktmpdir do |d|
  path = File.join(d, "de.yml")
  File.write(path, "de:\n  foo:\n    bar: Riegel\n  hi: Hallo %{name}\n  apples:\n    one: ein Apfel\n    other: \"%{count} Äpfel\"\n  n: 7\nfr:\n  foo:\n    bar: Barre\n")
  I18n.backend.load_translations(path)
  I18n.config.clear_available_locales_set      # the gem caches the set that enforce_available_locales checks
  p I18n.available_locales
  p I18n.t("foo.bar", locale: :de)
  p I18n.t("hi", locale: :de, name: "Welt")
  p I18n.t("apples", locale: :de, count: 2)
  p I18n.t("n", locale: :de)
  p I18n.t("foo.bar", locale: :fr)
  p I18n.t("foo.baz", locale: :fr)
end

puts "-- transliterate"
p I18n.transliterate("Ærøskøbing")
p I18n.transliterate("日本")
p I18n.transliterate("Ærøskøbing 日本", replacement: "*")
p I18n.transliterate("Český Straße")
