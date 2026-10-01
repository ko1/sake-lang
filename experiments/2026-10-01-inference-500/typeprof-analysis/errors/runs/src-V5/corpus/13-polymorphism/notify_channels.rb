class DeliveryFailed < StandardError
  attr_reader :channel, :retryable
  def initialize(message, channel, retryable)
    super(message)
    @channel = channel
    @retryable = retryable
  end
end

class Message
  attr_accessor :to, :subject, :body, :urgent
  def initialize(to, subject, body, urgent)
    @to = to
    @subject = subject
    @body = body
    @urgent = urgent
  end
end

module Channel
  def name = "channel"
  def cost_cents(msg) = 0
  def available?(hour) = true
  def deliver(msg, attempt) = raise("deliver not implemented")

  def describe = "#{name} (#{cost_cents(Message.new("x", "", "", false))}c base)"
end

class Email
  include Channel
  attr_reader :domain_blocklist
  def initialize(domain_blocklist)
    @domain_blocklist = domain_blocklist
  end
  def name = "email"
  def deliver(msg, attempt)
    domain = msg.to.split("@").last
    if @domain_blocklist.include?(domain)
      raise DeliveryFailed.new("#{domain} rejects mail", "email", false)
    end
    "mail to #{msg.to}: #{msg.subject}"
  end
end

class Sms
  include Channel
  attr_reader :per_segment
  def initialize(per_segment)
    @per_segment = per_segment
  end
  def name = "sms"
  def segments(msg) = (msg.body.size + 1).ceildiv(160)
  def cost_cents(msg) = segments(msg) * @per_segment
  def available?(hour) = hour >= 8 && hour < 21
  def deliver(msg, attempt)
    raise DeliveryFailed.new("sms gateway timeout", "sms", true) if attempt == 1 && msg.body.size > 150
    "sms (#{segments(msg)} seg) to #{msg.to}"
  end
end

class Push
  include Channel
  attr_reader :devices
  def initialize(devices)
    @devices = devices
  end
  def name = "push"
  def cost_cents(msg) = 1
  def deliver(msg, attempt)
    token = @devices[msg.to]
    raise DeliveryFailed.new("no device for #{msg.to}", "push", false) if !token    
    "push to device #{token}: #{truncate(msg.subject, 12)}"
  end
end

class Webhook
  include Channel
  attr_reader :url, :failures
  def initialize(url, failures)
    @url = url
    @failures = failures
  end
  def name = "webhook"
  def cost_cents(msg) = 2
  def deliver(msg, attempt)
    if attempt <= @failures
      raise DeliveryFailed.new("#{@url} returned 503", "webhook", true)
    end
    "POST #{@url} (attempt #{attempt})"
  end
end

def truncate(s, n) = s.size > n ? s[0...n - 1] + "~" : s

def send_with_retry(ch, msg, max_attempts, log)
  attempt = 1
  begin
    result = ch.deliver(msg, attempt)
    log << "  ok   #{result}"
    true
  rescue DeliveryFailed => e
    log << "  fail #{e.channel} attempt #{attempt}: #{e.message}"
    if e.retryable && attempt < max_attempts
      attempt += 1
      retry
    end
    false
  end
end

def route(channels, msg, hour, log)
  candidates = channels.select { |ch| ch.available?(hour) }
  candidates = candidates.sort_by { |ch| ch.cost_cents(msg) } unless msg.urgent
  candidates.each do |ch|
    return ch if send_with_retry(ch, msg, 3, log)
  end
  nil
end

push = Push.new({ "ann@example.com" => "dev-a1", "cy@corp.test" => "dev-c9" })
channels = [
  Webhook.new("https://hooks.example.com/notify", 3),
  Sms.new(4),
  push,
  Email.new(["blocked.org"])
]

puts "channels:"
channels.each { |ch| puts "  #{ch.describe}" }

long_text = "Your weekly report is ready. " * 6
messages = [
  [Message.new("ann@example.com", "Build finished", "All 412 tests passed.", false), 10],
  [Message.new("bob@blocked.org", "Invoice overdue", "Please pay invoice #77 by Friday.", false), 23],
  [Message.new("cy@corp.test", "Server down", "db-2 is not responding since 03:12", true), 3],
  [Message.new("dee@blocked.org", "Weekly report", long_text, false), 12],
  [Message.new("eve@blocked.org", "Password reset", "Use code 491-022.", true), 20]
]

spent = Hash.new(0)
messages.each do |msg, hour|
  log = []
  used = route(channels, msg, hour, log)
  puts format("[%02d:00] %s -> %s", hour, msg.subject, msg.to)
  log.each { |line| puts line }
  if used
    c = used.cost_cents(msg)
    spent[used.name] += c
    puts "  delivered via #{used.name} for #{c}c"
  else
    puts "  UNDELIVERED"
  end
end

puts "cost by channel:"
spent.each { |name, c| puts format("  %-8s %3dc", name, c) }
puts "total: #{spent.sum { |name, c| c }}c"
sms = channels.find { |ch| ch.is_a?(Sms) }
if sms
  puts "sms for long text: #{sms.cost_cents(Message.new("x", "s", long_text, false))}c"
end
