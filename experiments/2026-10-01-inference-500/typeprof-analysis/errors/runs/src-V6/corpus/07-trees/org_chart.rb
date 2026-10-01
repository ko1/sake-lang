require "set"

class Employee
  attr_reader :id, :name, :title, :manager_id, :salary
  attr_accessor :reports

  def initialize(id, name, title, manager_id, salary)
    @id = id
    @name = name
    @title = title
    @manager_id = manager_id
    @salary = salary
    @reports = []
  end

  def headcount = reports.sum { |r| 1 + r.headcount }
  def cost = salary + reports.sum(&:cost)
  def depth = reports.empty? ? 0 : 1 + reports.map(&:depth).max
end

class OrgError < StandardError
  attr_reader :employee_id

  def initialize(message, employee_id)
    super(message)
    @employee_id = employee_id
  end
end

def parse(text)
  staff = {}
  text.each_line do |line|
    id, name, title, mgr, salary = line.chomp.split("|").map(&:strip)
    e = Employee.new(id.to_i, name, title, mgr == "-" ? nil : mgr.to_i, salary.to_i)
    staff[e.id] = e
  end
  staff
end

def link(staff)
  roots = []
  staff.each_value do |e|
    if !e.manager_id    
      roots << e
    else
      boss = staff[e.manager_id]
      raise OrgError.new("#{e.name} reports to unknown id #{e.manager_id}", e.id) if !boss    
      boss.reports << e
    end
  end
  staff.each_value { |e| e.reports = e.reports.sort_by(&:name) }
  roots
end

def chain(staff, e)
  seen = Set.new
  path = [e]
  while (mid = path.last.manager_id) && mid
    raise OrgError.new("reporting cycle at #{path.last.name}", mid) if seen.include?(mid)
    seen << mid
    path << staff[mid]
  end
  path
end

def render(e, prefix, last, out)
  connector = !prefix     ? "" : (last ? "`-- " : "|-- ")
  lead = prefix || ""
  info = "#{e.name} (#{e.title})"
  n = e.headcount
  info += " [#{n} under, $#{e.cost / 1000}k]" if n > 0
  out << lead + connector + info
  child_prefix = !prefix     ? "" : lead + (last ? "    " : "|   ")
  e.reports.each_with_index { |r, i| render(r, child_prefix, i == e.reports.size - 1, out) }
  out
end

def common_manager(staff, a, b)
  up_a = chain(staff, a).map(&:id)
  chain(staff, b).find { |e| up_a.include?(e.id) }
end

def by_name(staff, name) = staff.values.find { |e| e.name == name }

data = <<~TXT
  1 | Grace   | CEO               | - | 310000
  2 | Alan    | CTO               | 1 | 240000
  3 | Ada     | CFO               | 1 | 230000
  4 | Linus   | Eng Manager       | 2 | 180000
  5 | Barbara | Eng Manager       | 2 | 175000
  6 | Ken     | Engineer          | 4 | 150000
  7 | Dennis  | Engineer          | 4 | 148000
  8 | Margaret| Staff Engineer    | 5 | 190000
  9 | Edsger  | Engineer          | 5 | 140000
  10| Donald  | Intern            | 9 | 60000
  11| Frances | Controller        | 3 | 160000
  12| Radia   | Accountant        | 11| 95000
TXT

staff = parse(data)
roots = link(staff)
roots.each { |r| render(r, nil, true, []).each { |l| puts l } }

puts "-- stats --"
managers = staff.values.reject { |e| e.reports.empty? }
widest = managers.max_by { |e| e.reports.size }
puts "depth of org: #{roots.first.depth}"
puts "managers: #{managers.size}, widest span: #{widest.name} (#{widest.reports.size})"
avg = staff.values.sum(&:salary) / staff.size
puts "average salary: $#{avg}"
leaves = staff.values.select { |e| e.reports.empty? }
puts "individual contributors: #{leaves.map(&:name).sort.join(", ")}"

puts "-- chains and common managers --"
d = by_name(staff, "Donald")
puts "Donald: #{chain(staff, d).map(&:name).join(" -> ")}"
pairs = [%w[Ken Dennis], %w[Donald Ken], %w[Radia Margaret], %w[Alan Edsger], %w[Ken Nobody]]
pairs.each do |x, y|
  a = by_name(staff, x)
  b = by_name(staff, y)
  if !a     || !b    
    puts "#{x} & #{y}: unknown employee"
    next
  end
  m = common_manager(staff, a, b)
  puts "#{x} & #{y}: #{m ? m.name : "none"}"
end

puts "-- bad data --"
bad = ["1 | A | Boss | - | 1\n2 | B | Lead | 7 | 1\n", "1 | A | Boss | 2 | 1\n2 | B | Lead | 1 | 1\n"]
bad.each do |text|
  s = parse(text)
  link(s)
  s.each_value { |e| chain(s, e) }
  puts "ok"
rescue OrgError => e
  puts "error (employee #{e.employee_id}): #{e.message}"
end
