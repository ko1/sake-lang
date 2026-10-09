require "stringio"
require_relative "ref/highline"

# The answers come from a StringIO, so the Sake program reads the same script.
input = StringIO.new([
  "Alice",            # Name?
  "abc", "200", "42", # Age? (not an Integer, out of range, ok)
  "1.75",             # Height?
  "ab1", "ABC",       # Code? (does not match, ok)
  "",                 # City? (the default)
  "",                 # Count? (the default)
  "",                 # Pick (a default after a newline)
  "maybe", "Y",       # Continue? (asked again, yes)
  "",                 # Really? (the default, no)
  "9", "2",           # Fruits (not a choice, banana)
  "b", "bl",          # ambiguous, blueberry
  "CHER",             # cherry, by a prefix in any case
  "mango",            # by its name
].join("\n") + "\n")
cli = HighLine.new(input, $stdout)

cli.say("Welcome")
cli.say("no newline here ")
cli.newline
cli.say(42)

name = cli.ask("Name? ")
p name
age = cli.ask("Age? ", Integer) { |q| q.in = 0..120 }
p age
p age + 1
height = cli.ask("Height (m)? ", Float) { |q| q.above = 0.0; q.below = 3.0 }
p height
code = cli.ask("Code? ") { |q| q.validate = /\A[A-Z]{3}\z/ }
p code
city = cli.ask("City? ") { |q| q.default = "Tokyo" }
p city
count = cli.ask("Count? ", Integer) { |q| q.default = 3 }
p count
pick = cli.ask("Pick\n") { |q| q.default = "x" }
p pick
ok = cli.agree("Continue? ")
p ok
p cli.agree("Really? ") { |q| q.default = "no" }
fruit = cli.choose do |menu|
  menu.header = "Fruits"
  menu.choices("apple", "banana", "cherry")
end
p fruit
p cli.choose("apple", "banana", "blueberry")
p cli.choose("apple", "banana", "cherry") { |menu| menu.prompt = "Which? " }
p cli.choose(:kiwi, :mango)
print cli.list(["a", 2, :c])
begin
  cli.ask("More? ")
rescue EOFError => e
  puts e.message
end

# the output as a StringIO
out = StringIO.new
cli2 = HighLine.new(StringIO.new("x\n5\n"), out)
p cli2.ask("Letter? ")
p cli2.ask("Digit?", Integer) { |q| q.above = 3 }
p out.string
p cli2.input == cli2.output
