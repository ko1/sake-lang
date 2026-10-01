class Edit
  attr_reader :op, :text, :old_line, :new_line

  def initialize(op, text, old_line, new_line)
    @op = op
    @text = text
    @old_line = old_line
    @new_line = new_line
  end

  def to_s
    mark = @op == :keep ? " " : (@op == :del ? "-" : "+")
    "#{mark} #{@text}"
  end
end

def lcs_table(a, b)
  n = a.size
  m = b.size
  t = Array.new(n + 1) { Array.new(m + 1, 0) }
  (n - 1).downto(0) do |i|
    (m - 1).downto(0) do |j|
      t[i][j] = if a[i] == b[j]
                  t[i + 1][j + 1] + 1
                else
                  [t[i + 1][j], t[i][j + 1]].max
                end
    end
  end
  t
end

def diff(a, b)
  t = lcs_table(a, b)
  edits = []
  i = 0
  j = 0
  while i < a.size && j < b.size
    if a[i] == b[j]
      edits << Edit.new(:keep, a[i], i + 1, j + 1)
      i += 1
      j += 1
    elsif t[i + 1][j] >= t[i][j + 1]
      edits << Edit.new(:del, a[i], i + 1, nil)
      i += 1
    else
      edits << Edit.new(:add, b[j], nil, j + 1)
      j += 1
    end
  end
  while i < a.size
    edits << Edit.new(:del, a[i], i + 1, nil)
    i += 1
  end
  while j < b.size
    edits << Edit.new(:add, b[j], nil, j + 1)
    j += 1
  end
  edits
end

def lcs_string(x, y)
  a = x.chars
  b = y.chars
  t = lcs_table(a, b)
  out = +""
  i = 0
  j = 0
  while i < a.size && j < b.size
    if a[i] == b[j]
      out << a[i]
      i += 1
      j += 1
    elsif t[i + 1][j] >= t[i][j + 1]
      i += 1
    else
      j += 1
    end
  end
  out
end

def show_diff(title, old_text, new_text)
  a = old_text.split("\n")
  b = new_text.split("\n")
  edits = diff(a, b)
  counts = Hash.new(0)
  edits.each { |e| counts[e.op] += 1 }
  puts "--- #{title}: #{counts[:keep]} same, #{counts[:del]} removed, #{counts[:add]} added"
  edits.each { |e| puts e }
  first_change = edits.find { |e| e.op != :keep }
  if first_change
    line = first_change.old_line || first_change.new_line
    puts "first change near line #{line}"
  else
    puts "no changes"
  end
end

old_src = "def greet(name)\n  puts \"hello\"\n  puts name\nend\n\ngreet(\"bob\")"
new_src = "def greet(name, punct)\n  puts \"hello\"\n  puts name + punct\nend\n\ngreet(\"bob\", \"!\")\ngreet(\"amy\", \"?\")"
show_diff("greet.rb", old_src, new_src)

list_a = "apples\nbread\nbutter\neggs\nmilk\ntea"
list_b = "bread\nbutter\ncheese\neggs\ntea\nyogurt"
show_diff("groceries", list_a, list_b)
show_diff("unchanged", list_a, list_a)

pairs = [["AGGTAB", "GXTXAYB"], ["dynamic", "programming"], ["kitten", "sitting"], ["abc", "xyz"]]
pairs.each do |x, y|
  common = lcs_string(x, y)
  puts format("lcs(%s, %s) = %-6s len %d", x, y, common.inspect, common.size)
end
