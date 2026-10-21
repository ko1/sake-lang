class ArticlesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_article, only: %i[ show edit update destroy ]
end
