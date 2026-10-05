require_relative "ref/semver"

# parse and print
["1.2.3", "0.0.0", "10.20.30", "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0+build.7",
 "1.0.0-rc.1+exp.sha.5114f85", " 2.0.0 "].each do |s|
  v = SemVer.parse(s)
  puts "#{s.strip} -> #{v} major=#{v.major} minor=#{v.minor} patch=#{v.patch} pre=#{v.pre} build=#{v.build} prerelease?=#{v.prerelease?}"
end
p SemVer.parse("1.2.3")
p SemVer.new(1, 2, 3, ["beta", "2"])

# invalid versions
["1.2", "1.2.3.4", "01.2.3", "1.2.3-", "1.2.3-01", "v1.2.3", "1.2.3-a..b", "", "a.b.c"].each do |s|
  begin
    SemVer.parse(s)
    puts "#{s.inspect}: parsed?"
  rescue SemVerError => e
    puts "#{s.inspect}: #{e.message}"
  end
end
p ["1.2.3", "1.2", "x"].map { |s| SemVer.valid?(s) }
begin
  SemVer.parse(123)
rescue SemVerError => e
  puts e.message
end
begin
  SemVer.new(1, -1, 0)
rescue SemVerError => e
  puts e.message
end

# comparing: the precedence example of semver.org
order = ["1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta", "1.0.0-beta.2",
         "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0", "1.0.1", "1.1.0", "2.0.0"]
vs = order.map { |s| SemVer.parse(s) }
shuffled = [5, 0, 10, 3, 7, 1, 9, 2, 8, 4, 6].map { |i| vs.fetch(i) }
puts shuffled.sort.join(" < ")
p vs.each_cons(2).all? { |a, b| a < b }
p SemVer.parse("1.0.0+a") == SemVer.parse("1.0.0+b")
p SemVer.parse("1.0.0") <=> SemVer.parse("1.0.0-rc.1")
p SemVer.parse("1.2.3") <=> SemVer.parse("1.10.0")
p vs.max
p vs.min

# bump
v = SemVer.parse("1.2.3")
[:major, :minor, :patch, :pre].each { |part| puts "#{v} bump #{part} -> #{v.bump(part)}" }
["1.2.3-alpha", "1.2.3-alpha.1", "1.2.3-rc.9", "2.0.0+b"].each do |s|
  w = SemVer.parse(s)
  puts "#{w}: patch -> #{w.bump(:patch)}, pre -> #{w.bump(:pre)}"
end
begin
  v.bump(:micro)
rescue SemVerError => e
  puts e.message
end

# requirements
reqs = ["~> 1.2", "~> 1.2.3", "~> 1", ">= 1.0, < 2", "^1.2.3", "^0.2.3", "^0.0.3", "= 1.2.3",
        "!= 1.2.3", "> 1.2.3", "<= 1.2.3", "1.2.3", ">= 1.0.0-beta, < 1.0.0"]
cands = ["0.0.3", "0.0.4", "0.2.5", "0.3.0", "1.0.0-beta.2", "1.0.0", "1.2.0", "1.2.3",
         "1.2.9", "1.3.0", "1.9.9", "2.0.0-alpha", "2.0.0"].map { |s| SemVer.parse(s) }
reqs.each do |rs|
  r = SemVerRequirement.parse(rs)
  ok = cands.select { |c| r.satisfied_by?(c) }
  puts "#{rs} (#{r}): #{ok.join(" ")}"
end
p SemVer.parse("1.4.0").satisfies?("~> 1.2")
p SemVer.max_satisfying(cands, ">= 1.0, < 1.3")
p SemVer.max_satisfying(cands, "> 5")
["", "~>", ">= x", "1.2.3.4", ">= 1.0,", "=> 1.0"].each do |s|
  begin
    SemVerRequirement.parse(s)
    puts "#{s.inspect}: parsed?"
  rescue SemVerError => e
    puts "#{s.inspect}: #{e.message}"
  end
end
