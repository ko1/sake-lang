# usage: ruby tools/features.rb TIMEOUT_LIST CORPUS_GLOB  -> features.tsv (one row per program)
# Static (Prism) features of each program. "mp_calls" = calls whose block has >= 2 positional params.
require "prism"; require "json"
timeouts = File.readlines(ARGV[0], chomp: true).map { _1.sub(%r{.*corpus/}, "") }.to_h { [_1, true] }
class V < Prism::Visitor
  attr_reader :f, :mp
  def initialize; @f = Hash.new(0); @mp = Hash.new(0); @defs = []; @depth = 0; super; end
  def visit_call_node(n)
    if n.block.is_a?(Prism::BlockNode)
      bp = n.block.parameters
      req = case bp
            when Prism::BlockParametersNode
              ps = bp.parameters
              ps ? ps.requireds.size + ps.posts.size + ps.optionals.size + (ps.rest.is_a?(Prism::RestParameterNode) ? 1 : 0) : 0
            when Prism::NumberedParametersNode then bp.maximum
            else 0
            end
      if req >= 2 then @f[:mp_blocks] += 1; @mp[n.name] += 1 end
      @f[:blocks] += 1
    end
    @f[:struct] += 1 if n.name == :new && n.receiver.is_a?(Prism::ConstantReadNode) && n.receiver.name == :Struct
    @f[:data_define] += 1 if n.name == :define && n.receiver.is_a?(Prism::ConstantReadNode) && n.receiver.name == :Data
    @f[:set] += 1 if %i[to_set].include?(n.name) || (n.receiver.is_a?(Prism::ConstantReadNode) && n.receiver.name == :Set)
    @f[:sort_by_array_key] += 1 if %i[sort_by min_by max_by].include?(n.name) && n.block.is_a?(Prism::BlockNode) && n.block.body&.body&.last.is_a?(Prism::ArrayNode)
    @f[:recursion] += 1 if @defs.last && n.receiver.nil? && n.name == @defs.last
    super
  end
  def visit_def_node(n) = (@f[:defs] += 1; @defs << n.name; super; @defs.pop)
  def visit_class_node(n) = (@f[:classes] += 1; super)
  def visit_module_node(n) = (@f[:modules] += 1; super)
  def visit_constant_read_node(n) = (@f[:comparable] += 1 if n.name == :Comparable; super)
  def visit_array_node(n) = lit(n, :array)
  def visit_hash_node(n) = (@f[:hash_lits] += 1; mixed(n); lit(n, :hash))
  def mixed(n)
    kinds = n.elements.grep(Prism::AssocNode).map { _1.value.class }.uniq
    @f[:hash_mixed_values] += 1 if kinds.size >= 2
  end
  def lit(n, k)
    @depth += 1
    @f[:max_lit_depth] = @depth if @depth > @f[:max_lit_depth]
    @f[:"max_#{k}_len"] = n.elements.size if n.elements.size > @f[:"max_#{k}_len"]
    @f[:lit_elems] += n.elements.size
    super_visit(n); @depth -= 1
  end
  def super_visit(n) = n.compact_child_nodes.each { _1.accept(self) }
end
cols = %i[loc defs classes blocks mp_blocks recursion struct data_define comparable set sort_by_array_key hash_lits hash_mixed_values max_lit_depth max_array_len max_hash_len lit_elems]
puts (["timeout", "path"] + cols + ["mp_methods"]).join("\t")
Dir[ARGV[1]].sort.each do |path|
  src = File.read(path); v = V.new; Prism.parse(src).value.accept(v)
  v.f[:loc] = src.lines.count { _1 !~ /\A\s*(#|$)/ }
  puts ([timeouts[path.sub(%r{.*corpus/}, "")] ? 1 : 0, path.sub(%r{.*corpus/}, "")] + cols.map { v.f[_1] } + [v.mp.map { "#{_1}:#{_2}" }.join(",")]).join("\t")
end
