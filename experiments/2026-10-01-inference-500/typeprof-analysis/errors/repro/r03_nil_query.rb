# `x.nil?` / `x == nil` do not narrow; `!x` does.
def head(xs)
  x = xs.find { |v| v > 1 }
  return 0 if x.nil?
  x + 1
end
p head([1, 2])
