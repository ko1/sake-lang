# frozen_string_literal: true

# Sake vs Ruby, per corpus: size, the type names written on operations, and the language features used.
# usage: ruby compare.rb CORPUS_DIR [LABEL]   (prints Markdown; reads */*.sake and the .rb next to each)
#
# Counted (Prism, comments and blank lines excluded):
#   lines       non-blank, non-comment lines
#   tokens      lexical tokens (no comments, newlines, or EOF)
#   qualified   calls `T.op(...)` / `x.T.op(...)` whose receiver is a constant: the type written on an
#               operation (T.new and T[...] are counted apart, as Ruby writes them too)
#   qual_chars  characters spent on those qualifiers ("String." in String.upcase(s))
#   typed       other places a type is written in Sake: typed Array literals T[...] (not Array/Hash/Set),
#               `x in T`, `in T` branches, `x => T` (type patterns only; Record patterns not counted)
#   features    attr_* lines, Struct.new, class B < A, initialize, optional / keyword parameters, `=> T`,
#               once, block_given?, &b, IO values, keyword arguments at calls
require "prism"

dir = ARGV[0] or abort "usage: ruby compare.rb CORPUS_DIR [LABEL]"
label = ARGV[1] || File.basename(dir)

def code_lines(src)
  src.lines.count { |l| !(s = l.strip).empty? && !s.start_with?("#") }
end

def tokens(src)
  Prism.lex(src).value.count { |tok, _| !%i[COMMENT NEWLINE EOF IGNORED_NEWLINE EMBDOC_BEGIN EMBDOC_LINE EMBDOC_END].include?(tok.type) }
end

TYPE_NAME = /\A[A-Z]/
BUILTIN_CONTAINERS = %w[Array Hash Set].freeze

def walk(node, &blk)
  return unless node
  yield node
  node.compact_child_nodes.each { walk(_1, &blk) }
end

def type_pattern?(p)
  case p
  when Prism::ConstantReadNode then true
  when Prism::AlternationPatternNode then type_pattern?(p.left) || type_pattern?(p.right)
  else false
  end
end

def sake_counts(src)
  c = Hash.new(0)
  walk(Prism.parse(src).value) do |n|
    case n
    when Prism::CallNode
      recv = n.receiver
      if recv.is_a?(Prism::ConstantReadNode) && n.call_operator_loc
        if n.name == :new then c[:new] += 1
        else
          c[:qualified] += 1
          c[:qual_chars] += recv.name.to_s.size + 1
        end
      elsif recv.is_a?(Prism::CallNode) && recv.name.to_s.match?(TYPE_NAME) && recv.receiver && n.call_operator_loc && recv.arguments.nil?
        c[:qualified] += 1 # x.T.op(...)
        c[:qual_chars] += recv.name.to_s.size + 1
      elsif recv.is_a?(Prism::ConstantReadNode) && n.name == :[] && !BUILTIN_CONTAINERS.include?(recv.name.to_s)
        c[:typed] += 1
      end
      c[:attr] += 1 if n.receiver.nil? && %i[attr_reader attr_accessor attr_writer].include?(n.name)
      c[:struct_new] += 1 if recv.is_a?(Prism::ConstantReadNode) && %i[Struct Exception].include?(recv.name) && n.name == :new
      c[:once] += 1 if n.receiver.nil? && n.name == :once
      c[:block_given] += 1 if n.receiver.nil? && n.name == :block_given?
      c[:io] += 1 if recv.is_a?(Prism::ConstantReadNode) && recv.name == :IO
      c[:block_pass] += 1 if n.block.is_a?(Prism::BlockArgumentNode)
      c[:kwargs_call] += 1 if n.arguments&.arguments&.last.is_a?(Prism::KeywordHashNode) && !(recv.is_a?(Prism::ConstantReadNode) && recv.name == :Hash)
    when Prism::ClassNode
      c[:class_paste] += 1 if n.superclass.is_a?(Prism::ConstantReadNode) && !%i[Exception StandardError].include?(n.superclass.name)
      c[:exception_class] += 1 if n.superclass.is_a?(Prism::ConstantReadNode) && %i[Exception StandardError].include?(n.superclass.name)
    when Prism::DefNode
      c[:initialize] += 1 if n.name == :initialize
      ps = n.parameters
      c[:optional_params] += ps.optionals.size if ps
      c[:keyword_params] += ps.keywords.size if ps
    when Prism::MatchRequiredNode
      if type_pattern?(n.pattern)
        c[:assert_type] += 1
        c[:typed] += 1
      end
    when Prism::MatchPredicateNode then c[:typed] += 1 if type_pattern?(n.pattern)
    when Prism::InNode then c[:typed] += 1 if type_pattern?(n.pattern)
    end
  end
  c
end

rows = Dir[File.join(dir, "*/*.sake")].sort.map do |sk|
  rb = sk.sub(/\.sake\z/, ".rb")
  s = File.read(sk)
  r = File.exist?(rb) ? File.read(rb) : ""
  { name: sk, s_lines: code_lines(s), r_lines: code_lines(r), s_tokens: tokens(s), r_tokens: tokens(r), **sake_counts(s) }
end

sum = ->(k) { rows.sum { _1[k] || 0 } }
n = rows.size
puts "## #{label} (#{n} programs)"
puts
puts "| measure | Sake | Ruby | Sake / Ruby |"
puts "|---|---|---|---|"
%i[lines tokens].each do |k|
  s = sum.(:"s_#{k}")
  r = sum.(:"r_#{k}")
  puts "| #{k} | #{s} | #{r} | #{format("%.3f", s.to_f / r)} |"
end
puts
q = sum.(:qualified)
puts "| type written in Sake | total | per program | per 100 lines |"
puts "|---|---|---|---|"
{ "qualified calls `T.op`" => :qualified, "chars of qualifiers" => :qual_chars, "other typed places (T[], in T, => T)" => :typed,
  "T.new" => :new }.each do |label2, k|
  t = sum.(k)
  puts "| #{label2} | #{t} | #{format("%.1f", t.to_f / n)} | #{format("%.1f", 100.0 * t / sum.(:s_lines))} |"
end
puts
puts "Qualifier characters are #{format("%.1f", 100.0 * sum.(:qual_chars) / rows.sum { File.read(_1[:name]).gsub(/#.*$/, "").size })}% of the Sake source (comments excluded)."
puts
puts "| feature | uses | programs using it |"
puts "|---|---|---|"
%i[attr struct_new class_paste exception_class initialize optional_params keyword_params kwargs_call assert_type once block_given block_pass io].each do |k|
  puts "| #{k} | #{sum.(k)} | #{rows.count { (_1[k] || 0).positive? }} |"
end
