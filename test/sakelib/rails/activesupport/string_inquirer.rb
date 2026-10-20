gem "activesupport", "8.1.3"
require "active_support"
require "active_support/core_ext/string/inquiry"
require "active_support/core_ext/array/inquiry"

# StringInquirer and ArrayInquirer (string_inquirer, array_inquirer, core_ext/string/inquiry, core_ext/array/inquiry)
env = "production".inquiry
p(env.production?, env.development?, env.staging?)
p(env == "production", env.to_s, env.respond_to?(:anything?))
puts("env: #{env}")
begin
  env.production
rescue NoMethodError => e
  puts e.message
end
variants = [:phone, "desktop"].inquiry
p(variants.phone?, variants.tablet?, variants.desktop?)
p(variants.any?(:tablet, :desktop), variants.any?, [].inquiry.any?)
