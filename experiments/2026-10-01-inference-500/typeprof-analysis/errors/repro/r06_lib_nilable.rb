# Library methods typed T? (find, min_by, index, match, ...) used where the program knows a value exists.
xs = [3, 1, 2]
best = xs.min_by { |x| -x }
p best + 1
