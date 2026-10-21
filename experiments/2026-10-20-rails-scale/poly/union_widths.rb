# How wide Sake's unions get: reads `bin/sake --types` output (the "fields:" section: one line per field of a
# struct allocation site, "  Type@site.field: T1 | T2 | ...") and counts, per field, the distinct kinds at the top
# level of its type. A kind is a member with its allocation site and element types dropped (String[]@L24 and
# String[]@L26 are one kind, Array), Symbol literals are Symbol, true|false is Boolean; nil is not counted.
# usage: ruby union_widths.rb TYPES.txt [--top N]
def split_top(s)
  parts, depth, cur = [], 0, +""
  s.scan(/ \| |[\[\]]|[^\[\] |]+|./) do |t|
    if t == " | " && depth == 0 then parts << cur; cur = +"" else
      depth += 1 if t == "["; depth -= 1 if t == "]"; cur << t end
  end
  parts << cur
end
def kind(m)
  m = m.strip
  return "Boolean" if m == "true|false"
  return "Symbol" if m.start_with?(":")
  return "Array" if m =~ /\A[^\[]*\[\]/ || m.start_with?("Array")
  m.sub(/[@\[].*/m, "")
end
lines = File.readlines(ARGV[0]).drop_while { _1 !~ /\Afields:/ }.drop(1).take_while { _1.start_with?("  ") }
top = (ARGV[ARGV.index("--top") + 1].to_i if ARGV.include?("--top")) || 15
rows = lines.filter_map do |l|
  name, type = l.strip.split(": ", 2)
  next unless type
  kinds = split_top(type).map { kind(_1) }.uniq - ["nil"]
  [name, kinds]
end
hist = rows.group_by { [_2.size, 6].min }.transform_values(&:size).sort
puts "fields: #{rows.size}"
hist.each { |w, n| printf("  %s kinds: %6d  (%.1f%%)\n", w == 6 ? ">=6" : w.to_s, n, 100.0 * n / rows.size) }
puts "widest:"
rows.sort_by { -_2.size }.first(top).each { |n, k| puts "  #{k.size} #{n.sub(/@\S*?(?=\.)/, "")}: #{k.join(" | ")[0, 160]}" }
# The same per declared field (Type.field, all allocation sites together: the widest site counts).
by = rows.group_by { |n, _| n.sub(/@[^.]*/, "") }.transform_values { |rs| rs.map(&:last).max_by(&:size) }
puts "declared fields: #{by.size}"
by.group_by { [_2.size, 6].min }.transform_values(&:size).sort.each { |w, n| printf("  %s kinds: %5d  (%.1f%%)\n", w == 6 ? ">=6" : w.to_s, n, 100.0 * n / by.size) }
puts "widest declared fields:"
by.sort_by { -_2.size }.first(top).each { |n, k| puts "  #{k.size} #{n}: #{k.join(" | ")[0, 200]}" }
