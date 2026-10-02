# TypeProf 0.31.1 never finishes on this (Ruby runs it fine and prints ["b", 2]).
p({"a" => 1, "b" => 2}.max_by { |k, v| v })
