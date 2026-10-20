# The controllers' class bodies: Ruby requires this file; Sake's generator reads it.
class NotesController < ActionController::Base
  after_action :count_visit
end
