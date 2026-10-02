# 6 precedence levels, like a recursive-descent parser building [:op, lhs, rhs] tuples
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
  node = level4
  node = [:op3, node, level4] while rand < 0.3
  node
end
def level4
  node = level5
  node = [:op4, node, level5] while rand < 0.3
  node
end
def level5
  node = level6
  node = [:op5, node, level6] while rand < 0.3
  node
end
def level6
  rand < 0.7 ? [:num, 1] : level1
end
p level1
