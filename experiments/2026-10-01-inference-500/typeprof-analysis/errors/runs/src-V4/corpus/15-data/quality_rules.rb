module Rule
  def run(record)
    value = record[field]
    return nil if !value     && optional?
    return "#{field} is missing" if !value     || value == ""
    check(value)
  end

  def describe = "#{field} rule"
end

class RequiredRule
  include Rule
  attr_reader :field

  def initialize(field)
    @field = field
  end

  def optional? = false
  def check(v) = nil
  def describe = "#{field} required"
end

class RangeRule
  include Rule
  attr_reader :field, :min, :max

  def initialize(field, min, max)
    @field = field
    @min = min
    @max = max
  end

  def optional? = true

  def check(v)
    n = Float(v) rescue nil
    return "#{field}=#{v} is not a number" if !n    
    return "#{field}=#{v} outside #{min}..#{max}" if n < min || n > max
    nil
  end

  def describe = "#{field} in #{min}..#{max}"
end

class PatternRule
  include Rule
  attr_reader :field, :regexp, :label

  def initialize(field, regexp, label)
    @field = field
    @regexp = regexp
    @label = label
  end

  def optional? = true
  def check(v) = v.match?(regexp) ? nil : "#{field}=#{v.inspect} is not a valid #{label}"
  def describe = "#{field} looks like #{label}"
end

class OneOfRule
  include Rule
  attr_reader :field, :choices

  def initialize(field, choices)
    @field = field
    @choices = choices
  end

  def optional? = false
  def check(v) = choices.include?(v) ? nil : "#{field}=#{v} not in #{choices.join("/")}"
  def describe = "#{field} one of #{choices.size}"
end

def rules
  [
    RequiredRule.new("id"),
    PatternRule.new("email", /\A[^@\s]+@[^@\s]+\.[a-z]{2,}\z/, "email"),
    RangeRule.new("age", 0, 120),
    OneOfRule.new("country", %w[DE FR JP US BR]),
    PatternRule.new("zip", /\A\d{5}\z/, "zip code"),
    RangeRule.new("score", 0.0, 1.0)
  ]
end

def records
  text = <<~TXT
    id=1;email=ana@example.com;age=34;country=BR;zip=01310;score=0.82
    id=2;email=bob(at)example.com;age=27;country=US;zip=9410;score=0.4
    id=;email=chen@example.cn;age=41;country=CN;score=0.91
    id=4;email=dora@example.de;age=-3;country=DE;zip=10115;score=1.7
    id=5;age=fifty;country=FR;zip=75001
    id=6;email=eve@example.jp;age=22;country=JP;zip=10000;score=0.55
  TXT
  text.lines.map do |line|
    line.chomp.split(";").to_h do |pair|
      k, _sep, v = pair.partition("=")
      [k, v]
    end
  end
end

all_rules = rules
violations = []
records.each_with_index do |rec, i|
  all_rules.each do |rule|
    msg = rule.run(rec)
    violations << [i + 1, rule, msg] if msg
  end
end

data = records
puts "Checked #{data.size} records against #{all_rules.size} rules: #{violations.size} violations"
puts
by_record = violations.group_by { |row, rule, msg| row }
1.upto(data.size) do |row|
  list = by_record[row]
  id = data.fetch(row - 1)["id"]
  label = !id     || id == "" ? "(no id)" : "id #{id}"
  if !list    
    puts "record #{row} #{label}: ok"
  else
    puts "record #{row} #{label}: #{list.size} problem(s)"
    list.each { |r, rule, msg| puts "    - #{msg}" }
  end
end
puts
puts "By rule:"
all_rules.each do |rule|
  n = violations.count { |r, ru, m| ru == rule }
  rate = n * 100.0 / data.size
  puts format("  %-28s %2d failing (%3.0f%%)", rule.describe, n, rate)
end
clean = data.size - by_record.size
puts format("Clean records: %d of %d", clean, data.size)
