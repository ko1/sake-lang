require "matrix"

include ExceptionForMatrix
ZeroVectorError = Vector::ZeroVectorError

def show(label, x) = puts("#{label}: #{x.inspect}")

# construction
a = Matrix[[1, 2], [3, 4]]
b = Matrix.columns([[5, 6], [7, 8]])
show("a", a)
show("b", b)
puts(a)
show("build", Matrix.build(2, 3) { |i, j| i * 10 + j })
show("identity", Matrix.identity(3))
show("unit", Matrix.unit(2))
show("zero", Matrix.zero(2))
show("scalar", Matrix.scalar(2, 7))
show("diagonal", Matrix.diagonal(1, 2, 3))
show("row_vector", Matrix.row_vector([1, 2, 3]))
show("column_vector", Matrix.column_vector(Vector[1, 2, 3]))
show("empty", Matrix.empty(0, 3))
show("empty.t", Matrix.empty(0, 3).transpose)
show("vstack", Matrix.vstack(a, b))
show("hstack", Matrix.hstack(a, b))

# access
show("a[0, 1]", a[0, 1])
show("a[-1, -1]", a[-1, -1])
show("a[5, 0]", a[5, 0])
show("element", a.element(1, 0))
show("row_count", a.row_count)
show("column_count", Matrix.build(2, 3) { |i, j| 0 }.column_count)
show("row", a.row(1))
show("column", a.column(0))
show("row out", a.row(2))
show("column out", a.column(-3))
show("row_vectors", a.row_vectors)
show("column_vectors", a.column_vectors)
show("to_a", a.to_a)
c = Matrix.rows(a.to_a)
c[0, 0] = 100
show("set", c)
show("a unchanged", a)
xs = []
a.each { |e| xs.push(e) }
show("each", xs)
a.each_with_index { |e, i, j| print("(#{i},#{j})=#{e} ") }
puts
show("map", a.map { |e| e * e })
m3 = Matrix[[2, 0, 1], [1, 3, 2], [1, 1, 2]]
show("minor", m3.minor(1, 2, 0, 2))
show("first_minor", m3.first_minor(0, 1))
show("cofactor", m3.cofactor(0, 1))
show("adjugate", m3.adjugate)

# arithmetic
show("a + b", a + b)
show("a - b", a - b)
show("a * b", a * b)
show("a * 2", a * 2)
show("a * 0.5", a * 0.5)
show("a * 1/3r", a * (1/3r))
show("a / 2", a / 2)
show("a / 2.0", a / 2.0)
show("a / b", a / b)
show("a * v", a * Vector[1, 1])
show("-a", -a)
show("a ** 0", a ** 0)
show("a ** 1", a ** 1)
show("a ** 5", a ** 5)
show("a ** -1", a ** -1)
show("a ** -2", a ** -2)
show("hadamard", a.hadamard_product(b))
show("rect * rect", Matrix.build(2, 3) { |i, j| i + j } * Matrix.build(3, 2) { |i, j| i * j + 1 })

# algebra
show("t", Matrix.build(2, 3) { |i, j| i * 3 + j }.t)
show("trace", m3.trace)
show("tr", (a * 1.5).tr)
show("det2", a.determinant)
show("det3", m3.det)
m4 = Matrix.build(4, 4) { |i, j| (i + 1) ** j }
show("det4", m4.det)
m5 = Matrix.build(5, 5) { |i, j| i == j ? 2 : (i - j) ** 2 }
show("det5", m5.det)
show("det5 float", (m5 * 0.1).det)
show("det5 rational", (m5 * (1/3r)).det)
show("det6 zero pivot", Matrix.build(6, 6) { |i, j| (i + j) % 6 == 0 ? 0 : i * j + 1 }.det)
show("det singular", Matrix.build(5, 5) { |i, j| i + j }.det)
show("det empty", Matrix.empty(0, 0).det)
show("det 1x1", Matrix[[7]].det)
show("det float3", Matrix[[1.5, 2.0, 0.1], [0.3, 4.0, 5.5], [6.0, 7.25, 8.0]].det)
show("inverse", m3.inverse)
show("inv float", Matrix[[4.0, 7.0], [2.0, 6.0]].inv)
show("inv rational", Matrix[[1/2r, 1/3r], [1/4r, 1/5r]].inverse)
hilbert = Matrix.build(4, 4) { |i, j| Rational(1, i + j + 1) }
show("hilbert inv", hilbert.inverse)
show("hilbert * inv", hilbert * hilbert.inverse == Matrix.identity(4))
show("inv pivot", Matrix[[0, 1], [1, 0]].inverse)
show("rank", m3.rank)
show("rank 1", Matrix[[1, 2], [2, 4]].rank)
show("rank 0", Matrix.zero(3).rank)
show("rank rect", Matrix.build(3, 5) { |i, j| i * j + j }.rank)
show("rank float", Matrix[[1.0, 2.0], [0.5, 1.0]].rank)
show("round", (m3 * 1.0).inverse.round(2))
show("round rational", (hilbert.inverse / 7).round(1))

