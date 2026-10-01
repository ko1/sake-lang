require "set"

class Cons
  attr_accessor :head, :tail

  def initialize(head, tail)
    @head = head
    @tail = tail
  end
end

module L
  module_function

  def from(xs)
    list = nil
    xs.reverse_each { |x| list = Cons.new(x, list) }
    list
  end

  def to_a(list)
    out = []
    while list
      out << list.head
      list = list.tail
    end
    out
  end

  def show(list) = "(" + to_a(list).map(&:inspect).join(" ") + ")"

  def length(list)
    n = 0
    while list
      n += 1
      list = list.tail
    end
    n
  end

  def reverse(list)
    acc = nil
    while list
      nxt = list.tail
      list.tail = acc
      acc = list
      list = nxt
    end
    acc
  end

  def dedupe!(list)
    seen = Set.new
    prev = nil
    node = list
    while node
      if seen.include?(node.head)
        prev.tail = node.tail
      else
        seen << node.head
        prev = node
      end
      node = node.tail
    end
    list
  end

  def partition(list, pivot)
    low = nil
    high = nil
    while list
      nxt = list.tail
      if list.head < pivot
        list.tail = low
        low = list
      else
        list.tail = high
        high = list
      end
      list = nxt
    end
    [reverse(low), reverse(high)]
  end

  def kth_from_end(list, k)
    lead = list
    k.times do
      return nil unless lead
      lead = lead.tail
    end
    trail = list
    while lead
      lead = lead.tail
      trail = trail.tail
    end
    trail&.head
  end

  def palindrome?(list)
    n = length(list)
    return true if n < 2
    mid = list
    ((n + 1) / 2 - 1).times { mid = mid.tail }
    second = reverse(mid.tail)
    a = list
    b = second
    same = true
    while b
      same = false if a.head != b.head
      a = a.tail
      b = b.tail
    end
    mid.tail = reverse(second)
    same
  end

  def rotate_right(list, k)
    n = length(list)
    return list if n == 0 || k % n == 0
    cut = list
    (n - k % n - 1).times { cut = cut.tail }
    new_head = cut.tail
    cut.tail = nil
    last = new_head
    last = last.tail while last.tail
    last.tail = list
    new_head
  end

  def interleave(a, b)
    return b if !a    
    Cons.new(a.head, interleave(b, a.tail))
  end

  def fold(list, acc)
    while list
      acc = yield(acc, list.head)
      list = list.tail
    end
    acc
  end
end

nums = L.from([4, 8, 4, 1, 9, 8, 2, 7, 1, 3])
puts "nums       #{L.show(nums)} length #{L.length(nums)}"
puts "3rd last   #{L.kth_from_end(nums, 3)}; 11th last #{L.kth_from_end(nums, 11).inspect}"
L.dedupe!(nums)
puts "deduped    #{L.show(nums)}"
low, high = L.partition(nums, 5)
puts "< 5        #{L.show(low)}"
puts ">= 5       #{L.show(high)}"
puts "sum/max    #{L.fold(low, 0) { |a, x| a + x }} / #{L.fold(high, 0) { |a, x| [a, x].max }}"
joined = L.interleave(low, high)
puts "interleave #{L.show(joined)}"
[1, 3, 7, 0].each do |k|
  joined = L.rotate_right(joined, k)
  puts "rotate #{k}   #{L.show(joined)}"
end
puts "reversed   #{L.show(L.reverse(joined))}"

["racecar", "level up", "abba", "abca", "x", ""].each do |w|
  chars = L.from(w.chars)
  result = L.palindrome?(chars)
  puts format("%-10s palindrome=%-5s intact=%s", w.inspect, result, L.to_a(chars).join == w)
end

words = L.from("pear apple pear fig apple kiwi fig plum".split(" "))
L.dedupe!(words)
short, long = L.partition(words, "g")
puts "words      #{L.show(words)}"
puts "before g   #{L.show(short)}, from g #{L.show(long)}"
puts "lengths    #{L.fold(L.interleave(short, long), "") { |acc, w| acc + w.size.to_s }}"
puts "empty      #{L.show(L.rotate_right(nil, 3))} #{L.palindrome?(nil)} #{L.kth_from_end(nil, 1).inspect}"
