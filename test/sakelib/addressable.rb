require "addressable/uri"
require "addressable/template"

def show(u)
  puts(u.to_s)
end

# parse and the components
u = Addressable::URI.parse("http://user:pw@Example.COM:8080/a/b/c.html;x=1?q=1&r=two#frag")
p(u.scheme, u.user, u.password, u.userinfo, u.host, u.port)
p(u.path, u.query, u.fragment, u.authority, u.site, u.origin)
p(u.basename, u.extname, u.request_uri, u.inferred_port, u.default_port)
p(u.absolute?, u.relative?, u.ip_based?, u.hostname)
p(u.to_hash)
p(u.inspect.sub(/:0x\h+/, ""))
r = Addressable::URI.parse("../x/y?z")
p(r.scheme, r.host, r.path, r.query, r.relative?, r.request_uri)
p(Addressable::URI.parse("mailto:bob@example.com").path)
p(Addressable::URI.parse("http://[::1]:3000/").hostname)
p(Addressable::URI.parse("").empty?)

# normalize: case, default port, dot segments, percent-encoding, IDN
show(Addressable::URI.parse("HTTP://www.Example.com:80/./a/../b/%7euser/%3f?b=2&a=1#F").normalize)
show(Addressable::URI.parse("http://example.com").normalize)
show(Addressable::URI.parse("http://example.com/a b/ü?q=a b").normalize)
show(Addressable::URI.parse("http://www.詹姆斯.com/").normalize)
show(Addressable::URI.parse("http://www.xn--8ws00zhy3a.com/").display_uri)
show(Addressable::URI.parse("http://müller.de/").normalize)
p(Addressable::URI.parse("http://example.com/?b=2&&a=1&b=2").normalized_query(:compacted, :sorted))
p(Addressable::URI.parse("feed://http://example.com/").normalize.to_s)
p(Addressable::URI.parse("http://example.com/").normalized_site)
p(Addressable::URI.parse("HTTP://a.com:443/").normalized_port, Addressable::URI.parse("https://a.com:443/").normalized_port)

# join, merge, route
base = Addressable::URI.parse("http://a/b/c/d;p?q")
["g", "./g", "g/", "/g", "//g", "?y", "g?y", "#s", "g#s", "..", "../g", "../..", "../../g", "../../../g", ""].each do |ref|
  puts("#{ref} -> #{base.join(ref)}")
end
show(Addressable::URI.join("http://example.com/a/", "b/", "c"))
show(base + "x/y")
show(u.merge(path: "/new", query: nil, port: 81))
show(Addressable::URI.parse("http://example.com/a/b/c").route_from("http://example.com/a/d"))
show(Addressable::URI.parse("http://example.com/a/").route_to("http://example.com/a/b/c?x"))
show(Addressable::URI.parse("http://example.com/x").route_from("http://other.com/x"))
show(u.omit(:userinfo, :port, :fragment))
show(u.omit(:scheme, :authority))
p(Addressable::URI.parse("http://example.com/") == Addressable::URI.parse("HTTP://EXAMPLE.COM:80"))
p(Addressable::URI.parse("http://example.com/").eql?(Addressable::URI.parse("HTTP://EXAMPLE.COM:80")))
p(Addressable::URI.parse("http://example.com/") === "http://Example.com/")

# setters
v = Addressable::URI.parse("http://example.com/path")
v.scheme = "https"
v.host = "www.example.org"
v.port = "8443"
v.user = "me"
v.password = "secret"
v.path = "other/file.txt"
v.query = "a=1"
v.fragment = "top"
show(v)
v.userinfo = "u2:p2"
v.authority = "host.example:99"
show(v)
v.site = "ftp://files.example"
show(v)
v.origin = "http://origin.example:8000"
show(v)
v.hostname = "::1"
p(v.host, v.hostname)
v.request_uri = "/req?x=y"
show(v)
w = Addressable::URI.new(scheme: "http", host: "example.com", path: "/a")
show(w)
w.query_values = {"b" => "two words", "a" => ["1", "2"], "c" => nil}
show(w)
p(w.query_values)
w.query_values = [["z", "1"], ["y", "2"]]
show(w)
p(Addressable::URI.parse("http://x/?a=1+2&b=%41&c&d=").query_values)
p(Addressable::URI.parse("http://x/?a=1&b=2").query_values(Array))
x = Addressable::URI.parse("http://example.com/a/../b")
x.normalize!
show(x)
x.join!("c/d")
show(x)
x.merge!(fragment: "f")
show(x)
show(x.dup)

