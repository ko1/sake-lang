h = Hash.new(0)
["a"].each { |a| h[a] += 1 }
p h.max_by { |_, n| n }
