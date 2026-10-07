lines = STDIN.readlines
if lines.empty?
  puts "invalid width"
  exit
end

width_line = lines[0].strip
if width_line.empty? || width_line !~ /^\d+$/
  puts "invalid width"
  exit
end

width = width_line.to_i
if width < 2 || width > 80
  puts "invalid width"
  exit
end

# Extract all words
all_words = []
text_lines = lines[1..-1] || []

text_lines.each do |line|
  words = line.split(/[\s\t]+/).reject(&:empty?)
  all_words.concat(words)
end

# Break long words
pieces = []
all_words.each do |word|
  while word.length > width
    pieces << word[0...width-1] + "-"
    word = word[width-1..-1]
  end
  pieces << word if word.length > 0
end

# Identify paragraphs
paragraphs = []
current_paragraph = []

text_lines.each do |line|
  words = line.split(/[\s\t]+/).reject(&:empty?)
  if words.empty?
    if current_paragraph.any?
      paragraphs << current_paragraph
      current_paragraph = []
    end
  else
    current_paragraph.concat(words)
  end
end

if current_paragraph.any?
  paragraphs << current_paragraph
end

# Break words in paragraphs
paragraph_pieces = paragraphs.map do |para|
  para_pieces = []
  para.each do |word|
    w = word
    while w.length > width
      para_pieces << w[0...width-1] + "-"
      w = w[width-1..-1]
    end
    para_pieces << w if w.length > 0
  end
  para_pieces
end

# Lay out lines
output_lines = []
paragraph_pieces.each_with_index do |para_pieces, para_idx|
  para_lines = []
  current_line = []
  current_length = 0

  para_pieces.each do |piece|
    piece_len = piece.length
    if current_line.empty?
      current_line << piece
      current_length = piece_len
    elsif current_length + 1 + piece_len <= width
      current_line << piece
      current_length += 1 + piece_len
    else
      para_lines << current_line
      current_line = [piece]
      current_length = piece_len
    end
  end

  para_lines << current_line if current_line.any?

  # Justify lines
  para_lines.each_with_index do |line, line_idx|
    is_last_line = (line_idx == para_lines.length - 1)
    if line.length == 1 || is_last_line
      # Left-aligned
      text = line.join(" ")
      output_lines << text
    else
      # Justify
      text_content = line.join("")
      total_spaces = width - text_content.length
      gaps = line.length - 1
      spaces_per_gap = total_spaces / gaps
      extra_spaces = total_spaces % gaps

      justified = ""
      line.each_with_index do |word, idx|
        justified << word
        if idx < line.length - 1
          spaces = spaces_per_gap
          spaces += 1 if idx < extra_spaces
          justified << " " * spaces
        end
      end
      output_lines << justified
    end
  end

  # Add blank line between paragraphs
  if para_idx < paragraph_pieces.length - 1
    output_lines << ""
  end
end

# Output
puts "+" + "-" * width + "+"
output_lines.each do |line|
  padded = line.ljust(width)
  puts "|#{padded}|"
end
puts "+" + "-" * width + "+"

puts "paragraphs: #{paragraphs.length}, lines: #{output_lines.length}, words: #{all_words.length}"
