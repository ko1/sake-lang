# The class bodies, read by Ruby (require_relative) and by Sake's generator
# (generate "rails/activesupport/active_support/generate/active_support", "rescuable_decl.rb").

class AppController
  include ActiveSupport::Rescuable
  rescue_from NotFound, with: :not_found
  rescue_from Denied, ArgumentError, with: :denied
end

class AdminController < AppController
  rescue_from StandardError, with: :oops
  rescue_from NotFound, with: :admin_not_found
end
