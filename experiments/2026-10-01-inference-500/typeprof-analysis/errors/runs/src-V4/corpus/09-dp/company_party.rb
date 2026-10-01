class Employee
  attr_reader :name, :fun, :reports

  def initialize(name, fun, reports)
    @name = name
    @fun = fun
    @reports = reports
  end
end

class OrgError < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

def parse_org(text)
  staff = {}
  boss_of = {}
  text.lines.each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    m = line.match(/\A(\w+)\s+(\d+)(?:\s+<\s+(\w+))?\z/)
    raise OrgError.new("cannot parse #{line.inspect}", "?") if !m    
    name = m[1]
    raise OrgError.new("duplicate employee", name) if staff.key?(name)
    staff[name] = Employee.new(name, m[2].to_i, [])
    boss_of[name] = m[3]
  end
  root = nil
  boss_of.each do |name, boss|
    if !boss    
      raise OrgError.new("two people at the top", name) if root
      root = staff[name]
    else
      manager = staff[boss]
      raise OrgError.new("unknown manager #{boss}", name) if !manager    
      manager.reports << staff[name]
    end
  end
  raise OrgError.new("nobody at the top", "-") if !root    
  root
end

# best fun of the subtree, with and without inviting its root
def party(emp, memo)
  memo[emp.name] ||= begin
    with_me = emp.fun
    without_me = 0
    emp.reports.each do |r|
      party(r, memo) => { with:, without: }
      with_me += without
      without_me += [with, without].max
    end
    { with: with_me, without: without_me }
  end
end

def guests(emp, may_invite, memo, out)
  party(emp, memo) => { with:, without: }
  invite = may_invite && with > without
  out << emp.name if invite
  emp.reports.each { |r| guests(r, !invite, memo, out) }
  out
end

def print_tree(emp, depth, invited)
  mark = invited.include?(emp.name) ? "*" : " "
  puts "  #{mark} #{"  " * depth}#{emp.name} (#{emp.fun})"
  emp.reports.each { |r| print_tree(r, depth + 1, invited) }
end

def headcount(emp) = 1 + emp.reports.sum { |r| headcount(r) }

org = <<~ORG
  # name fun < manager
  Grace 2
  Alan 5 < Grace
  Ada 7 < Grace
  Linus 3 < Grace
  Barbara 9 < Alan
  Ken 4 < Alan
  Dennis 6 < Ken
  Edsger 8 < Ada
  Tony 1 < Ada
  Niklaus 5 < Tony
  Donald 10 < Linus
  John 2 < Linus
  Frances 4 < John
ORG

root = parse_org(org)
memo = {}
party(root, memo) => { with:, without: }
best = [with, without].max
invited = guests(root, true, memo, [])
puts "#{headcount(root)} employees, best total fun #{best} with #{invited.size} guests"
print_tree(root, 0, invited)

puts "best party per department:"
root.reports.each do |dept|
  party(dept, memo) => { with:, without: }
  puts format("  %-8s %3d (head %s)", dept.name, [with, without].max, with > without ? "invited" : "stays home")
end

broken = [
  "A 1\nB 2 < A\nC 3 < Z",
  "A 1\nB 2",
  "A 1\nA 2 < A",
  "A one"
]
broken.each do |text|
  begin
    parse_org(text)
    puts "parsed"
  rescue OrgError => e
    puts "org error at #{e.name}: #{e.message}"
  end
end
