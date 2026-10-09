require "prism"
# Counts, per engine: field writes outside initialize, and the kinds of arguments at T.new sites.
dir = ARGV[0]
writes = Hash.new { |h, k| h[k] = Hash.new(0) }   # kind => field => n
new_args = Hash.new(0); new_sites = 0
walk = ->(node, in_init, locals) do
  case node
  when Prism::DefNode
    locals = node.parameters ? node.parameters.compact_child_nodes.flat_map { _1.respond_to?(:name) ? [_1.name] : [] } : []
    in_init = node.name == :initialize
  when Prism::InstanceVariableWriteNode, Prism::InstanceVariableOperatorWriteNode, Prism::InstanceVariableOrWriteNode, Prism::InstanceVariableAndWriteNode
    writes[in_init ? :initialize : :method][node.name] += 1
  when Prism::CallNode
    if node.name == :new && node.receiver.is_a?(Prism::ConstantReadNode) && node.arguments
      new_sites += 1
      node.arguments.arguments.each do |a|
        kind = case a
               when Prism::IntegerNode, Prism::FloatNode, Prism::StringNode, Prism::SymbolNode, Prism::NilNode, Prism::TrueNode, Prism::FalseNode, Prism::ArrayNode, Prism::HashNode, Prism::InterpolatedStringNode then :literal
               when Prism::CallNode then (a.name == :new && a.receiver.is_a?(Prism::ConstantReadNode)) ? :new : (a.receiver.is_a?(Prism::ConstantReadNode) ? :"T.op call" : :"other call")
               when Prism::LocalVariableReadNode then :local
               when Prism::InstanceVariableReadNode then :ivar
               when Prism::KeywordHashNode then :keyword
               else a.class.name.split("::").last.to_sym
               end
        new_args[kind] += 1
      end
    end
    writes[:setter][node.name] += 1 if node.name.start_with?("set_") && node.receiver.is_a?(Prism::ConstantReadNode)
  end
  node.compact_child_nodes.each { walk.(_1, in_init, locals) }
end
Dir.glob("#{dir}/**/*.sake").sort.each { walk.(Prism.parse_file(_1).value, false, []) }
puts "#{dir.split("/")[-3]}:"
writes.each { |k, h| puts "  @x writes in #{k}: #{h.values.sum} writes, #{h.size} fields" }
puts "  new sites: #{new_sites}; argument kinds: #{new_args.sort_by { -_2 }.to_h}"
