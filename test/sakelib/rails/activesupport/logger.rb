# ActiveSupport::Logger (SimpleFormatter, silence, log_at), TaggedLogging, BroadcastLogger.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/logger"
require "active_support/tagged_logging"
require "active_support/broadcast_logger"

log = ActiveSupport::Logger.new($stdout)
log.info("hello")
log.debug("debug shown")
log.info(123)
log.info([1, "two"])
log.info { "lazy" }
log.level = :info
log.debug("hidden")
p([log.level, log.debug?, log.info?])
log.silence do
  log.info("silenced: hidden")
  log.error("error shown in silence")
end
log.log_at(:debug) { log.debug("debug via log_at") }
p(log.local_level)
log.silencer = false
log.silence { log.info("silencer off: shown") }

puts("tagged:")
tagged = ActiveSupport::TaggedLogging.new(log)
tagged.tagged("BCX") { tagged.info("Stuff") }
tagged.tagged("BCX", "Jason") { tagged.info("Stuff") }
tagged.tagged("BCX") { tagged.tagged("Jason") { tagged.info("Stuff") } }
req = tagged.tagged("Req")
req.info("without a block")
tagged.info("the original has none")
p(tagged.push_tags("A", "", nil, "B"))
p([tagged.formatter.current_tags, tagged.formatter.tags_text])
tagged.info("pushed")
tagged.pop_tags
p(tagged.formatter.current_tags)
tagged.clear_tags!
tagged.info("cleared")
log.info("the untagged logger")

puts("broadcast:")
a = ActiveSupport::Logger.new($stdout)
a.formatter = ->(severity, time, progname, msg) { "A: #{msg}\n" }
b = ActiveSupport::Logger.new($stdout)
b.formatter = ->(severity, time, progname, msg) { "B: #{msg}\n" }
b.level = :warn
both = ActiveSupport::BroadcastLogger.new(a, b)
both.info("info to both")
both.warn("warn to both")
calls = 0
both.error { calls += 1; "lazy error" }
p([calls, both.level, both.debug?, both.progname])
both.silence { both.warn("silenced warn"); both.error("silenced error") }
both.stop_broadcasting_to(b)
both.warn("only A")
p(both.broadcasts.size)
