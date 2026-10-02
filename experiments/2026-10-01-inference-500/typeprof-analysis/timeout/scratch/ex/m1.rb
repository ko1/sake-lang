def expr
  node = factor
  node = [:add, node, factor] if rand < 0.5
  node
end

def factor
  rand < 0.5 ? [:num, 1] : expr
end

p expr
