def passage
  "It was the best of times, it was the worst of times, it was the age of wisdom, " \
  "it was the age of foolishness, it was the epoch of belief, it was the epoch of " \
  "incredulity, it was the season of Light, it was the season of Darkness."
end

def break_lines(words, width)
  lines = []
  current = []
  len = 0
  words.each do |w|
    needed = current.empty? ? w.size : len + 1 + w.size
    if needed > width && !current.empty?
      lines << current
      current = [w]
      len = w.size
    else
      current << w
      len = needed
    end
  end
  lines << current unless current.empty?
  lines
end

def justify_line(words, width)
  return words.first if words.size == 1
  letters = words.sum(&:size)
  gaps = words.size - 1
  spaces = width - letters
  base, extra = spaces.divmod(gaps)
  out = +""
  words.each_with_index do |w, i|
    out << w
    out << " " * (base + (i < extra ? 1 : 0)) if i < gaps
  end
  out
end

def align(words, width, mode, last)
  text = words.join(" ")
  case mode
  when :left then text
  when :right then text.rjust(width)
  when :center then text.center(width).rstrip
  when :justify then last ? text : justify_line(words, width)
  end
end

def badness(lines, width)
  total = 0
  lines.each_with_index do |words, i|
    next if i == lines.size - 1
    slack = width - words.join(" ").size
    total += slack * slack
  end
  total
end

def frame(rows, width)
  border = "+" + "-" * width + "+"
  puts border
  rows.each { |r| puts "|" + r.ljust(width) + "|" }
  puts border
end

words = passage.split(" ")
puts "words: #{words.size}, characters: #{passage.size}"
[30, 42].each do |width|
  lines = break_lines(words, width)
  puts "width #{width}: #{lines.size} lines, badness #{badness(lines, width)}"
  [:left, :right, :center, :justify].each do |mode|
    puts "[#{mode}]"
    rendered = lines.each_with_index.map { |ws, i| align(ws, width, mode, i == lines.size - 1) }
    frame(rendered, width)
  end
end
