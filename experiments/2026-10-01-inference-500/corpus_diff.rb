# frozen_string_literal: true

# Compares the Sake programs of two corpora (before / after the revision round) by syntax:
# lines, programs changed, uses of the new features, and typical workarounds.
# usage: ruby corpus_diff.rb corpus corpus-v2   (prints Markdown)
require "prism"

a_dir, b_dir = ARGV

FEATURES = {
  "chain x.T.f" => ->(n) { n.is_a?(Prism::CallNode) && (r = n.receiver).is_a?(Prism::CallNode) && r.receiver && r.call_operator_loc && r.name.to_s.match?(/\A[A-Z]/) && r.arguments.nil? },
  "_ (previous value)" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :_ && n.receiver.nil? && n.variable_call? },
  "(A|B).f" => lambda { |n|
    next false unless n.is_a?(Prism::CallNode) && n.receiver.is_a?(Prism::ParenthesesNode) && (u = n.receiver.body&.body&.first).is_a?(Prism::CallNode) && u.name == :|
    consts = ->(x) { x.is_a?(Prism::ConstantReadNode) || (x.is_a?(Prism::CallNode) && x.name == :| && consts.(x.receiver) && consts.(x.arguments.arguments[0])) }
    consts.(u)
  },
  "unary -x / +x / ~x" => ->(n) { n.is_a?(Prism::CallNode) && %i[-@ +@ ~].include?(n.name) && n.call_operator_loc.nil? },
  "!x" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :! && n.call_operator_loc.nil? },
  "Tuple compared (== < <=> with [..])" => ->(n) { n.is_a?(Prism::CallNode) && %i[== != < <= > >= <=>].include?(n.name) && [n.receiver, *n.arguments&.arguments].any?(Prism::ArrayNode) },
  "sort_by/min_by/max_by with a Tuple key" => lambda { |n|
    n.is_a?(Prism::CallNode) && %i[sort_by min_by max_by].include?(n.name) && n.block.is_a?(Prism::BlockNode) &&
      n.block.body&.body&.last.is_a?(Prism::ArrayNode)
  },
  "multiple assignment from a call" => ->(n) { n.is_a?(Prism::MultiWriteNode) && n.value.is_a?(Prism::CallNode) }
}.freeze

WORKAROUNDS = {
  "0 - x (unary minus)" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :- && n.receiver.is_a?(Prism::IntegerNode) && n.receiver.value.zero? || (n.is_a?(Prism::CallNode) && n.name == :- && n.receiver.is_a?(Prism::FloatNode) && n.receiver.value.zero?) },
  "x == false (negation)" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :== && n.arguments&.arguments&.first.is_a?(Prism::FalseNode) },
  "format(\"%0..\") sort keys" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :format && n.arguments&.arguments&.first.is_a?(Prism::StringNode) && n.arguments.arguments.first.unescaped.match?(/%0\d/) },
  "x[0] / x[1] right after a split" => ->(n) { n.is_a?(Prism::CallNode) && n.name == :[] && n.receiver.is_a?(Prism::CallNode) && n.receiver.name == :split },
  "case/in on types calling same-named ops" => ->(_) { false } # counted by sake_dispatch.rb
}.freeze

def walk(node, &blk)
  return unless node
  yield node
  node.compact_child_nodes.each { walk(_1, &blk) }
end

def counts(dir, table)
  c = Hash.new(0)
  progs = Hash.new { |h, k| h[k] = 0 }
  Dir["#{dir}/*/*.sake"].sort.each do |f|
    root = Prism.parse(File.read(f)).value
    seen = {}
    walk(root) do |n|
      table.each do |name, pred|
        next unless pred.(n)
        c[name] += 1
        seen[name] = true
      end
    end
    seen.each_key { progs[_1] += 1 }
  end
  [c, progs]
end

def lines(f) = File.readlines(f).count { !_1.strip.empty? && !_1.strip.start_with?("#") }

files = Dir["#{a_dir}/*/*.sake"].sort.map { _1.delete_prefix("#{a_dir}/") }
changed = files.select { File.read("#{a_dir}/#{_1}") != File.read("#{b_dir}/#{_1}") }
la = files.sum { lines("#{a_dir}/#{_1}") }
lb = files.sum { lines("#{b_dir}/#{_1}") }

puts "## Revision round: #{a_dir} → #{b_dir}"
puts
puts "- programs: #{files.size}; changed: #{changed.size}"
puts "- code lines (no blanks or comments): #{la} → #{lb} (#{format("%+.1f", 100.0 * (lb - la) / la)}%)"
puts
puts "| new feature | uses before | uses after | programs after |"
puts "|---|---|---|---|"
fa, = counts(a_dir, FEATURES)
fb, pb = counts(b_dir, FEATURES)
FEATURES.each_key { puts "| #{_1} | #{fa[_1]} | #{fb[_1]} | #{pb[_1]} |" }
puts
puts "| workaround | before | after |"
puts "|---|---|---|"
wa, = counts(a_dir, WORKAROUNDS)
wb, = counts(b_dir, WORKAROUNDS)
WORKAROUNDS.each_key { |k| next if k.start_with?("case/in"); puts "| #{k} | #{wa[k]} | #{wb[k]} |" }
puts
puts "Detected syntactically (Prism); \"Tuple compared\" counts only comparisons with a literal `[...]` operand."
