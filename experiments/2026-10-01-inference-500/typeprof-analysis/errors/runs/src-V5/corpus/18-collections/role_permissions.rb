# Role-based access control: roles grant permission Sets and include other roles.

class UnknownRole < StandardError
  attr_reader :role

  def initialize(message, role)
    super(message)
    @role = role
  end
end

class RoleCycle < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

class Role
  attr_reader :name, :grants, :includes

  def initialize(name, grants, includes)
    @name = name
    @grants = grants
    @includes = includes
  end
end

class User
  attr_reader :name, :roles, :denied

  def initialize(name, roles, denied)
    @name = name
    @roles = roles
    @denied = denied
  end
end

def define_roles
  defs = [
    ["viewer", "doc.read comment.read", ""],
    ["commenter", "comment.write", "viewer"],
    ["editor", "doc.write doc.create", "commenter"],
    ["publisher", "doc.publish", "editor"],
    ["auditor", "log.read", "viewer"],
    ["admin", "user.manage role.manage", "publisher auditor"]
  ]
  defs.to_h do |name, grants, incl|
    [name, Role.new(name, grants.split(" ").to_set, incl.split(" "))]
  end
end

def effective(roles, name, path)
  raise RoleCycle.new("cycle through #{name}", path + [name]) if path.include?(name)
  role = roles[name]
  raise UnknownRole.new("no role #{name}", name) unless role
  perms = role.grants.dup
  role.includes.each do |inc|
    perms.merge(effective(roles, inc, path + [name]))
  end
  perms
end

def user_perms(roles, user)
  all = user.roles.reduce(Set[]) { |acc, r| acc | effective(roles, r, []) }
  all - user.denied
end

roles = define_roles
puts "== Roles =="
roles.each_key do |name|
  perms = effective(roles, name, [])
  own = roles[name].grants
  inherited = perms - own
  puts format("%-10s %2d perms (own %d, inherited %d)", name, perms.size, own.size, inherited.size)
end

users = [
  User.new("alice", ["admin"], Set[]),
  User.new("bob", ["editor", "auditor"], Set["comment.write"]),
  User.new("carol", ["commenter"], Set[]),
  User.new("dan", ["publisher"], Set["doc.publish"])
]
perms_of = users.to_h { |u| [u.name, user_perms(roles, u)] }

puts "== Users =="
perms_of.each { |name, ps| puts "#{name}: #{ps.sort.join(" ")}" }

puts "== Who can... =="
["doc.publish", "log.read", "comment.write", "user.delete"].each do |perm|
  who = perms_of.select { |n, ps| ps.include?(perm) }.keys.sort
  puts format("%-14s %s", perm, who.empty? ? "(nobody)" : who.join(", "))
end

puts "== Comparisons =="
a = perms_of["bob"]
b = perms_of["dan"]
puts "bob only: #{(a - b).sort.join(" ")}"
puts "dan only: #{(b - a).sort.join(" ")}"
puts "carol within bob? #{perms_of["carol"].subset?(a)}"
puts "alice strictly above dan? #{perms_of["alice"].proper_superset?(b)}"
puts "bob and carol disjoint? #{a.disjoint?(perms_of["carol"])}"

everything = perms_of.values.reduce(Set[], :|)
unused = roles.values.select { |r| r.grants.disjoint?(everything) }
puts "roles granting nothing in use: #{unused.empty? ? "none" : unused.map(&:name).join(",")}"
by_area = everything.sort.group_by { |p| p.split(".")[0] }
puts "areas: #{by_area.map { |area, ps| "#{area}(#{ps.size})" }.join(" ")}"

puts "== Bad configurations =="
broken = define_roles
broken["viewer"] = Role.new("viewer", Set["doc.read"], ["admin"])
broken["guest"] = Role.new("guest", Set[], ["visitor"])
["editor", "guest", "auditor"].each do |name|
  puts "#{name}: #{effective(broken, name, []).size} perms"
rescue RoleCycle => e
  puts "#{name}: #{e.message} (#{e.path.join(" > ")})"
rescue UnknownRole => e
  puts "#{name}: missing role '#{e.role}'"
end
