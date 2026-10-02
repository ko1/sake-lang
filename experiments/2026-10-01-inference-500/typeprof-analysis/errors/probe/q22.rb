module Geo
  class << self  

  def area(w, h) = w * h
  def sq(x) = area(x, x)
end; end
p Geo.sq(2)
