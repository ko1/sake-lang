# usage: ruby tools/compare.rb features.tsv EXCLUDE_LIST -> per-feature: share of programs with feature>0 and median, timeout vs finished
rows = File.readlines(ARGV[0], chomp: true).map { _1.split("\t", -1) }
head = rows.shift
excl = ARGV[1] ? File.readlines(ARGV[1], chomp: true).map { _1.sub(%r{.*corpus/}, "") } : []
rows.reject! { excl.include?(_1[1]) }
t, f = rows.partition { _1[0] == "1" }
med = ->(a) { s = a.sort; s[s.size / 2] }
puts "n: timeout=#{t.size} finished=#{f.size} (excluded #{excl.size} crashed/OOM)"
puts "| feature | timeout: has it | finished: has it | timeout median | finished median |"
puts "|---|---|---|---|---|"
head[2..-2].each_with_index do |c, i|
  i += 2
  tv = t.map { _1[i].to_i }; fv = f.map { _1[i].to_i }
  puts "| #{c} | #{(100.0 * tv.count(&:positive?) / tv.size).round}% | #{(100.0 * fv.count(&:positive?) / fv.size).round}% | #{med[tv]} | #{med[fv]} |"
end
