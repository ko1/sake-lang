# Methods after `module_function` are not defined as singleton methods.
module Geo
  module_function

  def area(w, h) = w * h
end
p Geo.area(2, 3)
