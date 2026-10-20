# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class ApiController < ActionController::API
  rescue_from Forbidden, with: :forbidden
  before_action :count
end
class ItemsController < ApiController
  before_action :find_item, only: [:show, :update]
  after_action :tag, if: :tagged?
  skip_before_action :count, only: :ping
end
