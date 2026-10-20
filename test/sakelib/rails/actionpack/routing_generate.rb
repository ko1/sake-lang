gem "actionpack", "8.1.3"
require "action_dispatch"
require "action_controller"

# --- the shop's routes (Sake: fixtures/shop_routes.sake) ---
set = ActionDispatch::Routing::RouteSet.new
set.draw do
  root "products#index"
  resources :products do
    resources :reviews, only: [:index, :show]
    get :search, on: :collection
  end
  resource :cart, only: [:show, :update]
  namespace :admin do
    resources :orders, param: :number
  end
  get "pages/:slug", to: "pages#show", as: :page, slug: /[a-z-]+/
  get "files/*path", to: "files#show", as: :file
  get "(:locale)/about", to: "pages#about", as: :about
  direct(:homepage) { "https://rubyonrails.org" }
  direct(:product_search, sort: "name") { |query, options| { controller: "products", action: "search", q: query }.merge(options) }
end
# recognize_path checks that the controller class exists
controller = Class.new { def self.action_encoding_template(_action) = false }
%w[ProductsController ReviewsController CartsController PagesController FilesController].each { |c| Object.const_set(c, controller) }
Admin = Module.new
Admin.const_set(:OrdersController, controller)

# A record: its to_param is the URL parameter (Sake: a type that includes Routing::ToParam)
class Product
  attr_reader :id
  def initialize(id) = @id = id
  def to_param = "#{id}-widget"
end

# --- named route helpers (Rails defines them with define_method; Sake generates them) ---
class Ctx
  def initialize(routes) = @routes = routes
  def _routes = @routes
  def url_options = { host: "shop.test", protocol: "https" }
end
helpers = set.url_helpers
Ctx.include(helpers)
ctx = Ctx.new(set)
p [helpers.root_path, helpers.products_path, helpers.product_path(1), helpers.product_path(Product.new(7))]
p [helpers.product_reviews_path(3), helpers.product_review_path(3, 4), helpers.search_products_path(q: "red shoes")]
p [helpers.cart_path, helpers.admin_orders_path, helpers.admin_order_path("A-100"), helpers.edit_admin_order_path(number: 5)]
p [helpers.page_path("terms-of-use"), helpers.file_path("docs/a b.pdf"), helpers.about_path, helpers.about_path("ja")]
p [helpers.product_path(1, format: :json), helpers.products_path(page: 2, sort: "name"), helpers.product_path(id: 9, anchor: "top")]
p [helpers.product_url(1, host: "example.com"), helpers.products_url(host: "example.com", port: 8080, protocol: "https")]
p [ctx.product_url(5), ctx.product_path(5), ctx.root_url, ctx.product_review_url(Product.new(2), 8, only_path: true)]
p ctx.route_for(:product, 6)
p [helpers.homepage_url, helpers.homepage_path, ctx.product_search_path("shoes"), ctx.product_search_url("hat", sort: "price")]
begin
  helpers.product_path
rescue ActionController::UrlGenerationError => e
  p e.message
end
begin
  helpers.page_path("Not Valid")
rescue ActionController::UrlGenerationError => e
  p e.message
end

# --- url_for and path_for with controller/action options ---
p set.path_for(controller: "products", action: "show", id: 3)
p set.path_for(controller: "products", action: "index", page: 2)
p set.path_for(controller: "admin/orders", action: "edit", number: "B7")
p set.url_for(controller: "pages", action: "about", locale: "en", host: "example.org")
p set.path_for(controller: "products", action: "show", id: 3, _recall: { controller: "products", action: "index" })
p set.extra_keys(controller: "products", action: "index", page: 2, sort: "x")
begin
  set.path_for(controller: "nothing", action: "here")
rescue ActionController::UrlGenerationError => e
  p e.message
end

# --- recognize_path ---
p set.recognize_path("/products/12")
p set.recognize_path("/products/12", method: :patch)
p set.recognize_path("/products/12/reviews/3.json")
p set.recognize_path("/admin/orders/A-100/edit")
p set.recognize_path("/files/docs/a%20b.pdf")
p set.recognize_path("/ja/about")
p set.recognize_path("/products/")
begin
  set.recognize_path("/products/12", method: :post)
rescue ActionController::RoutingError => e
  p e.message
end
begin
  set.recognize_path("/pages/Bad_Slug")
rescue ActionController::RoutingError => e
  p e.message
end
