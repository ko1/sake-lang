class Job
  attr_reader :errors
  def initialize(errors) = @errors = errors
  def describe = "job"
end
class JQ
  attr_reader :done
  def initialize(done) = @done = done
end
q = JQ.new([])
j = Job.new([])
j.errors << "boom"
q.done << j
q.done.each { |x| puts x.describe }
