h = {}
(1..8).each { |n| h[n] = n }
p h.max_by { |k, v| v }
