Rails.application.routes.draw do
  resource :session
  resources :articles do
    resources :comments, only: [ :create, :destroy ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
