# Full-justification text layout inside a frame.
def pieces(word, width)
  out = []
  while word.size > width
    out << "#{word[0, width - 1]}-"
    word = word[(width - 1)..]
  end
  out << word
end

def layout(words, width)
  lines = []
  cur = []
  len = 0
  words.each do |w|
    if cur.any? && len + 1 + w.size > width
      lines << cur
      cur = []
      len = 0
    end
    len += cur.empty? ? w.size : 1 + w.size
    cur << w
  end
  lines << cur unless cur.empty?
  lines.each_with_index.map do |ws, i|
    next ws.join(" ") if i == lines.size - 1 || ws.size == 1
    gaps = ws.size - 1
    extra = width - ws.sum(&:size)
    ws.each_with_index.map { |w, j| j < gaps ? w + " " * (extra / gaps + (j < extra % gaps ? 1 : 0)) : w }.join
  end
end

first = $stdin.gets
width = first&.strip
unless width&.match?(/\A\d+\z/) && (2..80).cover?(width.to_i)
  puts "invalid width"
  exit
end
width = width.to_i

paras = [[]]
$stdin.each_line do |line|
  ws = line.chomp.split(/[ \t]+/).reject(&:empty?)
  if ws.empty?
    paras << [] unless paras.last.empty?
  else
    paras.last.concat(ws)
  end
end
paras.pop if paras.last.empty?

words = paras.sum(&:size)
puts "+#{'-' * width}+"
count = 0
paras.each_with_index do |ws, i|
  puts "|#{' ' * width}|" if i > 0
  layout(ws.flat_map { |w| pieces(w, width) }, width).each do |l|
    puts "|#{l.ljust(width)}|"
    count += 1
  end
end
puts "+#{'-' * width}+"
puts "paragraphs: #{paras.size}, lines: #{count}, words: #{words}"
