# The blog's routes (config/routes.rb) for the actionview tests
BLOG_ROUTES = ActionDispatch::Routing::RouteSet.new
BLOG_ROUTES.draw do
  root "posts#index"
  resources :posts do
    resources :comments
  end
  get "about", to: "pages#about", as: :about
end
