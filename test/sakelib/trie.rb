require_relative "ref/trie"

t = Trie.new
["car", "cart", "carbon", "cat", "dog", "do", "door", "日本", "日本語"].each_with_index do |w, i|
  t.insert(w, i)
end
t["zebra"] = 100
p t.size
p t.empty?
p ["car", "ca", "cart", "carts", "do", "日本語", "zebra", ""].map { |w| t[w] }
p ["car", "ca", "dog", "dogs", ""].map { |w| t.include?(w) }
p ["ca", "x", "日", "door", ""].map { |w| t.starts_with?(w) }

# prefix search, in order
p t.prefix_search("car")
p t.prefix_search("do")
p t.prefix_search("日")
p t.prefix_search("x")
p t.keys
p t.to_a

# longest prefix
["cartoon", "carbonate", "ca", "doorway", "日本語学校", "zebras", "x", ""].each do |s|
  puts "#{s.inspect} -> #{t.longest_prefix(s).inspect}"
end

# replace and delete
p t.insert("car", 42)
p t["car"]
p t.size
p t.node_count
p t.delete("carbon")
p t.delete("carbon")
p t.delete("ca")
p t.delete("missing")
p t.node_count
p t.prefix_search("car")
p t.delete("do")
p t.include?("dog")
p t.include?("do")
p t.delete("dog")
p t.delete("door")
p t.starts_with?("d")
p t.size
p t.node_count
t.each { |k, v| puts "#{k}=#{v}" }

# a set of words: the value defaults to true; the empty key
words = Trie.new
"the then there these this that".split(" ").each { |w| words.insert(w) }
p words.prefix_search("the")
p words["this"]
p words.longest_prefix("thereafter")
p words.longest_prefix("")
words.insert("")
p words.longest_prefix("xyz")
p words.include?("")
p words.size

# errors
begin
  words.insert(["ok", :sym].fetch(1))
rescue NoMatchingPatternError
  puts "key must be a String"
end
