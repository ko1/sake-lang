# Build-step scheduling: dependencies as a Hash of Sets, Kahn's algorithm in parallel stages, cycle reports.

class CycleError < StandardError
  attr_reader :nodes

  def initialize(message, nodes)
    super(message)
    @nodes = nodes
  end
end

class MissingDependency < StandardError
  attr_reader :step, :dependency

  def initialize(message, step, dependency)
    super(message)
    @step = step
    @dependency = dependency
  end
end

def parse_rules(text)
  deps = {}
  text.each_line do |line|
    line = line.strip
    next if line.empty?
    target, rest = line.split(":")
    deps[target.strip] = (rest || "").split(" ").to_set
  end
  deps
end

def check_missing(deps)
  deps.each do |step, ds|
    ds.each { |d| raise MissingDependency.new("#{step} needs #{d}", step, d) unless deps.key?(d) }
  end
end

def stages(deps)
  check_missing(deps)
  remaining = deps.transform_values(&:dup)
  result = []
  until remaining.empty?
    ready = remaining.select { |step, ds| ds.empty? }.keys.sort
    raise CycleError.new("dependency cycle", remaining.keys.sort) if ready.empty?
    result << ready
    done = ready.to_set
    ready.each { |s| remaining.delete(s) }
    remaining.each_value { |ds| ds.subtract(done) }
  end
  result
end

def dependents(deps, step)
  out = Set[]
  frontier = [step]
  until frontier.empty?
    cur = frontier.pop
    deps.each do |s, ds|
      frontier << s if ds.include?(cur) && out.add?(s)
    end
  end
  out
end

def durations = {"fetch" => 3, "configure" => 2, "codegen" => 4, "compile_core" => 9, "compile_ext" => 6,
                 "link" => 2, "docs" => 5, "test" => 8, "package" => 1, "lint" => 2}

rules = <<~RULES
  fetch:
  configure: fetch
  codegen: configure
  lint: fetch
  compile_core: configure codegen
  compile_ext: configure
  link: compile_core compile_ext
  docs: codegen
  test: link
  package: link docs test lint
RULES

deps = parse_rules(rules)
plan = stages(deps)
puts "== Stages =="
finish = {}
plan.each_with_index do |steps, i|
  puts "#{i + 1}: #{steps.join(", ")}"
  steps.each do |s|
    start = deps[s].empty? ? 0 : deps[s].map { |d| finish[d] }.max
    finish[s] = start + durations[s]
  end
end
puts "== Earliest finish =="
finish.sort_by { |e__0| s, t = e__0; [t, s] }.each { |s, t| puts format("  %-13s %2d", s, t) }
last_step, makespan = finish.max_by { |e__1| s, t = e__1; t }
puts "makespan: #{makespan} (ends with #{last_step})"
serial = durations.values.sum
puts format("serial time: %d, speedup %.2fx", serial, serial / makespan.to_f)

path = [last_step]
cur = last_step
until deps[cur].empty?
  cur = deps[cur].max_by { |d| finish[d] }
  path.unshift(cur)
end
puts "critical path: #{path.join(" -> ")}"

puts "== Impact of a change =="
["codegen", "compile_ext", "package"].each do |s|
  affected = dependents(deps, s)
  puts "#{s}: #{affected.empty? ? "nothing" : affected.sort.join(", ")}"
end

puts "== Broken rule sets =="
cyclic = parse_rules("a: c\nb: a\nc: b\nd:\ne: d\n")
missing = parse_rules("a:\nb: a zed\n")
[["cyclic", cyclic], ["missing", missing]].each do |name, rs|
  p stages(rs)
rescue CycleError => e
  puts "#{name}: #{e.message} among #{e.nodes.join(", ")}"
rescue MissingDependency => e
  puts "#{name}: step '#{e.step}' depends on unknown '#{e.dependency}'"
end
