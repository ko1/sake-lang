def key(x) = x
h = {}
h[key(nil).to_s] = 1
p h.max_by { |k, v| v }
