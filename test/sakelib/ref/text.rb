# Reference implementation for test/sakelib/text.rb: string metrics and formatting in plain Ruby.
# Levenshtein and Soundex follow the text gem (Text::Levenshtein, Text::Soundex), JaroWinkler the
# jaro_winkler gem, WordWrap ActionView's word_wrap. The modules are top-level (no Text:: prefix) so
# that the Sake test reads the same.

module Text
  module Levenshtein
    module_function

    # Edit distance (insert, delete, substitute) over characters; with max_distance, a larger
    # distance is reported as max_distance.
    def distance(a, b, max_distance = nil)
      a => String
      b => String
      s = a.chars
      t = b.chars
      prev = (0..t.size).to_a
      s.each_with_index do |sc, i|
        cur = [i + 1]
        t.each_with_index do |tc, j|
          cost = sc == tc ? 0 : 1
          cur << [cur[j] + 1, prev[j + 1] + 1, prev[j] + cost].min
        end
        prev = cur
      end
      d = prev.last
      max_distance && d > max_distance ? max_distance : d
    end
  end

  module Soundex
    module_function

    CODES = { "B" => "1", "F" => "1", "P" => "1", "V" => "1",
              "C" => "2", "G" => "2", "J" => "2", "K" => "2", "Q" => "2", "S" => "2", "X" => "2", "Z" => "2",
              "D" => "3", "T" => "3", "L" => "4", "M" => "5", "N" => "5", "R" => "6" }

    # American Soundex: the first letter, then up to three digits; nil when there is no letter.
    def soundex(str)
      letters = str.upcase.gsub(/[^A-Z]/, "")
      return nil if letters.empty?
      out = letters[0]
      last = CODES[letters[0]]
      letters.chars.drop(1).each do |c|
        code = CODES[c]
        if code
          out << code if code != last
          last = code
        elsif c != "H" && c != "W"
          last = nil
        end
        break if out.size == 4
      end
      out.ljust(4, "0")
    end
  end
end

module JaroWinkler
  module_function

  def jaro_distance(s1, s2, ignore_case: false)
    a = ignore_case ? s1.downcase.chars : s1.chars
    b = ignore_case ? s2.downcase.chars : s2.chars
    return 1.0 if a.empty? && b.empty?
    return 0.0 if a.empty? || b.empty?
    window = [[a.size, b.size].max / 2 - 1, 0].max
    a_match = Array.new(a.size, false)
    b_match = Array.new(b.size, false)
    matches = 0
    a.each_with_index do |c, i|
      lo = [i - window, 0].max
      hi = [i + window, b.size - 1].min
      (lo..hi).each do |j|
        next if b_match[j] || b[j] != c
        a_match[i] = true
        b_match[j] = true
        matches += 1
        break
      end
    end
    return 0.0 if matches == 0
    as = a.select.with_index { |_, i| a_match[i] }
    bs = b.select.with_index { |_, j| b_match[j] }
    transpositions = as.zip(bs).count { |x, y| x != y } / 2
    m = matches.to_f
    (m / a.size + m / b.size + (m - transpositions) / m) / 3.0
  end

  # Jaro similarity, raised for a common prefix (up to 4 characters) when it is above threshold.
  def distance(s1, s2, ignore_case: false, weight: 0.1, threshold: 0.7)
    raise ArgumentError, "weight should not exceed 0.25" if weight > 0.25
    j = jaro_distance(s1, s2, ignore_case: ignore_case)
    return j if j <= threshold
    a = ignore_case ? s1.downcase : s1
    b = ignore_case ? s2.downcase : s2
    prefix = 0
    prefix += 1 while prefix < 4 && prefix < a.size && prefix < b.size && a[prefix] == b[prefix]
    j + prefix * weight * (1 - j)
  end
end

module WordWrap
  module_function

  # ActionView's word_wrap: break lines longer than line_width at whitespace.
  def word_wrap(text, line_width: 80, break_sequence: "\n")
    raise ArgumentError, "line_width must be positive" unless line_width > 0
    text.split("\n").map do |line|
      line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1#{break_sequence}").rstrip : line
    end.join(break_sequence)
  end
end
