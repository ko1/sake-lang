# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class NotesController < ActionController::Base
  before_action :count_visit, except: [:destroy]
end
