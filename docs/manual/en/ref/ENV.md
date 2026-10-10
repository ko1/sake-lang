# ENV

ENV is the group of operations that read and write the process's environment variables. Ruby's `ENV["X"]` is written `ENV.get("X")`, and `ENV["X"] = v` is `ENV.set("X", v)` (in Sake `ENV` is not a value and cannot be indexed, see [Built-ins](../09-builtins.md)). Names and values are Strings.

A change is seen by this process and by the child processes started afterwards with `Open3` or `Kernel.system`. `ENV.to_h` is a copy; changing it does not change the environment, and `ENV.replace(h)` puts a whole Hash back as the environment.

ENV has no operators. The examples use names that start with `SAKE_DOC_` and remove them at the end.

## get

`ENV.get(String)`

The variable's value (a String), or nil when it is not set (Ruby's `ENV["X"]`). The result is `String | nil`, so `--strict` (level 2) reports using it unchecked as a `nil` problem. For a variable that must be present use `fetch`.

```ruby
ENV.set("SAKE_DOC_A", "1")
p(ENV.get("SAKE_DOC_A"))            # => "1"
p(ENV.get("SAKE_DOC_NOPE"))         # => nil
v = ENV.get("SAKE_DOC_A")
if v
  p(String.to_i(v) + 1)             # => 2
end
ENV.delete("SAKE_DOC_A")
```

```ruby error
home = ENV.get("HOME")
p(String.size(home))                # !> argument 1 may be nil
```

## fetch

`ENV.fetch(String, [String])`

The variable's value (a String). When it is not set, the second argument is returned if given, else it is a `KeyError` (Ruby's `ENV.fetch`; there is no block form). The result is never nil.

```ruby
ENV.set("SAKE_DOC_B", "x")
p(ENV.fetch("SAKE_DOC_B"))          # => "x"
p(ENV.fetch("SAKE_DOC_NOPE", "dflt"))   # => "dflt"
ENV.delete("SAKE_DOC_B")
```

```ruby error
ENV.fetch("SAKE_DOC_NOPE")          # !> KeyError: ENV.fetch: key not found: "SAKE_DOC_NOPE"
```

## set

`ENV.set(String, String)`

Sets the variable (replacing an existing value) and returns the value (Ruby's `ENV["X"] = v`). The value must be a String; another type is a `type` problem statically (removing is `delete`). An empty name, or one containing `=`, is refused by the OS: an `ArgumentError` with the OS's message (`Invalid argument - setenv()`), rescuable.

```ruby
p(ENV.set("SAKE_DOC_C", "1"))       # => "1"
p(ENV.set("SAKE_DOC_C", "2"))       # => "2"
out, status = Open3.capture2("sh", "-c", "echo $SAKE_DOC_C")
p(out)                              # => "2\n"
ENV.delete("SAKE_DOC_C")
```

```ruby error
ENV.set("SAKE_DOC_C", 1)            # !> ENV.set: argument 2 must be String, but is Integer
```

```ruby error
ENV.set("", "v")                    # !> ArgumentError: ENV.set: Invalid argument - setenv()
```

## key?

`ENV.key?(String)`

True when the variable is set (also when its value is the empty string).

```ruby
ENV.set("SAKE_DOC_D", "")
p(ENV.key?("SAKE_DOC_D"))           # => true
p(ENV.key?("SAKE_DOC_NOPE"))        # => false
ENV.delete("SAKE_DOC_D")
```

## delete

`ENV.delete(String)`

Removes the variable and returns the value it had (a String), or nil when it was not set (`String | nil`, level 2).

```ruby
ENV.set("SAKE_DOC_E", "1")
p(ENV.delete("SAKE_DOC_E"))         # => "1"
p(ENV.delete("SAKE_DOC_E"))         # => nil
p(ENV.key?("SAKE_DOC_E"))           # => false
```

## keys

`ENV.keys()`

The names of all set variables as an Array of Strings, in no defined order.

```ruby
ENV.set("SAKE_DOC_F", "1")
p(Array.include?(ENV.keys, "SAKE_DOC_F"))   # => true
p(Array.include?(ENV.keys, "SAKE_DOC_NOPE"))   # => false
ENV.delete("SAKE_DOC_F")
```

## to_h

`ENV.to_h()`

A copy of the whole environment as a Hash (String to String). Being a copy, changing the Hash does not change the environment, and a later `ENV.set` does not show in the Hash.

```ruby
ENV.set("SAKE_DOC_G", "1")
h = ENV.to_h
p(h["SAKE_DOC_G"])                  # => "1"
h["SAKE_DOC_H"] = "2"
p(ENV.key?("SAKE_DOC_H"))           # => false
ENV.delete("SAKE_DOC_G")
p(Hash.key?(h, "SAKE_DOC_G"))       # => true
```

## replace

`ENV.replace(Hash)`

Replaces the whole environment with the Hash's pairs and returns nil (Ruby's `ENV.replace`): every variable not in the Hash is removed, every pair is set. Keys and values must be Strings: the checker rejects a Hash whose key or value type is anything else (`the value must be String, but is Integer`, `argument key must be String, but is :a`), also through a function's parameter. Where it cannot see the types (a program run with `--strict=0`), a non-String key or value is a `TypeError` at run time, `keys and values must be String, got String => Integer`, raised before anything changes, so the environment is untouched. The typical use is to restore a copy taken with `ENV.to_h`.

```ruby
saved = ENV.to_h
p(ENV.replace(Hash["SAKE_DOC_R" => "1"]))   # => nil
p(ENV.keys)                         # => ["SAKE_DOC_R"]
p(ENV.get("SAKE_DOC_R"))            # => "1"
ENV.replace(saved)
p(ENV.key?("SAKE_DOC_R"))           # => false
p(ENV.to_h == saved)                # => true
```

```ruby error
ENV.replace(Hash["SAKE_DOC_R" => 1])   # !> ENV.replace: the value must be String, but is Integer [type]
```
