# Accuracy and output tokens per model × condition × kind, then per item, from the run.rb logs.
require "json"
rows = ARGV.flat_map { |f| File.readlines(f).map { JSON.parse(_1) } }
pct = ->(rs) { rs.empty? ? "-" : format("%3d/%-3d %3.0f%%", rs.count { _1["ok"] }, rs.size, 100.0 * rs.count { _1["ok"] } / rs.size) }
tok = ->(rs) { rs.empty? ? "-" : format("%4.0f", rs.sum { _1["out_tokens"] } / rs.size.to_f) }
conds = ENV["CONDS"] ? ENV["CONDS"].split(",") : %w[ruby sake sake+primer]
rows.group_by { _1["model"] }.each do |m, rs|
  puts "== #{m}", format("%-8s %-22s %-22s %-22s", "kind", *conds)
  %w[review gist].each do |k|
    puts format("%-8s %-22s %-22s %-22s", k, *conds.map { |c| s = rs.select { _1["kind"] == k && _1["cond"] == c }; "#{pct[s]} #{tok[s]}t" })
  end
  rs.group_by { _1["id"] }.sort.each do |id, is|
    puts format("  %-4s %s", id, conds.map { |c| s = is.select { _1["cond"] == c }; "#{c}=#{s.count { _1["ok"] }}/#{s.size}" }.join("  "))
  end
end
