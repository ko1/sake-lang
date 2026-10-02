# Errors of results-head that disappear when one change is applied alone (runs/S-*.jsonl).
require "json"
v0 = File.readlines(File.join(__dir__, "runs/V0.jsonl"))[0..-2].map { JSON.parse(_1) }.to_h { [_1["path"], _1["errors"].tally] }
Dir[File.join(__dir__, "runs/S-*.jsonl")].sort.each do |f|
  recs = File.readlines(f).map { JSON.parse(_1) }
  next puts("#{File.basename(f)}: not finished") unless recs.last["done"]
  gone = new = failed = 0
  recs[0..-2].each do |r|
    next failed += 1 if r["failed"]
    now = r["errors"].tally
    v0[r["path"]].each { |k, c| gone += [c - (now[k] || 0), 0].max }
    now.each { |k, c| new += [c - (v0[r["path"]][k] || 0), 0].max }
  end
  puts "#{File.basename(f, ".jsonl")}\tremoved #{gone}\tnew #{new}\tfailed programs #{failed}"
end
