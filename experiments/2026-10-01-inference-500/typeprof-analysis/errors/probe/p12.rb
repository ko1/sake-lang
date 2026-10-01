def g = [1, 2].find { |v| v > 1 }
def a1
  if (m = g) && m
    m + 1
  end
end
def a2
  while (m = g)
    return m + 1
  end
end
def a3
  if (m = g)
    m + 1
  end
end
def a4
  return 0 unless (m = g)
  m + 1
end
p a1, a2, a3, a4
