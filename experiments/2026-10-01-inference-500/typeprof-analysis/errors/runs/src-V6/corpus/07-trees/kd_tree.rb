class Place
  attr_reader :name, :x, :y

  def initialize(name, x, y)
    @name = name
    @x = x
    @y = y
  end

  def coord(axis) = axis == 0 ? x : y
  def dist2(qx, qy) = (x - qx)**2 + (y - qy)**2
end

class KdNode
  attr_reader :place, :axis, :left, :right

  def initialize(place, axis, left, right)
    @place = place
    @axis = axis
    @left = left
    @right = right
  end
end

class Search
  attr_accessor :best, :best_d2, :visited

  def initialize(best, best_d2, visited)
    @best = best
    @best_d2 = best_d2
    @visited = visited
  end
end

def build(places, depth)
  return nil if places.empty?
  axis = depth % 2
  sorted = places.sort_by { |p| p.coord(axis) }
  mid = sorted.size / 2
  KdNode.new(sorted[mid], axis, build(sorted.take(mid), depth + 1), build(sorted.drop(mid + 1), depth + 1))
end

def nearest(node, x, y, st)
  return if !node    
  st.visited += 1
  p = node.place
  d2 = p.dist2(x, y)
  if !st.best     || d2 < st.best_d2
    st.best = p
    st.best_d2 = d2
  end
  diff = (node.axis == 0 ? x : y) - p.coord(node.axis)
  near, far = diff < 0 ? [node.left, node.right] : [node.right, node.left]
  nearest(near, x, y, st)
  nearest(far, x, y, st) if diff * diff < st.best_d2
end

def k_nearest(node, x, y, k, found)
  return found if !node    
  p = node.place
  d2 = p.dist2(x, y)
  i = found.find_index { |_q, qd| d2 < qd }
  if !i    
    found << [p, d2] if found.size < k
  else
    found.insert(i, [p, d2])
    found.pop if found.size > k
  end
  diff = (node.axis == 0 ? x : y) - p.coord(node.axis)
  near, far = diff < 0 ? [node.left, node.right] : [node.right, node.left]
  k_nearest(near, x, y, k, found)
  worst = found.size < k ? nil : found.last[1]
  k_nearest(far, x, y, k, found) if !worst     || diff * diff < worst
  found
end

def in_box(node, x0, y0, x1, y1, out)
  return out if !node    
  p = node.place
  out << p.name if p.x.between?(x0, x1) && p.y.between?(y0, y1)
  c = p.coord(node.axis)
  lo, hi = node.axis == 0 ? [x0, x1] : [y0, y1]
  in_box(node.left, x0, y0, x1, y1, out) if lo <= c
  in_box(node.right, x0, y0, x1, y1, out) if hi >= c
  out
end

def height(node) = !node     ? 0 : 1 + [height(node.left), height(node.right)].max

data = <<~CSV
  Lisbon,-9.14,38.72
  Madrid,-3.70,40.42
  Paris,2.35,48.86
  London,-0.13,51.51
  Dublin,-6.26,53.35
  Brussels,4.35,50.85
  Amsterdam,4.90,52.37
  Berlin,13.40,52.52
  Prague,14.42,50.08
  Vienna,16.37,48.21
  Rome,12.50,41.90
  Warsaw,21.01,52.23
  Budapest,19.04,47.50
  Copenhagen,12.57,55.68
  Stockholm,18.07,59.33
  Oslo,10.75,59.91
  Athens,23.73,37.98
  Zurich,8.54,47.37
CSV
places = data.each_line.map do |line|
  name, x, y = line.chomp.split(",")
  Place.new(name, x.to_f, y.to_f)
end
tree = build(places, 0)
puts "#{places.size} places, tree height #{height(tree)}, root #{tree.place.name}"

queries = [["Lyon", 4.84, 45.76], ["Hamburg", 9.99, 53.55], ["Milan", 9.19, 45.46], ["Porto", -8.61, 41.15], ["Helsinki", 24.94, 60.17]]
queries.each do |name, x, y|
  st = Search.new(nil, 0.0, 0)
  nearest(tree, x, y, st)
  brute = places.min_by { |p| p.dist2(x, y) }
  ok = st.best.name == brute.name ? "agrees" : "DIFFERS"
  puts format("%-9s -> %-10s dist %.2f  (visited %d of %d, brute force %s)",
              name, st.best.name, Math.sqrt(st.best_d2), st.visited, places.size, ok)
end

puts "-- 3 nearest to Frankfurt (8.68, 50.11) --"
k_nearest(tree, 8.68, 50.11, 3, []).each do |p, d2|
  puts format("  %-10s %.2f", p.name, Math.sqrt(d2))
end

puts "-- inside box lon 0..15, lat 47..53 --"
puts "  #{in_box(tree, 0.0, 47.0, 15.0, 53.0, []).sort.join(", ")}"
puts "-- inside box lon 20..30, lat 30..40 --"
found = in_box(tree, 20.0, 30.0, 30.0, 40.0, [])
puts "  #{found.empty? ? "(none)" : found.join(", ")}"
