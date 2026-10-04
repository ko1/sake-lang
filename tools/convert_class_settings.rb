# frozen_string_literal: true

# Rewrites the old field declarations `class C < {reader: [x], accessor: [n], default: {n: 0}, exception: true}`
# into the body form (2026-10-04):
#   class C < Exception      # only when exception: true
#     attr_reader x
#     attr_accessor n = 0
# Fields keep their order (that of C.new's arguments); consecutive fields of one kind share a line.
# usage: ruby tools/convert_class_settings.rb FILE.sake...   (rewrites the files in place; prints the changed ones)
require "prism"

def kind_of(f, readers, writers)
  return "accessor" if readers.include?(f) && writers.include?(f)
  readers.include?(f) ? "reader" : "writer"
end

def convert(src)
  edits = []
  Prism.parse(src).value.statements.body.grep(Prism::ClassNode).each do |node|
    sup = node.superclass
    next unless sup.is_a?(Prism::HashNode)
    fields = []
    readers = []
    writers = []
    defaults = {}
    exception = false
    sup.elements.each do |el|
      key = el.key.unescaped
      case key
      when "reader", "accessor", "writer"
        names = el.value.elements.map { _1.slice.delete_prefix(":") }
        fields |= names
        readers |= names unless key == "writer"
        writers |= names unless key == "reader"
      when "default" then el.value.elements.each { defaults[_1.key.unescaped] = _1.value.slice }
      when "exception" then exception = el.value.is_a?(Prism::TrueNode)
      else raise "unknown setting #{key}"
      end
    end
    fields -= ["message"] if exception
    indent = src[src.rindex("\n", node.location.start_offset - 1).to_i...node.location.start_offset].delete("\n")
    inner = "#{indent}  "
    lines = fields.chunk { kind_of(_1, readers, writers) }.map do |kind, fs|
      "#{inner}attr_#{kind} #{fs.map { |f| defaults.key?(f) ? "#{f} = #{defaults[f]}" : f }.join(", ")}\n"
    end
    # " < {...}" after the class name becomes "" (or " < Exception"); the attr lines follow the header line.
    from = node.constant_path.location.end_offset
    to = sup.location.end_offset
    eol = src.index("\n", to) || src.size
    rest = src[to...eol]
    if rest.strip.empty? || rest.strip.start_with?("#")
      edits << [from, eol + 1, "#{exception ? " < Exception" : ""}#{rest}\n#{lines.join}"]
    else # `class C < {...}; end` or code after the header on its line
      edits << [from, to, "#{exception ? " < Exception" : ""}\n#{lines.join}#{indent} "]
    end
  end
  out = src.dup
  edits.sort_by { -_1[0] }.each { |a, b, text| out[a...b] = text }
  out
end

if __FILE__ == $0
  ARGV.each do |path|
    src = File.read(path)
    out = convert(src)
    next if out == src
    File.write(path, out)
    puts path
  end
end
