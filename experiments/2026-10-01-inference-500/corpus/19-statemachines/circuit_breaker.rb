class ServiceError < StandardError
  attr_reader :status

  def initialize(message, status)
    super(message)
    @status = status
  end
end

class CircuitOpen < StandardError
  attr_reader :retry_at

  def initialize(message, retry_at)
    super(message)
    @retry_at = retry_at
  end
end

class Service
  attr_reader :outcomes, :calls

  def initialize(outcomes)
    @outcomes = outcomes
    @calls = 0
  end

  def request(now, req)
    @calls += 1
    status = @outcomes.fetch(now, 200)
    raise ServiceError.new("#{req} failed with #{status}", status) if status >= 500
    "#{req}:ok"
  end
end

class Breaker
  attr_reader :state, :failures, :threshold, :cooldown, :opened_at, :trial_ok, :log

  def initialize(threshold, cooldown)
    @state = :closed
    @failures = 0
    @threshold = threshold
    @cooldown = cooldown
    @opened_at = 0
    @trial_ok = 0
    @log = []
  end

  def move(now, to)
    @log << "t=#{now} #{@state} -> #{to}"
    @state = to
  end

  def guard(now)
    return if @state != :open
    if now - @opened_at >= @cooldown
      move(now, :half_open)
      @trial_ok = 0
    else
      raise CircuitOpen.new("circuit open", @opened_at + @cooldown)
    end
  end

  def success(now)
    case @state
    in :half_open
      @trial_ok += 1
      if @trial_ok >= 2
        @failures = 0
        move(now, :closed)
      end
    in :closed then @failures = 0
    in :open then nil
    end
  end

  def failure(now)
    case @state
    in :half_open
      @opened_at = now
      move(now, :open)
    in :closed
      @failures += 1
      if @failures >= @threshold
        @opened_at = now
        move(now, :open)
      end
    in :open then nil
    end
  end

  def run(svc, now, req)
    guard(now)
    begin
      result = svc.request(now, req)
    rescue ServiceError
      failure(now)
      raise
    end
    success(now)
    result
  end
end

def call_with_retry(b, svc, now, req, stats)
  attempts = 0
  begin
    attempts += 1
    b.run(svc, now + attempts - 1, req)
  rescue ServiceError => e
    if attempts < 2 && e.status == 503
      stats[:retried] += 1
      retry
    end
    stats[:failed] += 1
    "#{req}:error #{e.status}"
  rescue CircuitOpen => e
    stats[:rejected] += 1
    "#{req}:rejected until t=#{e.retry_at}"
  end
end

outcomes = { 3 => 500, 4 => 503, 5 => 503, 6 => 500, 7 => 502, 14 => 500, 22 => 503, 30 => 500, 31 => 500, 32 => 500 }
svc = Service.new(outcomes)
b = Breaker.new(3, 6)
stats = { ok: 0, failed: 0, rejected: 0, retried: 0 }
t = 0
while t < 40
  res = call_with_retry(b, svc, t, "req#{t}", stats)
  stats[:ok] += 1 if res.end_with?(":ok")
  puts format("t=%02d %-10s %s", t, b.state, res) unless res.end_with?(":ok") && t % 5 != 0
  t += 2
end
puts "transitions:"
b.log.each { puts "  #{it}" }
puts "service calls: #{svc.calls}"
puts stats.to_a.map { |k, v| "#{k}=#{v}" }.join(" ")
