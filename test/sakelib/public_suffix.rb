require "public_suffix"

def show(d)
  p([d.trd, d.sld, d.tld, d.name, d.domain, d.subdomain, d.domain?, d.subdomain?])
end

def show_rule(r)
  if r == nil
    puts("no rule")
  else
    kind = r.class.name.split("::").last
    puts("#{kind} #{r.rule} value=#{r.value.inspect} length=#{r.length} private=#{r.private}")
  end
end

# parse: the registrable domain and its parts
show(PublicSuffix.parse("google.com"))
show(PublicSuffix.parse("www.google.com"))
show(PublicSuffix.parse("a.b.www.example.co.uk"))
show(PublicSuffix.parse("  WWW.Example.COM.  "))
show(PublicSuffix.parse("a.b.blogspot.com"))
show(PublicSuffix.parse("a.b.blogspot.com", ignore_private: true))
show(PublicSuffix.parse("www.city.kawasaki.jp"))
show(PublicSuffix.parse("www.ck"))
show(PublicSuffix.parse("x.www.ck"))
show(PublicSuffix.parse("example.unknowntld"))
show(PublicSuffix.parse("日本.jp"))
d = PublicSuffix.parse("blog.example.org")
p(d.to_s, d.to_a)
p(PublicSuffix::Domain.name_to_labels("a.b.c"))
show(PublicSuffix::Domain.new("com", "example", "www"))
show(PublicSuffix::Domain.new("com"))

# domain and valid?
p(PublicSuffix.domain("www.google.com"), PublicSuffix.domain("google.com"), PublicSuffix.domain("com"))
p(PublicSuffix.domain("www.example.co.uk"), PublicSuffix.domain("city.kawasaki.jp"), PublicSuffix.domain("foo.ck"))
p(PublicSuffix.domain("a.b.github.io"), PublicSuffix.domain("a.b.github.io", ignore_private: true))
p(PublicSuffix.domain(""), PublicSuffix.domain(".example.com"), PublicSuffix.domain("http://example.com"))
p(PublicSuffix.valid?("google.com"), PublicSuffix.valid?("com"), PublicSuffix.valid?("foo.ck"))
p(PublicSuffix.valid?("www.ck"), PublicSuffix.valid?("example.unknowntld"), PublicSuffix.valid?(""))
p(PublicSuffix.valid?("github.io"), PublicSuffix.valid?("github.io", ignore_private: true))

# errors
["", ".example.com", "http://example.com", "com", "foo.ck", "co.uk"].each do |name|
  begin
    show(PublicSuffix.parse(name))
  rescue PublicSuffix::DomainNotAllowed => e
    puts("DomainNotAllowed: #{e.message}")
  rescue PublicSuffix::DomainInvalid => e
    puts("DomainInvalid: #{e.message}")
  end
end
p(PublicSuffix.normalize("  Foo.COM. "))
p(PublicSuffix.normalize("").message)

# rules
["com", "*.ck", "!www.ck", "co.uk", "*"].each do |s|
  show_rule(PublicSuffix::Rule.factory(s))
end
show_rule(PublicSuffix::Rule.factory("blogspot.com", private: true))
show_rule(PublicSuffix::Rule.default)
p(PublicSuffix::Rule.factory("co.uk").match?("example.co.uk"), PublicSuffix::Rule.factory("co.uk").match?("example.xco.uk"))
p(PublicSuffix::Rule.factory("co.uk").decompose("www.example.co.uk"))
p(PublicSuffix::Rule.factory("*.ck").decompose("a.b.ck"))
p(PublicSuffix::Rule.factory("!www.ck").decompose("x.www.ck"))
p(PublicSuffix::Rule.factory("co.uk").decompose("co.uk"))
p(PublicSuffix::Rule.factory("*.ck").parts, PublicSuffix::Rule.factory("!www.ck").parts)
p(PublicSuffix::Rule::Normal.new(value: "a.b").length, PublicSuffix::Rule::Wildcard.new(value: "a").length)

# the default list and a list of one's own
list = PublicSuffix::List.default
p(list.size > 9000, list.empty?)
show_rule(list.find("www.ck"))
show_rule(list.find("example.co.uk"))
show_rule(list.find("a.b.blogspot.com"))
show_rule(list.find("a.b.blogspot.com", ignore_private: true))
show_rule(list.find("example.unknowntld"))
l = PublicSuffix::List.parse("com\n*.jp\n!city.kawasaki.jp\n// a comment\n\n===BEGIN PRIVATE DOMAINS===\nblogspot.com\n")
p(l.size)
l.each { |r| show_rule(r) }
show_rule(l.find("x.blogspot.com"))
show_rule(l.find("x.blogspot.com", ignore_private: true))
show_rule(l.find("unknown.zz"))
show_rule(l.find("unknown.zz", default: nil))
show_rule(l.find("www.city.kawasaki.jp"))
p(PublicSuffix.parse("x.blogspot.com", list: l).to_a)
p(PublicSuffix::List.parse("com\n===BEGIN PRIVATE DOMAINS===\nblogspot.com\n", private_domains: false).size)
l << PublicSuffix::Rule.factory("org")
p(l.size)
l.add(PublicSuffix::Rule.factory("net"))
p(l.size, l.default_rule.rule)
l2 = PublicSuffix::List.new
p(l2.empty?, l2 == PublicSuffix::List.new)
l2 << PublicSuffix::Rule.factory("com")
p(l2 == PublicSuffix::List.new, l2.size)
l2.clear
p(l2.size)

# List.default= replaces the default list
PublicSuffix::List.default = l
show(PublicSuffix.parse("a.b.blogspot.com"))
p(PublicSuffix.domain("www.example.co.uk"))
