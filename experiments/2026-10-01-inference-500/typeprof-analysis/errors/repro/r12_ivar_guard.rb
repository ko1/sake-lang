# A guard on an instance variable narrows only inside the `if`, not after an early return.
class Box
  def initialize = @v = nil
  def put(v) = @v = v
  def inc
    return 0 unless @v
    @v + 1
  end
end
b = Box.new
b.put(1)
p b.inc
