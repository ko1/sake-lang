require "abbrev"

p(Abbrev.abbrev(["car", "cone"]))
p(Abbrev.abbrev(["ruby", "rules"]))
p(Abbrev.abbrev(["car", "box", "cone", "crab"], /b/))
p(Abbrev.abbrev(["car", "box", "cone"], "ca"))
p(Abbrev.abbrev(["car", "box", "cone"], /\Az/))
p(["list", "load", "lint"].abbrev)
p(Abbrev.abbrev([]))
p(Abbrev.abbrev(["", "a"]))
p(Abbrev.abbrev(["same", "same", "sam"]))
p(Abbrev.abbrev(["日本", "日曜"]))

# a command dispatcher: unique prefixes of command names
table = Abbrev.abbrev(["start", "stop", "status", "restart"])
["sta", "sto", "st", "re", "status", "x"].each do |input|
  cmd = table[input]
  puts("#{input} -> #{cmd ? cmd : "(ambiguous or unknown)"}")
end