# predicates
show("square?", a.square?)
show("square? rect", Matrix.build(2, 3) { |i, j| 0 }.square?)
show("empty?", Matrix.empty(2, 0).empty?)
show("zero?", Matrix.zero(2).zero?)
show("diagonal?", Matrix.diagonal(1, 2).diagonal?)
show("upper?", Matrix[[1, 2], [0, 3]].upper_triangular?)
show("lower?", Matrix[[1, 2], [0, 3]].lower_triangular?)
show("symmetric?", (a + a.transpose).symmetric?)
show("antisymmetric?", (a - a.transpose).antisymmetric?)
show("orthogonal?", Matrix[[0, 1], [-1, 0]].orthogonal?)
show("permutation?", Matrix[[0, 1], [1, 0]].permutation?)
show("singular?", Matrix[[1, 2], [2, 4]].singular?)
show("regular?", a.regular?)
show("==", a == Matrix[[1, 2], [3, 4]])
show("== float", a == a * 1.0)
show("!=", a != b)
show("empty ==", Matrix.empty(0, 2) == Matrix.empty(0, 3))

# vectors
v = Vector[1, 2, 3]
w = Vector[4, 5, 6]
show("v", v)
puts(v)
show("v[0]", v[0])
show("v[-1]", v[-1])
show("v[9]", v[9])
show("size", v.size)
show("v + w", v + w)
show("v - w", v - w)
show("v * 2", v * 2)
show("v / 2", v / 2)
show("v / 2.0", v / 2.0)
show("-v", -v)
show("inner_product", v.inner_product(w))
show("dot", v.dot(w))
show("cross", v.cross_product(w))
show("norm", Vector[3, 4].norm)
show("magnitude", v.magnitude)
show("r", Vector[1/2r, 1/2r].r)
show("normalize", Vector[3, 4].normalize)
show("angle 0", v.angle_with(v * 2))
show("angle pi", v.angle_with(-v))
show("angle", Vector[1, 0].angle_with(Vector[1, 1]).round(10))
show("to_a", v.to_a)
show("map", v.map { |e| e * 10 })
show("map2", v.map2(w) { |x, y| x * y })
s = 0
v.each { |e| s += e }
show("each", s)
v.each2(w) { |x, y| print(x + y, " ") }
puts
show("zero", Vector.zero(3))
show("zero?", Vector.zero(2).zero?)
show("basis", Vector.basis(size: 3, index: 1))
show("covector", v.covector)
show("to_matrix", v.to_matrix)
show("v * matrix", v * Matrix.row_vector([1, 2]))
show("v + col matrix", v + Matrix.column_vector([1, 1, 1]))
show("v ==", v == Vector[1, 2, 3])
show("v == float", v == Vector[1.0, 2.0, 3.0])
show("v != w", v != w)
show("round", Vector[1.234, 5.678].round(1))
u = Vector[1, 2]
u[1] = 20
show("set", u)
show("complex dot", Vector[Complex(1, 2), 3].inner_product(Vector[Complex(0, 1), 1]))
show("complex norm", Vector[Complex(3, 4)].norm)
show("empty vector", Vector[])

# aliases
show("component", a.component(0, 0))
show("row_size", a.row_size)
show("column_size", a.column_size)
show("+a", +a)
show("entrywise", a.entrywise_product(a))
show("v.element", v.element(1))
show("v.component", v.component(2))
show("+v", +v)
show("cross", w.cross(v))
show("collect", v.collect { |e| e - 1 })
show("to_matrix", a.to_matrix)

# errors
def try(label)
  begin
    show(label, yield)
  rescue ErrDimensionMismatch => e
    puts("#{label}: ErrDimensionMismatch: #{e.message}")
  rescue ErrNotRegular => e
    puts("#{label}: ErrNotRegular: #{e.message}")
  rescue ErrOperationNotDefined => e
    puts("#{label}: ErrOperationNotDefined: #{e.message}")
  rescue ZeroVectorError => e
    puts("#{label}: ZeroVectorError: #{e.message}")
  rescue ArgumentError => e
    puts("#{label}: ArgumentError: #{e.message}")
  rescue IndexError => e
    puts("#{label}: IndexError: #{e.message}")
  rescue RuntimeError => e
    puts("#{label}: RuntimeError: #{e.message}")
  end
end
rect = Matrix.build(2, 3) { |i, j| i + j }
try("ragged") { Matrix[[1, 2], [3]] }
try("a + rect") { a + rect }
try("a * rect.t") { a * rect * 1 }
try("rect * a") { rect * a }
try("a + 1") { a + 1 }
try("a - 1.5") { a - 1.5 }
try("det rect") { rect.det }
try("inverse singular") { Matrix[[1, 2], [2, 4]].inverse }
try("inverse rect") { rect.inverse }
try("rect ** 2") { rect ** 2 }
try("trace rect") { rect.trace }
try("singular ** -1") { Matrix.zero(2) ** -1 }
try("v + short") { v + Vector[1, 2] }
try("v * v") { v * w }
try("v / v") { v / w }
try("dot short") { v.inner_product(Vector[1]) }
try("normalize zero") { Vector.zero(3).normalize }
try("angle zero") { v.angle_with(Vector.zero(3)) }
try("basis") { Vector.basis(size: 3, index: 3) }
try("v[5] =") { v[5] = 1 }
try("empty") { Matrix.empty(2, 2) }
try("first_minor") { a.first_minor(2, 0) }
try("cofactor empty") { Matrix.empty(0, 0).cofactor(0, 0) }

# a use: Fibonacci by matrix power, and solving a system exactly
fib = Matrix[[1, 1], [1, 0]]
show("fib(90)", (fib ** 90)[0, 1])
sys = Matrix[[2, 1, -1], [-3, -1, 2], [-2, 1, 2]]
show("solve", sys.inverse * Vector[8, -11, -3])
