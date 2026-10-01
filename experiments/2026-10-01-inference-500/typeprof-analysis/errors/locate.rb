# Prism helpers: find the call at an error position and collect static facts about the program.
require "prism"

module Locate
  module_function

  # error "(l,c)-(l2,c2):msg" -> [l, c, l2, c2, msg]
  def parse_err(e)
    e =~ /\A\((\d+),(\d+)\)-\((\d+),(\d+)\):(.*)\z/ or raise e
    [$1.to_i, $2.to_i, $3.to_i, $4.to_i, $5]
  end

  # all nodes with their ancestor chain
  def each_with_path(node, path = [], &blk)
    return unless node
    yield node, path
    path2 = path + [node]
    node.compact_child_nodes.each { each_with_path(_1, path2, &blk) }
  end

  def col(loc) = [loc.start_line, loc.start_column, loc.end_line, loc.end_column]

  # The CallNode (or other node) whose message or whole range matches; returns [node, ancestors].
  def node_at(root, l, c, l2, c2)
    best = nil
    each_with_path(root) do |n, path|
      locs = [n.location]
      locs << n.message_loc if n.respond_to?(:message_loc) && n.message_loc
      locs << n.operator_loc if n.respond_to?(:operator_loc) && n.operator_loc rescue nil
      locs << n.binary_operator_loc if n.respond_to?(:binary_operator_loc)
      if locs.compact.any? { col(_1) == [l, c, l2, c2] }
        best = [n, path] if best.nil? || path.size > best[1].size
      end
    end
    best
  end
end
