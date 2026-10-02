# 3 precedence levels, like a recursive-descent parser building [:op, lhs, rhs] tuples
def level1
  node = level2
  node = [:op1, node, level2] while rand < 0.3
  node
end
def level2
  node = level3
  node = [:op2, node, level3] while rand < 0.3
  node
end
def level3
  rand < 0.7 ? [:num, 1] : level1
end
p level1
