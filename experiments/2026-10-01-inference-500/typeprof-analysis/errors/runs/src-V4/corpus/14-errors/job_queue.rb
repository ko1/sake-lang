# A background job runner: failed jobs are requeued with a delay until max attempts, then dead-lettered.
class TemporaryFailure < StandardError
  attr_reader :retry_after

  def initialize(message, retry_after)
    super(message)
    @retry_after = retry_after
  end
end

class PermanentFailure < StandardError
  attr_reader :reason

  def initialize(message, reason)
    super(message)
    @reason = reason
  end
end

class Job
  attr_reader :id, :kind, :payload
  attr_accessor :attempts, :run_at, :errors

  def initialize(id, kind, payload, attempts, run_at, errors)
    @id = id
    @kind = kind
    @payload = payload
    @attempts = attempts
    @run_at = run_at
    @errors = errors
  end

  def describe = "#{@id}(#{@kind})"
end

class JobQueue
  attr_reader :pending, :dead, :done
  attr_accessor :clock

  def initialize(pending, dead, done, clock)
    @pending = pending
    @dead = dead
    @done = done
    @clock = clock
  end

  def enqueue(job) = @pending << job

  def next_due
    due = @pending.select { |j| j.run_at <= @clock }
    return nil if due.empty?
    job = due.min_by { |j| [j.run_at, j.id] }
    @pending.delete(job)
    job
  end
end

# Handlers succeed or fail depending on the payload and the attempt number.
def perform(job)
  payload = job.payload
  attempt = job.attempts
  case job.kind
  when :email
    raise PermanentFailure.new("bad address", "invalid") unless payload.include?("@")
    raise TemporaryFailure.new("smtp busy", 3) if attempt < 2
    "sent to #{payload}"
  when :resize
    size = Integer(payload) rescue raise(PermanentFailure.new("not a size: #{payload}", "parse"))
    raise TemporaryFailure.new("no worker free", 1) if size > 1000 && attempt < 3
    "resized to #{size / 2}"
  when :report
    raise TemporaryFailure.new("db unavailable", 5)
  end
end

MAX_ATTEMPTS = 4

def run(q)
  ticks = 0
  while !q.pending.empty? && ticks < 50
    job = q.next_due
    if !job    
      q.clock += 1
      ticks += 1
      next
    end
    job.attempts += 1
    now = q.clock
    begin
      result = perform(job)
      q.done << job
      puts "t=#{now} #{job.describe} ok: #{result}"
    rescue TemporaryFailure => e
      job.errors << e.message
      if job.attempts >= MAX_ATTEMPTS
        q.dead << job
        puts "t=#{now} #{job.describe} dead after #{job.attempts} attempts"
      else
        job.run_at = now + e.retry_after
        q.enqueue(job)
        puts "t=#{now} #{job.describe} retry at t=#{job.run_at}: #{e.message}"
      end
    rescue PermanentFailure => e
      job.errors << "#{e.reason}: #{e.message}"
      q.dead << job
      puts "t=#{now} #{job.describe} failed permanently: #{e.message}"
    end
  end
end

q = JobQueue.new([], [], [], 0)
specs = [[:email, "ann@example.com"], [:resize, "640"], [:resize, "4096"], [:email, "nobody"],
         [:report, "weekly"], [:resize, "huge"], [:email, "bob@example.com"]]
specs.each_with_index do |(kind, payload), i|
  q.enqueue(Job.new("j#{i + 1}", kind, payload, 0, i / 3, []))
end
run(q)

puts "done: #{q.done.map(&:id).join(" ")}"
puts "dead letters:"
q.dead.each do |j|
  puts "  #{j.describe} attempts=#{j.attempts} last=#{j.errors.last}"
end
attempts = (q.done + q.dead).sum(&:attempts)
puts "total attempts #{attempts}, finished at t=#{q.clock}"
