require "prism"
METHODS = %i[max_by min_by sort_by filter_map flat_map to_h map min max sum group_by]
ARGV.each do |path|
  code = File.read(path)
  walk = ->(n, defn) {
    if n.is_a?(Prism::CallNode) && METHODS.include?(n.name) && n.block.is_a?(Prism::BlockNode) && (bp = n.block.parameters).is_a?(Prism::BlockParametersNode) && bp.parameters && bp.parameters.requireds.size >= 2
      body = n.block.body
      last = body.is_a?(Prism::StatementsNode) ? body.body.last : body
      puts "#{path.sub(%r{.*corpus/}, '')}:#{n.location.start_line} in #{defn || 'toplevel'}: #{n.slice.lines.first.strip[0, 110]}" if last.is_a?(Prism::LocalVariableReadNode) || last.is_a?(Prism::IfNode)
    end
    n.compact_child_nodes.each { walk[_1, n.is_a?(Prism::DefNode) ? n.name : defn] }
  }
  walk[Prism.parse(code).value, nil]
end
