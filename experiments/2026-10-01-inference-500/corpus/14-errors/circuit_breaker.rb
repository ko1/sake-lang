# A circuit breaker guarding a remote dependency, driven by a simulated clock and outcome list.
class CircuitOpenError < StandardError
  attr_reader :retry_at

  def initialize(message, retry_at)
    super(message)
    @retry_at = retry_at
  end
end

class RemoteError < StandardError
  attr_reader :status

  def initialize(message, status)
    super(message)
    @status = status
  end
end

class Breaker
  attr_reader :threshold, :cooldown
  attr_accessor :state, :failures, :opened_at, :transitions

  def initialize(threshold, cooldown, state, failures, opened_at, transitions)
    @threshold = threshold
    @cooldown = cooldown
    @state = state
    @failures = failures
    @opened_at = opened_at
    @transitions = transitions
  end

  def guard(now)
    if @state == :open
      raise CircuitOpenError.new("circuit open", @opened_at + @cooldown) if now - @opened_at < @cooldown
      move(:half_open, now)
    end
    begin
      result = yield
    rescue RemoteError
      record_failure(now)
      raise
    end
    record_success(now)
    result
  end

  def record_failure(now)
    @failures += 1
    return unless @state == :half_open || @failures >= @threshold
    move(:open, now)
    @opened_at = now
  end

  def record_success(now)
    @failures = 0
    move(:closed, now) if @state != :closed
  end

  def move(to, now)
    @transitions << "t=#{now} #{@state} -> #{to}"
    @state = to
  end
end

def remote_call(outcome, request)
  return "200 #{request}" if outcome == 200
  raise RemoteError.new("upstream returned #{outcome}", outcome)
end

# [time, outcome the remote would give at that time]
schedule = [
  [0, 200], [1, 500], [2, 503], [3, 500], [4, 200], [6, 200],
  [9, 500], [10, 500], [11, 200], [12, 200], [16, 200], [17, 502],
  [18, 502], [19, 502], [25, 200], [26, 200]
]

breaker = Breaker.new(3, 5, :closed, 0, 0, [])
counts = Hash.new(0)
schedule.each do |t, outcome|
  line = format("t=%2d", t)
  begin
    body = breaker.guard(t) { remote_call(outcome, "req@#{t}") }
    counts[:ok] += 1
    puts "#{line} ok      #{body}"
  rescue CircuitOpenError => e
    counts[:rejected] += 1
    puts "#{line} reject  #{e.message} until t=#{e.retry_at}"
  rescue RemoteError => e
    counts[:failed] += 1
    puts "#{line} fail    #{e.status} (failures=#{breaker.failures}, #{breaker.state})"
  end
end

puts "transitions:"
breaker.transitions.each { |tr| puts "  #{tr}" }
puts "ok=#{counts[:ok]} failed=#{counts[:failed]} rejected=#{counts[:rejected]}"
puts "final state: #{breaker.state}"
