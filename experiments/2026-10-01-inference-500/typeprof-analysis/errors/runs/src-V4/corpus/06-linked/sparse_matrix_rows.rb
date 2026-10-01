class Entry
  attr_accessor :col, :val, :next

  def initialize(col, val, nxt)
    @col = col
    @val = val
    @next = nxt
  end
end

class DimensionError < StandardError
  attr_reader :left, :right

  def initialize(message, left, right)
    super(message)
    @left = left
    @right = right
  end
end

class Sparse
  attr_reader :ncols

  def self.from_dense(grid)
    m = Sparse.new(grid.size, grid[0].size)
    grid.each_with_index do |row, r|
      row.each_with_index { |v, c| m[[r, c]] = v if v != 0 }
    end
    m
  end

  def initialize(nrows, ncols)
    @rows = Array.new(nrows)
    @ncols = ncols
  end

  def nrows = @rows.size

  def [](rc)
    r, c = rc
    e = @rows[r]
    e = e.next while e && e.col < c
    e && e.col == c ? e.val : 0
  end

  def []=(rc, v)
    r, c = rc
    prev = nil
    e = @rows[r]
    while e && e.col < c
      prev = e
      e = e.next
    end
    if e && e.col == c
      if v == 0
        prev ? prev.next = e.next : @rows[r] = e.next
      else
        e.val = v
      end
    elsif v != 0
      fresh = Entry.new(c, v, e)
      prev ? prev.next = fresh : @rows[r] = fresh
    end
  end

  def each_in_row(r)
    e = @rows[r]
    while e
      yield e.col, e.val
      e = e.next
    end
  end

  def nonzeros
    n = 0
    nrows.times { |r| each_in_row(r) { n += 1 } }
    n
  end

  def +(other)
    raise DimensionError.new("cannot add #{shape} and #{other.shape}", shape, other.shape) if shape != other.shape
    out = Sparse.new(nrows, @ncols)
    nrows.times do |r|
      each_in_row(r) { |c, v| out[[r, c]] = v }
      other.each_in_row(r) { |c, v| out[[r, c]] += v }
    end
    out
  end

  def *(other)
    raise DimensionError.new("cannot multiply #{shape} by #{other.shape}", shape, other.shape) if @ncols != other.nrows
    out = Sparse.new(nrows, other.ncols)
    nrows.times do |r|
      each_in_row(r) do |k, v|
        other.each_in_row(k) { |c, w| out[[r, c]] += v * w }
      end
    end
    out
  end

  def transpose
    out = Sparse.new(@ncols, nrows)
    (nrows - 1).downto(0) do |r|
      each_in_row(r) { |c, v| out[[c, r]] = v }
    end
    out
  end

  def times_vector(xs)
    (0...nrows).map do |r|
      s = 0
      each_in_row(r) { |c, v| s += v * xs[c] }
      s
    end
  end

  def shape = "#{nrows}x#{@ncols}"

  def to_s
    (0...nrows).map { |r| (0...@ncols).map { |c| self[[r, c]].to_s.rjust(4) }.join }.join("\n")
  end
end

a = Sparse.from_dense([[1, 0, 0, 2], [0, 0, 3, 0], [0, 4, 0, 0]])
b = Sparse.from_dense([[0, 1], [5, 0], [0, 0], [2, 0]])
puts "A (#{a.shape}, #{a.nonzeros} nonzeros):"
puts a
puts "A^T:"
puts a.transpose
puts "A * B:"
puts a * b
puts "A + A:"
puts a + a
a[[0, 0]] = 0
a[[2, 3]] = 7
a[[1, 2]] = -3
puts "after edits (#{a.nonzeros} nonzeros):"
puts a
puts "A * [1,2,3,4] = #{a.times_vector([1, 2, 3, 4]).inspect}"
begin
  puts a * a
rescue DimensionError => e
  puts "error: #{e.message}"
end
begin
  puts a + b
rescue DimensionError => e
  puts "error: #{e.message} [#{e.left} vs #{e.right}]"
end

n = 30
band = Sparse.new(n, n)
n.times do |i|
  band[[i, i]] = 2
  band[[i, i + 1]] = -1 if i + 1 < n
  band[[i + 1, i]] = -1 if i + 1 < n
end
sq = band * band
puts "band #{band.shape}: #{band.nonzeros} nonzeros; squared: #{sq.nonzeros} nonzeros, trace #{(0...n).sum { |i| sq[[i, i]] }}"
ones = [1] * n
puts "band * ones = #{band.times_vector(ones).sum}"
