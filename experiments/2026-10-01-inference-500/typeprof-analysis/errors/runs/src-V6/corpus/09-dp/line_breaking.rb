class TooLongWord < StandardError
  attr_reader :word, :width

  def initialize(message, word, width)
    super(message)
    @word = word
    @width = width
  end
end

def badness(words, i, j, width)
  len = words[i..j].sum(&:size) + (j - i)
  return nil if len > width
  return 0 if j == words.size - 1
  (width - len)**3
end

# cost[i]: cheapest layout of words[i..]; brk[i]: index after the first line
def layout(words, width)
  words.each do |w|
    raise TooLongWord.new("word does not fit", w, width) if w.size > width
  end
  n = words.size
  cost = Array.new(n + 1, 0)
  brk = Array.new(n + 1, n)
  (n - 1).downto(0) do |i|
    best = nil
    (i...n).each do |j|
      b = badness(words, i, j, width)
      break if !b    
      total = b + cost[j + 1]
      if !best     || total < best
        best = total
        brk[i] = j + 1
      end
    end
    cost[i] = best
  end
  lines = []
  i = 0
  while i < n
    lines << words[i...brk[i]].join(" ")
    i = brk[i]
  end
  [cost[0], lines]
end

def greedy(words, width)
  lines = []
  current = ""
  words.each do |w|
    if current.empty?
      current = w
    elsif current.size + 1 + w.size <= width
      current = "#{current} #{w}"
    else
      lines << current
      current = w
    end
  end
  lines << current unless current.empty?
  lines
end

def raggedness(lines, width)
  lines[0...-1].sum { |line| (width - line.size)**3 }
end

def show(title, lines, width)
  puts "#{title} (cost #{raggedness(lines, width)})"
  puts "  +" + "-" * width + "+"
  lines.each { |l| puts "  |" + l.ljust(width) + "|" }
  puts "  +" + "-" * width + "+"
end

text = "Dynamic programming solves a problem by combining the solutions of overlapping subproblems, each solved once and stored for reuse, which turns many exponential searches into polynomial ones."
words = text.split(" ")

[24, 32].each do |width|
  cost, lines = layout(words, width)
  show("greedy, width #{width}", greedy(words, width), width)
  show("optimal, width #{width}", lines, width)
  puts "  dp cost #{cost} agrees" if cost == raggedness(lines, width)
end

short = "aaa bb cc ddddd".split(" ")
cost, lines = layout(short, 6)
p lines
p greedy(short, 6)

begin
  layout("a supercalifragilistic word".split(" "), 10)
rescue TooLongWord => e
  puts "#{e.message}: #{e.word.inspect} is wider than #{e.width}"
end
