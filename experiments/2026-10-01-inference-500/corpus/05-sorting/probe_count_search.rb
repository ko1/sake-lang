# Compare search strategies on sorted account numbers by how many array reads
# they make: linear, binary, interpolation, exponential (galloping), and
# jump search. Reads go through a counting wrapper type.

class Table
  attr_reader :data, :reads

  def initialize(data, reads)
    @data = data
    @reads = reads
  end

  def [](i)
    @reads += 1
    data.fetch(i)
  end

  def size = data.size
  def reset = @reads = 0
end

def linear(t, key)
  i = 0
  while i < t.size
    v = t[i]
    return i if v == key
    return nil if v > key
    i += 1
  end
  nil
end

def binary(t, key, lo, hi)
  while lo <= hi
    mid = (lo + hi) / 2
    v = t[mid]
    return mid if v == key
    if v < key
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  nil
end

def interpolation(t, key)
  lo = 0
  hi = t.size - 1
  while lo <= hi
    a = t[lo]
    b = t[hi]
    return nil if key < a || key > b
    return (a == key ? lo : nil) if a == b
    pos = lo + (key - a) * (hi - lo) / (b - a)
    v = t[pos]
    return pos if v == key
    if v < key
      lo = pos + 1
    else
      hi = pos - 1
    end
  end
  nil
end

def exponential(t, key)
  n = t.size
  return nil if n == 0
  return 0 if t[0] == key
  bound = 1
  bound *= 2 while bound < n && t[bound] < key
  binary(t, key, bound / 2, bound.clamp(0, n - 1))
end

def jump(t, key)
  n = t.size
  step = Integer.sqrt(n)
  prev = 0
  cur = step
  while cur < n && t[cur - 1] < key
    prev = cur
    cur += step
  end
  (prev...cur.clamp(0, n)).each do |i|
    v = t[i]
    return i if v == key
    return nil if v > key
  end
  nil
end

def run(method, t, key)
  t.reset
  idx = case method
        in :linear then linear(t, key)
        in :binary then binary(t, key, 0, t.size - 1)
        in :interpolation then interpolation(t, key)
        in :exponential then exponential(t, key)
        in :jump then jump(t, key)
        end
  [idx, t.reads]
end

def build(n)
  x = 1000
  Array.new(n) { |i| x += yield(i) }
end

methods = [:linear, :binary, :interpolation, :exponential, :jump]
datasets = {
  "uniform" => build(500) { |i| 7 },
  "skewed" => build(500) { |i| i * i / 50 + 1 },
  "lumpy" => build(500) { |i| i % 50 == 0 ? 400 : 1 }
}

datasets.each do |name, data|
  t = Table.new(data, 0)
  keys = [data[0], data[37], data[250], data[498], data.last + 3, data[100] + 1]
  totals = Hash.new(0)
  keys.each do |key|
    expected = data.index(key)
    methods.each do |m|
      idx, reads = run(m, t, key)
      raise "#{m} returned #{idx.inspect} for #{key}" if idx != expected
      totals[m] += reads
    end
  end
  puts "#{name}: #{methods.map { |m| format("%s=%d", m, totals[m]) }.join(" ")}"
end

t = Table.new(datasets["uniform"], 0)
begin
  t[500]
rescue IndexError
  puts "read past the end raises IndexError after #{t.reads} counted read(s)"
end
