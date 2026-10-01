a = [1, 2, 3]
a << 4
p a.first + 1
p a[0] + 1
p a.find { |x| x > 1 } + 1
h = { a: 1 }
p h[:a] + 1
p a.max + 1
p a.min_by { |x| -x } + 1
m = "a1".match(/\d/)
p m[0]
p "a1"[/\d/].to_i
p a.sum + 1
p a.max_by { |x| x }.abs
