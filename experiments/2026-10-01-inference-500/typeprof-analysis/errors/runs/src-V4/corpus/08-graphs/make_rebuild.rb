require "set"

class MissingTarget < StandardError
  attr_reader :name, :wanted_by

  def initialize(message, name, wanted_by)
    super(message)
    @name = name
    @wanted_by = wanted_by
  end
end

module Target
  def label = "#{name}#{kind}"
  def kind = ""
  def stale?(dep_times, rebuilt) = true
end

class FileTarget
  include Target
  attr_reader :name, :deps, :mtime

  def initialize(name, deps, mtime)
    @name = name
    @deps = deps
    @mtime = mtime
  end

  # A file target is stale when a dependency is newer, or is itself rebuilt.
  def stale?(dep_times, rebuilt)
    return true if !@mtime    
    @deps.any? { |d| rebuilt.include?(d) || (dep_times[d] || 0) > @mtime }
  end
end

class PhonyTarget
  include Target
  attr_reader :name, :deps

  def initialize(name, deps)
    @name = name
    @deps = deps
  end

  def kind = " (phony)"
end

def parse_makefile(text, mtimes)
  targets = {}
  phony = Set.new
  text.each_line do |line|
    line = line.chomp
    next if line.strip.empty? || line.start_with?("#")
    if (m = line.match(/^\.PHONY:\s*(.*)$/))
      phony.merge(m[1].split(" "))
      next
    end
    name, _, rest = line.partition(":")
    targets[name.strip] = rest.split(" ")
  end
  targets.to_h do |name, deps|
    t = phony.include?(name) ? PhonyTarget.new(name, deps) : FileTarget.new(name, deps, mtimes[name])
    [name, t]
  end
end

def build_order(targets, goal, mtimes, order, seen, wanted_by)
  return if seen.include?(goal)
  t = targets[goal]
  if !t    
    raise MissingTarget.new("no rule to make #{goal}", goal, wanted_by) unless mtimes.key?(goal)
    seen << goal
    return
  end
  seen << goal
  t.deps.each { |d| build_order(targets, d, mtimes, order, seen, goal) }
  order << goal
end

def make(title, text, mtimes, goal)
  puts "== #{title}: make #{goal}"
  targets = parse_makefile(text, mtimes)
  order = []
  build_order(targets, goal, mtimes, order, Set.new, "(command line)")
  rebuilt = Set.new
  clock = mtimes.values.max + 1
  times = mtimes.dup
  order.each do |name|
    t = targets[name]
    if t.stale?(times, rebuilt)
      puts "  build #{t.label}"
      rebuilt << name
      if t.is_a?(FileTarget)
        times[name] = clock
        clock += 1
      end
    else
      puts "  up to date: #{name}"
    end
  end
  puts "  #{rebuilt.size} of #{order.size} targets rebuilt"
rescue MissingTarget => e
  puts "  error: #{e.message} (needed by #{e.wanted_by})"
end

makefile = <<~MK
  # tiny C project
  .PHONY: all clean test
  all: app docs
  app: main.o util.o net.o
  main.o: main.c util.h
  util.o: util.c util.h
  net.o: net.c net.h util.h
  docs: manual.md
  test: app
  clean:
MK

fresh = { "main.c" => 10, "util.c" => 11, "util.h" => 9, "net.c" => 12, "net.h" => 9,
          "manual.md" => 5, "main.o" => 20, "util.o" => 21, "net.o" => 22, "app" => 30, "docs" => 31 }
make("nothing changed", makefile, fresh, "app")

touched = fresh.merge("util.h" => 40)
make("header touched", makefile, touched, "all")

make("object deleted", makefile, fresh.reject { |k, _| k == "net.o" }, "test")

make("missing source", makefile, fresh.reject { |k, _| k == "net.h" }, "app")
