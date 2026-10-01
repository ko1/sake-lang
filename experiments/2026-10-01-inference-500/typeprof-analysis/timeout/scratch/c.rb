def users_of(rows, feature)
  rows.filter_map { |id, plan, feats| feats.split(" ").include?(feature) ? id : nil }.to_set
end
rows = [["u01", "free", "search export"]]
s = users_of(rows, "search")
