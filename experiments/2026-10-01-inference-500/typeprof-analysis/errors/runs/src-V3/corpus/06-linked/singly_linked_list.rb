class Node
  attr_accessor :value, :next

  def initialize(value, nxt)
    @value = value
    @next = nxt
  end
end

class LinkedList
  attr_reader :head, :tail, :size

  def initialize
    @head = nil
    @tail = nil
    @size = 0
  end

  def push_front(v)
    node = Node.new(v, @head)
    @head = node
    @tail = node if @tail.nil?
    @size += 1
    self
  end

  def push_back(v)
    node = Node.new(v, nil)
    if @tail
      @tail.next = node
    else
      @head = node
    end
    @tail = node
    @size += 1
    self
  end

  def pop_front
    h = @head
    return nil unless h
    @head = h.next
    @tail = nil if @head.nil?
    @size -= 1
    h.value
  end

  def each
    node = @head
    while node
      yield node.value
      node = node.next
    end
    self
  end

  def to_a
    out = []
    each { |v| out << v }
    out
  end

  def find(target)
    index = 0
    node = @head
    while node
      return index if node.value == target
      index += 1
      node = node.next
    end
    nil
  end

  def remove(target)
    prev = nil
    node = @head
    while node
      if node.value == target
        nxt = node.next
        if prev
          prev.next = nxt
        else
          @head = nxt
        end
        @tail = prev if node.equal?(@tail)
        @size -= 1
        return true
      end
      prev = node
      node = node.next
    end
    false
  end

  def reverse!
    prev = nil
    node = @head
    @tail = node
    while node
      nxt = node.next
      node.next = prev
      prev = node
      node = nxt
    end
    @head = prev
    self
  end

  def insert_sorted(v)
    return push_front(v) if @head.nil? || v <= @head.value
    node = @head
    node = node.next while node.next && node.next.value < v
    fresh = Node.new(v, node.next)
    node.next = fresh
    @tail = fresh if fresh.next.nil?
    @size += 1
    self
  end

  def to_s = "(" + to_a.join(" -> ") + ")"
end

list = LinkedList.new
[3, 1, 4, 1, 5].each { |x| list.push_back(x) }
list.push_front(9)
puts "list: #{list} size=#{list.size}"
puts "find 4: #{list.find(4).inspect}"
puts "find 7: #{list.find(7).inspect}"
puts "remove 1: #{list.remove(1)} -> #{list}"
puts "remove 5 (tail): #{list.remove(5)} -> #{list}"
puts "remove 42: #{list.remove(42)}"
list.push_back(6)
puts "after push_back 6: #{list} tail=#{list.tail.value}"
list.reverse!
puts "reversed: #{list} tail=#{list.tail.value}"
popped = []
popped << list.pop_front while list.size > 2
puts "popped #{popped.inspect}, left #{list}"

sorted = LinkedList.new
[50, 20, 80, 20, 10, 90, 60].each { |x| sorted.insert_sorted(x) }
puts "sorted: #{sorted}"
total = 0
sorted.each { |v| total += v }
puts "sum=#{total} size=#{sorted.size}"

words = LinkedList.new
"the quick brown fox".split(" ").each { |w| words.push_front(w.upcase) }
puts "words: #{words}"
print words.pop_front, ";" while words.size > 0
puts
p words.pop_front
