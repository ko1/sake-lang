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
  rows.filter_map { |id, plan, feats| feats.split(" ").include?(feature) ? id : nil }.to_set
end

def label(s) = s.empty? ? "-" : s.sort.join(" ")

rows = responses
all = rows.map(&:first).to_set
s = users_of(rows, "search")
e = users_of(rows, "export")
y = users_of(rows, "sync")
puts "respondents: #{all.size}"
puts "search=#{s.size} export=#{e.size} sync=#{y.size}"

