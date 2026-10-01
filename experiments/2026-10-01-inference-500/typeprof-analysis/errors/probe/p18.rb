a = [1, 2]
p(a.sum { |v| v * 1.5 })
b = [1, 2].map { _1 }
p(b.sum { |v| v * 1.5 })
p(b.sum(0.0) { |v| v * 1.5 })
