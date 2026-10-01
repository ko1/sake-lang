def lift(v)
  case v
  in Integer then v
  in Float then v.to_i
  end
end
p lift(1) + 1
class N
  attr_accessor :z
  def initialize = @z = nil
end
n = N.new
m = (n.z ||= N.new)
p m.z
def nm(x)
  case x
  when Integer then x
  when Float then x.to_i
  end
end
p nm(1) + 1
