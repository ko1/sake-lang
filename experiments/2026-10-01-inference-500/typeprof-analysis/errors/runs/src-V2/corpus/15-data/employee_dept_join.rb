require "set"

class Employee
  attr_reader :id, :name, :dept_id, :manager_id, :salary

  def initialize(id, name, dept_id, manager_id, salary)
    @id = id
    @name = name
    @dept_id = dept_id
    @manager_id = manager_id
    @salary = salary
  end
end

class Department
  attr_reader :id, :name, :location

  def initialize(id, name, location)
    @id = id
    @name = name
    @location = location
  end
end

def employees
  [
    Employee.new(1, "Ada", 10, nil, 185000),
    Employee.new(2, "Brian", 10, 1, 132000),
    Employee.new(3, "Chloe", 20, 1, 141000),
    Employee.new(4, "Dmitri", 20, 3, 98000),
    Employee.new(5, "Elena", 20, 3, 101500),
    Employee.new(6, "Farid", 30, 1, 120000),
    Employee.new(7, "Grace", 30, 6, 123000),
    Employee.new(8, "Hiro", 40, 6, 126000),
    Employee.new(9, "Ines", 10, 2, 115000),
    Employee.new(10, "Jonas", 50, 42, 66000)
  ]
end

def departments
  [
    Department.new(10, "Engineering", "Berlin"),
    Department.new(20, "Data", "Lisbon"),
    Department.new(30, "Sales", "Madrid"),
    Department.new(60, "Legal", "Paris")
  ]
end

def index_by_id(rows)
  idx = {}
  rows.each { |r| idx[yield(r)] = r }
  idx
end

def median(values)
  sorted = values.sort
  n = sorted.size
  return nil if n == 0
  if n.odd?
    sorted[n / 2]
  else
    (sorted.fetch(n / 2 - 1) + sorted.fetch(n / 2)) / 2.0
  end
end

def fmt_k(amount)
  return "-" if amount.nil?
  format("%.1fk", amount / 1000.0)
end

emps = employees
depts = index_by_id(departments, &:id)
by_emp = index_by_id(emps, &:id)

puts "== Directory (inner join employees x departments) =="
joined = emps.filter_map do |e|
  d = depts[e.dept_id]
  next nil if d.nil?
  [e, d]
end
joined.sort_by { |e, d| d.name + "/" + e.name }.each do |e, d|
  mid = e.manager_id
  boss = mid ? by_emp[mid] : nil
  boss_name = boss ? boss.name : (mid ? "?#{mid}" : "(none)")
  puts format("%-12s %-8s %-7s reports to %s", d.name, d.location, e.name, boss_name)
end

puts
puts "== Unmatched =="
orphans = emps.reject { |e| depts.key?(e.dept_id) }
orphans.each { |e| puts "employee #{e.name} has unknown dept #{e.dept_id}" }
used = emps.map(&:dept_id).to_set
depts.each_value do |d|
  puts "department #{d.name} has no employees" unless used.include?(d.id)
end

puts
puts "== Salary by department =="
puts format("%-12s %3s %9s %9s %9s %9s", "Dept", "n", "min", "median", "max", "total")
groups = joined.group_by { |e, d| d.name }
groups.keys.sort.each do |name|
  salaries = groups.fetch(name).map { |e, d| e.salary }
  puts format("%-12s %3d %9s %9s %9s %9s", name, salaries.size, fmt_k(salaries.min),
              fmt_k(median(salaries)), fmt_k(salaries.max), fmt_k(salaries.sum))
end

puts
puts "== Managers and span of control =="
reports = Hash.new(0)
emps.each do |e|
  mid = e.manager_id
  reports[mid] += 1 if mid && by_emp.key?(mid)
end
reports.sort_by { |id, n| -n * 100 + id }.each do |id, n|
  m = by_emp.fetch(id)
  team = emps.select { |e| e.manager_id == id }
  over = team.select { |e| e.salary > m.salary }
  note = over.empty? ? "" : "  (earns less than #{over.map(&:name).join(", ")})"
  puts "#{m.name}: #{n} direct report(s)#{note}"
end

top = emps.max_by(&:salary)
puts
puts "Highest paid: #{top.name}" if top
