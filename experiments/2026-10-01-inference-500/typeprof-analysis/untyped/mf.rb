module M
  module_function

  def twice(x) = x * 2
end

module N
  def self.twice(x) = x * 2
end

p M.twice(3)
p N.twice(3)
