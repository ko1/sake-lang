def expr
  rand < 0.5 ? [:num, 1] : [:add, expr, expr]
end
p expr
