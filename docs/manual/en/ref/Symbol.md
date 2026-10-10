# Symbol

A Symbol is a name as a value, made by the literal `:name` (a name with spaces or other characters is `:"hello world"`; see [Values and types](../03-values.md)). Symbols of the same name are always one and the same value; they serve as Hash keys (the labels of `Hash[name: 1]` are Symbol keys) and as the marks of `case`/`in` branches. `String.to_sym(s)` (`String.intern`) makes one from a String, and `Symbol.to_s` turns it back. Ruby's `%i[a b]` is not available yet (rejected statically); an Array of Symbols is written `Symbol[:a, :b]`.

There is no `Symbol#to_proc` (`&:name`). Blocks are not values, so `Array.map(xs, &:to_s)` is rejected statically; write `{ |x| Integer.to_s(x) }` ([Functions and blocks](../04-functions.md)).

When branching on literals, `case s in :a ... in :b ... end`, and `s` is a Symbol that did not come from a literal (the result of `String.to_sym`, say), `--strict=3` reports that some values fall through, as `exhaustive` (add an `else`; see [Control](../06-control.md)).

The operators on Symbols are `==`, `!=`, `<`, `<=`, `>`, `>=` and `<=>`, and they compare Symbols with Symbols only (with a String or an Integer on the right, `<` and the others are a `type` problem statically). `:a == "a"` is false, but the function form `Symbol.==(:a, "a")` raises `TypeError` at run time. `Symbol.<(x, y)` and so on are the function forms of those operators ([Operators and indexing](../05-operators.md)).

The string-like operations (`upcase`, `slice`, `match`, `start_with?`, ...) give the result of treating the name as a String. Some return a Symbol (`upcase` and friends), some a String (`slice`). None changes the Symbol itself (a Symbol is immutable).

## Symbol[]

`Symbol[*Any]`

Makes an **Array of Symbols**. It is a typed Array like `Integer[]`: every element must be a Symbol, and every write (`Array.push`, ...) is checked. Anything but a Symbol is a `type` problem statically and a `TypeError` at run time. The empty Array of Symbols is `Symbol[]`.

```ruby
syms = Symbol[:a, :b]
Array.push(syms, :c)
p(syms)                            # => [:a, :b, :c]
p(Array.size(Symbol[]))            # => 0
```

```ruby error
Array.push(Symbol[:a], "x")        # !> Array.push: an element must be Symbol, but is String
```

## to_s, id2name, name

`Symbol.to_s(x)`

`Symbol.id2name(x)`

`Symbol.name(x)`

The name as a String. `to_s` and `id2name` return a new (writable) String each time; `name` returns the name the Symbol holds, which is frozen as in Ruby, so changing it with `String.upcase!` or the like is a `TypeError`.

```ruby
p(Symbol.to_s(:hello))             # => "hello"
p(Symbol.id2name(:"with space"))   # => "with space"
s = Symbol.to_s(:abc)
String.upcase!(s)
p(s)                               # => "ABC"
p(Symbol.name(:abc))               # => "abc"
```

```ruby error
s = Symbol.name(:abc)
String.upcase!(s)                  # !> TypeError: String.upcase!: cannot change this String in place
```

## to_sym, intern

`Symbol.to_sym(x)`

`Symbol.intern(x)`

