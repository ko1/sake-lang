# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class FormsController < ActionController::Base
  protect_from_forgery with: :exception
end
class OpenController < FormsController
  skip_forgery_protection only: :create
end
class NullController < ActionController::Base
  protect_from_forgery
end
class ResetController < ActionController::Base
  protect_from_forgery with: :reset_session, except: :login
end
