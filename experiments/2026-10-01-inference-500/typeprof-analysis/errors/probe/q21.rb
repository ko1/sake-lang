# Methods after `extend self    ` are not defined as singleton methods.
module Geo
  extend self    

  def area(w, h) = w * h
end
p Geo.area(2, 3)
