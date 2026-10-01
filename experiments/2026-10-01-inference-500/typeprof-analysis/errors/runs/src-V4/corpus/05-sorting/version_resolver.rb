# Package version resolution: parse version strings, sort them with
# segment-wise comparison (pre-releases before their release), and resolve
# constraints like "~> 2.3", ">= 1.4", "< 3" with binary search.

class Version
  include Comparable
  attr_reader :segments, :pre, :text

  def initialize(segments, pre, text)
    @segments = segments
    @pre = pre
    @text = text
  end

  def self.parse(s)
    m = s.match(/\A(\d+(?:\.\d+)*)(?:-([a-z]+\d*))?\z/)
    raise ArgumentError, "malformed version: #{s}" unless m
    Version.new(m[1].split(".").map(&:to_i), m[2], s)
  end

  def <=>(other)
    sa = segments
    sb = other.segments
    [sa.size, sb.size].max.times do |i|
      x = sa[i] || 0
      y = sb[i] || 0
      return x <=> y if x != y
    end
    return 0 if !pre     && !other.pre    
    return 1 if !pre    
    return -1 if !other.pre    
    pre <=> other.pre
  end

  def to_s = text
end

def bump(v)
  keep = v.segments.take(v.segments.size - 1)
  keep[-1] += 1
  Version.parse(keep.join("."))
end

def first_index(sorted)
  lo = 0
  hi = sorted.size
  while lo < hi
    mid = (lo + hi) / 2
    if yield(sorted[mid])
      hi = mid
    else
      lo = mid + 1
    end
  end
  lo
end

# Returns the half-open index range of versions satisfying one constraint.
def range_for(sorted, constraint)
  op, text = constraint.split(" ")
  v = Version.parse(text)
  case op
  in ">=" then [first_index(sorted) { |x| x >= v }, sorted.size]
  in ">" then [first_index(sorted) { |x| x > v }, sorted.size]
  in "<" then [0, first_index(sorted) { |x| x >= v }]
  in "<=" then [0, first_index(sorted) { |x| x > v }]
  in "~>" then [first_index(sorted) { |x| x >= v }, first_index(sorted) { |x| x >= bump(v) }]
  in "=" then [first_index(sorted) { |x| x >= v }, first_index(sorted) { |x| x > v }]
  end
end

def resolve(sorted, requirement, allow_pre)
  lo = 0
  hi = sorted.size
  requirement.split(",").each do |c|
    a, b = range_for(sorted, c.strip)
    lo = a if a > lo
    hi = b if b < hi
  end
  candidates = (sorted[lo...hi] || []).select { |v| allow_pre || !v.pre     }
  candidates.last
end

published = ["1.0", "1.2.0", "2.0.0-rc1", "1.10.1", "1.9.3", "2.0.0", "2.3.1", "1.4", "2.3.0",
             "2.10.0-beta2", "2.4.0", "3.0.0-alpha1", "2.3.10", "1.10.0", "2.9.9", "2.10.0"]
versions = published.map { |s| Version.parse(s) }.sort
puts "sorted: #{versions.join(" < ")}"
puts "as plain strings: #{published.sort.join(" ")}"
puts "newest: #{versions.max}, oldest: #{versions.min}"

requirements = ["~> 2.3", "~> 2.3.0", ">= 1.4, < 2", "< 3", "= 2.0.0", "> 2.10.0", "~> 1.9, >= 1.10"]
requirements.each do |req|
  picked = resolve(versions, req, false)
  with_pre = resolve(versions, req, true)
  extra = with_pre && (!picked     || with_pre > picked) ? " (pre-release: #{with_pre})" : ""
  puts format("%-18s -> %s%s", req, picked ? picked.to_s : "no match", extra)
end

["1.2.x", "2.0-RC1"].each do |bad|
  Version.parse(bad)
rescue ArgumentError => e
  puts e.message
end
puts "1.2 <=> 1.2.0: #{Version.parse("1.2") <=> Version.parse("1.2.0")}"
