# frozen_string_literal: true

# Where TypeProf's untyped comes from: joins typeprof.jsonl (slots with untyped) with the methods that
# actually ran (called.json, from called_trace.rb). usage: ruby analyze.rb > report.md
require "json"
require "zlib"

rows = Zlib::GzipReader.open("../../results-head/typeprof.jsonl.gz") { |z| z.readlines.map { JSON.parse(_1) } }.reject { _1["error"] }
called = JSON.parse(File.read("called.json"))

slots = Hash.new(0)
rows.each { |r| r["counts"].each { |u, c| slots[u] += c.values.sum - c.fetch("none", 0) } }

items = []
rows.each do |r|
  ran = called.fetch(r["path"]) || []
  r["detail"].each do |unit, label, cls, type|
    next unless %w[unknown partial].include?(cls)
    meth = label.split(" ").first
    c, m = meth.split("#", 2)
    m = m.delete_suffix("=")
    reached = ran.include?("#{c}##{m}") || ran.include?("#{c}.#{m}") ||
              (unit == "sig.field" && ran.any? { _1.start_with?("#{c}#") })
    shape =
      if type == "untyped" then "untyped"
      elsif type.match?(/\AArray\[untyped\]\z/) then "Array[untyped]"
      elsif type.match?(/\AHash\[untyped, untyped\]\z/) then "Hash[untyped, untyped]"
      elsif type.start_with?("Hash[") then "Hash[K, untyped] or Hash[untyped, V]"
      elsif type.start_with?("Array[") then "Array[... untyped ...]"
      elsif type.start_with?("[") then "tuple with untyped"
      else "other (#{type[0, 40]})"
      end
    items << { path: r["path"], unit:, label:, cls:, type:, reached:, shape: }
  end
end

puts "# Where TypeProf's untyped comes from"
puts
puts "#{rows.size} programs that TypeProf finished. A slot is a method parameter, a return value, or an attr reader."
puts "\"reached\": the method ran when the program was executed (TracePoint :call); a field counts as reached when any method of its class ran."
puts
puts "| unit | slots | with untyped | of which in methods that never ran | in methods that ran |"
puts "|---|---|---|---|---|"
%w[sig.param sig.ret sig.field].each do |u|
  xs = items.select { _1[:unit] == u }
  puts "| #{u} | #{slots[u]} | #{xs.size} (#{format("%.1f", 100.0 * xs.size / slots[u])}%) | #{xs.count { !_1[:reached] }} | #{xs.count { _1[:reached] }} |"
end
puts
puts "## Shape of the untyped type, in methods that ran"
puts
puts "| shape | param | ret | field |"
puts "|---|---|---|---|"
ran = items.select { _1[:reached] }
ran.group_by { _1[:shape] }.sort_by { -_2.size }.each do |shape, xs|
  c = xs.group_by { _1[:unit] }.transform_values(&:size)
  puts "| #{shape} | #{c["sig.param"] || 0} | #{c["sig.ret"] || 0} | #{c["sig.field"] || 0} |"
end
puts
puts "## Programs with the most untyped slots in methods that ran"
puts
ran.group_by { _1[:path] }.sort_by { -_2.size }.first(12).each { |p, xs| puts "- #{p}: #{xs.size}" }
puts
puts "## Sample (every 25th untyped slot in a method that ran)"
puts
ran.each_slice(25).map(&:first).each { |x| puts "- #{x[:path]} `#{x[:label]}` (#{x[:unit]}): `#{x[:type]}`" }
