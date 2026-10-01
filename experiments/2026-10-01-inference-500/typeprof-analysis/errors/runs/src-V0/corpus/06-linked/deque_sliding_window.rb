class DNode
  attr_accessor :value, :prev, :next

  def initialize(value, prev, nxt)
    @value = value
    @prev = prev
    @next = nxt
  end
end

class Deque
  attr_reader :length

  def initialize
    @front = nil
    @back = nil
    @length = 0
  end

  def empty? = @length == 0

  def push_back(v)
    node = DNode.new(v, @back, nil)
    if @back
      @back.next = node
    else
      @front = node
    end
    @back = node
    @length += 1
    self
  end

  def push_front(v)
    node = DNode.new(v, nil, @front)
    if @front
      @front.prev = node
    else
      @back = node
    end
    @front = node
    @length += 1
    self
  end

  def pop_front
    node = @front
    return nil unless node
    @front = node.next
    if @front
      @front.prev = nil
    else
      @back = nil
    end
    @length -= 1
    node.value
  end

  def pop_back
    node = @back
    return nil unless node
    @back = node.prev
    if @back
      @back.next = nil
    else
      @front = nil
    end
    @length -= 1
    node.value
  end

  def peek_front = @front&.value
  def peek_back = @back&.value

  def [](i)
    return nil if i >= @length || i < -@length
    if i < 0
      node = @back
      (-i - 1).times { node = node.prev }
    else
      node = @front
      i.times { node = node.next }
    end
    node.value
  end

  def to_s
    parts = []
    node = @front
    while node
      parts << node.value.inspect
      node = node.next
    end
    "<" + parts.join(", ") + ">"
  end
end

def sliding_max(xs, k)
  window = Deque.new
  out = []
  xs.each_with_index do |x, i|
    window.pop_front while !window.empty? && window.peek_front <= i - k
    window.pop_back while !window.empty? && xs[window.peek_back] <= x
    window.push_back(i)
    out << xs[window.peek_front] if i >= k - 1
  end
  out
end

def palindrome?(text)
  d = Deque.new
  text.downcase.each_char { |c| d.push_back(c) if c.match?(/[a-z0-9]/) }
  while d.length > 1
    return false if d.pop_front != d.pop_back
  end
  true
end

d = Deque.new
d.push_back(2).push_back(3)
d.push_front(1).push_front(0)
puts "deque #{d} length=#{d.length}"
puts "d[0]=#{d[0]} d[2]=#{d[2]} d[-1]=#{d[-1]} d[-4]=#{d[-4]} d[9]=#{d[9].inspect}"
puts "pop_back=#{d.pop_back} pop_front=#{d.pop_front} -> #{d}"
2.times { d.pop_back }
puts "emptied: #{d} front=#{d.peek_front.inspect} pop=#{d.pop_front.inspect}"

temps = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9]
[1, 3, 5].each do |k|
  puts "max over #{k}: #{sliding_max(temps, k).inspect}"
end

["A man, a plan, a canal: Panama", "deque", "Was it a car or a cat I saw?", "", "ab"].each do |s|
  puts "#{s.inspect} palindrome? #{palindrome?(s)}"
end

rotating = Deque.new
"abcdef".each_char { |c| rotating.push_back(c) }
4.times do |round|
  (round + 1).times { rotating.push_back(rotating.pop_front) }
  puts "rotate #{round + 1}: #{rotating}"
end
