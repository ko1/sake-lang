def a5(a)
  h, m = a
  h.foo
  m.bar
end
a5([1, 2, 3].map { _1 })
def a6(a)
  h, m = *a
  h.foo
  m.bar
end
a6([1, 2, 3].map { _1 })
def a7(a)
  h = a[0]
  h.foo
end
a7([1, 2, 3].map { _1 })
