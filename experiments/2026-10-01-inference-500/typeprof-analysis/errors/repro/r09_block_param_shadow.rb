# A block parameter named like a local variable assigned later in the same scope gets that local's nil.
[1, 2].each { |v| p v + 1 }
v = "done"
puts v
