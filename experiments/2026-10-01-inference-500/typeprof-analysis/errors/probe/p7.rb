def g = [1, 2].find { |v| v > 1 }
def n1(x = g) = x.nil? || x.even?
def n2(x = g) = x && x.even?
def n3(x = g) = x.nil? ? 0 : x + 1
def n4(x = g)
  until x.nil?
    return x + 1
  end
end
def n5(x = g)
  case x
  when nil then 0
  else x + 1
  end
end
def n6(x = g)
  unless x
    0
  else
    x + 1
  end
end
def n7(x = g)
  return 0 if !x
  x + 1
end
def n8(x = g)
  raise "no" unless x
  x + 1
end
def n9(x = g)
  if x.is_a?(Integer)
    x + 1
  end
end
def n10(x = g)
  [1].each do |i|
    next unless x
    p x + i
  end
end
def n11(x = g)
  x or return 0
  x + 1
end
def n12(x = g)
  return 0 if x == nil
  x + 1
end
def n13(x = g)
  y = x || 0
  y + 1
end
def n14(x = g)
  x = 3 if x.nil?
  x + 1
end
def n15(x = g)
  if !x.nil?
    x + 1
  end
end
def n16(x = g)
  while x
    return x + 1
  end
end
p n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16
