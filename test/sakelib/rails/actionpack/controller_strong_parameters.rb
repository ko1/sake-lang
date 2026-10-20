gem "actionpack", "8.1.3"
require "action_controller"
require "active_support/core_ext/object/deep_dup"

P = ActionController::Parameters

def show(label, x)
  puts("#{label}: #{x.inspect}")
end

def check(label)
  show(label, yield)
rescue ActionController::ParameterMissing, ActionController::ExpectedParameterMissing => e
  puts("#{label}: #{e.class}: #{e.message} keys=#{e.keys.inspect}")
rescue ActionController::UnpermittedParameters => e
  puts("#{label}: #{e.class}: #{e.message} params=#{e.params.inspect}")
rescue ActionController::UnfilteredParameters, ActionController::InvalidParameterKey => e
  puts("#{label}: #{e.class}: #{e.message}")
end

# params as a request gives them (String keys), plus a Symbol-keyed Hash
raw = {
  "controller" => "posts", "action" => "create",
  "post" => { "title" => "Hello", "body" => "World", "admin" => "1", "tags" => ["a", "b"],
              "prefs" => { "theme" => "dark", "size" => 3, "deep" => { "x" => "1" } },
              "comments" => [{ "text" => "c1", "spam" => "x" }, { "text" => "c2" }],
              "authors_attributes" => { "0" => { "name" => "ann", "age" => "3" }, "1" => { "name" => "bob" } },
              "published_at(1i)" => "2026", "published_at(2i)" => "10" },
  "id" => "42", "empty" => "", "flag" => false, "list" => []
}
params = P.new(raw)
show("new", params)
show("permitted?", params.permitted?)
show("[] symbol", params[:id])
show("[] string", params["id"])
show("nested", params[:post][:title])
show("after access", params)
show("keys", params.keys)
show("key?", [params.key?(:post), params.has_key?("post"), params.include?(:nope)])
show("dig", params.dig(:post, :prefs, :theme))
show("dig array", params.dig(:post, :comments, 0, :text))
show("fetch", params.fetch(:id))
show("fetch default", params.fetch(:none, "dflt"))
show("fetch block", params.fetch(:none) { "blk" })
check("fetch missing") { params.fetch(:none) }

# require / permit
check("require") { params.require(:post) }
check("require missing") { params.require(:nope) }
check("require empty") { params.require(:empty) }
check("require false") { params.require(:flag) }
check("require list") { params.require([:id, :flag]) }
post = params.require(:post)
check("permit scalars") { post.permit(:title, :body) }
check("permit array") { post.permit(:title, tags: []) }
check("permit hash any") { post.permit(prefs: {}) }
check("permit hash keys") { post.permit(prefs: [:theme]) }
check("permit array of hashes") { post.permit(comments: [:text]) }
check("permit explicit array of hashes") { post.permit(comments: [[:text]]) }
check("permit nested attributes") { post.permit(authors_attributes: [:name]) }
check("permit multi-parameter") { post.permit(:published_at) }
check("permit scalar not hash") { post.permit(:prefs, :tags) }
check("permit string keys") { post.permit("title", { "tags" => [] }) }
check("permit to_h") { post.permit(:title, tags: []).to_h }
check("to_h unpermitted") { post.to_h }
check("to_unsafe_h") { post.slice(:title, :prefs).to_unsafe_h }
check("to_hash") { post.permit(:title, prefs: {}).to_hash }
check("to_query") { post.permit(:title, tags: []).to_query }
check("to_query ns") { post.permit(:title).to_query("p") }

# expect
check("expect") { params.expect(post: [:title, :body]) }
check("expect scalar") { params.expect(:id) }
check("expect two") { params.expect(:id, post: [:title]) }
check("expect array of hashes") { params[:post].expect(comments: [[:text]]) }
check("expect missing") { params.expect(user: [:name]) }
check("expect wrong shape") { params.expect(id: [:x]) }
check("expect!") { params.expect!(user: [:name]) }

# action_on_unpermitted_parameters
P.action_on_unpermitted_parameters = :raise
check("raise one") { post.permit(:title, :body, :admin, :tags, :prefs, :comments, :authors_attributes, "published_at(1i)") }
check("raise many") { post.permit(:title) }
check("raise top keeps controller/action") { params.permit(:id, :empty, :flag, :list, post: {}) }
check("expect does not raise") { params.expect(:id) }
class Logged
  def call(name, start, finish, id, payload)
    puts("#{name}: #{payload[:keys].inspect} #{payload[:context].inspect}")
  end
end
ActiveSupport::Notifications.subscribe("unpermitted_parameters.action_controller", Logged.new)
P.action_on_unpermitted_parameters = :log
check("log") { P.new({ "a" => "1", "b" => "2" }, { action: "create" }).permit(:a) }
P.action_on_unpermitted_parameters = false
P.permit_all_parameters = true
check("permit_all") { P.new("a" => "1") }
P.permit_all_parameters = false

# permit! and the other Hash-like methods
check("permit!") { P.new("a" => { "b" => [{ "c" => 1 }] }).permit! }
check("permit! nested") { P.new("a" => { "b" => "1" }).permit![:a].permitted? }
q = P.new("a" => "1", "b" => nil, "c" => "", "d" => { "e" => "2" })
check("slice") { q.slice(:a, "d") }
check("except") { q.except(:a) }
check("without") { q.without(:a, :b) }
check("compact") { q.compact }
check("compact_blank") { q.compact_blank }
check("select") { q.select { |k, v| k == "a" || k == "c" } }
check("reject") { q.reject { |k, v| v.nil? } }
check("transform_values") { q.slice(:a, :c).transform_values { |v| "#{v}!" } }
check("transform_keys") { q.slice(:a, :c).transform_keys { |k| k.upcase } }
check("merge") { q.slice(:a).merge(z: "26") }
check("merge params") { q.slice(:a).merge(P.new(b: "2").permit!) }
check("reverse_merge") { q.slice(:a).reverse_merge(a: "0", y: "25") }
check("values") { q.values }
check("each_pair") { r = []; q.each_pair { |k, v| r << [k, v.class.name] }; r }
check("each_value") { r = []; q.each_value { |v| r << v.class.name }; r }
check("has_value?") { [q.has_value?("1"), q.has_value?({ "e" => "2" }), q.value?("9")] }
check("values_at") { q.values_at(:a, :d) }
check("empty?") { [q.empty?, P.new.empty?] }
check("==") { [P.new(a: "1") == P.new("a" => "1"), P.new(a: "1") == P.new(a: "1").permit!, P.new(a: "1") == { "a" => "1" }] }
r = P.new("a" => "1", "b" => "2", "c" => "3")
check("extract!") { r.extract!(:a, :b) }
check("after extract!") { r }
check("delete") { [r.delete(:c), r.delete(:zz), r.delete(:zz) { |k| "no #{k}" }] }
d = P.new("a" => { "b" => "1" })
e = d.deep_dup
e[:a][:b] = "2"
check("deep_dup") { [d, e] }
check("[]=") { s = P.new; s[:k] = "v"; s["h"] = { x: 1 }; s }
check("to_s") { P.new(a: 1).to_s }
check("extract_value") { P.new(tags: "a_b__c").extract_value(:tags) }
check("invalid key") { P.new(1 => "x") }
