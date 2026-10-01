class A; def a = 1; end
class B; def b = 2; end
def w1(x)
  case x
  when A then x.a
  when B then x.b
  end
end
def w2(x)
  case x
  in A then x.a
  in B then x.b
  end
end
def w3(x)
  case x
  in A => y then y.a
  in B => y then y.b
  end
end
def w4(x)
  return x.a if x.is_a?(A)
  x.b
end
def w5(x) = x.is_a?(A) ? x.a : x.b
def w6(x)
  if x.is_a?(A)
    x.a
  else
    x.b
  end
end
[A.new, B.new].each { |o| p w1(o), w2(o), w3(o), w4(o), w5(o), w6(o) }
