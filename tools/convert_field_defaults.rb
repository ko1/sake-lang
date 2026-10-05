# frozen_string_literal: true

# Rewrites field defaults `attr_reader items = Array[]` into initialize (2026-10-05: fields have no
# defaults; C.new may leave out trailing fields of a type with initialize, which sets them):
#   - a default no `C.new` gives:   `@items = Array[]` in initialize
#   - a default some `C.new` gives: `@items = Array[] if @items == nil`
#   - `= nil`: dropped (a left-out field is nil); `@x = nil` only when the class needs an initialize anyway
# Calls are looked up in the file and in every file of the set that requires it (by name).
# usage: ruby tools/convert_field_defaults.rb FILE...   (rewrites in place; prints the changed files)
require "prism"

Default = Struct.new(:name, :index, :src, :is_nil)
ClassInfo = Struct.new(:name, :node, :fields, :defaults, :attr_lines, :init, :parent)

def requires_of(path, src)
  src.scan(/^require\s+"([^"]+)"/).flatten.map { |n| File.basename(n, ".sake") }
end

files = ARGV.to_h { [_1, File.read(_1)] }
by_base = files.keys.group_by { File.basename(_1, ".sake") }
# users[path]: files whose requires (transitively) include path, and path itself
req = files.to_h { |p, s| [p, requires_of(p, s).flat_map { |n| (by_base[n] || []).select { |q| File.dirname(q) == File.dirname(p) || q.include?("sakelib/") } }] }
closure = lambda do |p, seen = {}|
  next [] if seen[p]
  seen[p] = true
  [p, *req[p].flat_map { closure.(_1, seen) }]
end
users = Hash.new { |h, k| h[k] = [] }
files.each_key { |p| closure.(p).each { |q| users[q] << p } }

# [argc, keyword names] of every `C.new(...)` in src (nil argc: unknown, e.g. a splat)
def new_calls(src, cls)
  calls = []
  visit = lambda do |n|
    # `new(...)` without a type (inside a class or an included module) may be cls's own
    if n.is_a?(Prism::CallNode) && n.name == :new && ((n.receiver.is_a?(Prism::ConstantReadNode) && n.receiver.name.to_s == cls) || n.receiver.nil?)
      args = n.arguments&.arguments || []
      kw = args.last.is_a?(Prism::KeywordHashNode) ? args.pop.elements.map { _1.key.unescaped } : []
      calls << [args.any? { _1.is_a?(Prism::SplatNode) } ? nil : args.size, kw]
    end
    n.compact_child_nodes.each { visit.(_1) }
  end
  visit.(Prism.parse(src).value)
  calls
end

ATTR = %i[attr_reader attr_accessor attr_writer].freeze

def attr_call(st)
  return nil unless st.is_a?(Prism::CallNode) && st.receiver.nil?
  return st if ATTR.include?(st.name)
  st.arguments.arguments[0] if st.name == :private && st.arguments&.arguments&.size == 1 && attr_call(st.arguments.arguments[0])
end

def classes(src)
  out = []
  Prism.parse(src).value.statements.body.each do |st|
    next unless st.is_a?(Prism::ClassNode) && st.constant_path.is_a?(Prism::ConstantReadNode)
    body = st.body.is_a?(Prism::StatementsNode) ? st.body.body : []
    attrs = body.filter_map { |b| (a = attr_call(b)) && [b, a] }
    next if attrs.empty? && body.none? { _1.is_a?(Prism::DefNode) && _1.name == :initialize }
    fields = []
    defaults = []
    attrs.each do |_, a|
      (a.arguments&.arguments || []).each do |x|
        name = x.respond_to?(:name) ? x.name.to_s : x.unescaped
        defaults << Default.new(name, fields.size, x.value.slice, x.value.is_a?(Prism::NilNode)) if x.is_a?(Prism::LocalVariableWriteNode)
        fields << name
      end
    end
    init = body.find { _1.is_a?(Prism::DefNode) && _1.name == :initialize }
    parent = st.superclass.is_a?(Prism::ConstantReadNode) ? st.superclass.name.to_s : nil
    out << ClassInfo.new(st.constant_path.name.to_s, st, fields, defaults, attrs.map(&:first), init, parent)
  end
  out
end

files.each do |path, src|
  infos = classes(src).reject { _1.defaults.empty? }
  next if infos.empty?
  edits = [] # [start, end, replacement]
  infos.each do |c|
    calls = users[path].flat_map { new_calls(files[_1], c.name) }
    # subclasses pasted from c (class B < C) in the same files pass c's fields at the same positions
    users[path].each { |u| classes(files[u]).select { _1.parent == c.name }.each { |b| calls += new_calls(files[u], b.name) } }
    given = ->(d) { calls.any? { |argc, kw| argc.nil? || argc > d.index || kw.include?(d.name) } }
    omitted = calls.any? { |argc, kw| argc && argc < c.fields.size && !(c.fields.drop(argc) - kw).empty? }
    lines = c.defaults.filter_map do |d|
      next nil if d.is_nil && given.(d)
      next "@#{d.name} = nil" if d.is_nil
      given.(d) ? "@#{d.name} = #{d.src} if @#{d.name} == nil" : "@#{d.name} = #{d.src}"
    end
    # `= nil` only: an initialize is needed only when some C.new leaves a field out
    lines = [] if c.defaults.all?(&:is_nil) && !c.init && !omitted
    lines = ["nil"] if lines.empty? && omitted && !c.init # an initialize that lets C.new leave fields out
    c.attr_lines.each do |line|
      a = attr_call(line)
      a.arguments.arguments.each do |x|
        next unless x.is_a?(Prism::LocalVariableWriteNode)
        edits << [x.location.start_offset, x.location.end_offset, x.name.to_s]
      end
    end
    next if lines.empty?
    indent = " " * c.attr_lines.first.location.start_column
    if (init = c.init)
      param = init.parameters&.requireds&.first&.name || "c"
      if init.equal_loc # def initialize(c) = expr
        body = init.body.slice
        text = "def initialize(#{param})\n#{lines.map { "#{indent}  #{_1}\n" }.join}#{indent}  #{body}\n#{indent}end"
        edits << [init.location.start_offset, init.location.end_offset, text]
      else
        bstart = init.body ? init.body.location.start_offset : nil
        if bstart
          bindent = " " * init.body.location.start_column
          edits << [bstart, bstart, lines.map { "#{_1}\n#{bindent}" }.join]
        else
          pos = init.rparen_loc ? init.rparen_loc.end_offset : init.name_loc.end_offset
          edits << [pos, pos, lines.map { "\n#{indent}  #{_1}" }.join]
        end
      end
    else
      param = c.name[0].downcase
      text = lines.size == 1 && !lines[0].include?(" if ") ? "\n#{indent}def initialize(#{param}) = #{lines[0]}" :
                               "\n#{indent}def initialize(#{param})\n#{lines.map { "#{indent}  #{_1}\n" }.join}#{indent}end"
      last = c.attr_lines.last.location
      edits << [last.end_offset, last.end_offset, text]
    end
  end
  out = src.b # Prism offsets count bytes
  edits.sort_by { -_1[0] }.each { |s, e, r| out[s...e] = r.b }
  out.force_encoding(Encoding::UTF_8)
  next if out == src
  File.write(path, out)
  puts path
end
