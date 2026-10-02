h = Hash.new(0); h["a"] += 1; p h.max_by { |k, v| v }
