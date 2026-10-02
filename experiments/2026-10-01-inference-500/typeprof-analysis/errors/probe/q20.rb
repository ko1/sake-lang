orgs = Hash.new(0)
%w[a b a].each { |w| orgs[w] += 1 }
top = orgs.max_by { |_, n| n }
p top
p orgs["a"] + 1
