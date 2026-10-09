# Classifies the field types in a `bin/sake --types` dump: one type / nil|T / union (2+ non-nil types) / union+nil,
# and counts container fields whose type lists more than one allocation site.
#   ruby classify_fields.rb types-sake-1.txt
lines = File.readlines(ARGV[0])
i = lines.index { _1.start_with?("fields:") } or abort "no fields: section"
fs = lines[i + 1..].take_while { _1.start_with?("  ") }.map { _1.strip.split(": ", 2) }
strip = ->(t) { t.gsub(/(Array|Hash|Set)@L\d+(#\d+)?( [\w.?]+)?\[[^\]]*\]/, "CONTAINER") }
single = nil_t = union = union_nil = cont_multi = 0
sums = Hash.new(0)
fs.each do |_, t|
  atoms = strip.(t).split(" | ").map(&:strip)
  cont_multi += 1 if atoms.count("CONTAINER") > 1
  atoms = atoms.uniq
  nil_p = atoms.delete("nil")
  if atoms.size <= 1 then nil_p ? nil_t += 1 : single += 1
  else nil_p ? union_nil += 1 : union += 1; sums[atoms.sort.join(" | ")] += 1
  end
end
puts "#{ARGV[0]}: #{fs.size} fields: single #{single}, nil|T #{nil_t}, union #{union}, union+nil #{union_nil}; container fields with >1 site #{cont_multi}"
puts "  distinct unions #{sums.size}; by size #{sums.keys.map { _1.split(" | ").size }.tally.sort.to_h}"
sums.sort_by { -_2 }.first(3).each { |k, v| puts "  #{v} fields: #{k[0, 100]}" }