The Symbol itself (as Ruby's). A Symbol is made from a String by `String.to_sym` and `String.intern`.

```ruby
p(Symbol.to_sym(:a))               # => :a
p(Symbol.intern(:a) == :a)         # => true
p(String.to_sym("a") == :a)        # => true
```

## length, size

`Symbol.length(x)`

`Symbol.size(x)`

The number of characters in the name (an Integer; not bytes).

```ruby
p(Symbol.length(:hello))           # => 5
p(Symbol.size(:日本))              # => 2
```

## empty?

`Symbol.empty?(x)`

True when the name is empty (`:""`).

```ruby
p(Symbol.empty?(:""))              # => true
p(Symbol.empty?(:a))               # => false
```

## encoding

`Symbol.encoding(x)`

The name of the name's encoding, as a String (Ruby returns an Encoding object). An ASCII-only name is `"US-ASCII"`, any other `"UTF-8"`.

```ruby
p(Symbol.encoding(:hello))         # => "US-ASCII"
p(Symbol.encoding(:日本))          # => "UTF-8"
```

## upcase, downcase, capitalize, swapcase

`Symbol.upcase(x)`

`Symbol.downcase(x)`

`Symbol.capitalize(x)`

`Symbol.swapcase(x)`

A new Symbol with the name in upper case, in lower case, with only the first character upper case (the rest lower), or with the cases swapped. As Ruby's `String` operations of the same names; Unicode characters are converted too. The option arguments (`:ascii`, ...) do not exist.

```ruby
p(Symbol.upcase(:hello))           # => :HELLO
p(Symbol.downcase(:HeLLo))         # => :hello
p(Symbol.capitalize(:hello_world)) # => :Hello_world
p(Symbol.swapcase(:HeLLo))         # => :hEllO
p(Symbol.downcase(:ÀB))            # => :àb
```

## succ, next

`Symbol.succ(x)`

`Symbol.next(x)`

A new Symbol with the name advanced by Ruby's `String#succ` (`:a` → `:b`, `:az` → `:ba`, `:zz` → `:aaa`, `:a9` → `:b0`).

```ruby
p(Symbol.succ(:a))                 # => :b
p(Symbol.next(:az))                # => :ba
p(Symbol.succ(:zz))                # => :aaa
p(Symbol.succ(:a9))                # => :b0
```

## start_with?, end_with?

`Symbol.start_with?(x, String)`

`Symbol.end_with?(x, String)`

True when the name starts or ends with the String `s`. The argument is a String; passing a Symbol is a `type` problem statically (Ruby's forms with several arguments or a Regexp do not exist).

```ruby
p(Symbol.start_with?(:hello, "he"))   # => true
p(Symbol.end_with?(:hello, "lo"))     # => true
p(Symbol.start_with?(:hello, "x"))    # => false
```

```ruby error
p(Symbol.start_with?(:abc, :a))    # !> Symbol.start_with?: argument 2 must be String, but is :a
```

## slice

`Symbol.slice(x, Integer, [Integer])`

A part of the name as a String. `slice(s, i)` is the one character at position `i` (a negative one counts from the end); `slice(s, i, n)` is `n` characters from position `i`. Outside the name it is nil (as Ruby's `String#slice`; `slice(s, i, n)` with `i` equal to the length is `""`). Because the result may be nil, using it unchecked is reported at level 2. There is no Range or String index (a `type` problem statically).

```ruby
p(Symbol.slice(:hello, 1))         # => "e"
p(Symbol.slice(:hello, -1))        # => "o"
p(Symbol.slice(:hello, 1, 3))      # => "ell"
p(Symbol.slice(:hello, 10))        # => nil
p(Symbol.slice(:abc, 3, 1))        # => ""
```

```ruby error
p(Symbol.slice(:abc, 0..1))        # !> Symbol.slice: argument 2 must be Integer, but is Range[Integer]
```

## match

`Symbol.match(x, Regexp|String)`

Matches the pattern against the name and returns the MatchData of the first match, or nil when there is none (reported at level 2). A String pattern is taken as the source of a regular expression (as in Ruby).

```ruby
m = Symbol.match(:hello, /l+/)
p(m)                               # => #<MatchData "ll">
if m
  p(MatchData.to_s(m))             # => "ll"
end
p(Symbol.match(:hello, "l+"))      # => #<MatchData "ll">
p(Symbol.match(:hello, /z/))       # => nil
```

## match?

`Symbol.match?(x, Regexp|String)`

True when the name matches the pattern. It makes no MatchData, so use it when only whether it matched matters.

```ruby
p(Symbol.match?(:hello, /ell/))    # => true
p(Symbol.match?(:hello, "x"))      # => false
```

## casecmp

`Symbol.casecmp(x, Symbol)`

Compares the names of two Symbols ignoring case (in the ASCII range) and returns -1, 0, or 1. The argument must be a Symbol (a String is a `type` problem statically). Because Ruby's `casecmp` returns nil when it cannot compare, the result type is `Integer | nil`, and using it in arithmetic unchecked is reported at level 2.

```ruby
p(Symbol.casecmp(:a, :A))          # => 0
p(Symbol.casecmp(:a, :B))          # => -1
p(Symbol.casecmp(:b, :A))          # => 1
```

```ruby error
p(Symbol.casecmp(:a, "b"))         # !> Symbol.casecmp: argument 2 must be Symbol, but is String
```

## casecmp?

`Symbol.casecmp?(x, Symbol)`

True when the names of two Symbols are equal ignoring case (by Unicode case folding). As with `casecmp`, the result may be nil in its type.

```ruby
p(Symbol.casecmp?(:a, :A))         # => true
p(Symbol.casecmp?(:a, :b))         # => false
p(Symbol.casecmp?(:Straße, :STRASSE))   # => true
```

## ==, !=

`Symbol.==(x, Any)`

`Symbol.!=(x, Any)`

True when the two are Symbols of the same name (`!=` is the negation). The operator `:a == "a"` is false, but the function form `Symbol.==(:a, "a")` raises `TypeError` at run time when the right operand is not a Symbol.

```ruby
p(:a == :a)                        # => true
p(:a != :b)                        # => true
p(:a == "a")                       # => false
p(Symbol.==(:a, :a))               # => true
```

```ruby error
p(Symbol.==(:a, "a"))              # !> TypeError: Symbol.==: no implementation for (Symbol, String)
```

## <, <=, >, >=

`Symbol.<(x, Any)`

`Symbol.<=(x, Any)`

`Symbol.>(x, Any)`

`Symbol.>=(x, Any)`

Compare the names of two Symbols as Strings (byte order, as in Ruby). The right operand must be a Symbol; a String or an Integer is a `type` problem statically.

```ruby
p(:a < :b)                         # => true
p(:b >= :c)                        # => false
p(Symbol.<=(:a, :a))               # => true
```

```ruby error
p(:a < "a")                        # !> which the left operand's type does not support
```

## <=>

`Symbol.<=>(x, Any)`

The result of comparing the names as -1, 0, or 1. The rules are those of `<`, and the right operand must be a Symbol. It serves as the key of `Array.sort_by`.

```ruby
p(:a <=> :b)                       # => -1
p(:aa <=> :b)                      # => -1
p(Symbol.<=>(:a, :a))              # => 0
```
