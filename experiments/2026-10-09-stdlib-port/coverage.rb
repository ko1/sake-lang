# Ruby's public instance methods per core class vs the operations Sake's registry defines in that namespace.
$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "set"; require "stringio"
program = Sake.load("puts 1\n", "x.sake", out: StringIO.new)
reg = program.registry
SKIP = /\A(__|instance_|singleton_|public_|private_|protected_|method|define_|respond_to|send|object_id|class\z|frozen\?|freeze|dup|clone|itself|then|yield_self|tap|display|extend|is_a\?|kind_of\?|instance_of\?|nil\?|equal\?|eql\?|hash\z|inspect\z|to_s\z|to_enum|enum_for|taint|untaint|trust|untrust|pretty_|=~|!~|!\z|!=|==\z|===|<=>|\[\]|\+|-|\*|\/|%|\*\*|<<|>>|&|\||\^|~|<\z|<=|>\z|>=|-@|\+@)/
{ Integer => "Integer", Float => "Float", Rational => "Rational", Complex => "Complex", String => "String", Symbol => "Symbol",
  Array => "Array", Hash => "Hash", Set => "Set", Range => "Range", Regexp => "Regexp", MatchData => "MatchData", Time => "Time" }.each do |klass, ns|
  ruby = klass.public_instance_methods(false).map(&:to_s).reject { _1.match?(SKIP) }.sort
  ruby += Enumerable.public_instance_methods(false).map(&:to_s).reject { _1.match?(SKIP) } if klass.include?(Enumerable) && ![Array, Hash].include?(klass)
  ruby = ruby.uniq.sort
  have = reg.names(ns).map(&:to_s)
  missing = ruby - have
  puts "#{ns}: ruby #{ruby.size}, sake #{have.size}, missing #{missing.size}: #{missing.join(" ")}"
end
%w[Kernel Math File Dir IO].each { |ns| puts "#{ns}: sake #{reg.names(ns).size}: #{reg.names(ns).sort.join(" ")}" }
