# Feature-usage survey: Venn regions of three Sets, inclusion-exclusion check, and per-plan breakdowns.

def responses
  [
    ["u01", "free", "search export"], ["u02", "pro", "search sync api"], ["u03", "free", "search"],
    ["u04", "team", "sync api"], ["u05", "pro", "export sync"], ["u06", "free", ""],
    ["u07", "team", "search export sync api"], ["u08", "pro", "api"], ["u09", "free", "search sync"],
    ["u10", "team", "export"], ["u11", "pro", "search export sync"], ["u12", "free", "search export"]
  ]
end

def users_of(rows, feature)
  rows.filter_map { |e__0| id, plan, feats = e__0; feats.split(" ").include?(feature) ? id : nil }.to_set
end

def label(s) = s.empty? ? "-" : s.sort.join(" ")

rows = responses
all = rows.map(&:first).to_set
s = users_of(rows, "search")
e = users_of(rows, "export")
y = users_of(rows, "sync")
puts "respondents: #{all.size}"
puts "search=#{s.size} export=#{e.size} sync=#{y.size}"

regions = {
  "search only" => s - e - y,
  "export only" => e - s - y,
  "sync only" => y - s - e,
  "search+export" => (s & e) - y,
  "search+sync" => (s & y) - e,
  "export+sync" => (e & y) - s,
  "all three" => s & e & y,
  "none" => all - (s | e | y)
}
puts "== Venn regions =="
regions.each { |name, members| puts format("%-14s %2d  %s", name, members.size, label(members)) }

covered = regions.sum { |name, members| members.size }
puts "regions add up: #{covered == all.size}"
union_size = s.size + e.size + y.size - (s & e).size - (s & y).size - (e & y).size + (s & e & y).size
puts "inclusion-exclusion: #{union_size} == #{(s | e | y).size}"
overlapping = regions.keys.combination(2).select { |a, b| regions[a].intersect?(regions[b]) }
puts "overlapping regions: #{overlapping.size}"

puts "== Exactly k features (of search/export/sync) =="
counts = all.to_h { |u| [u, [s, e, y].count { |set| set.include?(u) }] }
(0..3).each do |k|
  who = counts.select { |u, n| n == k }.keys.sort
  puts "  #{k}: #{who.size} #{who.join(" ")}"
end

puts "== By plan =="
plans = rows.group_by { |e__1| id, plan, feats = e__1; plan }
plans.keys.sort.each do |plan|
  ids = plans[plan].map(&:first).to_set
  shares = [["search", s], ["export", e], ["sync", y]].map do |name, set|
    format("%s %3.0f%%", name, (ids & set).size * 100.0 / ids.size)
  end
  puts format("  %-5s n=%d  %s", plan, ids.size, shares.join("  "))
end

api = users_of(rows, "api")
puts "api users: #{label(api)}; all on paid plans? #{api.all? { |u| rows.any? { |id, plan, f| id == u && plan != "free" } }}"
puts "api users without sync: #{label(api - y)}"
feature_counts = rows.flat_map { |id, plan, feats| feats.split(" ") }.tally
puts "popularity: #{feature_counts.sort_by { |f, n| [-n, f] }.map { |f, n| "#{f}(#{n})" }.join(" ")}"
