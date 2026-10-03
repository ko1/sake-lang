# frozen_string_literal: true

# Where are Struct fields written? For each field of each user type (Struct.new or class settings):
# never written after `new`, written only inside the type's class (`@x = v`, set_x there), or written
# from outside (`T.set_x(...)` elsewhere). Fields of the second and first kind could be `reader:`.
# usage: ruby field_access.rb FILE.sake...   (prints totals as Markdown)
require "prism"
require "set"

tot = Hash.new(0)
by_form = Hash.new { |h, k| h[k] = Hash.new(0) }
ARGV.each do |path|
  root = Prism.parse_file(path).value
  types = {} # name => [form, fields]
  walk = ->(n, &blk) { return unless n; blk.(n); n.compact_child_nodes.each { walk.(_1, &blk) } }
  walk.(root) do |n|
    if n.is_a?(Prism::ConstantWriteNode) && n.value.is_a?(Prism::CallNode) && n.value.name == :new &&
       n.value.receiver.is_a?(Prism::ConstantReadNode) && n.value.receiver.name == :Struct
      types[n.name.to_s] = ["Struct.new", (n.value.arguments&.arguments || []).grep(Prism::SymbolNode).map(&:unescaped)]
    elsif n.is_a?(Prism::ClassNode) && n.superclass.is_a?(Prism::HashNode)
      fields = n.superclass.elements.flat_map do |el|
        next [] unless el.respond_to?(:key) && %w[accessor reader writer].include?(el.key.unescaped)
        el.value.elements.map { _1.slice.delete_prefix(":") }
      end
      types[n.constant_path.slice] = ["settings", fields.uniq]
    end
  end
  inside = Hash.new { |h, k| h[k] = Set.new }  # type => fields written inside its class
  outside = Hash.new { |h, k| h[k] = Set.new } # type => fields written from elsewhere
  visit = lambda do |n, owner|
    return unless n
    owner = n.constant_path.slice if n.is_a?(Prism::ClassNode)
    case n
    when Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode, Prism::InstanceVariableOrWriteNode
      inside[owner] << n.name.to_s.delete_prefix("@") if owner
    when Prism::CallNode
      if (m = n.name.to_s.match(/\Aset_(\w+)\z/))
        t = n.receiver.is_a?(Prism::ConstantReadNode) ? n.receiver.name.to_s : (n.receiver.nil? ? owner : nil)
        (t == owner ? inside : outside)[t] << m[1] if t
      end
    end
    n.compact_child_nodes.each { visit.(_1, owner) }
  end
  visit.(root, nil)
  types.each do |name, (form, fields)|
    fields.each do |f|
      kind = outside[name].include?(f) ? "written from outside" : (inside[name].include?(f) ? "written only inside its class" : "never written after new")
      tot[kind] += 1
      by_form[form][kind] += 1
    end
  end
end
kinds = ["never written after new", "written only inside its class", "written from outside"]
all = tot.values.sum
puts "| fields | all | Struct.new | class settings |"
puts "|---|---|---|---|"
kinds.each { |k| puts "| #{k} | #{tot[k]} (#{(100.0 * tot[k] / all).round(1)}%) | #{by_form["Struct.new"][k]} | #{by_form["settings"][k]} |" }
puts "| total | #{all} | #{by_form["Struct.new"].values.sum} | #{by_form["settings"].values.sum} |"
