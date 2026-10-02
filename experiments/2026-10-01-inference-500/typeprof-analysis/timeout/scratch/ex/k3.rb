def expr
  case rand(10)
  when 0 then [:num, 1]
  when 1 then [:op1, expr, expr]
  when 2 then [:op2, expr, expr]
  when 3 then [:op3, expr, expr]
  end
end
p expr
