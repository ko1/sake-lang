# Reference implementation for test/sakelib/pqueue.rb: a priority queue on a binary heap, in plain Ruby.
# Like the pqueue gem, but the order is a keyword (order: :max or :min) over the elements' <=>; the
# gem's comparison block (PQueue.new { |a, b| a < b }) is also taken here, which the Sake port cannot do.

class PQueue
  attr_reader :order

  def initialize(elements = [], order: :max, &cmp)
    raise ArgumentError, "order must be :max or :min, not #{order.inspect}" unless order == :max || order == :min
    @order = order
    @cmp = cmp
    @heap = []
    elements.each { |x| push(x) }
  end

  def size = @heap.size
  alias length size
  def empty? = @heap.empty?
  def top = @heap.first
  alias peek top

  def push(*xs)
    xs.each do |x|
      @heap << x
      sift_up(@heap.size - 1)
    end
    self
  end

  def <<(x) = push(x)

  def pop
    return nil if @heap.empty?
    top = @heap.first
    last = @heap.pop
    unless @heap.empty?
      @heap[0] = last
      sift_down(0)
    end
    top
  end

  # The n first elements in pop order, removed.
  def shift(n)
    out = []
    while out.size < n && !empty?
      out << pop
    end
    out
  end

  def to_a
    return @heap.sort { |a, b| @cmp.call(a, b) ? -1 : 1 } if @cmp
    sorted = @heap.sort
    order == :max ? sorted.reverse : sorted
  end
  def each_pop
    yield pop until empty?
    self
  end

  def merge(other)
    other.to_a.each { |x| push(x) }
    self
  end

  def clear
    @heap.clear
    self
  end

  def inspect = "#<PQueue #{order} #{to_a.inspect}>"

  private

  def before?(a, b)
    return @cmp.call(a, b) if @cmp
    c = a <=> b
    raise ArgumentError, "comparison of #{a.inspect} with #{b.inspect} failed" unless c
    order == :max ? c > 0 : c < 0
  end

  def sift_up(i)
    while i > 0
      parent = (i - 1) / 2
      break unless before?(@heap[i], @heap[parent])
      @heap[i], @heap[parent] = @heap[parent], @heap[i]
      i = parent
    end
  end

  def sift_down(i)
    n = @heap.size
    loop do
      l = 2 * i + 1
      r = l + 1
      best = i
      best = l if l < n && before?(@heap[l], @heap[best])
      best = r if r < n && before?(@heap[r], @heap[best])
      break if best == i
      @heap[i], @heap[best] = @heap[best], @heap[i]
      i = best
    end
  end
end
