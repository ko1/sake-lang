require "prism"
# For each struct type: field order (class attr_* lines or Struct.new(:a, ...)), the kinds of the arguments at every
# T.new site per position, and later writes (T.set_x / @x = in methods). Reports fields whose creation arguments are
# all nil literals (the "fix the type at creation" rule would type them Nil) and whether they are written later.
dir = ARGV[0]
fields = {}            # type => [field names]
args = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }  # type => idx => kinds
later = Hash.new { |h, k| h[k] = Hash.new(0) }                      # type => field => writes
cur_class = nil
walk = ->(node) do
  case node
  when Prism::ClassNode
    cur_class = node.constant_path.slice
    fields[cur_class] ||= []
    node.body&.compact_child_nodes&.each do |s|
      if s.is_a?(Prism::CallNode) && s.name.to_s.start_with?("attr_") && s.arguments
        fields[cur_class].concat(s.arguments.arguments.map { |a| a.respond_to?(:name) ? a.name.to_s : a.slice.delete(":") })
      elsif s.is_a?(Prism::CallNode) && s.name == :private && s.arguments&.arguments&.first.is_a?(Prism::CallNode)
        inner = s.arguments.arguments.first
        fields[cur_class].concat(inner.arguments.arguments.map { |a| a.respond_to?(:name) ? a.name.to_s : a.slice.delete(":") }) if inner.name.to_s.start_with?("attr_")
      end
    end
    node.compact_child_nodes.each { walk.(_1) }
    cur_class = nil
    return
  when Prism::ConstantWriteNode
    v = node.value
    if v.is_a?(Prism::CallNode) && v.name == :new && v.receiver&.slice == "Struct" && v.arguments
      fields[node.name.to_s] = v.arguments.arguments.map { _1.slice.delete(":") }
    end
  when Prism::CallNode
    if node.name == :new && node.receiver.is_a?(Prism::ConstantReadNode) && node.arguments
      t = node.receiver.name.to_s
      node.arguments.arguments.each_with_index do |a, i|
        if a.is_a?(Prism::KeywordHashNode)
          a.elements.each { |e| args[t][e.key.unescaped.to_s] << (e.value.is_a?(Prism::NilNode) ? :nil : :other) }
        else
          args[t][i] << (a.is_a?(Prism::NilNode) ? :nil : :other)
        end
      end
    elsif node.name.to_s.start_with?("set_") && node.receiver.is_a?(Prism::ConstantReadNode)
      later[node.receiver.name.to_s][node.name.to_s.delete_prefix("set_")] += 1
    end
  when Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode, Prism::InstanceVariableOrWriteNode
    later[cur_class][node.name.to_s.delete_prefix("@")] += 1 if cur_class && !$in_init
  when Prism::DefNode
    $in_init = node.name == :initialize
    node.compact_child_nodes.each { walk.(_1) }
    $in_init = false
    return
  end
  node.compact_child_nodes.each { walk.(_1) }
end
Dir.glob("#{dir}/**/*.sake").sort.each { walk.(Prism.parse_file(_1).value) }
puts "#{dir.split("/")[-3]}: types #{fields.size}, fields #{fields.values.sum(&:size)}"
all_nil = 0; conflicts = []
fields.each do |t, names|
  names.each_with_index do |f, i|
    kinds = args[t][i] + args[t][f]
    next if kinds.empty? || !kinds.all?(:nil)
    all_nil += 1
    conflicts << "#{t}.#{f} (#{later[t][f]} later writes)" if later[t][f] > 0
  end
end
puts "  fields created only with nil: #{all_nil}; of them written later: #{conflicts.size}"
conflicts.each { puts "    #{_1}" }
puts "  later writes to fields created with non-nil: #{later.sum { |t, h| h.count { |f, _| !(args[t][fields[t]&.index(f)] || []).all?(:nil) || args[t][fields[t]&.index(f)].to_a.empty? } }} fields"
