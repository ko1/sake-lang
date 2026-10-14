#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts .sake files to the 2026-10-14 constructors (ko1: `T[...]` is an Array of T for every T):
#   Array[a, b]  -> Any[a, b]        (Any = Kernel, the prelude's alias: an Array of any values)
#   Hash[k => v] -> Hash.of(k => v)  Hash[] -> Hash.new
#   Set[a, b]    -> Set.of(a, b)     Set[]  -> Set.new
# Only the constructor form `X[...]` (a constant receiver, no `.`) changes; a file that does not parse is
# reported and left alone. Sake code inside strings (a generator's output) is not seen: check those by hand.
# usage: ruby tools/convert_any_array.rb FILE_OR_DIR...   (prints the files it changed and the counts)

require "prism"

def edits_for(node, out)
  if node.is_a?(Prism::CallNode) && node.name == :[] && node.call_operator_loc.nil? &&
     node.receiver.is_a?(Prism::ConstantReadNode) && %i[Array Hash Set].include?(node.receiver.name) && node.opening_loc
    r = node.receiver.location
    empty = node.arguments.nil? && node.block.nil?
    case node.receiver.name
    when :Array then out << [r.start_offset, r.end_offset, "Any"]
    else
      if empty
        out << [r.start_offset, node.closing_loc.end_offset, "#{node.receiver.name}.new"]
      else
        out << [node.opening_loc.start_offset, node.opening_loc.end_offset, ".of("]
        out << [node.closing_loc.start_offset, node.closing_loc.end_offset, ")"]
      end
    end
  end
  node.compact_child_nodes.each { edits_for(_1, out) }
end

files = ARGV.flat_map { File.directory?(_1) ? Dir.glob(File.join(_1, "**/*.sake")).select { |f| File.file?(f) } : [_1] }
changed = 0
count = 0
files.each do |f|
  src = File.binread(f)
  result = Prism.parse(src.dup.force_encoding("UTF-8"), filepath: f)
  unless result.errors.empty?
    warn "skipped (does not parse): #{f}"
    next
  end
  edits = []
  edits_for(result.value, edits)
  next if edits.empty?
  out = src.dup
  edits.sort_by { -_1[0] }.each { |s, e, text| out[s...e] = text.b }
  File.binwrite(f, out)
  changed += 1
  count += edits.count { _1[2] != ")" }
  puts f
end
warn "#{count} constructors in #{changed} files"
