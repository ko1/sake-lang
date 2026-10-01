def lerp((a, b)) = a + b
p lerp([1, 2])
[[1, 2]].each_with_index { |(a, b), i| p a + b + i }
[[1, 2]].each { |a, b| p a + b }
t = 0.5
q = 2 ** 3
r = t ** 2
s = 2 * t ** 2
p q, 1
p r + 1
p s + 1
n = [1, 2.5].first
p 2.0 * n
p n * 2.0
z = 0.0
z += 3 * n
p z
