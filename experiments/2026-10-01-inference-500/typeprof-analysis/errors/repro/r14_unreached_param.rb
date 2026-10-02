# A parameter that never receives a value (the call was not seen) fails every overload it is passed to.
module Ops
  module_function

  def inc(x) = 1 + x
end
p Ops.inc(1)
