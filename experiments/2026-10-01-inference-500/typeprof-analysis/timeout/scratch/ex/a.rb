def expr
  node = 1
  loop do
    node = [:add, node, 2]
  end
  node
end
expr
