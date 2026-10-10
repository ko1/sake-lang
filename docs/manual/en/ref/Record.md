# Record

A Record is a set of (field name, value) pairs, made by the literal `{x: 1, y: "a"}` ([Values and types](../03-values.md)). In Ruby that spelling is a Hash; in Sake it is a **Record, not a Hash**. A Hash is made by `Hash[x: 1]` ([Hash](Hash.md)). `{}` (empty) and `{"a" => 1}` (the `=>` form) are rejected statically.

A Record's type is its set of (field, type) pairs, written `{x: Integer, y: String}`. Records with the same set have the same type. Field order is not part of the type: `{y: 2, x: 1}` prints as `{x: 1, y: 2}`. A Record is never a value of a class (classes are told apart by name, Record types by structure; see [Structs](../07-classes.md)).

Fields are read with a pattern: `r => {x:, y: name}` binds the local `x` to field `x` and `name` to field `y`. Listing only some of the fields is allowed, and `case r in {x:} ... end` is the same pattern. Naming a field the Record does not have is a `type` problem statically (a `KeyError` at run time), and so is matching a value that is not a Record (a `TypeError` at run time). Writing to a field (`r.x = v`, `r[:x] = v`) does not exist yet (both are rejected statically; `Indexable.[]=` does not take a Record).

The operators on a Record are `==` and `!=` (true when the field sets are the same and each value is equal). There is no index `r[:x]`.

The three operations of this chapter treat a Record as data (for code that walks any Record). Their argument type is `Any`; anything but a Record is a `TypeError` at run time. The fields come out in field-name order (the order they print in).

## keys

`Record.keys(Any)`

A new Array of the field names as Symbols. The order is field-name order, not the order written in the literal.

```ruby
r = {x: 1, y: "a"}
p(Record.keys(r))                  # => [:x, :y]
p(Record.keys({y: 2, x: 1}))       # => [:x, :y]
```

```ruby error
p(Record.keys(Hash[x: 1]))         # !> TypeError: Record.keys: argument 1 must be a Record, got Hash
```

## values

`Record.values(Any)`

A new Array of the field values, in the order of `keys`. It is independent of the Record, and the Array can grow. Its element type is the union of the field types.

```ruby
r = {x: 1, y: "a"}
vs = Record.values(r)
p(vs)                              # => [1, "a"]
Array.push(vs, 3)
p(r)                               # => {x: 1, y: "a"}
```

## to_h

`Record.to_h(Any)`

A new Hash with the field names as Symbol keys. To the checker its key type is Symbol and its value type is the union of the field types, so for a Record whose fields differ in type, using `h[:x]` directly in arithmetic is a `type` problem (a Hash has only one value type). When the fields share a type it is an ordinary Hash. A nested Record stays a Record as a value.

```ruby
r = {x: 1, y: 2}
h = Record.to_h(r)
p(h)                               # => {x: 1, y: 2}
p(Hash.fetch(h, :x) + Hash.fetch(h, :y))   # => 3
p(Record.to_h({name: "a", pos: {x: 1}}))   # => {name: "a", pos: {x: 1}}
```

```ruby error
h = Record.to_h({x: 1, y: "a"})
p(Hash.fetch(h, :x) + 1)           # !> which the left operand's type does not support
```
