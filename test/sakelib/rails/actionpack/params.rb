gem "actionpack", "8.1.3"
require "action_dispatch"
require "active_support/core_ext/hash/indifferent_access"   # (Request loads it)

def show(label, v) = puts("#{label}: #{v.inspect}")
def build(qs) = ActionDispatch::ParamBuilder.from_query_string(qs).to_h

puts("-- QueryParser.each_pair")
show("pairs", ActionDispatch::QueryParser.each_pair("a=1&b=x+y%21&c&d=&&e=%E3%81%82").to_a)
show("separator ;", ActionDispatch::QueryParser.each_pair("a=1; b=2", ";").to_a)
show("separator &;", ActionDispatch::QueryParser.each_pair("a=1;b=2&c=3", "&;").to_a)

puts("-- ParamBuilder")
show("flat", build("a=1&b=2&a=3"))
show("nested", build("user[name]=ko1&user[address][city]=Tokyo"))
show("array", build("ids[]=1&ids[]=2&ids[]="))
show("array of hashes", build("items[][id]=1&items[][qty]=2&items[][id]=3"))
show("nested array of hashes", build("o[items][][id]=1&o[items][][id]=2"))
show("x[][y][z]", build("x[][y][z]=1&x[][y][w]=2"))
show("no value", build("flag&other=1"))
show("leading bracket", build("[a]=1&b[=2"))
show("empty key", build("=1&a=2"))
show("deep", build("a[b][c][d]=1"))
def error(label)
  yield
rescue ActionDispatch::ParameterTypeError => e
  show("#{label}: ParameterTypeError", e.message)
rescue ActionDispatch::ParamsTooDeepError => e
  show("#{label}: ParamsTooDeepError", e.message)
end
error("hash then array") { build("a[]=1&a[b]=2") }
error("array then hash") { build("a[b]=1&a[]=2") }
error("too deep") { ActionDispatch::ParamBuilder.new(3).from_query_string("a[b][c][d]=1") }
show("from_pairs", ActionDispatch::ParamBuilder.from_pairs([["post[title]", "Hi"], ["post[tags][]", "a"]]).to_h)
show("from_hash", ActionDispatch::ParamBuilder.from_hash({ "a" => [1, nil, { b: 2 }], c: { "d" => nil } }).to_h)
