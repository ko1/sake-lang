def key(x) = x
h = {}
h[key(nil).to_s.undefined_meth] = 1
p h.max_by { |k, v| v } rescue p $!.class
