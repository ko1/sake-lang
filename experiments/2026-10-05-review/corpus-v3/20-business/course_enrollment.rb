class Course
  attr_reader :code, :title, :credits, :capacity, :prereqs, :slot, :roster, :waitlist

  def initialize(code, title, credits, capacity, prereqs, slot)
    @code = code
    @title = title
    @credits = credits
    @capacity = capacity
    @prereqs = prereqs
    @slot = slot
    @roster = []
    @waitlist = []
  end
end

class Student
  attr_reader :id, :name, :completed, :max_credits

  def initialize(id, name, completed, max_credits)
    @id = id
    @name = name
    @completed = completed
    @max_credits = max_credits
  end
end

class EnrollError < StandardError
  attr_reader :course, :reason

  def initialize(message, course, reason)
    super(message)
    @course = course
    @reason = reason
  end
end

class Registrar
  attr_reader :courses, :students

  def initialize(courses, students)
    @courses = courses
    @students = students
  end

  def course(code)
    @courses[code] or raise EnrollError.new("no course #{code}", code, :unknown)
  end

  def schedule_of(sid) = @courses.values.select { |c| c.roster.include?(sid) }

  def credits_of(sid) = schedule_of(sid).sum(&:credits)

  def enroll(sid, code)
    c = course(code)
    s = @students.fetch(sid)
    raise EnrollError.new("already enrolled", code, :duplicate) if c.roster.include?(sid)
    missing = c.prereqs.reject { |p| s.completed.include?(p) }
    raise EnrollError.new("missing #{missing.join(", ")}", code, :prereq) unless missing.empty?
    clash = schedule_of(sid).find { |o| o.slot == c.slot }
    raise EnrollError.new("time clash with #{clash.code}", code, :clash) if clash
    if credits_of(sid) + c.credits > s.max_credits
      raise EnrollError.new("over #{s.max_credits} credits", code, :credits)
    end
    if c.roster.size >= c.capacity
      c.waitlist << sid
      return :waitlisted
    end
    c.roster << sid
    :enrolled
  end

  # dropping frees a seat for the first waitlisted student who can still take it
  def drop(sid, code)
    c = course(code)
    raise EnrollError.new("not enrolled", code, :not_enrolled) unless c.roster.delete(sid)
    promoted = nil
    while promoted.nil? && !c.waitlist.empty?
      candidate = c.waitlist.shift
      begin
        promoted = candidate if enroll(candidate, code) == :enrolled
      rescue EnrollError => e
        puts "    #{@students.fetch(candidate).name} skipped: #{e.message}"
      end
    end
    promoted
  end
end

# order courses so that every prerequisite comes first
def study_plan(courses, goal, done, seen, plan)
  return plan if done.include?(goal) || plan.include?(goal)
  raise EnrollError.new("prerequisite cycle at #{goal}", goal, :cycle) if seen.include?(goal)
  seen << goal
  courses.fetch(goal).prereqs.each { |p| study_plan(courses, p, done, seen, plan) }
  plan << goal
end

courses = {}
[
  ["CS101", "Intro to Programming", 4, 3, [], "MWF9"],
  ["CS201", "Data Structures", 4, 2, ["CS101"], "MWF10"],
  ["CS301", "Algorithms", 4, 2, ["CS201", "MA201"], "TR9"],
  ["MA101", "Calculus I", 4, 3, [], "TR9"],
  ["MA201", "Discrete Math", 3, 2, ["MA101"], "MWF11"],
  ["BU110", "Accounting Basics", 3, 2, [], "MWF10"],
  ["CS999", "Thesis", 6, 1, ["CS998"], "TR1"],
  ["CS998", "Research Methods", 3, 1, ["CS999"], "TR3"]
].each do |code, title, credits, cap, pre, slot|
  courses[code] = Course.new(code, title, credits, cap, pre, slot)
end
students = {
  1 => Student.new(1, "Ada", Set["CS101", "MA101"], 12),
  2 => Student.new(2, "Bao", Set["CS101"], 10),
  3 => Student.new(3, "Cyd", Set[], 16),
  4 => Student.new(4, "Dov", Set["CS101", "MA101", "CS201"], 12),
  5 => Student.new(5, "Eun", Set["CS101", "MA101", "MA201"], 8)
}
reg = Registrar.new(courses, students)

requests = [
  [:add, 1, "CS201"], [:add, 2, "CS201"], [:add, 4, "CS201"], [:add, 5, "CS201"],
  [:add, 1, "MA201"], [:add, 1, "BU110"], [:add, 3, "CS101"], [:add, 3, "MA101"],
  [:add, 3, "CS301"], [:add, 4, "CS301"], [:add, 2, "MA201"], [:add, 4, "MA201"],
  [:add, 3, "BU110"], [:add, 5, "MA201"], [:add, 2, "PH100"], [:add, 1, "CS201"],
  [:drop, 1, "CS201"], [:drop, 3, "CS201"], [:add, 2, "BU110"], [:add, 5, "BU110"],
  [:drop, 1, "BU110"], [:drop, 4, "CS201"]
]
requests.each do |op, sid, code|
  name = students.fetch(sid).name
  begin
    if op == :add
      puts "#{name} + #{code}: #{reg.enroll(sid, code)}"
    else
      promoted = reg.drop(sid, code)
      who = promoted ? students.fetch(promoted).name : "nobody"
      puts "#{name} - #{code}: dropped, seat goes to #{who}"
    end
  rescue EnrollError => e
    puts "#{name} #{op == :add ? "+" : "-"} #{code}: refused (#{e.reason}: #{e.message})"
  end
end

puts
courses.each_value do |c|
  roster = c.roster.map { |sid| students.fetch(sid).name }
  wait = c.waitlist.map { |sid| students.fetch(sid).name }
  next if roster.empty? && wait.empty?
  w = wait.empty? ? "" : "  waitlist: #{wait.join(", ")}"
  puts format("%-6s %-22s %d/%d %s%s", c.code, c.title, roster.size, c.capacity, roster.join(", "), w)
end

puts
students.each_value do |s|
  puts format("%-4s %2d credits: %s", s.name, reg.credits_of(s.id), reg.schedule_of(s.id).map(&:code).join(" "))
end

puts
[[3, "CS301"], [2, "CS301"], [1, "CS999"]].each do |sid, goal|
  s = students.fetch(sid)
  begin
    plan = study_plan(courses, goal, s.completed, Set[], [])
    puts "#{s.name} -> #{goal}: #{plan.join(" > ")}"
  rescue EnrollError => e
    puts "#{s.name} -> #{goal}: #{e.message}"
  end
end
