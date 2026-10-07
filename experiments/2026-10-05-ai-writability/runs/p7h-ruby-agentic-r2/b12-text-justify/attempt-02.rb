#!/usr/bin/env ruby

# Read input
lines = STDIN.readlines.map(&:rstrip)

# Parse width
if lines.empty?
  puts "invalid width"
  exit
end

width_str = lines[0].strip
unless width_str.match?(/^\d+$/)
  puts "invalid width"
  exit
end

width = width_str.to_i
if width < 2 || width > 80
  puts "invalid width"
  exit
end

# Extract text lines (remaining lines)
text_lines = lines[1..-1] || []

# Extract words from text lines
paragraphs = []
current_paragraph = []
current_words = 0

text_lines.each do |line|
  words = line.split(/[\s\t]+/).reject(&:empty?)

  if words.empty?
    # Blank line - end of paragraph
    if current_paragraph.any?
      paragraphs << { words: current_paragraph.dup, count: current_words }
      current_paragraph.clear
      current_words = 0
    end
  else
    # Add words to current paragraph
    words.each do |word|
      current_paragraph << word
      current_words += 1
    end
  end
end

# Add the last paragraph if any
if current_paragraph.any?
  paragraphs << { words: current_paragraph.dup, count: current_words }
end

# Print top border
puts "+" + "-" * width + "+"

# Process and print paragraphs
total_lines = 0
total_words = paragraphs.sum { |p| p[:count] }

paragraphs.each_with_index do |para, para_idx|
  words = para[:words]

  # Break long words
  broken_words = []
  words.each do |word|
    while word.length > width
      broken_words << word[0, width - 1] + "-"
      word = word[width - 1..-1]
    end
    broken_words << word
  end

  # Fill lines greedily
  para_lines = []
  current_line = []

  broken_words.each do |word|
    if current_line.empty?
      current_line << word
    else
      # Calculate line length with single spaces
      test_length = current_line.join(" ").length + 1 + word.length
      if test_length <= width
        current_line << word
      else
        # Current line is full, save it and start new one
        para_lines << current_line
        current_line = [word]
      end
    end
  end

  # Add the last line
  para_lines << current_line if current_line.any?

  # Justify and print lines
  para_lines.each_with_index do |line_words, line_idx|
    is_last_line = (line_idx == para_lines.length - 1)

    if line_words.length == 1 || is_last_line
      # Single word or last line: left-align
      text = line_words.join(" ")
      padded = text + " " * (width - text.length)
    else
      # Multiple words, not last line: justify
      text_without_spaces = line_words.join("")
      gaps = line_words.length - 1
      total_word_length = text_without_spaces.length
      total_spaces_needed = width - total_word_length
      spaces_per_gap = total_spaces_needed / gaps
      extra_spaces = total_spaces_needed % gaps

      parts = []
      line_words.each_with_index do |word, idx|
        parts << word
        if idx < line_words.length - 1
          gap_spaces = spaces_per_gap + (idx < extra_spaces ? 1 : 0)
          parts << " " * gap_spaces
        end
      end
      padded = parts.join("")
    end

    puts "|" + padded + "|"
    total_lines += 1
  end

  # Print separator between paragraphs (except after the last one)
  if para_idx < paragraphs.length - 1
    puts "|" + " " * width + "|"
  end
end

# Print bottom border
puts "+" + "-" * width + "+"

# Print stats
puts "paragraphs: #{paragraphs.length}, lines: #{total_lines}, words: #{total_words}"
