# An autocomplete index: MSD radix sort of a word list (bucket per character),
# then prefix queries answered with two binary searches on the sorted list.

def char_at(s, d)
  return 0 if d >= s.size
  s[d].ord - 96
end

def msd_sort(words, d)
  return words if words.size <= 1
  buckets = Array.new(27) { [] }
  words.each { |w| buckets[char_at(w, d)] << w }
  out = buckets[0].dup
  1.upto(26) do |c|
    out.concat(msd_sort(buckets[c], d + 1))
  end
  out
end

def first_at_least(sorted, s)
  lo = 0
  hi = sorted.size
  while lo < hi
    mid = (lo + hi) / 2
    if sorted[mid] < s
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def complete(sorted, prefix, limit)
  start = first_at_least(sorted, prefix)
  stop = first_at_least(sorted, prefix + "{")   # "{" sorts right after "z"
  [stop - start, sorted[start...stop].take(limit)]
end

def normalize(text)
  text.downcase.split(/[^a-z]+/).reject(&:empty?)
end

def longest_common_prefix(a, b)
  n = 0
  n += 1 while n < a.size && n < b.size && a[n] == b[n]
  a[0...n]
end

text = "The quick brown fox jumps over the lazy dog. A quiet quarry quietly quits; " +
       "the dog dozes, the fox forages. Brown bread, brownies and broth: browse the bakery. " +
       "Jumping jacks, jumpers and jugglers join the joyful jamboree."

words = normalize(text).uniq
sorted = msd_sort(words, 0)
puts "#{sorted.size} distinct words"
puts "msd order matches builtin sort: #{sorted == words.sort}"
puts sorted.take(10).join(" ")

["qu", "brow", "j", "the", "x", "do"].each do |prefix|
  total, shown = complete(sorted, prefix, 4)
  more = total > shown.size ? " (+#{total - shown.size} more)" : ""
  puts format("%-5s -> %s%s", prefix, shown.join(", "), more)
end

freq = normalize(text).tally
best, count = freq.min_by { |w, n| [-n, w] }
puts "most frequent: #{best} x#{count}"

groups = sorted.chunk_while { |a, b| a[0] == b[0] }.to_a
widest = groups.max_by(&:size)
puts "largest initial-letter group: #{widest[0][0]} (#{widest.size} words)"
best_lcp = ""
sorted.each_cons(2) do |a, b|
  l = longest_common_prefix(a, b)
  best_lcp = l if l.size > best_lcp.size
end
puts "longest shared prefix between neighbours: #{best_lcp}"
