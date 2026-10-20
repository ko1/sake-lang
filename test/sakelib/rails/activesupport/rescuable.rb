# ActiveSupport::Rescuable: rescue_from, rescue_with_handler (the last declaration wins; a cause is tried).
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/rescuable"

class NotFound < StandardError
end
class Denied < StandardError
end
class Unknown < StandardError
end
require_relative "rescuable_decl"

class AppController
  def not_found(e) = puts("  not_found: #{e.message}")
  def denied(e) = puts("  denied: #{e.class}: #{e.message}")
  def run(kind)
    case kind
    when :not_found then raise NotFound, "no post 7"
    when :denied then raise Denied, "admins only"
    when :argument then raise ArgumentError, "bad id"
    when :unknown then raise Unknown, "?"
    when :cause
      begin
        raise NotFound, "inner"
      rescue NotFound
        raise Unknown, "outer"
      end
    end
  end
  def process(kind)
    run(kind)
    :ok
  rescue => e
    handled = rescue_with_handler(e) || raise
    "handled #{handled.message}"
  end
end

class AdminController
  def oops(e) = puts("  oops: #{e.message}")
  def admin_not_found(e) = puts("  admin_not_found: #{e.message}")
end

[:none, :not_found, :denied, :argument, :cause].each do |kind|
  puts("app #{kind}:")
  p(AppController.new.process(kind))
end
puts("app unknown:")
begin
  AppController.new.process(:unknown)
rescue Unknown => e
  puts("  re-raised Unknown: #{e.message}")
end
[:not_found, :denied, :unknown].each do |kind|
  puts("admin #{kind}:")
  p(AdminController.new.process(kind))
end
p(AppController.rescue_handlers.map { |name, handler| [name, handler] })
p(AdminController.rescue_handlers.map { |name, handler| [name, handler] })
