require "set"

class Exam
  attr_reader :course, :students
  attr_accessor :slot

  def initialize(course, students, slot)
    @course = course
    @students = students
    @slot = slot
  end

  def to_s = "#{course}(#{students.size})"
end

def enrollments
  {
    "amy" => ["math", "physics", "art"],
    "bob" => ["math", "chem"],
    "cat" => ["physics", "chem", "bio"],
    "dan" => ["art", "history"],
    "eva" => ["bio", "history", "math"],
    "fox" => ["music"],
    "gus" => ["chem", "music", "art"],
    "hal" => ["history", "physics"]
  }
end

def build_exams(enr)
  exams = {}
  enr.each do |student, courses|
    courses.each do |c|
      exams[c] ||= Exam.new(c, Set.new, nil)
      exams[c].students << student
    end
  end
  exams
end

def conflicts(exams)
  names = exams.keys.sort
  graph = names.to_h { |n| [n, Set.new] }
  names.each_with_index do |a, i|
    names.drop(i + 1).each do |b|
      shared = exams[a].students & exams[b].students
      next if shared.empty?
      graph[a] << b
      graph[b] << a
    end
  end
  graph
end

# Welsh-Powell: most-constrained exams first, each gets the lowest free slot.
def assign_slots(exams, graph)
  order = graph.keys.sort_by { |n| [-graph[n].size, n] }
  order.each do |name|
    used = graph[name].filter_map { |other| exams[other].slot }.to_set
    slot = 0
    slot += 1 while used.include?(slot)
    exams[name].slot = slot
  end
  exams.values.map(&:slot).max + 1
end

def verify(exams, graph)
  bad = []
  graph.each do |a, nbs|
    nbs.each do |b|
      next unless a < b
      bad << "#{a}/#{b}" if exams[a].slot == exams[b].slot
    end
  end
  bad
end

exams = build_exams(enrollments)
graph = conflicts(exams)
graph.keys.sort.each do |n|
  puts format("%-8s clashes with %d: %s", n, graph[n].size, graph[n].sort.join(","))
end
slots = assign_slots(exams, graph)
puts "slots needed: #{slots}"
slots.times do |s|
  in_slot = exams.values.select { |e| e.slot == s }.sort_by(&:course)
  seats = in_slot.sum { |e| e.students.size }
  puts "slot #{s + 1}: #{in_slot.join(" ")} - #{seats} seats"
end
problems = verify(exams, graph)
puts problems.empty? ? "schedule ok" : "clashes: #{problems.join(" ")}"

per_student = enrollments.map do |student, courses|
  "#{student}:#{courses.map { |c| exams[c].slot + 1 }.sort.join}"
end
puts per_student.join(" ")
