# frozen_string_literal: true

# Compares two `bin/sake --types` dumps (Typer and Typer2) on what the checker reports: the verdict counts,
# the non-proven checks and the field types, with container site labels (`Array@L64#2`, clones `'`) removed,
# since the two typers number sites differently. Prints the differences; exit 1 when there are any.
#   ruby compare.rb types-sake-1-typer1.txt types-sake-1-typer2.txt
a, b = ARGV.map { File.read(_1) }
# Labels go, and a union's repeated members (Typer has one site per instantiation, Typer2 a template and clones).
norm = ->(s) { s.gsub(/@L\d+(#\d+)?( [\w.?]+)?'*/, "").split(" | ").uniq.join(" | ") }
section = lambda do |text, name|
  lines = text.lines
  i = lines.index { _1.start_with?("#{name}:") } or return []
  lines[i + 1..].take_while { _1.start_with?("  ") }.map { norm.(_1.strip) }
end
summary = ->(t) { t.lines.find { _1.start_with?("checks:") }.to_s.strip }
puts "summary: #{summary.(a)} | #{summary.(b)}"
diffs = 0
[["checks", ->(t) { t.lines.take_while { !_1.start_with?("arrays:") }.select { _1.start_with?("  ") }.map { norm.(_1.strip) } }],
 ["fields", ->(t) { section.(t, "fields") }]].each do |name, pick|
  x = pick.(a).sort
  y = pick.(b).sort
  only_a = x - y
  only_b = y - x
  puts "#{name}: #{x.size} vs #{y.size}; only in first #{only_a.size}, only in second #{only_b.size}"
  (only_a.map { "  - #{_1}" } + only_b.map { "  + #{_1}" }).first(40).each { puts _1[0, 240] }
  diffs += only_a.size + only_b.size
end
exit(diffs.zero? ? 0 : 1)
