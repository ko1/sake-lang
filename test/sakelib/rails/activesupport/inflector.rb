gem "activesupport", "8.1.3"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/string/inflections"

# ActiveSupport::Inflector and String's inflections (core_ext/string/inflections), as Rails apps call them.
["post", "person", "status", "octopus", "sheep", "category", "mouse", "datum", "analysis", "news"].each do |w|
  puts "#{w} #{w.pluralize} #{w.pluralize.singularize} #{w.pluralize(1)}"
end
p("active_record/base".camelize, "user_session".camelize(:lower), "ActiveRecord::Base".underscore)
p("BlogPost".tableize, "blog_posts".classify, "Admin::User".foreign_key, "author_id".humanize)
p("x-men: the last stand".titleize, "puni_puni".dasherize, "Admin::User".demodulize, "Admin::User".deconstantize)
p("Ærøskøbing is nice!".parameterize, "Hello World".parameterize(separator: "_"), "hello".upcase_first)
p(ActiveSupport::Inflector.ordinalize(1), ActiveSupport::Inflector.ordinalize(12), ActiveSupport::Inflector.ordinalize(-23), ActiveSupport::Inflector.ordinal(102))
p(ActiveSupport::Inflector.transliterate("Jürgen Müller"), ActiveSupport::Inflector.transliterate("日本", "*"))
begin
  "x".camelize(:middle)
rescue ArgumentError => e
  puts e.message
end

# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(/^(ox)$/i, '\1en')
  inflect.irregular("octopus", "octopodes")
  inflect.uncountable("equipment", "feedback")
  inflect.acronym("API")
  inflect.acronym("HTML")
  inflect.human(/_cnt$/i, '\1_count')
end
p("ox".pluralize, "octopus".pluralize, "octopodes".singularize, "feedback".pluralize)
p("api_controller".camelize, "APIController".underscore, "html_api/v1".camelize, "HTMLParser".underscore)
p("html_api".titleize, "comments_cnt".humanize, "APIKey".tableize)
ins = ActiveSupport::Inflector.inflections
p(ins.plurals.size > 20, ins.acronyms.keys)
ins.clear(:acronyms)
p("api_controller".camelize)
