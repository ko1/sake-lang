# Course enrollment analysis with set algebra: who takes what, overlaps, and conflicts.

class Course
  attr_reader :code, :title, :slot, :students

  def initialize(code, title, slot, students)
    @code = code
    @title = title
    @slot = slot
    @students = students
  end

  def enroll(name) = @students.add(name)
  def size = @students.size
  def to_s = "#{@code} (#{@title})"
end

def build_courses
  courses = [
    Course.new("CS101", "Intro Programming", :mon_am, Set[]),
    Course.new("CS201", "Data Structures", :tue_pm, Set[]),
    Course.new("MA110", "Calculus I", :mon_am, Set[]),
    Course.new("MA220", "Linear Algebra", :wed_am, Set[]),
    Course.new("PH100", "Physics", :tue_pm, Set[]),
    Course.new("EN105", "Writing", :fri_am, Set[])
  ]
  roster = [
    ["ann", "CS101 MA110 EN105"],
    ["bob", "CS101 CS201 MA220"],
    ["cho", "MA110 MA220 PH100"],
    ["dev", "CS201 PH100"],
    ["eve", "CS101 MA110 MA220 EN105"],
    ["fay", "EN105"],
    ["gus", "CS201 MA220 PH100 EN105"],
    ["hal", "CS101 CS201"]
  ]
  by_code = courses.to_h { |c| [c.code, c] }
  roster.each do |name, codes|
    codes.split(" ").each do |code|
      course = by_code[code]
      if course
        course.enroll(name)
      else
        puts "unknown course #{code} for #{name}"
      end
    end
  end
  courses
end

def find_course(courses, code)
  courses.find { |c| c.code == code }
end

def jaccard(a, b)
  union = (a | b).size
  return 0.0 if union == 0
  (a & b).size / union.to_f
end

courses = build_courses
puts "== Enrollment =="
courses.sort_by { |c| -c.size }.each do |c|
  names = c.students.sort.join(", ")
  puts format("%-28s %d: %s", c.to_s, c.size, names)
end

everyone = courses.reduce(Set[]) { |acc, c| acc | c.students }
puts "students: #{everyone.size}"

cs = courses.select { |c| c.code.start_with?("CS") }
ma = courses.select { |c| c.code.start_with?("MA") }
cs_students = cs.reduce(Set[]) { |acc, c| acc.union(c.students) }
ma_students = ma.reduce(Set[]) { |acc, c| acc.union(c.students) }
puts "== Departments =="
puts "CS and MA: #{(cs_students & ma_students).sort.join(" ")}"
puts "CS only:   #{(cs_students - ma_students).sort.join(" ")}"
puts "MA only:   #{ma_students.difference(cs_students).sort.join(" ")}"
neither = everyone - (cs_students | ma_students)
puts "neither:   #{neither.sort.join(" ")}"

puts "== Slot conflicts =="
by_slot = courses.group_by(&:slot)
by_slot.each do |slot, group|
  next if group.size < 2
  group.combination(2).each do |a, b|
    clash = a.students & b.students
    unless clash.empty?
      puts "#{slot}: #{a.code}/#{b.code} -> #{clash.sort.join(", ")}"
    end
  end
end

puts "== Similar courses =="
pairs = courses.combination(2).map do |a, b|
  [a.code, b.code, jaccard(a.students, b.students)]
end
top = pairs.sort_by { |x, y, j| [-j, x, y] }.take(3)
top.each { |x, y, j| puts format("%s ~ %s  %.2f", x, y, j) }

puts "== Lookups =="
["MA220", "BIO1"].each do |code|
  c = find_course(courses, code)
  if c
    others = find_course(courses, "CS201").students | find_course(courses, "PH100").students | find_course(courses, "MA110").students
    puts "#{code}: subset of CS201+PH100+MA110? #{c.students.subset?(others)}"
  else
    puts "#{code}: no such course"
  end
end
loads = Hash.new(0)
courses.each { |c| c.students.each { |s| loads[s] += 1 } }
heavy = loads.select { |s, n| n >= 4 }
puts "heavy load: #{heavy.keys.sort.join(", ")}"
p loads.max_by { |e__0| s, n = e__0; n }
