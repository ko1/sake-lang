# pal[i][j]: s[i..j] reads the same both ways
def palindrome_table(s)
  n = s.size
  pal = Array.new(n) { Array.new(n, false) }
  (n - 1).downto(0) do |i|
    i.upto(n - 1) do |j|
      pal[i][j] = true if s[i] == s[j] && (j - i < 2 || pal[i + 1][j - 1])
    end
  end
  pal
end

def longest_substring(s, pal)
  best_i = 0
  best_len = s.size > 0 ? 1 : 0
  pal.each_with_index do |row, i|
    row.each_with_index do |ok, j|
      if ok && j - i + 1 > best_len
        best_len = j - i + 1
        best_i = i
      end
    end
  end
  s[best_i, best_len]
end

def min_cut_partition(s, pal)
  n = s.size
  cuts = []
  start_of = []
  n.times do |j|
    best = nil
    from = 0
    0.upto(j) do |i|
      next unless pal[i][j]
      c = i == 0 ? 0 : cuts[i - 1] + 1
      if !best     || c < best
        best = c
        from = i
      end
    end
    cuts << best
    start_of << from
  end
  pieces = []
  j = n - 1
  while j >= 0
    i = start_of[j]
    pieces.unshift(s[i..j])
    j = i - 1
  end
  [n == 0 ? 0 : cuts[n - 1], pieces]
end

def longest_subsequence(s)
  n = s.size
  return "" if n == 0
  t = Array.new(n) { Array.new(n, 0) }
  (n - 1).downto(0) do |i|
    t[i][i] = 1
    (i + 1).upto(n - 1) do |j|
      t[i][j] = s[i] == s[j] ? t[i + 1][j - 1] + 2 : [t[i + 1][j], t[i][j - 1]].max
    end
  end
  left = +""
  middle = ""
  i = 0
  j = n - 1
  while i <= j
    if i == j
      middle = s[i]
      break
    elsif s[i] == s[j]
      left << s[i]
      i += 1
      j -= 1
    elsif t[i + 1][j] >= t[i][j - 1]
      i += 1
    else
      j -= 1
    end
  end
  left + middle + left.reverse
end

def normalize(text) = text.downcase.gsub(/[^a-z]/, "")

samples = %w[banana racecar aab abacdcaba noonabbad character x abcdef]
samples.each do |s|
  pal = palindrome_table(s)
  count = pal.sum { |row| row.count(true) }
  cuts, pieces = min_cut_partition(s, pal)
  puts s
  puts "  palindromic substrings: #{count}"
  puts "  longest substring:      #{longest_substring(s, pal)}"
  puts "  longest subsequence:    #{longest_subsequence(s)}"
  puts "  min cuts: #{cuts} -> #{pieces.join("|")}"
end

phrases = ["A man, a plan, a canal: Panama", "Never odd or even", "Dynamic programming"]
phrases.each do |phrase|
  letters = normalize(phrase)
  sub = longest_subsequence(letters)
  whole = sub == letters
  puts format("%-32s %-6s keep %2d/%2d letters", phrase.inspect, whole ? "yes" : "no", sub.size, letters.size)
end
