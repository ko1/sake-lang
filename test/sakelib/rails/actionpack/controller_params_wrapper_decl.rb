# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class ApplicationController < ActionController::Base
  wrap_parameters format: [:json]
end
class PostsController < ApplicationController
end
class PeopleController < ApplicationController
  wrap_parameters :person, include: [:name, :age]
end
class CommentsController < ApplicationController
  wrap_parameters exclude: [:secret]
end
class NotesController < ApplicationController
  wrap_parameters false
end
class Api::UsersController < ActionController::API
  wrap_parameters format: [:json, :url_encoded_form]
end
