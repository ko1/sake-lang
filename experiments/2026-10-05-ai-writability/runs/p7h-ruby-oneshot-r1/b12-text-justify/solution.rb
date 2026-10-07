def read_width(first_line)
  line = first_line.strip

  if line.empty? || line !~ /^\d+$/
    return nil
  end

  w = line.to_i
  if w < 2 || w > 80
    return nil
  end

  w
end

def break_word(word, w)
  pieces = []
  while word.length > w
    pieces << word[0...w-1] + '-'
    word = word[w-1..-1]
  end
  pieces << word if word.length > 0
  pieces
end

def justify_line(words, w, is_last)
  if words.length == 1 || is_last
    line = words.join(' ')
    line.ljust(w)
  else
    word_length = words.sum(&:length)
    space_count = words.length - 1
    total_extra = w - word_length - space_count

    base_space = 1 + total_extra / space_count
    extra_gaps = total_extra % space_count

    result = ""
    words.each_with_index do |word, i|
      result += word
      if i < words.length - 1
        spaces = base_space
        spaces += 1 if i < extra_gaps
        result += ' ' * spaces
      end
    end
    result
  end
end

first_line = STDIN.readline.chomp
w = read_width(first_line)

if w.nil?
  puts "invalid width"
else
  lines = STDIN.readlines.map { |l| l.chomp }

  paragraphs = []
  current_paragraph_words = []

  lines.each do |line|
    words = line.split(/[ \t]+/).reject { |w| w.empty? }

    if words.empty?
      if current_paragraph_words.length > 0
        paragraphs << current_paragraph_words
        current_paragraph_words = []
      end
    else
      current_paragraph_words.concat(words)
    end
  end

  if current_paragraph_words.length > 0
    paragraphs << current_paragraph_words
  end

  pieces_per_paragraph = []
  total_words = 0

  paragraphs.each do |para_words|
    total_words += para_words.length
    pieces = []
    para_words.each do |word|
      if word.length > w
        pieces.concat(break_word(word, w))
      else
        pieces << word
      end
    end
    pieces_per_paragraph << pieces
  end

  total_text_lines = 0
  all_lines = []

  pieces_per_paragraph.each_with_index do |pieces, para_idx|
    para_lines = []
    current_line = []

    pieces.each do |piece|
      if current_line.empty?
        current_line << piece
      elsif (current_line.sum(&:length) + current_line.length + piece.length) <= w
        current_line << piece
      else
        para_lines << current_line
        current_line = [piece]
      end
    end

    if current_line.length > 0
      para_lines << current_line
    end

    para_lines.each_with_index do |words, line_idx|
      is_last = (line_idx == para_lines.length - 1)
      all_lines << justify_line(words, w, is_last)
    end

    total_text_lines += para_lines.length

    if para_idx < pieces_per_paragraph.length - 1
      all_lines << ' ' * w
    end
  end

  puts '+' + '-' * w + '+'
  all_lines.each do |line|
    puts '|' + line + '|'
  end
  puts '+' + '-' * w + '+'
  puts "paragraphs: #{pieces_per_paragraph.length}, lines: #{total_text_lines}, words: #{total_words}"
end
