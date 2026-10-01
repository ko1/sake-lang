def pc(s)
  h, m = s.split(":").map(&:to_i)
  h * 60 + m
end
p pc("09:30")
