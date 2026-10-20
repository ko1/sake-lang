# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class ApplicationController < ActionController::Base
  rescue_from RecordNotFound, with: :not_found
  around_action :wrap
  after_action :stamp
end
class PostsController < ApplicationController
  before_action :authenticate, except: [:index, :show]
  before_action :load_post, only: [:show, :update]
  skip_after_action :stamp, only: :destroy
end
