# `case x in Const` does not narrow x (case/when and `in Const => y` do).
def describe(v)
  case v
  in Integer then v.even? ? "even" : "odd"
  in String then v.upcase
  end
end
p describe(1)
p describe("a")
