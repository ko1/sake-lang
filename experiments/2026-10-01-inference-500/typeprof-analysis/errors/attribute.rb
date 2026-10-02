# Attribute each error of results-head to the first counterfactual variant (runs/V*.jsonl) in which
# it disappears. Errors are multisets keyed by the full error line "(l,c)-(l,c):message".
# usage: ruby attribute.rb [V0 V1 ...]  -> runs/attribution.tsv (path, error, first variant without it or "residual")
require "json"
require "zlib"
EXP = File.expand_path("../..", __dir__)
names = ARGV.empty? ? Dir[File.join(__dir__, "runs/V*.jsonl")].map { File.basename(_1, ".jsonl") }.sort : ARGV
load_run = lambda do |n|
  recs = File.readlines(File.join(__dir__, "runs/#{n}.jsonl")).map { JSON.parse(_1) }
  abort "#{n}: not finished" unless recs.last["done"] == n
  recs[0..-2].to_h { [_1["path"], _1] }
end
runs = names.to_h { [_1, load_run.(_1)] }
head = Zlib::GzipReader.open(File.join(EXP, "results-head/typeprof.jsonl.gz")) { |z| z.each_line.map { JSON.parse(_1) } }
head = head.select { _1["errors"]&.any? }.to_h { [_1["path"], _1["errors"]] }

# harness check: V0 must reproduce results-head exactly
bad = head.count { |path, errs| runs["V0"][path]["errors"]&.sort != errs.sort }
$stderr.puts "V0 vs results-head: #{bad} programs differ"
out = File.open(File.join(__dir__, "runs/attribution.tsv"), "w")
tally = Hash.new(0)
newerr = Hash.new(0)
failed = Hash.new(0)
head.each do |path, errs|
  remaining = errs.tally
  first = {}
  names.drop(1).each do |n|
    rec = runs[n][path]
    if rec.nil? || rec["failed"]
      # the counterfactual could not be analyzed (TypeProf out of memory / time): what is still
      # unattributed cannot be attributed to this or any later variant
      failed[n] += 1
      remaining.each { |k, c| c.times { (first[k] ||= []) << "failed@#{n}" } if c > 0 }
      remaining.transform_values! { 0 }
      break
    end
    now = rec["errors"].tally
    newerr[n] += now.sum { |k, c| [c - (errs.tally[k] || 0), 0].max }
    remaining.each_key do |k|
      gone = remaining[k] - (now[k] || 0)
      next unless gone > 0
      first[k] ||= []
      gone.times { first[k] << n }
      remaining[k] -= gone
    end
  end
  errs.tally.each do |k, c|
    attrs = (first[k] || []) + ["residual"] * (c - (first[k] || []).size)
    attrs.each { |a| out.puts [path, k, a].join("\t"); tally[a] += 1 }
  end
end
out.close
tally.sort_by { names.index(_1[0]) || 99 }.each { |k, v| puts "#{k}\t#{v}" }
puts "errors not in results-head, per variant: #{newerr}"
puts "programs that failed, per variant: #{failed}"
