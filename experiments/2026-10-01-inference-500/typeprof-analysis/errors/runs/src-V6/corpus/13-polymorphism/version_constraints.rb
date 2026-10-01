class InvalidVersion < StandardError
  attr_reader :text
  def initialize(message, text)
    super(message)
    @text = text
  end
end

class Version
  include Comparable
  attr_reader :major, :minor, :patch, :pre

  def initialize(major, minor, patch, pre)
    @major = major
    @minor = minor
    @patch = patch
    @pre = pre
  end

  def self.parse(s)
    m = s.match(/\A(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.]+))?\z/)
    raise InvalidVersion.new("invalid version: #{s}", s) unless m
    minor = m[2]
    patch = m[3]
    Version.new(m[1].to_i, minor ? minor.to_i : 0, patch ? patch.to_i : 0, m[4])
  end

  def self.compare_pre(a, b)
    return 0 if !a     && !b    
    return 1 if !a    
    return -1 if !b    
    xs = a.split(".")
    ys = b.split(".")
    xs.zip(ys).each do |x, y|
      break if !y    
      xnum = x.match?(/\A\d+\z/)
      ynum = y.match?(/\A\d+\z/)
      c = if xnum && ynum
        x.to_i <=> y.to_i
      elsif xnum
        -1
      elsif ynum
        1
      else
        x <=> y
      end
      return c if c != 0
    end
    xs.size <=> ys.size
  end

  def <=>(b)
    c = @major <=> b.major
    c = @minor <=> b.minor if c == 0
    c = @patch <=> b.patch if c == 0
    c = Version.compare_pre(@pre, b.pre) if c == 0
    c
  end

  def bump(part)
    case part
    in :major then Version.new(@major + 1, 0, 0, nil)
    in :minor then Version.new(@major, @minor + 1, 0, nil)
    in :patch then Version.new(@major, @minor, @patch + 1, nil)
    end
  end

  def prerelease? = !!@pre    
  def to_s = @pre ? "#{@major}.#{@minor}.#{@patch}-#{@pre}" : "#{@major}.#{@minor}.#{@patch}"
end

class Requirement
  attr_accessor :op, :version, :parts

  def initialize(op, version, parts)
    @op = op
    @version = version
    @parts = parts
  end

  def self.parse(s)
    m = s.strip.match(/\A(>=|<=|>|<|=|~>)?\s*(\S+)\z/)
    raise InvalidVersion.new("invalid requirement: #{s}", s) unless m
    text = m[2]
    op = m[1] || "="
    Requirement.new(op, Version.parse(text), text.split(".").size)
  end

  def satisfied?(v)
    target = version
    case op
    in "=" then v == target
    in ">" then v > target
    in ">=" then v >= target
    in "<" then v < target
    in "<=" then v <= target
    in "~>"
      upper = parts <= 2 ? target.bump(:major) : target.bump(:minor)
      v >= target && v < upper
    end
  end

  def to_s = "#{op} #{version}"
end

def parse_constraint(s) = s.split(",").map { |part| Requirement.parse(part) }

def matches?(reqs, v) = reqs.all? { |r| r.satisfied?(v) }

def best_match(versions, constraint, allow_pre)
  reqs = parse_constraint(constraint)
  candidates = versions.select { |v| matches?(reqs, v) && (allow_pre || !v.prerelease?) }
  candidates.max
end

raw = ["1.0.0", "1.2.0", "1.2.10", "1.2.9", "1.10.0", "2.0.0-alpha", "2.0.0-alpha.1", "2.0.0-beta",
       "2.0.0-beta.2", "2.0.0-beta.11", "2.0.0-rc.1", "2.0.0", "2.1", "3", "x.y", "1.2.3.4", "2.0.1"]
versions = []
raw.each do |s|
  begin
    versions << Version.parse(s)
  rescue InvalidVersion => e
    puts "skip: #{e.message}"
  end
end

sorted = versions.sort
puts "sorted:"
sorted.each { |v| puts "  #{v}#{v.prerelease? ? " (pre)" : ""}" }
puts "newest: #{versions.max}"
stable = versions.reject(&:prerelease?)
puts "oldest stable: #{stable.min}"

constraints = ["~> 1.2", "~> 1.2.0", ">= 1.2, < 2", "> 2.0.0-beta", "= 2.1.0", "~> 2", "< 1.0", ">= 2.0.0-rc.1, <= 2.0.0"]
puts "constraints:"
constraints.each do |c|
  best = best_match(versions, c, false)
  best_pre = best_match(versions, c, true)
  shown = best ? best.to_s : "none"
  shown_pre = best_pre ? best_pre.to_s : "none"
  puts format("  %-26s stable=%-8s any=%s", c, shown, shown_pre)
end

puts "bumps of 1.2.9:"
base = Version.parse("1.2.9")
[:patch, :minor, :major].each { |part| puts "  #{part}: #{base.bump(part)}" }

puts "equal 2.1 vs 2.1.0: #{Version.parse("2.1") == Version.parse("2.1.0")}"
puts "1.2.10 > 1.2.9: #{Version.parse("1.2.10") > Version.parse("1.2.9")}"
puts "beta.11 > beta.2: #{Version.parse("2.0.0-beta.11") > Version.parse("2.0.0-beta.2")}"

begin
  parse_constraint(">= 1.0, ~> banana")
rescue InvalidVersion => e
  puts "bad constraint: #{e.message} (#{e.text})"
end

by_major = stable.group_by(&:major)
by_major.each { |maj, vs| puts "major #{maj}: #{vs.sort.join(", ")}" }
