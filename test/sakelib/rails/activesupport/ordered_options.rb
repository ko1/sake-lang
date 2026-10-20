gem "activesupport", "8.1.3"
require "active_support"
require "active_support/ordered_options"

# ActiveSupport::OrderedOptions and InheritableOptions (ordered_options)
config = ActiveSupport::OrderedOptions.new
config.log_level = :debug
config[:time_zone] = "UTC"
config.retries = 3
p(config.log_level, config["time_zone"], config.retries, config.api_key)
p(config.log_level!, config.key?(:log_level), config.keys)
begin
  config.api_key!
rescue KeyError => e
  puts e.message
end
config[:db] = { primary: { host: "localhost" } }
p(config.dig(:db, :primary, :host), config.dig(:nothing, :x))
p(config)
child = ActiveSupport::InheritableOptions.new(config)
child[:time_zone] = "Tokyo"
p(child.time_zone, child.log_level, child.key?(:retries))
p(child.overridden?(:time_zone), child.overridden?(:log_level), child.to_h.keys)
grand = child.inheritable_copy
p(grand.time_zone, grand == child)
from_hash = ActiveSupport::InheritableOptions.new({ a: 1 })
p(from_hash[:a], from_hash.to_h)
