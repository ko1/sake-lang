gem "actionpack", "8.1.3"
require "action_dispatch"
require "active_support/core_ext/object/to_query"   # what a Rails app has loaded

def show(label, v) = puts("#{label}: #{v.inspect}")
URL = ActionDispatch::Http::URL

puts("-- url_for")
show("host and path", URL.url_for(host: "example.com", path: "/posts"))
show("only_path", URL.url_for(host: "example.com", path: "/posts", only_path: true))
show("port", URL.url_for(host: "example.com", port: 3000, path: "/"))
show("default port dropped", URL.url_for(host: "example.com", port: 80, path: "/"))
show("https 443 dropped", URL.url_for(host: "example.com", protocol: "https", port: 443, path: "/a"))
show("protocol with ://", URL.url_for(host: "example.com", protocol: "https://", path: "/a"))
show("protocol-relative", URL.url_for(host: "example.com", protocol: "//", path: "/a"))
show("protocol false", URL.url_for(host: "example.com", protocol: false, path: "/a"))
show("host with protocol and port", URL.url_for(host: "https://example.com:8443", path: "/a"))
show("params", URL.url_for(host: "example.com", path: "/search", params: { q: "a b", page: 2, tags: ["x", "y"], empty: nil }))
show("nested params", URL.url_for(host: "example.com", path: "/s", params: { filter: { name: "ko1", age: 50 }, z: "1" }))
show("anchor", URL.url_for(host: "example.com", path: "/posts", anchor: "comment 1"))
show("trailing_slash", URL.path_for(path: "", trailing_slash: true))
show("script_name", URL.path_for(script_name: "/app/", path: "/posts"))
show("user and password", URL.url_for(host: "example.com", path: "/", user: "ko1", password: "p@ss"))
show("subdomain", URL.url_for(host: "www.example.com", subdomain: "api", path: "/"))
show("subdomain false", URL.url_for(host: "www.example.com", subdomain: false, path: "/"))
show("domain", URL.url_for(host: "www.example.com", domain: "example.org", path: "/"))
show("tld_length", URL.url_for(host: "www.example.co.uk", subdomain: "shop", tld_length: 2, path: "/"))
show("ip host", URL.url_for(host: "127.0.0.1", subdomain: "x", port: 8080, path: "/"))
begin
  URL.url_for(path: "/posts")
rescue ArgumentError => e
  show("ArgumentError", e.message)
end
begin
  URL.url_for(host: "example.com", protocol: "http:/x", path: "/")
rescue ArgumentError => e
  show("bad protocol", e.message)
end

puts("-- domains")
show("extract_domain", URL.extract_domain("www.example.com", 1))
show("extract_domain 2", URL.extract_domain("www.example.co.uk", 2))
show("extract_domain ip", URL.extract_domain("192.168.0.1", 1))
show("extract_subdomains", URL.extract_subdomains("a.b.example.com", 1))
show("extract_subdomain", URL.extract_subdomain("a.b.example.com", 1))
show("extract_subdomains ip", URL.extract_subdomains("10.0.0.1", 1))
show("tld_length", URL.tld_length)
