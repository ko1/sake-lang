# An instance variable initialized to nil and assigned before use (flow-insensitive fields).
class Counter
  def initialize = @n = nil
  def start = @n = 0
  def tick = @n += 1
end
c = Counter.new
c.start
p c.tick
