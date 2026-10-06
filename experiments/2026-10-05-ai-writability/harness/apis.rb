# frozen_string_literal: true

# Calls to APIs that do not exist, counted from the program text: ruby apis.rb FILE...  (solution.* or attempt-NN.*)
# One JSON line per file:
#   nowhere   calls to a name defined nowhere (both languages, the same rule: no built-in type/module and no
#             definition in the file has a function/method of that name)
#   elsewhere Sake only: the name exists, but not on the type written (`Array.upcase`); Ruby cannot tell
#             this statically (the receiver's type is unknown), so it is nil there
#   names     the offending calls; nowhere/elsewhere are nil (not 0) when the file does not parse.
# Sake: from the checker's resolver (`bin/sake --strict=0 -c`). Ruby: Prism call names against every method
# of every module loaded after the file's `require`s, plus what the file defines (def, attr_*, Struct/Data members).
require_relative "common"
require "prism"

module APIs
  module_function

  def sake(file)
    out, err, st = AW.run([AW::SAKE, "--strict=0", "-c", file], "")
    text = out + err
    return { nowhere: nil, elsewhere: nil, names: [], error: text.lines.first(3).join } if text.include?("syntax error")
    nowhere, elsewhere = [], []
    # an error line and its hint lines
    text.scan(/^\S+:\d+:\d+: error: (.*)\n((?:  hint: .*\n)*)/) do |msg, hints|
      case msg
      when /\Aundefined function `([A-Z]\w*)\.([^`]+)`/
        (hints.include?("is defined in") ? elsewhere : nowhere) << "#{$1}.#{$2}"
      when /\Aundefined type or module `([^`]+)`/
        nowhere << $1
      when /\Aundefined (?:local variable or )?function `([^`]+)`/
        (hints.match?(/hint: [A-Z]\w*\.\Q#{$1}\E\(/) ? elsewhere : nowhere) << $1
      end
    end
    { nowhere: nowhere.size, elsewhere: elsewhere.size, names: nowhere + elsewhere.map { "#{_1} (other type)" }, status: st }
  end

  LIBS = Hash.new do |h, reqs|
    code = "#{reqs.map { "require #{_1.dump}; " }.join}names = []; ObjectSpace.each_object(Module) { |m| " \
           "names.concat(m.instance_methods(true), m.private_instance_methods(true), m.singleton_methods(true), " \
           "m.private_methods(true)) rescue nil }; puts names.uniq.map(&:to_s)"
    out, err, st = AW.run(["ruby", "--disable-gems", "-e", code], "")
    abort "listing Ruby methods failed: #{err}" unless st == 0
    h[reqs] = out.lines.map(&:chomp).to_set
  end

  def ruby(file)
    res = Prism.parse_file(file)
    return { nowhere: nil, elsewhere: nil, names: [], error: res.errors.first(3).map(&:message).join("; ") } if res.failure?
    calls, defined, reqs = [], Set.new, []
    walk = lambda do |n|
      case n
      when Prism::CallNode
        if n.receiver.nil? && n.name == :require && (a = n.arguments&.arguments&.first).is_a?(Prism::StringNode)
          reqs << a.unescaped
        elsif n.receiver.nil? && %i[attr_reader attr_writer attr_accessor define_method alias_method].include?(n.name)
          n.arguments&.arguments&.each do |s|
            next unless s.is_a?(Prism::SymbolNode)
            defined << s.unescaped
            defined << "#{s.unescaped}=" unless n.name == :attr_reader
          end
        elsif %i[new define].include?(n.name) && n.receiver.is_a?(Prism::ConstantReadNode) && %i[Struct Data].include?(n.receiver.name)
          n.arguments&.arguments&.each { |s| defined.merge([s.unescaped, "#{s.unescaped}="]) if s.is_a?(Prism::SymbolNode) }
        end
        calls << [n.name.to_s, n.location.start_line]
      when Prism::DefNode then defined << n.name.to_s
      when Prism::AliasMethodNode then defined << n.new_name.unescaped
      end
      n.compact_child_nodes.each { walk.(_1) }
    end
    walk.(res.value)
    known = LIBS[reqs.sort.uniq]
    bad = calls.reject { |name, _| known.include?(name) || defined.include?(name) }
    { nowhere: bad.size, elsewhere: nil, names: bad.map { |name, line| "#{name}:#{line}" } }
  end
end

if $0 == __FILE__
  require "set"
  ARGV.each do |f|
    r = AW.lang_of(f) == "sake" ? APIs.sake(f) : APIs.ruby(f)
    puts JSON.generate({ file: f }.merge(r))
  end
end
