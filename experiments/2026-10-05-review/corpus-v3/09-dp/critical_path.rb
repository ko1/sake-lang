class Task
  attr_reader :id, :days, :deps

  def initialize(id, days, deps)
    @id = id
    @days = days
    @deps = deps
  end
end

class CycleError < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

def parse_plan(text)
  tasks = {}
  text.lines.each do |line|
    parts = line.strip.split(/\s+/)
    next if parts.empty?
    id = parts[0].delete_suffix(":")
    tasks[id] = Task.new(id, parts[1].to_i, parts.drop(2))
  end
  tasks
end

def visit(tasks, id, state, order, trail)
  st = state[id]
  return if st == :done
  if st == :active
    trail << id
    start = trail.index(id)
    raise CycleError.new("dependency cycle", trail.drop(start).join(" -> "))
  end
  state[id] = :active
  trail << id
  task = tasks[id]
  raise KeyError, "unknown task #{id}" if task.nil?
  task.deps.each { |d| visit(tasks, d, state, order, trail) }
  trail.pop
  state[id] = :done
  order << id
end

def topo_order(tasks)
  state = {}
  order = []
  tasks.keys.each { |id| visit(tasks, id, state, order, []) }
  order
end

# finish[id] = earliest finish; via[id] = the dependency that finishes last
def schedule(tasks)
  order = topo_order(tasks)
  finish = {}
  via = {}
  chains = {}
  order.each do |id|
    task = tasks[id]
    start = 0
    task.deps.each do |d|
      if finish[d] > start
        start = finish[d]
        via[id] = d
      end
    end
    finish[id] = start + task.days
    chains[id] = task.deps.empty? ? 1 : task.deps.sum { |d| chains[d] }
  end
  { order: order, finish: finish, via: via, chains: chains }
end

def critical_path(sched)
  sched => { finish:, via: }
  cur = finish.max_by { |_, f| f }[0]
  path = []
  while cur
    path.unshift(cur)
    cur = via[cur]
  end
  path
end

def slack(tasks, sched)
  sched => { order:, finish: }
  total = finish.values.max
  latest = order.to_h { |id| [id, total] }
  order.reverse_each do |id|
    start_by = latest[id] - tasks[id].days
    tasks[id].deps.each do |d|
      latest[d] = start_by if start_by < latest[d]
    end
  end
  order.to_h { |id| [id, latest[id] - finish[id]] }
end

plan = <<~PLAN
  design: 5
  schema: 3 design
  api: 8 schema
  ui: 10 design
  auth: 4 schema
  tests: 6 api auth
  docs: 3 api ui
  beta: 2 tests ui docs
  launch: 1 beta
PLAN

tasks = parse_plan(plan)
sched = schedule(tasks)
sched => { order:, finish:, chains: }
puts "order: #{order.join(", ")}"
puts "project takes #{finish.values.max} days"
puts "critical path: #{critical_path(sched).join(" -> ")}"
puts "dependency chains ending at launch: #{chains["launch"]}"
float = slack(tasks, sched)
puts "task     start finish slack"
order.each do |id|
  f = finish[id]
  s = f - tasks[id].days
  puts format("%-8s %5d %6d %5d%s", id, s, f, float[id], float[id] == 0 ? "  *" : "")
end

bad_plans = [
  "a: 1 c\nb: 2 a\nc: 3 b",
  "a: 1\nb: 2 a zz"
]
bad_plans.each do |text|
  begin
    schedule(parse_plan(text))
    puts "ok"
  rescue CycleError => e
    puts "#{e.message}: #{e.path}"
  rescue KeyError => e
    puts "bad plan: #{e.message}"
  end
end
