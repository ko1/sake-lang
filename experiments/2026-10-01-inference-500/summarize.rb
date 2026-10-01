# frozen_string_literal: true

# Summarizes the outputs of run.sh into Markdown.
# usage: ruby summarize.rb OUTDIR   (reads sake.jsonl, typeprof.jsonl, strict.tsv; prints Markdown)
require "json"
require "zlib"

dir = ARGV.fetch(0)
CLASSES = %w[mono nilable union partial unknown none].freeze
UNITS = %w[expr.var expr.call sig.param sig.ret sig.field].freeze

def load(path)
  return Zlib::GzipReader.open("#{path}.gz") { |z| z.readlines.map { JSON.parse(_1) } } if File.exist?("#{path}.gz")
  File.exist?(path) ? File.readlines(path).map { JSON.parse(_1) } : []
end
def domain(path) = File.basename(File.dirname(path))
def pct(n, d) = d.zero? ? "-" : format("%.1f%%", 100.0 * n / d)

def table(rows, units)
  out = +"| unit | n | #{CLASSES.join(" | ")} | determined |\n|---|---|#{"---|" * CLASSES.size}---|\n"
  units.each do |u|
    c = Hash.new(0)
    rows.each { |r| r.dig("counts", u)&.each { |k, v| c[k] += v } }
    n = c.values.sum
    reached = n - c["none"]
    det = c["mono"] + c["nilable"] + c["union"]
    out << "| #{u} | #{n} | #{CLASSES.map { "#{c[_1]} (#{pct(c[_1], n)})" }.join(" | ")} | #{pct(det, reached)} |\n"
  end
  out
end

sake = load(File.join(dir, "sake.jsonl"))
tp = load(File.join(dir, "typeprof.jsonl"))
ok_sake = sake.reject { _1["error"] }
ok_tp = tp.reject { _1["error"] }

puts "## Sake typer (#{ok_sake.size} programs; #{sake.size - ok_sake.size} failed to load)\n\n"
puts "\"determined\" = mono + nilable + union among reached units (no unknown anywhere in the type).\n\n"
puts table(ok_sake, UNITS)
puts
puts "- not converged within the pass limit: #{ok_sake.count { !_1["converged"] }}"
puts "- dead (never called) functions: #{ok_sake.sum { _1["dead"].size }}"
checks = Hash.new(0)
ok_sake.each { |r| r["checks"].each { |k, v| checks[k] += v } }
puts "- run-time check sites: #{checks.map { "#{_1}=#{_2}" }.join(" ")}"
sake.select { _1["error"] }.each { puts "- load error: #{_1["path"]}: #{_1["error"]}" }

puts "\n## TypeProf on the Ruby versions (#{ok_tp.size} programs; #{tp.size - ok_tp.size} failed)\n\n"
puts table(ok_tp, %w[sig.param sig.ret sig.field])
puts
puts "- reported errors (all false: every program runs): #{ok_tp.sum { _1["errors"].size }} in #{ok_tp.count { _1["errors"].any? }} programs"
kinds = Hash.new(0)
ok_tp.each { |r| r["errors"].each { kinds[_1.sub(/\A\S+:/, "")] += 1 } }
kinds.sort_by { -_2 }.first(10).each { puts "  - #{_2}: #{_1}" }
tp.select { _1["error"] }.each { puts "- failure: #{_1["path"]}: #{_1["error"]}" }

strict = File.exist?(File.join(dir, "strict.tsv")) ? File.readlines(File.join(dir, "strict.tsv")).map { _1.chomp.split("\t") } : []
unless strict.empty?
  puts "\n## Sake checks before running on correct programs (false reports)\n\n"
  puts "| level | programs rejected | diagnostics |\n|---|---|---|"
  strict.group_by { _1[1] }.sort.each do |lvl, rs|
    puts "| #{lvl} | #{rs.count { _1[2].to_i.nonzero? }} / #{rs.size} | #{rs.sum { _1[3].to_i }} |"
  end
end

puts "\n## Per domain\n\n| domain | programs | Sake expr determined | Sake sig determined | TypeProf sig determined |\n|---|---|---|---|---|"
det = lambda do |rows, units|
  c = Hash.new(0)
  rows.each { |r| units.each { |u| r.dig("counts", u)&.each { |k, v| c[k] += v } } }
  pct(c["mono"] + c["nilable"] + c["union"], c.values.sum - c["none"])
