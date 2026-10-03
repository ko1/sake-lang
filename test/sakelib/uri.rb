require "uri"

def show(u)
  p([u.scheme, u.userinfo, u.user, u.password, u.host, u.hostname, u.port,
     u.path, u.opaque, u.query, u.fragment, u.to_s, u.absolute?, u.relative?])
  p(u)
end

puts("-- parse")
inputs = ["HTTP://User:Pw@Example.COM:8080/a/b?x=1#Frag", "https://example.com",
  "http://example.com:/p", "mailto:a@b.com", "urn:isbn:0451450523?x", "//host/p", "/abs?q",
  "rel/p", "", "http://[::1]:3000/", "http://192.168.0.1/", "ftp://ftp.example.com/pub/file.txt",
  "http://h/%7Efoo", "file:///etc/hosts", "http://user@h", "http://user:@h", "foo:/bar", "http://h?q",
  "ws://h", "wss://h:443/x", "HTTP://h:80/", "http://h:0080/", "ldap://ldap.example.com/dc=x",
  "https://h:8443/a?b=c&d=e#f?g", "#frag", "?q=1", "http://h/a%20b"]
inputs.each { |s| show(URI.parse(s)) }

puts("-- errors")
bad = ["http://a b", "http://h/é", "http://h:x/", "1http://h", "http://h/<", "http://h/%zz", "日本", "http://h/😀\u0085"]
bad.each do |s|
  begin
    URI.parse(s)
    puts("parsed?")
  rescue URI::InvalidURIError => e
    p(e.message)
  end
end

puts("-- request_uri")
p(URI.parse("http://h/p?q=1").request_uri)
p(URI.parse("http://h").request_uri)
p(URI.parse("http://h?x").request_uri)

puts("-- join (RFC 3986 5.4)")
base = "http://a/b/c/d;p?q"
refs = ["g:h", "g", "./g", "g/", "/g", "//g", "?y", "g?y", "#s", "g#s", "g?y#s", ";x", "g;x",
  "g;x?y#s", "", ".", "./", "..", "../", "../g", "../..", "../../", "../../g",
  "../../../g", "../../../../g", "/./g", "/../g", "g.", ".g", "g..", "..g", "./../g", "./g/.",
  "g/./h", "g/../h", "g;x=1/./y", "g;x=1/../y", "g?y/./x", "g?y/../x", "g#s/./x", "g#s/../x"]
refs.each { |r| puts("#{r} -> #{URI.join(base, r)}") }
p(URI.join("http://example.com/docs/", "api/v1"))
p(URI.join(URI.parse("http://example.com/a/b"), "c?d#e"))
p(URI.join("http://example.com/a/", "b/", "c"))
p(URI.join("http://example.com/a/", "b/", "c/", "../d"))
p(URI.join("http://example.com/a"))
p(URI.join("http://example.com:8080/a", "//other.org/x"))

puts("-- merge and +")
u = URI.parse("https://example.com/a/b/c")
p(u.merge("../d"))
p(u + "x?y=1")
p(u + URI.parse("/root"))
begin
  URI.parse("a/b").merge("c")
rescue URI::BadURIError => e
  p(e.message)
end

puts("-- setters")
u = URI.parse("http://example.com/search")
u.query = URI.encode_www_form({"q" => "ruby sake", "page" => 2})
puts(u)
u.fragment = "top"
u.port = 8080
u.path = "/find"
u.host = "example.org"
puts(u)
p(URI.parse("http://EXAMPLE.com").normalize)

puts("-- equality")
p(URI.parse("http://h/a") == URI.parse("http://h/a"))
p(URI.parse("http://h/a") == URI.parse("http://h/b"))

puts("-- split")
p(URI.split("http://u@h:8080/p/q?x#f"))
p(URI.split("http://h/p"))
p(URI.split("mailto:a@b"))
p(URI.split("rel/p?x"))

puts("-- www form")
p(URI.encode_www_form({"q" => "a b", "lang" => "日本語", "x" => nil, "list" => [1, 2, nil]}))
p(URI.encode_www_form([["a", "1"], ["a", "2"], ["b&c", "d=e"]]))
p(URI.encode_www_form({sym: :val, n: 1.5}))
p(URI.encode_www_form({}))
p(URI.decode_www_form("a=1&b=%E3%81%82+x&c&=v&d=&e=%zz"))
p(URI.decode_www_form(""))
p(URI.decode_www_form("a=1&&b=2&"))
p(URI.decode_www_form("a=b=c"))
begin
  URI.decode_www_form("a=é")
rescue ArgumentError => e
  p(e.message)
end

puts("-- components")
p(URI.encode_www_form_component("a b*-._~!'()/?&=+%é😀"))
p(URI.encode_www_form_component(""))
p(URI.encode_uri_component("a b+c"))
p(URI.decode_www_form_component("a+b%20c%E6%97%A5"))
p(URI.decode_uri_component("a+b%20c"))
p(URI.decode_www_form_component(""))
["%", "%4", "%zz", "a%"].each do |s|
  begin
    URI.decode_www_form_component(s)
  rescue ArgumentError => e
    p(e.message)
  end
end
p(URI.decode_www_form_component(URI.encode_www_form_component("round trip 日本 & =")))

puts("-- the optional encoding of decoded values")
b = URI.decode_www_form_component("%E6%97%A5+x", "ASCII-8BIT")
p(b)
p(URI.decode_uri_component("%E6%97%A5+x", "ASCII-8BIT"))
p(URI.decode_www_form("k=%E6%97%A5&x=1", "ASCII-8BIT").map { |k, v| [k, v] })
