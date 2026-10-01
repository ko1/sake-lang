# Call a flaky (scripted) service with retries, exponential backoff and a per-call budget.
class TransientError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

class FatalError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

class GiveUpError < StandardError
  attr_reader :attempts, :last_code

  def initialize(message, attempts, last_code)
    super(message)
    @attempts = attempts
    @last_code = last_code
  end
end

class Service
  attr_reader :name, :script
  attr_accessor :calls

  def initialize(name, script, calls)
    @name = name
    @script = script
    @calls = calls
  end

  # The script says what each successive call does: "ok", "timeout", "busy", "denied".
  def request(payload)
    step = @script[@calls] || "ok"
    @calls += 1
    case step
    when "ok" then "#{@name}:#{payload.upcase}"
    when "timeout" then raise TransientError.new("#{@name} timed out", 504)
    when "busy" then raise TransientError.new("#{@name} is busy", 503)
    when "denied" then raise FatalError.new("#{@name} denied access", 403)
    end
  end
end

def backoff_ms(attempt, base, cap)
  [base * (2**(attempt - 1)), cap].min
end

def with_retry(max_attempts, base, cap, log)
  attempt = 0
  waited = 0
  begin
    attempt += 1
    result = yield(attempt)
    log << "  attempt #{attempt}: ok"
    [result, waited]
  rescue TransientError => e
    if attempt >= max_attempts
      log << "  attempt #{attempt}: #{e.code}, giving up"
      raise GiveUpError.new("gave up after #{attempt} attempts", attempt, e.code)
    end
    delay = backoff_ms(attempt, base, cap)
    waited += delay
    log << "  attempt #{attempt}: #{e.code} #{e.message}, waiting #{delay}ms"
    retry
  end
end

services = [
  Service.new("alpha", ["ok"], 0),
  Service.new("beta", ["timeout", "busy", "ok"], 0),
  Service.new("gamma", ["busy", "busy", "busy", "busy", "busy", "ok"], 0),
  Service.new("delta", ["timeout", "denied"], 0),
  Service.new("eps", ["busy", "timeout", "busy", "timeout", "ok"], 0)
]

stats = { "ok" => 0, "gave_up" => 0, "fatal" => 0 }
total_wait = 0
services.each do |svc|
  log = []
  puts "#{svc.name}:"
  begin
    value, waited = with_retry(4, 100, 500, log) { |n| svc.request("req#{n}") }
    total_wait += waited
    stats["ok"] += 1
    log.each { |l| puts l }
    puts "  => #{value} (waited #{waited}ms)"
  rescue GiveUpError => e
    stats["gave_up"] += 1
    log.each { |l| puts l }
    puts "  => #{e.message}; last code #{e.last_code}"
  rescue FatalError => e
    stats["fatal"] += 1
    log.each { |l| puts l }
    puts "  => fatal #{e.code}: #{e.message}"
  ensure
    puts "  calls made: #{svc.calls}"
  end
end

puts "summary: #{stats.map { |k, v| "#{k}=#{v}" }.join(" ")}"
puts "total backoff: #{total_wait}ms"
