h = { "a" => 1, "b" => 3 }
top = h.max_by { |_, n| n }
p top
top2 = h.max_by { |k, n| n }
p top2
