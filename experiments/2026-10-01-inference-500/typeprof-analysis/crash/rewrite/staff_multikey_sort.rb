# Sort a staff directory by a user-supplied list of sort keys (field + direction)
# with a stable merge sort driven by a comparator block.

class Employee
  attr_reader :name, :dept, :salary, :hired

  def initialize(name, dept, salary, hired)
    @name = name
    @dept = dept
    @salary = salary
    @hired = hired
  end
end

def field(e, f)
  case f
  in :name then e.name
  in :dept then e.dept
  in :salary then e.salary
  in :hired then e.hired
  end
end

def compare(a, b, spec)
  spec.each do |key|
    key => {field: f, dir:}
    c = field(a, f) <=> field(b, f)
    next if c == 0
    return dir == :desc ? -c : c
  end
  0
end

def merge_sort(a, &cmp)
  return a.dup if a.size <= 1
  mid = a.size / 2
  left = merge_sort(a.take(mid), &cmp)
  right = merge_sort(a.drop(mid), &cmp)
  out = []
  i = 0
  j = 0
  while i < left.size && j < right.size
    if cmp.call(right[j], left[i]) < 0
      out << right[j]
      j += 1
    else
      out << left[i]
      i += 1
    end
  end
  out.concat(left.drop(i), right.drop(j))
end

def parse_spec(text)
  text.split(",").map do |part|
    name, dir = part.strip.split(" ")
    f = name.to_sym
    raise ArgumentError, "unknown field #{name}" unless [:name, :dept, :salary, :hired].include?(f)
    {field: f, dir: dir == "desc" ? :desc : :asc}
  end
end

def show(staff)
  staff.each do |e|
    puts format("  %-8s %-6s %6d %d", e.name, e.dept, e.salary, e.hired)
  end
end

staff = [
  Employee.new("Mori", "eng", 92000, 2019), Employee.new("Abe", "ops", 61000, 2021),
  Employee.new("Kudo", "eng", 105000, 2015), Employee.new("Sano", "sales", 58000, 2022),
  Employee.new("Ueda", "eng", 92000, 2017), Employee.new("Iwai", "ops", 61000, 2018),
  Employee.new("Oka", "sales", 75000, 2016), Employee.new("Endo", "eng", 78000, 2023),
  Employee.new("Hara", "ops", 70000, 2020), Employee.new("Noda", "sales", 58000, 2019)
]

["dept, salary desc, name", "hired desc", "salary, hired", "dept desc, name desc"].each do |text|
  spec = parse_spec(text)
  puts "sort by #{text}:"
  show(merge_sort(staff) { |a, b| compare(a, b, spec) })
end

begin
  parse_spec("dept, age desc")
rescue ArgumentError => e
  puts "bad spec: #{e.message}"
end

# Stability check: sorting by name first and then by dept alone keeps names ordered within a dept.
by_name = merge_sort(staff) { |a, b| compare(a, b, parse_spec("name")) }
two_pass = merge_sort(by_name) { |a, b| compare(a, b, parse_spec("dept")) }
one_pass = merge_sort(staff) { |a, b| compare(a, b, parse_spec("dept, name")) }
puts "two stable passes == one two-key sort: #{two_pass.map(&:name) == one_pass.map(&:name)}"

payroll = Hash.new(0)
staff.each { |e| payroll[e.dept] += e.salary }
top, total = payroll.max_by { |e__| _, v = e__; v }
puts "largest payroll: #{top} #{total}"
