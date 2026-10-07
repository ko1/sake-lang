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

# Break long words
def break_words(words, width)
  result = []
  words.each do |word|
    while word.length > width
      result << word[0...width-1] + "-"
      word = word[width-1..-1]
    end
    result << word
  end
  result
end

# Layout paragraphs
output_lines = []
broken_paras = []

paragraphs.each do |para_words|
  broken_words = break_words(para_words, width)
  broken_paras << broken_words

  lines = []
  current_line = []

  broken_words.each do |word|
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
  lines.each_with_index do |line, idx|
    is_last = (idx == lines.length - 1)

    if line.length == 1 || is_last
      # Single word or last line: left-aligned
      text = line.join(" ")
      output_lines << text.ljust(width)
    else
      # Justify: distribute extra spaces
      words = line
      spaces_needed = width - words.map(&:length).sum
      gaps = words.length - 1

      extra_spaces_per_gap = spaces_needed / gaps
      extra_leftmost = spaces_needed % gaps

      parts = []
      words.each_with_index do |word, i|
        parts << word
        if i < words.length - 1
          spaces = 1 + extra_spaces_per_gap
          spaces += 1 if i < extra_leftmost
          parts << " " * spaces
        end
      end

      output_lines << parts.join
    end
  end
end

# Output
puts "+" + "-" * width + "+"

broken_paras.each_with_index do |_, para_idx|
  para_lines = []
  current_line = []

  broken_paras[para_idx].each do |word|
    test_line = current_line + [word]
    if test_line.join(" ").length <= width
      current_line = test_line
    else
      if !current_line.empty?
        para_lines << current_line
      end
      current_line = [word]
    end
  end

  if !current_line.empty?
    para_lines << current_line
  end

  para_lines.each_with_index do |line, idx|
    is_last = (idx == para_lines.length - 1)

    if line.length == 1 || is_last
      text = line.join(" ")
    else
      words = line
      spaces_needed = width - words.map(&:length).sum
      gaps = words.length - 1

      extra_spaces_per_gap = spaces_needed / gaps
      extra_leftmost = spaces_needed % gaps

      parts = []
      words.each_with_index do |word, i|
        parts << word
        if i < words.length - 1
          spaces = 1 + extra_spaces_per_gap
          spaces += 1 if i < extra_leftmost
          parts << " " * spaces
        end
      end

      text = parts.join
    end

    puts "|" + text.ljust(width) + "|"
  end

  # Separator between paragraphs
  if para_idx < broken_paras.length - 1
    puts "|" + " " * width + "|"
  end
end

puts "+" + "-" * width + "+"
puts "paragraphs: #{paragraphs.length}, lines: #{output_lines.length}, words: #{total_words}"
