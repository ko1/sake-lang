class Frame
  attr_reader :value, :min, :max, :below

  def initialize(value, min, max, below)
    @value = value
    @min = min
    @max = max
    @below = below
  end
end

class MinMaxStack
  attr_reader :size

  def initialize
    @top = nil
    @size = 0
  end

  def push(v)
    t = @top
    lo = t && t.min < v ? t.min : v
    hi = t && t.max > v ? t.max : v
    @top = Frame.new(v, lo, hi, t)
    @size += 1
    self
  end

  def pop
    t = @top
    return nil unless t
    @top = t.below
    @size -= 1
    t.value
  end

  def peek = @top&.value
  def min = @top&.min
  def max = @top&.max
  def empty? = @top.nil?
end

def spans(prices)
  st = MinMaxStack.new
  prices.each_with_index.map do |p, i|
    st.pop while !st.empty? && prices[st.peek] <= p
    prev = st.peek
    st.push(i)
    prev ? i - prev : i + 1
  end
end

def next_greater(xs)
  st = MinMaxStack.new
  out = Array.new(xs.size, -1)
  xs.each_with_index do |x, i|
    out[st.pop] = x while !st.empty? && xs[st.peek] < x
    st.push(i)
  end
  out
end

def largest_rectangle(heights)
  st = MinMaxStack.new
  best = 0
  best_at = nil
  i = 0
  n = heights.size
  while i <= n
    h = i < n ? heights[i] : 0
    if st.empty? || heights[st.peek] <= h
      st.push(i)
      i += 1
    else
      top = st.pop
      left = st.peek
      width = left ? i - left - 1 : i
      area = heights[top] * width
      if area > best
        best = area
        best_at = [left ? left + 1 : 0, width, heights[top]]
      end
    end
  end
  [best, best_at]
end

prices = [100, 80, 60, 70, 60, 75, 85, 90, 65, 95]
puts "prices: #{prices.inspect}"
puts "spans:  #{spans(prices).inspect}"
puts "next greater: #{next_greater(prices).inspect}"

window = MinMaxStack.new
prices.each do |p|
  window.push(p)
  puts format("push %3d  min %3d  max %3d  size %d", p, window.min, window.max, window.size)
end
4.times do
  v = window.pop
  puts format("pop  %3d  min %3d  max %3d", v, window.min, window.max)
end

[[2, 1, 5, 6, 2, 3], [6, 2, 5, 4, 5, 1, 6], [3, 3, 3], []].each do |hs|
  area, where = largest_rectangle(hs)
  if where
    start, width, height = where
    puts "#{hs.inspect} -> #{area} (from #{start}, width #{width}, height #{height})"
  else
    puts "#{hs.inspect} -> #{area}"
  end
end
empty = MinMaxStack.new
p [empty.pop, empty.min, empty.peek]
