# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class AdminController < ActionController::Base
  http_basic_authenticate_with name: "dhh", password: "secret", except: :open
end
class ReportsController < ActionController::Base
end
