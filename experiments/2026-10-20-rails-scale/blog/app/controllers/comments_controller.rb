class CommentsController < ApplicationController
  allow_unauthenticated_access only: :create
end
