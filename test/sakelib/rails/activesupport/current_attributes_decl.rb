# The class body, read by Ruby (require_relative) and by Sake's generator
# (generate "rails/activesupport/active_support/generate/active_support", "current_attributes_decl.rb").

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account
  attribute :request_id, default: "none"
  before_reset :log_reset
  resets :clear_cache
end
