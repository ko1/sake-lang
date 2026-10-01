b = []
b << [1, 2]
b.each { |s, f| p(s - f) }
c = []
c << [1, 2]
c.last[1] = 5
c.each { |s, f| p(s - f) }
d = [[1, 2]]
d.each { |s, f| p(s - f) }
e = [[1, 2], [3, 4]].map { |x, y| [x, y] }
e.each { |s, f| p(s - f) }
