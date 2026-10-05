require_relative "ref/pqueue"

# A job orders by priority (higher first), then by name (earlier first).
Job = Struct.new(:priority, :name) do
  include Comparable
  def <=>(b)
    c = priority <=> b.priority
    c == 0 ? b.name <=> name : c
  end
  def to_s = "#{name}(#{priority})"
end

# One queue type per element type: a field has one type for all instances of its type.
class WordQueue < PQueue
end
class JobQueue < PQueue
end
class TaskQueue < PQueue
end

# numbers: the largest first by default, the smallest with order: :min
q = PQueue.new([5, 3, 8, 1, 9, 2])
p q.size
p q.top
q.push(7, 10)
q << 0
p q.length
p q.pop
p q.pop
p q.to_a
p q.size
p q.shift(3)
p q
mq = PQueue.new([5, 3, 8, 1, 9, 2], order: :min)
out = []
mq.each_pop { |x| out << x }
p out
p mq.empty?
p mq.pop
p mq.top

# heap sort of many values, against Array.sort
nums = (1..200).to_a.map { |i| i * 7919 % 211 }
hq = PQueue.new(nums, order: :min)
p hq.to_a == nums.sort
p hq.size

# Strings, and merge
sq = WordQueue.new(["pear", "apple", "fig"], order: :min)
sq.merge(WordQueue.new(["kiwi", "banana"]))
p sq.to_a
p sq.pop
sq.clear
p sq.empty?

# a custom order: the element type's own <=>
jobs = JobQueue.new([Job.new(2, "backup"), Job.new(5, "deploy"), Job.new(2, "alert"), Job.new(1, "lint")])
jobs.push(Job.new(5, "build"))
puts jobs.to_a.join(" ")
p jobs.pop
p jobs.pop
lazy = JobQueue.new([Job.new(2, "backup"), Job.new(5, "deploy"), Job.new(2, "alert")], order: :min)
puts lazy.to_a.join(" ")

# Tuples: [priority, insertion number, task] keeps equal priorities in insertion order
tq = TaskQueue.new([], order: :min)
seq = 0
[[3, "c"], [1, "a"], [3, "d"], [1, "b"], [2, "x"]].each do |pr, task|
  tq.push([pr, seq, task])
  seq += 1
end
tq.each_pop { |pr, _, task| puts "#{pr} #{task}" }

# errors
begin
  PQueue.new([1], order: :biggest)
rescue ArgumentError => e
  puts e.message
end

