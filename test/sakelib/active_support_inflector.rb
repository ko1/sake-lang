require "active_support/all"

# The same program as active_support_inflector.sake, with ActiveSupport itself.
I = ActiveSupport::Inflector
%w[person people sheep octopus octopi CamelOctopus words quiz ox oxen mouse matrix vertex index axis test bus buffalo tomato datum medium analysis wife half knife hive query box church wish miss virus status alias news series movie shoe crisis thesis child children man men woman sex move zombie equipment Information fish money CamelSheep database databases ley rice jeans police cactus].each { |w| puts "#{w}: #{I.pluralize(w)} / #{I.singularize(w)}" }
p I.pluralize(""), I.singularize("ss"), I.pluralize("s"), I.singularize("s")
p I.camelize("active_model/errors"), I.camelize("active_model", false), I.camelize("Active_MODEL"), I.camelize("ab1_c"), I.camelize("a/b"), I.camelize("")
p I.underscore("ActiveModel::Errors"), I.underscore("SSLError"), I.underscore("HTML5Parser"), I.underscore("already_under"), I.underscore("Foo-Bar"), I.underscore("ABC"), I.underscore("aB"), I.underscore("Html5")
p I.humanize("employee_salary"), I.humanize("author_id"), I.humanize("author_id", capitalize: false), I.humanize("_id"), I.humanize("author_id", keep_id_suffix: true), I.humanize("  _leading"), I.humanize("ABC_def"), I.humanize("x__y")
p I.titleize("man from the boondocks"), I.titleize("x-men: the last stand"), I.titleize("TheManWithoutAPast"), I.titleize("raiders_of_the_lost_ark"), I.titleize("string_ending_with_id", keep_id_suffix: true), I.titleize("o'neil isn't here (ok)"), I.titleize("string_ending_with_id")
p I.tableize("RawScaledScorer"), I.tableize("ham_and_egg"), I.tableize("fancyCategory"), I.classify("ham_and_eggs"), I.classify("posts"), I.classify("calculus"), I.classify("schema.posts")
p I.demodulize("ActiveSupport::Inflector::Inflections"), I.demodulize("::Inflections"), I.demodulize(""), I.deconstantize("Net::HTTP"), I.deconstantize("::Net::HTTP"), I.deconstantize("String"), I.deconstantize("::String"), I.deconstantize("")
p I.foreign_key("Message"), I.foreign_key("Message", false), I.foreign_key("Admin::Post")
p [1,2,3,4,11,12,13,21,22,23,101,111,1002,1003,-11,-1021,0,1.5,113,100].map { |n| I.ordinalize(n) }
p I.parameterize("Donald E. Knuth"), I.parameterize("^très|Jolie-- "), I.parameterize("Donald E. Knuth", separator: "_"), I.parameterize("^très|Jolie__ ", separator: "_"), I.parameterize("Donald E. Knuth", preserve_case: true), I.parameterize("^très|Jolie__ "), I.parameterize("^très_Jolie-- ", separator: "."), I.parameterize("a  b", separator: "--"), I.parameterize("a b", separator: ""), I.parameterize("--x--")
p I.transliterate("Ærøskøbing"), I.transliterate("Jürgen"), I.transliterate("日本"), I.transliterate("日本", "*"), I.transliterate("abc"), I.transliterate("ẞ")
p I.upcase_first("what a Lovely Day"), I.downcase_first("If"), I.upcase_first("")
p I.dasherize("puni_puni")
puts "== acronym"
ActiveSupport::Inflector.inflections { |i| i.acronym "HTML"; i.acronym "RESTful" }
p I.camelize("html"), I.camelize("my_html_parser"), I.underscore("MyHTMLParser"), I.titleize("RESTfulController"), I.humanize("html_error"), I.camelize("restful_controller"), I.underscore("RESTfulController"), I.underscore("HTMLS")
