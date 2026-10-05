class Task
  attr_reader :id, :title, :days, :deps
  attr_accessor :early, :late

  def initialize(id, title, days, deps, early, late)
    @id = id
    @title = title
    @days = days
    @deps = deps
    @early = early
    @late = late
  end

  def slack = late - early
  def finish = early + days
  def critical? = slack == 0
end

class CycleFound < StandardError
  attr_reader :at

  def initialize(message, at)
    super(message)
    @at = at
  end
end

def load_tasks(rows)
  tasks = {}
  rows.each do |row|
    m = row.match(/^(\w+)\s+(\d+)d\s+"([^"]+)"(?:\s+after\s+(.*))?$/)
    next unless m
    deps = m[4] ? m[4].split(",") : []
    tasks[m[1]] = Task.new(m[1], m[3], m[2].to_i, deps.map(&:strip), 0, 0)
  end
  tasks
end

def topo_order(tasks)
  state = {}
  order = []
  tasks.each_key { |id| visit(tasks, id, state, order) }
  order
end

def visit(tasks, id, state, order)
  return if state[id] == :done
  raise CycleFound.new("dependency cycle", id) if state[id] == :active
  state[id] = :active
  tasks[id].deps.each { |d| visit(tasks, d, state, order) }
  state[id] = :done
  order << id
end

def schedule(tasks)
  order = topo_order(tasks)
  order.each do |id|
    t = tasks[id]
    t.early = t.deps.map { |d| tasks[d].finish }.max || 0
  end
  project_end = tasks.values.map(&:finish).max
  successors = Hash.new { |h, k| h[k] = [] }
  tasks.each do |id, t|
    t.deps.each { |d| successors[d] << id }
  end
  order.reverse_each do |id|
    t = tasks[id]
    succ = successors.fetch(id, [])
    latest_finish = succ.empty? ? project_end : succ.map { |s| tasks[s].late }.min
    t.late = latest_finish - t.days
  end
  [order, project_end]
end

def chain(tasks, order)
  order.select { |id| tasks[id].critical? }.sort_by { |id| tasks[id].early }
end

def gantt(t)
  pad = " " * t.early
  bar = (t.critical? ? "#" : "=") * t.days
  slack = "." * t.slack
  "|#{pad}#{bar}#{slack}"
end

def plan(title, rows)
  puts "== #{title}"
  tasks = load_tasks(rows)
  order, total = schedule(tasks)
  puts "tasks: #{tasks.size}, duration: #{total} days"
  order.each do |id|
    t = tasks[id]
    puts format("%-5s %-12s %2d-%2d slack %2d %s", id, t.title, t.early, t.finish, t.slack, gantt(t))
  end
  puts "critical: #{chain(tasks, order).join(" -> ")}"
  flex = tasks.values.max_by(&:slack)
  puts "most flexible: #{flex.title} (#{flex.slack} days)"
rescue CycleFound => e
  puts "#{e.message} at #{e.at}"
end

plan("house", [
  'site 3d "clear site"',
  'fdn 5d "foundation" after site',
  'frame 7d "framing" after fdn',
  'roof 4d "roofing" after frame',
  'plumb 4d "plumbing" after frame',
  'elec 3d "wiring" after frame',
  'wall 5d "drywall" after plumb, elec',
  'paint 3d "painting" after wall, roof',
  'yard 2d "landscaping" after site',
  'move 1d "move in" after paint, yard'
])
plan("release", [
  'spec 2d "write spec"',
  'api 4d "build api" after spec',
  'ui 6d "build ui" after spec',
  'docs 2d "docs" after api',
  'qa 3d "testing" after api, ui',
  'ship 1d "ship it" after qa, docs',
  'note this line is ignored'
])
plan("broken", ['a 1d "first" after c', 'b 1d "second" after a', 'c 1d "third" after b'])
