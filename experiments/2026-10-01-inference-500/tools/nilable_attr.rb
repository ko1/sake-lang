# frozen_string_literal: true
# usage: ruby tools/nilable_attr.rb   (run in this directory; compares results-v3 and results-v4)
# Which units went mono -> nilable between v3 and v4, and are those variables destructuring targets?
require "json"; require "zlib"; require "prism"
def load(f) = (f.end_with?(".gz") ? Zlib::GzipReader.open(f, &:readlines) : File.readlines(f)).map { JSON.parse(_1) }.to_h { [_1["path"], _1["detail"] || []] }
a = load("results-v3/sake.jsonl.gz"); b = load("results-v4/sake.jsonl")
def targets(path)
  names = Hash.new(false)
  walk = ->(n) do
    return unless n
    case n
    when Prism::MultiWriteNode then n.lefts.each { names[_1.name.to_s] = true if _1.respond_to?(:name) }
    when Prism::BlockNode
      ps = n.parameters.is_a?(Prism::BlockParametersNode) ? n.parameters.parameters : nil
      if ps && ps.requireds.size + ps.posts.size + (ps.rest ? 1 : 0) >= 2
        ps.requireds.each { |r| r.is_a?(Prism::MultiTargetNode) ? r.lefts.each { names[_1.name.to_s] = true } : names[r.name.to_s] = true }
      end
      ps&.requireds&.each { |r| r.lefts.each { names[_1.name.to_s] = true } if r.is_a?(Prism::MultiTargetNode) }
    when Prism::NumberedParametersNode then nil
    end
    n.compact_child_nodes.each { walk.(_1) }
  end
  walk.(Prism.parse_file(path).value)
  names
end
tot = Hash.new(0); progs = Hash.new(0)
b.each do |path, det|
  old = a[path].to_h { [[_1[0], _1[1], _1[2]], _1[3]] } rescue {}
  t = nil
  det.each do |u, line, text, cls, ty|
    next unless u == "expr.var"
    o = old[[u, line, text]]
    next unless (o.nil? || o == "mono") && cls == "nilable"
    next if o.nil? && !old.empty? && false
    t ||= targets(path)
    k = t[text] ? "destructure target" : "other"
    tot[k] += 1
  end
end
p tot
