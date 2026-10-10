# Reference implementation of semver (Semantic Versioning 2.0.0) in plain Ruby, for test/sakelib/semver.rb.
# SemVer: parse, compare, bump. SemVer::Requirement: Gem::Requirement-like constraints ("~> 1.2", ">= 1.0, < 2", "^1.2").

class SemVerError < StandardError; end

class SemVer
  include Comparable

  PATTERN = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\z/

  attr_reader :major, :minor, :patch, :pre, :build

  def initialize(major, minor, patch, pre = [], build = [])
    raise SemVerError, "version numbers must be Integers" unless [major, minor, patch].all?(Integer)
    raise SemVerError, "negative version number" if major < 0 || minor < 0 || patch < 0
    pre.each do |id|
      raise SemVerError, "invalid prerelease identifier: #{id.inspect}" unless id.match?(/\A(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)\z/)
    end
    @major, @minor, @patch, @pre, @build = major, minor, patch, pre, build
  end

  def self.parse(s)
    raise SemVerError, "not a String: #{s.inspect}" unless s.is_a?(String)
    m = PATTERN.match(s.strip)
    raise SemVerError, "invalid version: #{s.inspect}" unless m
    new(m[1].to_i, m[2].to_i, m[3].to_i, m[4] ? m[4].split(".") : [], m[5] ? m[5].split(".") : [])
  end

  def self.valid?(s)
    parse(s)
    true
  rescue SemVerError
    false
  end

  def prerelease? = !pre.empty?

  def <=>(other)
    return nil unless other.is_a?(SemVer)
    c = [major, minor, patch] <=> [other.major, other.minor, other.patch]
    return c unless c == 0
    SemVer.compare_pre(pre, other.pre)
  end

  def self.compare_pre(x, y)
    return 0 if x.empty? && y.empty?
    return 1 if x.empty?
    return -1 if y.empty?
    x.zip(y).each do |a, b|
      break if b.nil?
      c = compare_ident(a, b)
      return c unless c == 0
    end
    x.size <=> y.size
  end

  def self.compare_ident(a, b)
    na = a.match?(/\A\d+\z/)
    nb = b.match?(/\A\d+\z/)
    if na && nb then a.to_i <=> b.to_i
    elsif na then -1
    elsif nb then 1
    else a <=> b
    end
  end

  def bump(part)
    case part
    when :major then SemVer.new(major + 1, 0, 0)
    when :minor then SemVer.new(major, minor + 1, 0)
    when :patch then prerelease? ? SemVer.new(major, minor, patch) : SemVer.new(major, minor, patch + 1)
    when :pre
      if pre.empty?
        SemVer.new(major, minor, patch + 1, ["0"])
      elsif pre.last.match?(/\A\d+\z/)
        SemVer.new(major, minor, patch, pre[0...-1] + [(pre.last.to_i + 1).to_s])
      else
        SemVer.new(major, minor, patch, pre + ["0"])
      end
    else raise SemVerError, "unknown part: #{part.inspect}"
    end
  end

  def to_s
    s = "#{major}.#{minor}.#{patch}"
    s += "-#{pre.join(".")}" unless pre.empty?
    s += "+#{build.join(".")}" unless build.empty?
    s
  end

  def inspect = "#<SemVer #{self}>"

  def satisfies?(req) = SemVer::Requirement.parse(req).satisfied_by?(self)

  def self.max_satisfying(versions, req)
    r = SemVer::Requirement.parse(req)
    versions.select { |v| r.satisfied_by?(v) }.max
  end
end

class SemVer::Requirement
  OP = /\A(~>|>=|<=|!=|=|>|<|\^)?\s*(0|[1-9]\d*)(?:\.(0|[1-9]\d*))?(?:\.(0|[1-9]\d*))?(?:-([0-9A-Za-z.-]+))?\z/

  # Each constraint: [op, version, the number of segments written].
  attr_reader :constraints

  def initialize(constraints)
    @constraints = constraints
  end

  def self.parse(s)
    raise SemVerError, "not a String: #{s.inspect}" unless s.is_a?(String)
    parts = s.split(",").map(&:strip)
    raise SemVerError, "empty requirement" if parts.empty? || parts.any?(&:empty?)
    cs = parts.map do |part|
      m = OP.match(part)
      raise SemVerError, "invalid requirement: #{part.inspect}" unless m
      segs = m[4] ? 3 : (m[3] ? 2 : 1)
      v = SemVer.new(m[2].to_i, (m[3] || "0").to_i, (m[4] || "0").to_i, m[5] ? m[5].split(".") : [])
      [m[1] || "=", v, segs]
    end
    new(cs)
  end

  def self.upper(op, v, segs)
    if op == "~>"
      case segs
      when 1, 2 then SemVer.new(v.major + 1, 0, 0)
      else SemVer.new(v.major, v.minor + 1, 0)
      end
    elsif v.major > 0 then SemVer.new(v.major + 1, 0, 0)
    elsif v.minor > 0 then SemVer.new(0, v.minor + 1, 0)
    else SemVer.new(0, 0, v.patch + 1)
    end
  end

  def satisfied_by?(v)
    constraints.all? do |op, w, segs|
      case op
      when "=" then v == w
      when "!=" then v != w
      when ">" then v > w
      when "<" then v < w
      when ">=" then v >= w
      when "<=" then v <= w
      else v >= w && v < SemVer::Requirement.upper(op, w, segs)
      end
    end
  end

  def to_s
    constraints.map do |op, v, segs|
      "#{op} #{[v.major, v.minor, v.patch].first(segs).join(".")}#{v.prerelease? ? "-#{v.pre.join(".")}" : ""}"
    end.join(", ")
  end
end
