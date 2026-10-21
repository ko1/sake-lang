# (Sake only) The class body of Rails::HealthController (health_controller.sake), for ActionController's generator
class Rails::HealthController < ActionController::Base
  rescue_from Exception, with: :render_down
end
