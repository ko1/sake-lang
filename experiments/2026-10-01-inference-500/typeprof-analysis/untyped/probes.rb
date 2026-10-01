def masgn(s)
  a, b = s.split(",")
  a
end
def partition_first(s)
  whole, _dot, frac = s.partition(".")
  whole.to_i * 100 + frac.to_i
end
def symproc(xs) = xs.map(&:to_i)
def captures(s)
  m = s.match(/(\d+)-(\d+)/)
  raise ArgumentError if m.nil?
  y, mo = m.captures.map(&:to_i)
  y * 12 + mo
end
def med(xs)
  s = xs.sort
  s.fetch(s.size / 2)
end
def ternary_float(n) = n.odd? ? 1.0 : 2.0 / 3
p masgn("x,y"), partition_first("12.5"), symproc(["1"]), captures("2026-10"), med([3, 1, 2]), ternary_float(3)
