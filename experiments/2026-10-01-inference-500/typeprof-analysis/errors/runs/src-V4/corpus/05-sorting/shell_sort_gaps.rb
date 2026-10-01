# Shell sort with three gap sequences, compared by comparison counts on
# several input shapes.

module Gaps
  module_function

  def shell(n)
    gaps = []
    g = n / 2
    while g > 0
      gaps << g
      g /= 2
    end
    gaps
  end

  def knuth(n)
    gaps = []
    g = 1
    while g < n
      gaps.unshift(g)
      g = 3 * g + 1
    end
    gaps
  end

  def ciura(n)
    [701, 301, 132, 57, 23, 10, 4, 1].select { |g| g < n }
  end

  def sequence(name, n)
    case name
    in :shell then shell(n)
    in :knuth then knuth(n)
    in :ciura then ciura(n)
    end
  end
end

def shell_sort(input, gaps)
  a = input.dup
  compares = 0
  gaps.each do |gap|
    (gap...a.size).each do |i|
      x = a[i]
      j = i
      while j >= gap
        compares += 1
        break unless a[j - gap] > x
        a[j] = a[j - gap]
        j -= gap
      end
      a[j] = x
    end
  end
  [a, compares]
end

def lcg_list(n, seed, mod)
  x = seed
  Array.new(n) do
    x = (x * 1664525 + 1013904223) % 4294967296
    x % mod
  end
end

def shapes(n)
  random = lcg_list(n, 42, 10000)
  ascending = (0...n).to_a
  descending = ascending.reverse
  sawtooth = ascending.map { |i| i % 17 }
  few = lcg_list(n, 7, 4)
  almost = ascending.dup
  0.step(n - 2, 25) do |i|
    almost[i], almost[i + 1] = almost[i + 1], almost[i]
  end
  { "random" => random, "ascending" => ascending, "descending" => descending,
    "sawtooth" => sawtooth, "few-unique" => few, "almost" => almost }
end

n = 400
names = [:shell, :knuth, :ciura]
puts format("%-11s %8s %8s %8s", "input", "shell", "knuth", "ciura")
totals = Hash.new(0)
shapes(n).each do |label, data|
  expected = data.sort
  row = names.map do |name|
    sorted, compares = shell_sort(data, Gaps.sequence(name, n))
    raise "#{name} failed on #{label}" unless sorted == expected
    totals[name] += compares
    compares
  end
  puts format("%-11s %8d %8d %8d", label, *row)
end
best = names.min_by { |nm| totals[nm] }
puts "gaps for n=#{n}: knuth=#{Gaps.knuth(n)} ciura=#{Gaps.ciura(n)}"
puts "fewest comparisons overall: #{best} (#{totals[best]})"

words = "pear fig apple kiwi banana cherry date grape lime mango nectarine olive".split(" ")
sorted_words, c = shell_sort(words, Gaps.ciura(words.size))
puts "#{sorted_words.join(" ")} (#{c} comparisons)"
