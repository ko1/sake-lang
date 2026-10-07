#!/usr/bin/env ruby

lines = STDIN.readlines
if lines.empty?
  puts "invalid width"
  exit
end

width_str = lines[0].strip
if width_str !~ /^\d+$/
  puts "invalid width"
  exit
end

width = width_str.to_i
if width < 2 || width > 80
  puts "invalid width"
  exit
end

# Extract paragraphs (separated by blank lines)
paragraphs = []
current_para = []
in_blank = true

lines[1..-1].each do |line|
  words_in_line = line.split
  if words_in_line.empty?
    if !in_blank && !current_para.empty?
      paragraphs << current_para
      current_para = []
    end
    in_blank = true
  else
    in_blank = false
    current_para.concat(words_in_line)
  end
end

if !current_para.empty?
  paragraphs << current_para
end

# Count total words before breaking
total_words = paragraphs.flatten.length

# Break long words and layout
def break_and_layout(words, width)
  # Break long words
  broken = []
  words.each do |word|
    while word.length > width
      broken << word[0...width-1] + "-"
      word = word[width-1..-1]
    end
    broken << word
  end

  # Layout into lines
  lines = []
  current_line = []

  broken.each do |word|
    test_line = current_line + [word]
    if test_line.join(" ").length <= width
      current_line = test_line
    else
      if !current_line.empty?
        lines << current_line
      end
      current_line = [word]
    end
  end

  if !current_line.empty?
    lines << current_line
  end

  # Justify lines
  justified = []
  lines.each_with_index do |line, idx|
    is_last = (idx == lines.length - 1)

    if line.length == 1 || is_last
      # Single word or last line: left-aligned
      text = line.join(" ")
      justified << text.ljust(width)
    else
      # Justify: distribute spaces
      word_chars = line.map(&:length).sum
      total_spaces_needed = width - word_chars
      gaps = line.length - 1

      spaces_per_gap = total_spaces_needed / gaps
      extra_spaces = total_spaces_needed % gaps

      parts = []
      line.each_with_index do |word, i|
        parts << word
        if i < line.length - 1
          num_spaces = spaces_per_gap
          num_spaces += 1 if i < extra_spaces
          parts << " " * num_spaces
        end
      end

      justified << parts.join
    end
  end

  justified
end

# Output
puts "+" + "-" * width + "+"

output_lines = []
paragraphs.each_with_index do |para, para_idx|
  para_output = break_and_layout(para, width)
  output_lines.concat(para_output)

  para_output.each do |line|
    puts "|" + line + "|"
  end

  # Separator between paragraphs (but not after the last)
  if para_idx < paragraphs.length - 1
    puts "|" + " " * width + "|"
  end
end

puts "+" + "-" * width + "+"
puts "paragraphs: #{paragraphs.length}, lines: #{output_lines.length}, words: #{total_words}"
