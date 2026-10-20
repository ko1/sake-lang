# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class LogsController < ActionController::Base
  rescue_from Gone, with: :gone
  before_action :authenticate, only: :secret
end
