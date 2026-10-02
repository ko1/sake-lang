# Markdown tables from classified.tsv: causes with counts, programs and one representative example,
# and the methods at the erroring call for some causes.
require_relative "locate"
EXP = File.expand_path("../..", __dir__)
rows = File.readlines(File.join(__dir__, "classified.tsv")).drop(1).map { _1.chomp.split("\t") }
by = rows.group_by { _1[4] }
puts "| cause | errors | programs | example (file:line) | code |"
puts "|---|---:|---:|---|---|"
by.sort_by { -_2.size }.each do |cause, rs|
  msg = rs.map { _1[1].sub(/\A[^:]*:/, "") }.tally.max_by(&:last).first
  ex = rs.select { _1[1].end_with?(msg) && _1[5].size < 90 }.min_by { [_1[5].size, _1[0]] } || rs.first
  line = ex[1][/\A\((\d+)/, 1]
  puts "| #{cause} | #{rs.size} | #{rs.map(&:first).uniq.size} | #{ex[0].delete_prefix("corpus/")}:#{line} `#{ex[1].sub(/\A[^:]*:/, "")}` | `#{ex[5].gsub("|", "\\|")}` |"
end
puts "| total | #{rows.size} | #{rows.map(&:first).uniq.size} | | |"
puts
%w[interface-nominal numeric-catchall-overload].each do |cause|
  t = Hash.new(0)
  (by[cause] || []).each do |path, err, *|
    root = (@cache ||= {})[path] ||= Prism.parse_file(File.join(EXP, path)).value
    l, c, l2, c2, = Locate.parse_err(err)
    n, = Locate.node_at(root, l, c, l2, c2)
    name = n.respond_to?(:name) ? n.name.to_s : n.class.name
    name = "#{n.receiver.slice}.#{name}" if n.is_a?(Prism::CallNode) && n.receiver.is_a?(Prism::ConstantReadNode)
    t[name] += 1
  end
  puts "#{cause}: " + t.sort_by { -_2 }.map { "#{_1} #{_2}" }.join(", ")
end
