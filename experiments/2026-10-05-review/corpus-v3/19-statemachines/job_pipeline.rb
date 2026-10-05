class Job
  attr_accessor :name, :deps, :duration, :fail_times, :max_retries, :state, :attempts, :started, :finished

  def initialize(name, deps, duration, fail_times, max_retries)
    @name = name
    @deps = deps
    @duration = duration
    @fail_times = fail_times
    @max_retries = max_retries
    @state = :pending
    @attempts = 0
    @started = nil
    @finished = nil
  end
end

class CycleError < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

def topo_check(jobs)
  marks = {}
  order = []
  jobs.keys.each { |name| dfs(jobs, name, marks, order, []) }
  order
end

def dfs(jobs, name, marks, order, path)
  case marks[name]
  in :done then return
  in :visiting then raise CycleError.new("cycle detected", (path + [name]).join(" -> "))
  in nil then nil
  end
  marks[name] = :visiting
  path << name
  jobs[name].deps.each { |d| dfs(jobs, d, marks, order, path) }
  path.pop
  marks[name] = :done
  order << name
end

def run_pipeline(jobs, slots)
  clock = 0
  running = []
  log = []
  loop do
    jobs.each do |name, job|
      next if job.state != :pending
      dep_states = job.deps.map { |d| jobs[d].state }
      if dep_states.any? { it == :failed || it == :skipped }
        job.state = :skipped
        log << "t=#{clock} #{name} skipped"
      elsif dep_states.all? { it == :succeeded }
        job.state = :ready
      end
    end
    ready = jobs.values.select { it.state == :ready }
    ready.sort_by(&:name).each do |job|
      next if running.size >= slots
      job.state = :running
      job.attempts += 1
      job.started = clock
      running << job
      log << "t=#{clock} #{job.name} start (attempt #{job.attempts})"
    end
    break if running.empty?
    clock += 1
    running.dup.each do |job|
      next if clock - job.started < job.duration
      running.delete(job)
      if job.attempts <= job.fail_times
        if job.attempts <= job.max_retries
          job.state = :ready
          log << "t=#{clock} #{job.name} failed, will retry"
        else
          job.state = :failed
          log << "t=#{clock} #{job.name} FAILED"
        end
      else
        job.state = :succeeded
        job.finished = clock
        log << "t=#{clock} #{job.name} done"
      end
    end
  end
  [log, clock]
end

def build(specs)
  jobs = {}
  specs.each do |name, deps, dur, fails, retries|
    jobs[name] = Job.new(name, deps, dur, fails, retries)
  end
  jobs
end

pipelines = [
  ["release", 2, [
    ["fetch", [], 2, 0, 0], ["compile", ["fetch"], 3, 1, 2], ["lint", ["fetch"], 1, 0, 0],
    ["test", ["compile"], 4, 0, 0], ["docs", ["fetch"], 2, 0, 0],
    ["package", ["test", "lint", "docs"], 1, 0, 0], ["publish", ["package"], 1, 0, 0]
  ]],
  ["flaky", 3, [
    ["setup", [], 1, 0, 0], ["unit", ["setup"], 2, 0, 0], ["e2e", ["setup"], 3, 3, 1],
    ["report", ["unit", "e2e"], 1, 0, 0], ["notify", ["unit"], 1, 0, 0]
  ]],
  ["cyclic", 1, [
    ["a", ["c"], 1, 0, 0], ["b", ["a"], 1, 0, 0], ["c", ["b"], 1, 0, 0]
  ]]
]

pipelines.each do |title, slots, specs|
  puts "== #{title} (#{slots} slots)"
  jobs = build(specs)
  begin
    order = topo_check(jobs)
    puts "order: #{order.join(" ")}"
    log, finished = run_pipeline(jobs, slots)
    log.each { puts "  #{it}" }
    summary = jobs.values.map(&:state).tally
    puts "finished at t=#{finished}: #{summary.map { |k, v| "#{k}=#{v}" }.join(" ")}"
  rescue CycleError => e
    puts "#{e.message}: #{e.path}"
  end
end
