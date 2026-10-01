# frozen_string_literal: true

# Summarizes the outputs of run.sh into Markdown.
# usage: ruby summarize.rb OUTDIR   (reads sake.jsonl, typeprof.jsonl, strict.tsv; prints Markdown)
require "json"

dir = ARGV.fetch(0)
CLASSES = %w[mono nilable union partial unknown none].freeze
UNITS = %w[expr.var expr.call sig.param sig.ret sig.field].freeze

def load(path) = File.exist?(path) ? File.readlines(path).map { JSON.parse(_1) } : []
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
