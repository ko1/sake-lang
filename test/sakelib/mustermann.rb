# Mustermann: sinatra-type patterns and Regexp patterns (mustermann 3.1.1); mustermann.sake is the same program.
require "mustermann"

def show(pattern, path)
  m = Mustermann.new(pattern)
  puts "#{pattern.inspect} #{path.inspect} => #{m.params(path).inspect} #{(m === path).inspect}"
end

show("/hello/:name", "/hello/world")
show("/hello/:name", "/hello/a%20b")
show("/hello/:name", "/hello/a/b")
show("/say/*/to/*", "/say/hello/to/the/world")
show("/posts/:id(.:format)?", "/posts/1.json")
show("/posts/:id(.:format)?", "/posts/1")
show("/posts/:id(.:format)?", "/posts/v1.2.xml")
show("/:name.:ext", "/a.b.c")
show("/foo/?", "/foo")
show("/foo/?", "/foo/")
show("/a/:b?", "/a/")
show("/files/*.*", "/files/dir/x.tar.gz")
show("/x/{id}", "/x/9")
show("/p/:id/edit", "/p/3/edit")
show("/*path/raw", "/a/b/raw")
show("/(en|de)/:page", "/de/home")
show("/a\\(b\\)", "/a(b)")
show(%r{/num/(?<n>\d+)}, "/num/12")
show(%r{/num/(\d+)}, "/num/x")

m = Mustermann.new("/hello/:name")
p m.names
md = m.match("/hello/x")
p(md ? md[0] : nil)
p m.peek_size("/hello/x/more")
p Mustermann.new("/say/*/to/:name").names

["/a(b", "/a)b"].each do |bad|
  begin
    Mustermann.new(bad)
  rescue Mustermann::Error => e
    puts e.inspect
  end
end
