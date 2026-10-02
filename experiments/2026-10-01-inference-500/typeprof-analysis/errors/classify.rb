# Final classification of every TypeProf error in results-head:
#   1. the counterfactual variant in which it first disappears (runs/attribution.tsv, from attribute.rb)
#   2. for errors no variant removes, static detectors (static.rb) on the source at the error position
#   3. hand labels (hand.tsv: path, error, label, note) override both
# usage: ruby classify.rb  -> classified.tsv, and a summary table on stdout
require "json"
require_relative "static"
EXP = File.expand_path("../..", __dir__)
VARIANT_CAUSE = {
  "V1" => "interface-nominal", "V2" => "numeric-catchall-overload", "V3" => "masgn-from-Array",
  "V4" => "sig-vertex-sharing", "V5" => "module_function", "V6" => "block-param-shadow",
  "V7" => "nil?-no-narrow", "V8" => "assign-in-cond-no-narrow", "V9" => "lib-nilable-return",
  "V10" => "user-nil", "V11" => "empty-arg",
}
hand = File.exist?(File.join(__dir__, "hand.tsv")) ?
  File.readlines(File.join(__dir__, "hand.tsv")).reject { _1.start_with?("#") || _1.strip.empty? }.to_h { r = _1.chomp.split("\t"); [[r[0], r[1]], r[2]] } : {}
rows = File.readlines(File.join(__dir__, "runs/attribution.tsv")).map { _1.chomp.split("\t") }
cache = {}
out = File.open(File.join(__dir__, "classified.tsv"), "w")
out.puts %w[path error variant static_cause final_cause source_line].join("\t")
summary = Hash.new { |h, k| h[k] = { n: 0, progs: {} } }
rows.each do |path, err, variant|
  src, root = cache[path] ||= begin
    s = File.read(File.join(EXP, path)); [s, Prism.parse(s).value]
  end
  f = Static.facts(root, src, err)
  st = if f[:module_function] then "module_function"
       elsif f[:destructured]&.any? then "nested-destructure-param"
       elsif f[:shadow]&.any? then "block-param-shadow"
       elsif f[:case_in] then "case-in-no-narrow"
       end
  final = hand[[path, err]] || VARIANT_CAUSE[variant] || (variant.start_with?("failed@") ? "counterfactual-run-failed" : nil) || st || "unclassified"
  line = src.lines[Locate.parse_err(err)[0] - 1].strip
  out.puts [path, err, variant, st || "-", final, line].join("\t")
  summary[final][:n] += 1
  summary[final][:progs][path] = true
end
out.close
summary.sort_by { -_2[:n] }.each { |k, v| puts "#{k}\t#{v[:n]}\t#{v[:progs].size}" }
puts "total\t#{summary.sum { _2[:n] }}"
