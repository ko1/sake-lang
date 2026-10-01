def a1(s) = s.split(":").map(&:to_i)
def a2(s) = s.split(":").map { |x| x.to_i }
def a3(s)
  h, m = s.split(":").map { |x| x.to_i }
  h * 60 + m
end
def a4(s)
  h, m = s.split(":")
  h + m
end
def a5(a)
  h, m = a
  h + m
end
p a1("1:2"), a2("1:2"), a3("1:2"), a4("1:2"), a5([1, 2, 3].map { _1 })
