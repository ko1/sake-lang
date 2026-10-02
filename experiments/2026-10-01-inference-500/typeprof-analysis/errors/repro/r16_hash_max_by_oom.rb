# Not a false positive: TypeProf runs out of memory on this (ruby: ["a", 1]).
h = { "a" => 1 }
p h.max_by { |_, n| n }
