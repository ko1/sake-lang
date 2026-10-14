User = Struct.new(:name, :team, :email, :active)
Item = Struct.new(:name, :count, :price, :qty)
Event = Struct.new(:name, :time)
Cart = Struct.new(:items)
Result = Struct.new(:name, :score)

# R1
def low_stock(items)
  items.select { |i| i.count <= 5 }.map { |i| i.name }
end
p low_stock([Item.new("a", 5, 1, 1), Item.new("b", 2, 1, 1), Item.new("c", 9, 1, 1)])

# R2
def average(scores)
  return 0 if scores.empty?
  scores.sum / scores.size
end
p average([1, 2])

# R3
users = [User.new("a", "x", "A@x", true), User.new("b", "y", "a@x", false), User.new("c", "x", "c@x", true)]
counts = users.group_by { |u| u.team }.transform_values { |ms| ms.size }
counts.sort_by { |team, n| -n }.each do |team, n|
  puts "#{team}: #{n}"
end

# R4
def recent(events)
  events.sort_by { |e| e.time }.first(3).map { |e| e.name }
end
p recent([Event.new("e1", 1), Event.new("e2", 2), Event.new("e3", 3), Event.new("e4", 4)])

# R5
def unique_emails(users)
  users.map { |u| u.email.downcase }.uniq.size
end
p unique_emails(users)

# R6
def price(cart)
  total = cart.items.sum { |i| i.price * i.qty }
  total >= 10_000 ? total * 9 / 10 : total
end
p price(Cart.new([Item.new("a", 1, 5000, 2)]))

# G1
text = "to be or not to be to"
words = text.split
counts = words.tally
top = counts.max_by { |w, n| n }
puts top[0]

# G2
values = [1, 2, 3, 9, 1, 1, 4]
sums = values.each_slice(3).map { |r| r.sum }
puts sums.max

# G3
defaults = { "color" => "red", "size" => "M" }
prefs = { "color" => "blue" }
settings = defaults.merge(prefs)
settings.each { |k, v| puts "#{k}=#{v}" }

# G4
results = [Result.new("a", 70), Result.new("b", 40), Result.new("c", 59)]
passed, failed = results.partition { |r| r.score >= 60 }
puts "#{failed.size} failed"

# G5
names = users.select { |u| u.active }.map { |u| u.name }.sort
puts names.first(5).join(", ")

# G6
ns = ["ann", "bob"]
scores = [35, 72]
ns.zip(scores).each do |name, score|
  puts "#{name}: #{"*" * (score / 10)}"
end
