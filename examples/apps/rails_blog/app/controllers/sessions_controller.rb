class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
end
