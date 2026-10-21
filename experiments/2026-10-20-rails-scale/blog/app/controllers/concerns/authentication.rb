# The class-body side of Authentication (authentication.sake has its methods): Rails' generator expands it
# into the class bodies that include it.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end
end
