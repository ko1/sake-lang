class S
  def initialize = @x = 1
  attr_reader :x
end
h = {}
h[1] = S.new.x
p h.max_by { |k, v| v }
