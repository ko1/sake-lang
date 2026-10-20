gem "actionpack", "8.1.3"
require "active_support/all"
require "action_controller"
require "action_controller/test_case"

# Functional tests (ActionController::TestCase): get/post/delete an action with params (path, query and body),
# format:, as: :json, xhr:, session: and flash: given to the request; the session, the flash and the cookies kept
# between the test's requests; assert_response and assert_redirected_to.
require_relative "controller_test_case_decl"
class NotesController < ActionController::Base
  def index = render plain: "notes visits=#{session[:visits].inspect} notice=#{flash[:notice].inspect} theme=#{cookies[:theme].inspect} page=#{params[:page].inspect} xhr=#{request.xhr?}"
  def show = render json: { "id" => params[:id], "format" => request.format.to_sym.to_s }
  def create
    cookies[:theme] = params[:theme] if params[:theme]
    redirect_to "/notes", notice: "Created #{params[:title]}"
  end
  def destroy = head :no_content

  private
  def count_visit
    v = session[:visits]
    session[:visits] = (v.is_a?(Integer) ? v : 0) + 1
  end
end

ROUTES = ActionDispatch::Routing::RouteSet.new
ROUTES.draw do
  resources :notes, only: [:index, :show, :create, :destroy]
end

class NotesControllerTest < ActionController::TestCase
  tests NotesController
end
tc = NotesControllerTest.new("functional")
tc.instance_variable_set(:@routes, ROUTES)
tc.setup_controller_request_and_response

def show(tc)
  r = tc.response
  puts("#{tc.request.request_method} -> #{r.status} #{r.media_type.inspect} #{r.location.inspect} #{r.body.inspect}")
end

def check(label)
  yield
  puts "#{label}: ok"
rescue Minitest::Assertion => e
  puts "#{label}: #{e.message.lines.map(&:chomp).reject { |l| l.start_with?("    ") }.join(" | ")}"   # without a backtrace
end

puts "-- get, params in the query and the path"
tc.get :index
show(tc)
tc.get :index, params: { page: 2 }
show(tc)
tc.get :show, params: { id: 5 }
show(tc)
tc.get :show, params: { id: 5 }, format: :json
show(tc)
puts "-- post with a body, the flash and the cookies on the next requests"
tc.post :create, params: { title: "First", theme: "dark" }
show(tc)
check("redirected to /notes") { tc.assert_redirected_to "/notes" }
check("redirected to /other") { tc.assert_redirected_to "/other" }
check("redirect") { tc.assert_response :redirect }
tc.get :index
show(tc)
tc.get :index
show(tc)
p(tc.session[:visits])
puts "-- session:, flash:, xhr:, as: :json"
tc.get :index, session: { visits: 10 }
show(tc)
tc.get :index, flash: { notice: "given" }
show(tc)
tc.get :index, xhr: true
show(tc)
tc.post :create, params: { title: "Json" }, as: :json
show(tc)
p(tc.request.content_type)
puts "-- delete, assert_response"
tc.delete :destroy, params: { id: 1 }
show(tc)
check("no_content") { tc.assert_response :no_content }
check("success") { tc.assert_response :success }
check("200") { tc.assert_response 200 }
