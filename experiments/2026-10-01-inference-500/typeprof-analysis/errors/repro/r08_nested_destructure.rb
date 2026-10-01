# Nested destructuring parameters, in a def or a block, are typed nil.
def sum_pair((a, b)) = a + b
p sum_pair([1, 2])
[[1, 2]].each_with_index { |(x, y), i| p x * y + i }
