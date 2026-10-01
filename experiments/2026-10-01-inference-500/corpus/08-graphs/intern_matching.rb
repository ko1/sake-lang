require "set"

class Intern
  attr_reader :name, :skills, :wishes

  def initialize(name, skills, wishes)
    @name = name
    @skills = skills
    @wishes = wishes
  end
end

class Project
  attr_reader :code, :needs

  def initialize(code, needs)
    @code = code
    @needs = needs
  end
end

def compatible?(intern, project)
  intern.wishes.include?(project.code) &&
    project.needs.all? { |s| intern.skills.include?(s) }
end

def try_assign(i, interns, projects, owner, visited)
  intern = interns[i]
  projects.each_with_index do |pr, j|
    next unless compatible?(intern, pr)
    next if visited.include?(j)
    visited << j
    holder = owner[j]
    if holder.nil? || try_assign(holder, interns, projects, owner, visited)
      owner[j] = i
      return true
    end
  end
  false
end

def match(interns, projects)
  owner = {}
  matched = 0
  interns.size.times do |i|
    matched += 1 if try_assign(i, interns, projects, owner, Set.new)
  end
  [owner, matched]
end

def parse_interns(lines)
  lines.map do |line|
    name, skills, wishes = line.split(";").map(&:strip)
    Intern.new(name, skills.split(" "), wishes.split(" "))
  end
end

interns = parse_interns([
  "ada; ruby sql; web db",
  "ben; c asm; kernel",
  "cai; ruby js css; web ui",
  "dot; sql python; db ml",
  "eli; python math; ml",
  "fay; js css; ui web",
  "gil; c; kernel db"
])

projects = [
  Project.new("web", ["ruby"]),
  Project.new("db", ["sql"]),
  Project.new("kernel", ["c"]),
  Project.new("ml", ["python", "math"]),
  Project.new("ui", ["js", "css"]),
  Project.new("docs", [])
]

options = interns.map { |it| [it.name, projects.count { |pr| compatible?(it, pr) }] }
options.each { |name, n| puts format("%-4s can take %d project(s)", name, n) }

owner, matched = match(interns, projects)
puts "matched #{matched} of #{interns.size} interns to #{projects.size} projects"
projects.each_with_index do |pr, j|
  i = owner[j]
  who = i.nil? ? "(open)" : interns[i].name
  puts format("  %-6s <- %-6s needs: %s", pr.code, who, pr.needs.empty? ? "-" : pr.needs.join("+"))
end
taken = owner.values
idle = (0...interns.size).reject { |i| taken.include?(i) }
puts "unplaced: #{idle.map { |i| interns[i].name }.join(", ")}"
