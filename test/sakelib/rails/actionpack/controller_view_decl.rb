# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class ApplicationController < ActionController::Base
  helper_method :current_user, :greeting
end
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
end
class PagesController < ApplicationController
  layout "admin", except: [:home, :plain_with_layout]
end
class AdminPagesController < PagesController
  layout :choose_layout
end
class BareController < ApplicationController
  layout false
end
