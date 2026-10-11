require "hana"
require "json"

# Applies one patch (JSON text) to a document (JSON text) and prints the result or the error.
def run(doc, patch)
  result = Hana::Patch.new(JSON.parse(patch)).apply(JSON.parse(doc))
  puts(JSON.generate(result))
rescue Hana::Patch::FailedTestException => e
  puts("FailedTestException: #{e.message} (path #{e.path.inspect}, value #{e.value.inspect})")
rescue Hana::Patch::OutOfBoundsException => e
  puts("OutOfBoundsException: #{e.message}")
rescue Hana::Patch::ObjectOperationOnArrayException => e
  puts("ObjectOperationOnArrayException: #{e.message}")
rescue Hana::Patch::InvalidObjectOperationException => e
  puts("InvalidObjectOperationException: #{e.message}")
rescue Hana::Patch::IndexError => e
  puts("IndexError: #{e.message}")
rescue Hana::Patch::MissingTargetException => e
  puts("MissingTargetException: #{e.message}")
rescue Hana::Patch::InvalidPath => e
  puts("InvalidPath: #{e.message}")
rescue Hana::Patch::Exception => e
  puts("Patch::Exception: #{e.message}")
rescue Hana::Pointer::FormatError => e
  puts("FormatError: #{e.message}")
rescue KeyError => e
  puts("KeyError: #{e.message}")
end

# JSON Pointer (RFC 6901, section 5)
doc = JSON.parse('{"foo": ["bar", "baz"], "": 0, "a/b": 1, "c%d": 2, "e^f": 3, "g|h": 4,
  "i\\\\j": 5, "k\"l": 6, " ": 7, "m~n": 8}')
["", "/foo", "/foo/0", "/", "/a~1b", "/c%d", "/e^f", "/g|h", "/i\\j", "/k\"l", "/ ", "/m~0n",
 "/foo/1", "/foo/2", "/nope", "/nope/deeper"].each do |path|
  p([path, Hana::Pointer.new(path).eval(doc)])
end
p(Hana::Pointer.parse("/a/b~1c/~0d/"))
p(Hana::Pointer.parse("/a^/b/c^^d"))
p(Hana::Pointer.new("/x/y").to_a)
p(Hana::Pointer.new("/x/y").map { |part| part.upcase })
p(Hana::Pointer.eval(["foo", "1"], doc))
begin
  Hana::Pointer.new("foo")
rescue Hana::Pointer::FormatError => e
  puts("FormatError: #{e.message}")
end
begin
  Hana::Pointer.new("/foo/01").eval(doc)
rescue Hana::Patch::IndexError => e
  puts("IndexError: #{e.message}")
end

# JSON Patch (RFC 6902, appendix A)
run('{"foo": "bar"}', '[{"op": "add", "path": "/baz", "value": "qux"}]')
run('{"foo": ["bar", "baz"]}', '[{"op": "add", "path": "/foo/1", "value": "qux"}]')
run('{"baz": "qux", "foo": "bar"}', '[{"op": "remove", "path": "/baz"}]')
run('{"foo": ["bar", "qux", "baz"]}', '[{"op": "remove", "path": "/foo/1"}]')
run('{"baz": "qux", "foo": "bar"}', '[{"op": "replace", "path": "/baz", "value": "boo"}]')
run('{"foo": {"bar": "baz", "waldo": "fred"}, "qux": {"corge": "grault"}}',
    '[{"op": "move", "from": "/foo/waldo", "path": "/qux/thud"}]')
run('{"foo": ["all", "grass", "cows", "eat"]}', '[{"op": "move", "from": "/foo/1", "path": "/foo/3"}]')
run('{"baz": "qux", "foo": ["a", 2, "c"]}',
    '[{"op": "test", "path": "/baz", "value": "qux"}, {"op": "test", "path": "/foo/1", "value": 2}]')
run('{"baz": "qux"}', '[{"op": "test", "path": "/baz", "value": "bar"}]')
run('{"foo": "bar"}', '[{"op": "add", "path": "/child", "value": {"grandchild": {}}}]')
run('{"foo": "bar"}', '[{"op": "add", "path": "/baz", "value": "qux", "xyz": 123}]')
run('{"foo": "bar"}', '[{"op": "add", "path": "/baz/bat", "value": "qux"}]')
run('{"/": 9, "~1": 10}', '[{"op": "test", "path": "/~01", "value": 10}]')
run('{"foo": ["bar"]}', '[{"op": "add", "path": "/foo/-", "value": ["abc", "def"]}]')

# more: copy, whole-document operations, several operations in a row
run('{"a": {"b": 1}, "c": [1, 2]}', '[{"op": "copy", "from": "/a", "path": "/d"}, {"op": "copy", "from": "/c/0", "path": "/c/-"}]')
run('{"a": 1}', '[{"op": "replace", "path": "", "value": [1, 2]}]')
run('{"a": 1}', '[{"op": "add", "path": "", "value": {"b": 2}}]')
run('{"a": {"x": 1}}', '[{"op": "add", "path": "/a/y", "value": 2}, {"op": "remove", "path": "/a/x"}, {"op": "move", "from": "/a", "path": "/b"}]')
run('[1, 2, 3]', '[{"op": "add", "path": "/0", "value": 0}, {"op": "remove", "path": "/3"}]')
run('{"a": 1}', '[{"op": " add ", "path": "/b", "value": 2}]')
run('{"a": [1, {"b": null}]}', '[{"op": "test", "path": "/a/1/b", "value": null}]')

# errors
run('{"a": 1}', '[{"op": "frob", "path": "/a"}]')
run('{"a": 1}', '[{"op": "add", "value": 1}]')
run('{"a": 1}', '[{"op": "add", "path": null, "value": 1}]')
run('{"a": 1}', '[{"op": "add", "path": "/b"}]')
run('{"a": 1}', '[{"op": "add", "path": "b", "value": 1}]')
run('{"a": [1]}', '[{"op": "add", "path": "/a/5", "value": 1}]')
run('{"a": [1]}', '[{"op": "add", "path": "/a/x", "value": 1}]')
run('{"a": [1]}', '[{"op": "remove", "path": "/a/1"}]')
run('{"a": [1]}', '[{"op": "remove", "path": "/a/-"}]')
run('{"a": 1}', '[{"op": "remove", "path": "/b"}]')
run('{"a": 1}', '[{"op": "remove", "path": "/a/b"}]')
run('{"a": 1}', '[{"op": "add", "path": "/a/b", "value": 2}]')
run('{"a": [1]}', '[{"op": "test", "path": "/a/01", "value": 1}]')
run('{"a": 1}', '[{"op": "copy", "from": "/x", "path": "/b"}]')
run('{"a": [1]}', '[{"op": "copy", "from": "/a/x", "path": "/b"}]')
run('{"a": 1}', '[{"op": "copy", "path": "/b"}]')
run('{"a": 1}', '[{"op": "move", "from": "/a", "path": "/x/y"}]')
run('{"a": {"b": [1, 2]}}', '[{"op": "test", "path": "/a", "value": {"b": [1, 2, 3]}}]')
