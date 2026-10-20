gem "actionpack", "8.1.3"
require "action_dispatch"

# --- the path parser, the String visitor and Journey::Format (Ruby's journey test, side by side with journey.sake) ---
paths = ["/posts/:id(.:format)", "/files/*path", "(/:locale)/hello(.:format)", "/a|/b", "/x\\:y", "/:controller(/:action(/:id))"]
paths.each do |s|
  tree = ActionDispatch::Journey::Parser.parse(s)
  puts "#{s} -> #{tree} #{tree.type}"
  kinds = []
  tree.each { |n| kinds << n.type }
  p kinds
  ast = ActionDispatch::Journey::Ast.new(tree, true)
  p [ast.names, ast.path_params, ast.glob?]
  pattern = ActionDispatch::Journey::Path::Pattern.new(ast, {}, "/.?", true)
  p [pattern.source, pattern.required_names, pattern.optional_names]
  p pattern.build_formatter.evaluate({ id: "1 2", format: "json", path: "a/b c", locale: "en", controller: "admin/users", action: "show" })
end

# --- requirements: a symbol's regexp, and the offsets of groups inside requirements ---
tree = ActionDispatch::Journey::Parser.parse("/posts/:year/:id(.:format)")
ast = ActionDispatch::Journey::Ast.new(tree, true)
reqs = { year: /(19|20)\d\d/, id: /\d+/ }
ast.requirements = reqs
pattern = ActionDispatch::Journey::Path::Pattern.new(ast, reqs, "/.?", true)
p pattern.source
md = pattern.match("/posts/2024/15.json")
p [md.names, md.captures, md.named_captures, md.to_s]
p pattern.match("/posts/1899/15")
p pattern.requirements_anchored?

# --- an unanchored pattern (mount) leaves the rest of the path ---
tree = ActionDispatch::Journey::Parser.parse("/admin")
pattern = ActionDispatch::Journey::Path::Pattern.new(ActionDispatch::Journey::Ast.new(tree, false), {}, "/.?", false)
md = pattern.match("/admin/users/1")
p [pattern.source, md.to_s, md.post_match]

# --- Router::Utils ---
U = ActionDispatch::Journey::Router::Utils
p [U.normalize_path("/foo/"), U.normalize_path(""), U.normalize_path("foo"), U.normalize_path("/%ab//c/"), U.normalize_path(nil)]
p [U.escape_path("a b/c?d"), U.escape_segment("a b/c?d"), U.escape_fragment("a b/c?d#e"), U.escape_segment("日本")]