# tld and domain (the Public Suffix List)
y = Addressable::URI.parse("http://www.example.co.uk/")
p(y.tld, y.domain)
y.tld = "com"
show(y)

# encoding
p(Addressable::URI.encode_component("a b&c/d?é"))
p(Addressable::URI.encode_component("a b&c/d", Addressable::URI::CharacterClasses::UNRESERVED))
p(Addressable::URI.encode_component("a b&c", Addressable::URI::CharacterClassesRegexps::UNRESERVED))
p(Addressable::URI.encode_component("simple+text", "a-z", "+"))
p(Addressable::URI.unencode("%41%42%2Fc%C3%A9"))
p(Addressable::URI.unencode("%41%2F%2B", String, "/"))
p(Addressable::URI.unescape("a%20b"))
p(Addressable::URI.normalize_component("%7euser a", Addressable::URI::CharacterClasses::UNRESERVED))
p(Addressable::URI.normalize_component("a+b%2Bc", "a-z+", "+"))
p(Addressable::URI.encode("http://example.com/a b?q=é#f g"))
p(Addressable::URI.escape("http://ex.com/ü"))
p(Addressable::URI.normalized_encode("http://example.com/%7Ea b?q=é"))
p(Addressable::URI.form_encode({"name" => "Bob Smith", "tags" => ["a&b", "c"], "n" => "1\n2"}))
p(Addressable::URI.form_encode([["b", "2"], ["a", "1"]], true))
p(Addressable::URI.form_unencode("name=Bob+Smith&x=%26&flag&y=1%0D%0A2"))

# heuristic_parse
["example.com", "http:/example.com", "www.example.com/path?q", "192.168.0.1:8080/x",
 "file:///tmp/x", "feed://example.com/rss", "user@example.com"].each do |s|
  puts("#{s} -> #{Addressable::URI.heuristic_parse(s)}")
end
show(Addressable::URI.heuristic_parse("example.com", {scheme: "https"}))
show(Addressable::URI.convert_path("/tmp/some file"))

# IDNA
p(Addressable::IDNA.to_ascii("www.Bücher.de"))
p(Addressable::IDNA.to_ascii("日本語.jp"))
p(Addressable::IDNA.to_unicode("xn--bcher-kva.de"))
p(Addressable::IDNA.to_unicode("xn--wgv71a119e.jp"))
p(Addressable::IDNA.to_unicode("xn--!!.com"))

# errors
["http://exa mple.com/", "http:", "1http://x", "http://host:port/", "//a//b", "http://[x y]/"].each do |s|
  begin
    show(Addressable::URI.parse(s))
  rescue Addressable::URI::InvalidURIError => e
    puts("InvalidURIError: #{e.message}")
  end
end
begin
  Addressable::URI.new(path: "a:b")
rescue Addressable::URI::InvalidURIError => e
  puts("InvalidURIError: #{e.message}")
end
begin
  Addressable::URI.parse("mailto:x").request_uri = "/y"
rescue Addressable::URI::InvalidURIError => e
  puts("InvalidURIError: #{e.message}")
end
begin
  u.omit(:bogus)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
begin
  u.merge(authority: "a.com", host: "b.com")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
begin
  u.merge(path: 1)
rescue TypeError => e
  puts("TypeError: #{e.message}")
