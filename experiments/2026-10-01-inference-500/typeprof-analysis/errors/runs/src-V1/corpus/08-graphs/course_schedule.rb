class CycleError < StandardError
  attr_reader :remaining

  def initialize(message, remaining)
    super(message)
    @remaining = remaining
  end
end

class UnknownCourse < StandardError
  attr_reader :course

  def initialize(message, course)
    super(message)
    @course = course
  end
end

class Course
  attr_reader :code, :credits, :prereqs

  def initialize(code, credits, prereqs)
    @code = code
    @credits = credits
    @prereqs = prereqs
  end
end

def catalog(entries)
  entries.each_with_object({}) do |line, courses|
    code, rest = line.split(":")
    credits_s, prereq_s = rest.split("|")
    prereqs = (prereq_s || "").strip.split(",").map(&:strip).reject(&:empty?)
    courses[code.strip] = Course.new(code.strip, credits_s.to_i, prereqs)
  end
end

def check_known(courses)
  courses.each_value do |c|
    c.prereqs.each do |pre|
      raise UnknownCourse.new("#{c.code} needs unknown #{pre}", pre) unless courses.key?(pre)
    end
  end
end

# Kahn's algorithm; courses that become available together form one term.
def plan_terms(courses)
  check_known(courses)
  indeg = Hash.new(0)
  dependents = {}
  courses.each do |code, c|
    indeg[code] += 0
    c.prereqs.each do |pre|
      indeg[code] += 1
      (dependents[pre] ||= []) << code
    end
  end
  ready = indeg.keys.select { |k| indeg[k] == 0 }.sort
  terms = []
  placed = 0
  until ready.empty?
    terms << ready
    placed += ready.size
    nxt = []
    ready.each do |code|
      dependents.fetch(code, []).each do |d|
        indeg[d] -= 1
        nxt << d if indeg[d] == 0
      end
    end
    ready = nxt.sort
  end
  if placed < courses.size
    left = indeg.keys.select { |k| indeg[k] > 0 }.sort
    raise CycleError.new("cyclic prerequisites", left)
  end
  terms
end

def report(name, entries)
  puts "== #{name}"
  courses = catalog(entries)
  begin
    terms = plan_terms(courses)
    terms.each_with_index do |term, i|
      credits = term.sum { |c| courses[c].credits }
      puts format("term %d (%2d cr): %s", i + 1, credits, term.join(", "))
    end
    heavy = terms.max_by(&:size)
    puts "widest term has #{heavy.size} courses"
  rescue CycleError => e
    puts "error: #{e.message}: #{e.remaining.join(" ")}"
  rescue UnknownCourse => e
    puts "error: #{e.message} (#{e.course})"
  end
end

cs = [
  "CS101: 4 |",
  "CS102: 4 | CS101",
  "MATH1: 3 |",
  "MATH2: 3 | MATH1",
  "CS201: 4 | CS102, MATH1",
  "CS202: 4 | CS102",
  "CS301: 3 | CS201, CS202",
  "CS310: 3 | CS201, MATH2",
  "CS350: 3 | CS202",
  "CS401: 6 | CS301, CS310, CS350",
  "ART1: 2"
]
report("computer science", cs)

loopy = [
  "A1: 3 |", "B1: 3 | A1, C1", "C1: 3 | D1", "D1: 3 | B1", "E1: 3 | A1"
]
report("loopy", loopy)

typo = ["X1: 3 |", "X2: 3 | X1, X9"]
report("typo", typo)
