# ActiveSupport::Subscriber and LogSubscriber: attach_to, events by method name, color, detach_from.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/log_subscriber"
require "active_support/core_ext/object/blank"
require "active_support/logger"

class SqlLogSubscriber < ActiveSupport::LogSubscriber
  def sql(event)
    info("  #{color("SQL", :blue, bold: true)} #{event.payload[:sql]}")
  end
  def cache(event) = debug("  cache #{event.payload[:key]}")
  def broken(event) = raise("boom")
end

class Counter < ActiveSupport::Subscriber
  def initialize
    super
    @count = 0
  end
  def process_action(event)
    @count += 1
    puts("  process_action #{event.payload[:action]} (#{@count})")
  end
end

N = ActiveSupport::Notifications
log = ActiveSupport::Logger.new($stdout)
log.level = :info
ActiveSupport::LogSubscriber.logger = log
sql_subscriber = SqlLogSubscriber.new
SqlLogSubscriber.attach_to(:active_record, sql_subscriber)
puts("log subscriber:")
N.instrument("sql.active_record", { sql: "SELECT 1" })
N.instrument("cache.active_record", { key: "k" })
log.level = :debug
N.instrument("cache.active_record", { key: "k2" })
ActiveSupport::LogSubscriber.colorize_logging = false
N.instrument("sql.active_record", { sql: "SELECT 2" })
p(sql_subscriber.patterns.keys)
puts("subscriber:")
counter = Counter.new
Counter.attach_to(:action_controller, counter)
N.instrument("process_action.action_controller", { action: "index" })
N.instrument("process_action.action_controller", { action: "show" })
p(counter.patterns.keys)
puts("detach_from:")
SqlLogSubscriber.detach_from(:active_record)
N.instrument("sql.active_record", { sql: "SELECT 3" })
p(sql_subscriber.patterns.keys)
puts("no logger:")
SqlLogSubscriber.attach_to(:active_record, sql_subscriber)
ActiveSupport::LogSubscriber.logger = nil
N.instrument("sql.active_record", { sql: "SELECT 4" })
p(N.notifier.listening?("sql.active_record"))
