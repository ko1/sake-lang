gem "actionpack", "8.1.3"
require "action_controller"
require "tmpdir"

# ActionController's log lines (Processing by, Parameters, Completed, Redirected to, Filter chain halted,
# rescue_from handled, Sent data, Unpermitted parameters), written to a log file. Durations and the backtrace
# frame differ between runs, so they are replaced before printing.
class Gone < StandardError
end
require_relative "controller_log_subscriber_decl"
class LogsController < ActionController::Base
  def index = render plain: "page #{params[:page]}"
  def create = redirect_to "/logs"
  def secret = render plain: "secret"
  def broken = raise Gone, "it is gone"
  def download = send_data "data", filename: "logs.txt"
  def filter
    p = params.require(:log).permit(:title)
    render plain: "title=#{p[:title]}"
  end

  private
  def authenticate = head :forbidden
  def gone(e) = head :gone
end


set = ActionDispatch::Routing::RouteSet.new
set.draw do
  resources :logs, only: [:index, :create]
  ["secret", "broken", "download", "filter"].each { |a| get "logs/#{a}", to: "logs##{a}" }
end


path = File.join(Dir.tmpdir, "sake_controller_log_subscriber.log")
File.delete(path) if File.exist?(path)
log = ActiveSupport::Logger.new(path)
log.level = :debug
ActiveSupport::LogSubscriber.logger = log
ActiveSupport::LogSubscriber.colorize_logging = false
ActionController::Base.logger = log
# (ActionController::LogSubscriber.attach_to :action_controller ran when action_controller loaded)
ActionController::Parameters.action_on_unpermitted_parameters = :log

def send_request(set, method, path)
  env = Rack::MockRequest.env_for("http://www.example.com#{path}", method: method)
  status, _, _ = set.call(env)
  puts("#{method} #{path} -> #{status}")
end

send_request(set, "GET", "/logs?page=2")
send_request(set, "POST", "/logs")
send_request(set, "GET", "/logs/secret.json")
send_request(set, "GET", "/logs/broken")
send_request(set, "GET", "/logs/download")
send_request(set, "GET", "/logs/filter?log[title]=a&log[body]=b&log[tag]=c")

log.close
File.readlines(path).each do |line|
  l = line.chomp.gsub(/\d+(\.\d+)?ms/, "Nms")
  l = l.sub(/ - .*\z/, " - <frame>").sub(/request: #<[^>]*>/, "request: #<ActionDispatch::Request>")
  puts("log: #{l}") unless l.start_with?("# Logfile created")
end
File.delete(path)
