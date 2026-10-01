# The variable assigned in a condition is not narrowed in the guarded branch.
def first_digit(s)
  if (m = s.match(/\d/))
    m[0]
  end
end
p first_digit("a1")
