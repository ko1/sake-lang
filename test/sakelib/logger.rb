require "logger"

# The Sake port's default format is Ruby's without the pid (Sake has no Process.pid).
class Logger::Formatter
  def call(severity, time, progname, msg)
    sprintf("%.1s, [%s] %5s -- %s: %s\n", severity, format_datetime(time), severity, progname, msg2str(msg))
  end
end

def fixed = Time.new(2026, 10, 3, 12, 34, 56)
def Time.now = Time.new(2026, 10, 3, 12, 34, 56)   # the Sake test fixes the time with set_fixed_time

log = Logger.new($stdout)
p(log.level)
log.debug("debug message")
log.info("info message")
log.warn("warn message")
log.error("error message")
log.fatal("fatal message")
log.unknown("unknown message")
log.info([1, "two", :three])
log.info(nil)
log.info("ユニコード ✓")
log.info("")

log.progname = "myapp"
log.info("with progname")
log.add(Logger::WARN, "via add", "other")
log.add(Logger::ERROR, nil, "message in progname slot")
log.add(nil, "nil severity", nil)
log.log(9, "severity 9", nil)

log.level = Logger::WARN
p(log.level)
log.info("hidden")
log.warn("shown")
p([log.debug?, log.info?, log.warn?, log.error?, log.fatal?])
log.level = :error
p(log.level)
log.level = "INFO"
p(log.level)
log.level = "fatal"
p(log.level)
begin
  log.level = :verbose
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
log.debug!
p(log.level)
log.error!
p(log.error?)
# A logger of its own: Ruby's logger 1.7.0 keeps the with_level level after the block when the old level was set
wl = Logger.new($stdout)
wl.error!
wl.with_level(:debug) do
  wl.debug("inside with_level")
end
p(wl.level)
wl.debug("after with_level: hidden")
log.info!

log.datetime_format = "%H:%M:%S"
log.info("short datetime")
log.datetime_format = nil

log.formatter = proc { |sev, time, prog, msg| format("%<severity>s [%<progname>s] %<msg>s\n", severity: sev, progname: prog, msg: msg) }
log.info("custom format")
log.formatter = proc { |sev, time, prog, msg| format("%-5<severity>s %<datetime>s: %<msg>s\n", severity: sev, datetime: time.strftime("%Y/%m/%d"), msg: msg) }
log.error("custom with time")
log.formatter = nil

p(log << "raw text\n")

# optional arguments: no message, add/log without message or progname
log.info
log.add(Logger::WARN)
log.add(Logger::INFO, "add with a message")
log.log(Logger::ERROR, "log with a message")
log.unknown

# stderr as the device (not compared: the test reads stdout)
elog = Logger.new($stderr)
elog.info("to stderr")

quiet = Logger.new(nil)
p(quiet.info("nothing"))

path = "/tmp/sakelib-logger-test.log"
File.write(path, "")
flog = Logger.new(path)
flog.progname = "file"
flog.info("first line")
flog.warn("second line")
flog.debug("third line")
flog.close
$stderr.reopen(File::NULL)    # Ruby warns "log writing failed. closed stream"; the Sake port is silent
flog.info("after close")
lines = File.readlines(path)
p(lines.size)
first = lines.fetch(0)
p(first[0, 21])
lines.drop(1).each { |l| print(l) }
File.write(path, "")
