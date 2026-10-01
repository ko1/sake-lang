# frozen_string_literal: true

# How much TypeProf infers from the Ruby version of each program, in the units of measure.rb.
# usage: ruby typeprof_measure.rb FILE.rb...   (prints one JSON object per program)
#
#   sig.param  each parameter of each method TypeProf reports (initialize and attr writers skipped)
#   sig.ret    the return type of each such method
#   sig.field  each attr_reader / attr_accessor (the reader's return type)
#   errors     the lines of `typeprof --show-errors` (every program runs correctly, so all are false)
# TypeProf reports methods that are never called too (with untyped parameters); measure.rb skips
# unreached Sake functions, so the counts are not paired slot by slot.
require "json"
require "open3"
require "prism"
require "rbs"
require_relative "classify"

def structural(t)
  case t
  when RBS::Types::Union then t.types.flat_map { structural(_1) }.uniq.sort_by(&:inspect)
  when RBS::Types::Optional then (structural(t.type) + ["Nil"]).uniq.sort_by(&:inspect)
  when RBS::Types::Bases::Any then [[:unknown]]
  when RBS::Types::Bases::Bottom then []
  when RBS::Types::Bases::Nil then ["Nil"]
  when RBS::Types::Bases::Bool then ["Boolean"]
  when RBS::Types::Literal then [t.literal.class.name] # e.g. a Symbol literal type
  when RBS::Types::Tuple then [[:tuple, t.types.map { structural(_1) }]]
  when RBS::Types::Record then [[:record, t.all_fields.map { |k, v| [k, structural(v.is_a?(Array) ? v[0] : v)] }]]
  when RBS::Types::ClassInstance
    name = t.name.to_s.delete_prefix("::")
    args = t.args.map { structural(_1) }
    case [name, args.size]
    in ["Array", 1] then [[:array, *args]]
    in ["Hash", 2] then [[:hash, *args]]
    in ["Set", 1] then [[:set, *args]]
    in ["Range", 1] then [[:range, *args]]
    in [_, 0] then [name]
    else [[:generic, name, *args]]
    end
  else [t.to_s]
  end
end

# Names defined by attr_* per class: { "Point" => { "x" => :reader | :writer | :accessor } }.
def attrs_of(source)
  out = Hash.new { |h, k| h[k] = {} }
  walk = lambda do |node, cls|
    case node
    when Prism::ClassNode, Prism::ModuleNode
      cls = [cls, node.constant_path.slice].compact.join("::")
    when Prism::CallNode
      if node.receiver.nil? && %i[attr_reader attr_writer attr_accessor].include?(node.name)
        node.arguments&.arguments&.each do |a|
          out[cls || "Object"][a.unescaped] = node.name.to_s.delete_prefix("attr_").to_sym if a.is_a?(Prism::SymbolNode)
        end
      end
    end
    node.compact_child_nodes.each { walk.(_1, cls) }
  end
  walk.(Prism.parse(source).value, nil)
  out
end

def decls(list, ns = nil, &blk)
  list.each do |d|
    case d
    when RBS::AST::Declarations::Class, RBS::AST::Declarations::Module
      name = [ns, d.name.to_s.delete_prefix("::")].compact.join("::")
      yield name, d
      decls(d.members.grep(RBS::AST::Declarations::Base), name, &blk)
    end
  end
end

ARGV.each do |path|
  out, err, st = Open3.capture3("typeprof", "--show-errors", path)
  unless st.success?
    puts JSON.generate(path:, error: "typeprof failed: #{err.lines.first&.chomp}")
    next
  end
  errors = out.lines.grep(/^# \(\d+,\d+\)-/).map { _1.delete_prefix("# ").chomp }
  _, _, sig = RBS::Parser.parse_signature(out)
  attrs = attrs_of(File.read(path))
  counts = Hash.new { |h, k| h[k] = Hash.new(0) }
  detail = []
  add = lambda do |unit, label, type|
    c = Classify.classify(structural(type))
    counts[unit][c] += 1
    detail << [unit, label, c, type.to_s] unless c == :mono
  end
  decls(sig) do |cls, d|
    d.members.grep(RBS::AST::Members::MethodDefinition).each do |m|
      name = m.name.to_s
      next if name == "initialize"
      attr = attrs[cls][name.delete_suffix("=")]
      next if attr && name.end_with?("=")
      m.overloads.each do |ov|
        f = ov.method_type.type
        if attr
          add.("sig.field", "#{cls}##{name}", f.return_type)
          next
        end
        params = f.required_positionals + f.optional_positionals + [f.rest_positionals].compact +
                 f.required_keywords.values + f.optional_keywords.values
        params.each_with_index { |p, i| add.("sig.param", "#{cls}##{name} #{p.name || i}", p.type) }
        add.("sig.ret", "#{cls}##{name}", f.return_type) unless f.return_type.is_a?(RBS::Types::Bases::Void)
      end
    end
  end
  puts JSON.generate(path:, counts:, errors:, detail:)
rescue RBS::ParsingError => e
  puts JSON.generate(path:, error: "rbs parse: #{e.message.lines.first.chomp}")
end
