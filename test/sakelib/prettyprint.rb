require "prettyprint"

# Oppen's tree example (from Ruby's test/prettyprint): a node is "name" then its children in parentheses.
class Tree
  attr_reader :string, :children
  def initialize(string, children)
    @string = string
    @children = children
  end

  def show(q)
    q.group do
      q.text(@string)
      q.nest(@string.length) do
        unless @children.empty?
          q.text("[")
          q.nest(1) do
            first = true
            @children.each do |c|
              if first
                first = false
              else
                q.text(",")
                q.breakable
              end
              c.show(q)
            end
          end
          q.text("]")
        end
      end
    end
  end

  def altshow(q)
    q.group do
      q.text(@string)
      unless @children.empty?
        q.text("[")
        q.nest(2) do
          q.breakable
          first = true
          @children.each do |c|
            if first
              first = false
            else
              q.text(",")
              q.breakable
            end
            c.altshow(q)
          end
        end
        q.breakable
        q.text("]")
      end
    end
  end
end

def leaf(s) = Tree.new(s, [])

def tree
  Tree.new("aaaa", [
    Tree.new("bbbbb", [leaf("ccc"), leaf("dd")]),
    leaf("eee"),
    Tree.new("ffff", [leaf("gg"), leaf("hhh"), leaf("ii")])])
end

def hello(width)
  PrettyPrint.format(+"", width) do |q|
    q.group do
      q.group do
        q.group do
          q.group do
            q.text("hello")
            q.breakable
            q.text("a")
          end
          q.breakable
          q.text("b")
        end
        q.breakable
        q.text("c")
      end
      q.breakable
      q.text("d")
    end
  end
end

def tail_group(width)
  PrettyPrint.format(+"", width) do |q|
    q.group do
      q.group do
        q.text("abc")
        q.breakable
        q.text("def")
      end
      q.group do
        q.text("ghi")
        q.breakable
        q.text("jkl")
      end
    end
  end
end

def fill(width)
  PrettyPrint.format(+"", width) do |q|
    q.group do
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14].each do |i|
        q.text(i.to_s)
        q.fill_breakable if i < 14
      end
    end
  end
end

[79, 32, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1].each do |w|
  puts("--- tree #{w}")
  puts(PrettyPrint.format(+"", w) { |q| tree.show(q) })
end
[79, 30, 20, 15, 10].each do |w|
  puts("--- altshow #{w}")
  puts(PrettyPrint.format(+"", w) { |q| tree.altshow(q) })
end
[79, 12, 10, 7, 6, 1].each do |w|
  puts("--- hello #{w}")
  puts(hello(w))
end
[79, 11, 10, 5].each do |w|
  puts("--- tail_group #{w}")
  puts(tail_group(w))
end
[79, 20, 10, 2].each do |w|
  puts("--- fill #{w}")
  puts(fill(w))
end

# group with open/close text and an indent; breakable with its own separator and width; nest
puts("--- group/nest")
s = PrettyPrint.format(+"", 12) do |q|
  q.text("x = ")
  q.group(1, "[", "]") do
    q.text("alpha")
    q.text(",")
    q.breakable("  ", 2)
    q.text("beta")
    q.text(";")
    q.breakable("", 0)
    q.nest(4) do
      q.text("gamma")
      q.text(",")
      q.breakable
      q.text("delta")
    end
  end
end
puts(s)
# format appends to the given output and returns it; the newline can be changed
out = +"pre:"
r = PrettyPrint.format(out, 5, "|") do |q|
  q.text("aaa")
  q.breakable
  q.text("bbb")
end
p(r)
p(out == r)
# a width given to text overrides its length (e.g. for escape sequences)
p(PrettyPrint.format(+"", 6) { |q| q.text("123456789", 1); q.breakable; q.text("ab") })
# empty format; text only
p(PrettyPrint.format(+"", 10) { |q| nil })
p(PrettyPrint.format(+"", 1) { |q| q.text("toolong") })

# singleline_format: breakables are their separators
p(PrettyPrint.singleline_format(+"") { |q| q.text("a"); q.breakable; q.group(1, "(", ")") { q.text("b"); q.breakable("-"); q.text("c") } })

# PrettyPrint.new / text / breakable / flush / output
q = PrettyPrint.new(+"", 4)
q.text("ab")
q.breakable
q.text("cd")
p(q.output)
q.flush
p(q.output)
p([q.maxwidth, q.newline, q.indent])
q2 = PrettyPrint.new(+"")
p(q2.maxwidth)