end
begin
  Addressable::URI.parse("/relative").route_from("http://example.com/")
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# Template: RFC 6570 expansion, levels 1 to 4 (the RFC's examples)
vars = {
  "var" => "value", "hello" => "Hello World!", "path" => "/foo/bar", "empty" => "",
  "x" => "1024", "y" => "768", "list" => ["red", "green", "blue"],
  "keys" => {"semi" => ";", "dot" => ".", "comma" => ","}, "undef" => nil
}
["{var}", "{hello}", "{+var}", "{+hello}", "{+path}/here", "here?ref={+path}", "X{#var}", "X{#hello}",
 "map?{x,y}", "{x,hello,y}", "{+x,hello,y}", "{+path,x}/here", "{#x,hello,y}", "{#path,x}/here",
 "X{.var}", "X{.x,y}", "{/var}", "{/var,x}/here", "{;x,y}", "{;x,y,empty}", "{?x,y}", "{?x,y,empty}",
 "?fixed=yes{&x}", "{&x,y,empty}", "{var:3}", "{var:30}", "{list}", "{list*}", "{keys}", "{keys*}",
 "{+path:6}/here", "{+list}", "{+list*}", "{+keys}", "{+keys*}", "{#path:6}/here", "{#list}", "{#list*}",
 "{#keys*}", "X{.var:3}", "X{.list}", "X{.list*}", "X{.keys}", "X{.keys*}", "{/var:1,var}", "{/list}",
 "{/list*}", "{/list*,path:4}", "{/keys}", "{/keys*}", "{;hello:5}", "{;list}", "{;list*}", "{;keys}",
 "{;keys*}", "{?var:3}", "{?list}", "{?list*}", "{?keys}", "{?keys*}", "{&var:3}", "{&list}", "{&list*}",
 "{&keys}", "{&keys*}", "{undef}", "{?undef,x}", "{var}{undef}{x}"].each do |pattern|
  puts("#{pattern} => #{Addressable::Template.new(pattern).expand(vars)}")
end
t = Addressable::Template.new("http://example.com/{resource}/{id}{?q,page}")
show(t.expand({"resource" => "users", "id" => 42, "q" => "a b"}))
show(t.expand({resource: "posts", id: "7"}))
p(t.pattern, t.variables, t.keys, t.variable_defaults)
p(t.inspect.sub(/:0x\h+/, ""))
p(t == Addressable::Template.new("http://example.com/{resource}/{id}{?q,page}"))
p(t.partial_expand({"resource" => "users"}).pattern)
p(Addressable::Template.new("{?a,b,c}").partial_expand({"b" => "2"}).pattern)
p(Addressable::Template.new("http://x/{name}").expand({"name" => "Ünïcödé"}).to_s)
p(Addressable::Template.new("{var}").expand({"var" => "é"}, nil, false).to_s)

# Template: extract and match
p(t.extract("http://example.com/users/42?q=hello%20world&page=2"))
p(t.extract("http://example.com/users/42"))
p(t.extract("http://other.com/users/42"))
p(Addressable::Template.new("/search{?tags*}").extract("/search?tags=a&tags=b"))
p(Addressable::Template.new("{/segments*}").extract("/a/b/c"))
p(Addressable::Template.new("/files{/path*}{.ext}").extract("/files/a/b.txt"))
p(Addressable::Template.new("/q{?keys*}").extract("/q?a=1&b=2"))
p(Addressable::Template.new("{;x,y}").extract(";x=1;y=2"))
p(Addressable::Template.new("{+path}/here").extract("/foo/bar/here"))
p(Addressable::Template.new("http://example.com/").extract("http://example.com/"))
md = t.match("http://example.com/users/42?q=x")
p(md.variables, md.values, md.captures, md.to_a, md.to_s, md.string)
p(md["id"], md[0], md[2], md[1, 2], md.values_at(1, 2), md.pre_match, md.post_match)
p(md.mapping, md.uri.to_s, md.template.pattern)
p(md.inspect.sub(/:0x\h+/, ""))
p(t.match("ftp://nope/"))
p(Addressable::Template.new("{x}/{y}").to_regexp.source == Addressable::Template.new("{x}/{y}").source)
p(Addressable::Template.new("{x}/{y}").named_captures)
