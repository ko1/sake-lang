# Schedules project tasks with dependencies in working days (topological
# order, earliest start/finish, slack, critical path) and draws a text Gantt chart.

class Task
  attr_reader :id, :name, :deps
  attr_accessor :days, :start, :finish, :late_start

  def initialize(id, name, days, deps)
    @id = id
    @name = name
    @days = days
    @deps = deps
    @start = 0
    @finish = 0
    @late_start = 0
  end
end

class CycleError < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def civil_from_days(z)
  z += 719468
  era = z / 146097
  doe = z - era * 146097
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  mp = (5 * doy + 2) / 153
  m = mp < 10 ? mp + 3 : mp - 9
  [yoe + era * 400 + (m <= 2 ? 1 : 0), m, doy - (153 * mp + 2) / 5 + 1]
end

def wday(z) = (z + 4) % 7

# Calendar date of working day number n (0-based) counted from a Monday.
def workday_date(monday, n) = monday + (n / 5) * 7 + n % 5

def show(z)
  _y, m, d = civil_from_days(z)
  format("%02d/%02d", m, d)
end

def topo_order(tasks)
  by_id = tasks.to_h { |t| [t.id, t] }
  state = Hash.new(:new)
  order = []
  stack = []
  tasks.each { |t| visit(by_id, state, order, stack, t.id) }
  order
end

def visit(by_id, state, order, stack, id)
  return if state[id] == :done
  if state[id] == :active
    raise CycleError.new("dependency cycle", stack.join(" -> ") + " -> " + id)
  end
  t = by_id[id]
  raise KeyError, "unknown task #{id}" if t.nil?
  state[id] = :active
  stack.push(id)
  t.deps.each { |d| visit(by_id, state, order, stack, d) }
  stack.pop
  state[id] = :done
  order << t
end

def schedule(tasks)
  order = topo_order(tasks)
  finish_of = {}
  order.each do |t|
    t.start = t.deps.map { |d| finish_of.fetch(d) }.max || 0
    t.finish = t.start + t.days
    finish_of[t.id] = t.finish
  end
  project_end = finish_of.values.max
  late_start = {}
  order.reverse.each do |t|
    succ = order.select { |s| s.deps.include?(t.id) }
    late_finish = succ.empty? ? project_end : succ.map { |s| late_start.fetch(s.id) }.min
    late_start[t.id] = late_finish - t.days
    t.late_start = late_finish - t.days
  end
  [order, project_end]
end

def plan
  [
    Task.new("req", "Requirements", 4, []),
    Task.new("ux", "UX design", 6, ["req"]),
    Task.new("api", "API design", 3, ["req"]),
    Task.new("be", "Backend", 12, ["api"]),
    Task.new("fe", "Frontend", 10, ["ux", "api"]),
    Task.new("int", "Integration", 4, ["be", "fe"]),
    Task.new("doc", "Docs", 5, ["api"]),
    Task.new("qa", "QA", 6, ["int"]),
    Task.new("rel", "Release", 1, ["qa", "doc"])
  ]
end

kickoff = days_from_civil(2026, 10, 5)
order, total = schedule(plan)
puts "Project starts Mon #{show(kickoff)}, #{total} working days, ends #{show(workday_date(kickoff, total - 1))}"
puts
width = total
order.each do |t|
  s = t.start
  f = t.finish
  slack = t.late_start - s
  bar = " " * s + (slack == 0 ? "=" : "-") * (f - s) + " " * (width - f)
  puts format("%-13s %s..%s |%s| slack %d", t.name, show(workday_date(kickoff, s)), show(workday_date(kickoff, f - 1)), bar, slack)
end

critical = order.select { |t| t.late_start == t.start }
puts
puts "Critical path: #{critical.map(&:id).join(" > ")}"
weekends = (kickoff..workday_date(kickoff, total - 1)).count { |z| [0, 6].include?(wday(z)) }
puts "Calendar days: #{workday_date(kickoff, total - 1) - kickoff + 1}, of which weekend days: #{weekends}"

slipped = plan
be = slipped.find { |t| t.id == "be" }
be.days += 3 if be
_o2, total2 = schedule(slipped)
puts "Backend +3 days: project #{total2 - total >= 0 ? "+" : ""}#{total2 - total} days"

broken = [Task.new("a", "A", 1, ["c"]), Task.new("b", "B", 1, ["a"]), Task.new("c", "C", 1, ["b"])]
begin
  schedule(broken)
rescue CycleError => e
  puts "Rejected: #{e.message}: #{e.path}"
end
missing = [Task.new("x", "X", 2, ["y"])]
begin
  schedule(missing)
rescue KeyError => e
  puts "Rejected: #{e.message}"
end
