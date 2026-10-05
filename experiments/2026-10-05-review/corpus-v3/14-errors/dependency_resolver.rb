# Resolve install order for packages with a DFS topological sort; detect cycles, missing and version conflicts.
class CycleError < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

class MissingPackage < StandardError
  attr_reader :name, :wanted_by

  def initialize(message, name, wanted_by)
    super(message)
    @name = name
    @wanted_by = wanted_by
  end
end

class VersionConflict < StandardError
  attr_reader :name, :need, :have

  def initialize(message, name, need, have)
    super(message)
    @name = name
    @need = need
    @have = have
  end
end

class Package
  attr_reader :name, :version, :deps

  def initialize(name, version, deps)
    @name = name
    @version = version
    @deps = deps
  end
end

def registry
  [
    Package.new("app", 3, [["web", 2], ["db", 1], ["log", 1]]),
    Package.new("web", 2, [["http", 1], ["log", 1]]),
    Package.new("http", 1, [["socket", 1]]),
    Package.new("socket", 1, []),
    Package.new("db", 1, [["pool", 1], ["log", 1]]),
    Package.new("pool", 1, []),
    Package.new("log", 1, []),
    Package.new("cli", 1, [["args", 1], ["log", 2]]),
    Package.new("args", 1, []),
    Package.new("a", 1, [["b", 1]]),
    Package.new("b", 1, [["c", 1]]),
    Package.new("c", 1, [["a", 1]]),
    Package.new("plugin", 1, [["web", 1], ["theme", 1]])
  ].to_h { |pkg| [pkg.name, pkg] }
end

def visit(reg, name, min_version, wanted_by, state, order, stack)
  pkg = reg[name] or raise MissingPackage.new("#{name} not found (wanted by #{wanted_by})", name, wanted_by)
  if pkg.version < min_version
    raise VersionConflict.new("#{wanted_by} needs #{name} >= #{min_version}", name, min_version, pkg.version)
  end
  case state[name]
  when :done then return
  when :visiting
    raise CycleError.new("dependency cycle", stack.drop(stack.index(name)) << name)
  end
  state[name] = :visiting
  stack.push(name)
  pkg.deps.each { |dep, ver| visit(reg, dep, ver, name, state, order, stack) }
  stack.pop
  state[name] = :done
  order << name
end

def install_order(reg, root)
  order = []
  visit(reg, root, 1, "user", {}, order, [])
  order
end

reg = registry
failures = 0
%w[app socket cli a plugin nosuch].each do |root|
  order = install_order(reg, root)
  puts "#{root}: #{order.join(" -> ")}"
rescue CycleError => e
  failures += 1
  puts "#{root}: #{e.message} #{e.path.join(" > ")}"
rescue MissingPackage => e
  failures += 1
  puts "#{root}: missing #{e.name}, required by #{e.wanted_by}"
rescue VersionConflict => e
  failures += 1
  puts "#{root}: #{e.message}, but #{e.have} is available"
end
puts "#{failures} of 6 roots could not be resolved"