end
ok_sake.group_by { domain(_1["path"]) }.sort.each do |d, rs|
  trs = ok_tp.select { domain(_1["path"]) == d }
  puts "| #{d} | #{rs.size} | #{det.(rs, %w[expr.var expr.call])} | #{det.(rs, %w[sig.param sig.ret sig.field])} | #{det.(trs, %w[sig.param sig.ret sig.field])} |"
end

puts "\n## Why Sake units are not mono (by callee / reason)\n\n"
causes = Hash.new { |h, k| h[k] = Hash.new(0) }
ok_sake.each do |r|
  r["detail"].each do |unit, _line, text, c, shown|
    reason = shown[/\?\(([^)]*)\)/, 1]
    key =
      if reason then "unknown: #{reason.sub(/ for .*/, " for ...")}"
      elsif unit == "expr.call" then "#{c}: #{text[/\A[\w.:?!]+(\[\]=?)?/] || text[0, 15]}"
      else "#{c}: #{unit}"
      end
    causes[c][key] += 1
  end
end
%w[unknown partial union nilable].each do |c|
  next unless causes.key?(c)
  puts "**#{c}** (#{causes[c].values.sum}): " + causes[c].sort_by { -_2 }.first(15).map { "`#{_1}` #{_2}" }.join(", ")
  puts
end

verify = File.exist?(File.join(dir, "verify.tsv")) ? File.readlines(File.join(dir, "verify.tsv")).map { _1.chomp.split("\t") } : []
puts "\n## Corpus check\n\n- programs: #{verify.size}; run with exit 0 and output identical to Ruby and .out: #{verify.count { _1[1] == "ok" }}"
verify.reject { _1[1] == "ok" }.each { puts "  - #{_1[0]}: #{_1[1]}" }

def cross(path)
  rows = File.exist?(path) ? File.readlines(path).grep(/^\| (?!program|---)/).map { _1.split("|").map(&:strip) } : []
  [rows.size, rows.sum { _1[9].to_i }, rows.count { _1[9].to_i.positive? }]
end
n, v, p_ = cross(File.join(dir, "crosscheck.md"))
sn, sv, sp = cross(File.join(dir, "crosscheck-sabotage.md"))
puts "\n## Soundness (crosscheck)\n\n| typer | programs checked | violations | programs with violations |\n|---|---|---|---|"
puts "| as is | #{n} | #{v} | #{p_} |\n| sabotaged (negative control) | #{sn} | #{sv} | #{sp} |"

poly = load(File.join(dir, "polysites.jsonl")).reject { _1["error"] }
unless poly.empty?
  puts "\n## Dispatch demand\n\nRuby versions, run with receiver tracing: call sites (line, method) whose receivers had 2+ classes (nil excluded).\n"
  cats = Hash.new(0)
  progs = Hash.new(0)
  poly.each { |r| r["poly"].each { |k, c| cats[k] += c; progs[k] += 1 } }
  puts "\n| category | sites | programs |\n|---|---|---|"
  %w[operator show exception user builtin mixed].each { |k| puts "| #{k} | #{cats[k]} | #{progs[k]} |" }
  puts "\n(traced sites in total: #{poly.sum { _1["sites"] }}; programs: #{poly.size})"
  ms = Hash.new(0)
  poly.each { |r| r["found"].each { |f| ms["#{f["category"]}: (#{f["classes"].join("|")}).#{f["method"]}"] += 1 if %w[builtin mixed].include?(f["category"]) } }
  puts "\nbuiltin/mixed sites: " + ms.sort_by { -_2 }.first(25).map { "`#{_1}` #{_2}" }.join(", ")
end
disp = load(File.join(dir, "dispatch.jsonl"))
unless disp.empty?
  man = disp.flat_map { _1["manual"] }
  puts "\nSake versions: hand-written dispatch (case/in or if-in branches calling the same operation through different types): " \
       "#{man.size} operations in #{disp.count { _1["manual"].any? }} programs; calls through a module of the program: " \
       "#{disp.sum { _1["module_calls"] }} in #{disp.count { _1["module_calls"].positive? }} programs."
  puts "\n" + man.map { "(#{_1["types"].join("|")}).#{_1["op"]}" }.tally.sort_by { -_2 }.first(30).map { "`#{_1}` #{_2}" }.join(", ")
end
