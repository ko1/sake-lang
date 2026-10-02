[1, 2].each { |v| p v + 1 }
xs = [[1, 2]]
xs.each { |(v, w)| [3].each { |u| p v + u + w } }
v = "done"
puts v if v.nil?
module M
  module_function

  def f(x) = x + 1
end
p M.f(1)
