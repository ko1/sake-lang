# The routes of view_records (config/routes.rb)
VIEW_RECORDS_ROUTES = ActionDispatch::Routing::RouteSet.new
VIEW_RECORDS_ROUTES.draw do
  resources :articles do
    resources :comments, only: [ :create, :destroy ]
  end
end
