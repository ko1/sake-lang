users = Hash.new(0)
%w[a b a].each { |w| users[w] += 1 }
active = users.max_by { |_, n| n }
p active
