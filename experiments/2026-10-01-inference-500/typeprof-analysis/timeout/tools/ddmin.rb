# usage: ruby tools/ddmin.rb IN.rb OUT.rb [SECS=15]
# Line-based delta debugging: keep removing chunks of lines while the program still parses (Prism)
# and TypeProf still does not finish within SECS (judged by tools/tp; TIMEOUT or exit != 0 with RSS kill both count as "slow").
require "prism"
src, out, secs = ARGV[0], ARGV[1], (ARGV[2] || 15)
lines = File.readlines(src).reject { _1 =~ /\A\s*(#.*)?\n?\z/ }
tmp = out + ".try.rb"
slow = ->(ls) {
  s = ls.join
  next false unless Prism.parse(s).success?
  File.write(tmp, s)
  r = `#{__dir__}/tp -t #{secs} #{tmp}`
  r.start_with?("TIMEOUT")
}
abort "original is not slow" unless slow[lines]
n = 2
while lines.size >= 2
  chunk = (lines.size / n.to_f).ceil
  reduced = false
  (0...lines.size).step(chunk).each do |i|
    cand = lines[0...i] + lines[i + chunk..].to_a
    if slow[cand]
      lines = cand; n = [n - 1, 2].max; reduced = true
      $stderr.puts "#{lines.size} lines"; File.write(out, lines.join)
      break
    end
  end
  next if reduced
  break if chunk == 1
  n = [n * 2, lines.size].min
end
File.write(out, lines.join); File.delete(tmp) if File.exist?(tmp)
puts "#{lines.size} lines -> #{out}"
