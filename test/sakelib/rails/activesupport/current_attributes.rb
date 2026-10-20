# ActiveSupport::CurrentAttributes: attributes with defaults, set { }, reset with its callbacks.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/current_attributes"
require_relative "current_attributes_decl"

class Current
  def log_reset = puts("  before reset: #{user.inspect}")
  def clear_cache = puts("  after reset: #{user.inspect}")
end

p(Current.attributes)
Current.user = "ko1"
Current.account = "ruby"
p([Current.user, Current.account, Current.request_id])
p(Current.attributes.sort_by { |k, _| k })   # sorted: Sake's order is the fields', Ruby's the assignments'
Current.set(user: "matz", request_id: "r-1") do
  p([Current.user, Current.request_id])
end
p([Current.user, Current.request_id])
Current.reset
p([Current.user, Current.account, Current.request_id])
p(Current.instance.equal?(Current.instance))
