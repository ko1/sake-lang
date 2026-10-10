# String

A String is a sequence of characters with an encoding, as Ruby's String. The literals are `"abc"`, `'abc'` and `"a#{x}"` (interpolation shows the value with `to_s`, see [Values and types](../03-values.md)); a literal is UTF-8, and every evaluation of a literal makes a new String. Strings are **mutable**: the operations whose names end in `!`, and `concat`, `append_as_bytes`, `prepend`, `insert`, `replace`, `clear`, `setbyte`, `bytesplice`, `force_encoding`, change their subject in place; every other operation leaves the subject alone and returns a new String. The Strings a program cannot change are Hash keys, Set elements, the names of Symbols (`Symbol.name`), the String a MatchData holds (`MatchData.string`) and the program's arguments (`ARGV`): changing one of them in place is a `TypeError` at run time (`cannot change this String in place: it is a Hash key, a Set element, a Symbol's name, or a program argument`).

Every operation is written with its type: `String.upcase(s)`, never `s.upcase`. The operators on Strings are `+` (String, String), `*` (String, Integer), `%` (the format operator), `==`, `!=`, `<`, `<=`, `>`, `>=`, `<=>` (String, String), `=~`, `!~` (String, Regexp), and the index `s[i]`, `s[i, n]`, `s[range]` ([Operators and indexing](../05-operators.md)). The entries `String.+(x, y)` and so on below are the function forms of those operators. There is no `s[i] = v`: a String cannot be indexed for writing (a `type` problem statically); change it with `String.sub!`, `String.insert`, `String.bytesplice` or `String.replace`.

Many operations give **nil** for a miss: `index`, `rindex`, `byteindex`, `byterindex`, `match`, `getbyte`, `casecmp`, `unpack1`, `slice!`, `sub!`, `gsub!`, and the in-place forms that give nil when nothing changed (`upcase!`, `strip!`, `chomp!`, `tr!`, ...). Using such a result unchecked is a `nil` problem at `--strict` level 2. Only the index forms `s[i]`, `s[i, n]`, `s[range]`, `String.slice` and `String.byteslice` give the nil of a miss (`index-nil`), which is reported only at level 3 ([Overview](../01-overview.md)).

Where Sake differs from Ruby: `sub` and `gsub` need a replacement or a block; a `MatchData` is read with `m[i]` (there are no `$~`, `$1`); `scan`, `partition` and `rpartition` give Tuples where Ruby gives Arrays; `count`, `start_with?`, `end_with?`, `include?` take one argument each (`chomp`, `delete`, `squeeze` take what their `!` forms take: a separator, several sets); iteration (`each_char`, ...) needs a block. The table in [Built-in operations](../09-builtins.md) lists the operations in short.

## String[]

`String[*Any]`

Makes an **Array of Strings** (not a String). It is a typed Array like `Integer[]` and `Tuple[]`: every element must be a String, and every write (`Array.push`, ...) is checked. An element that is not a String is a `type` problem statically and a `TypeError` at run time. The empty Array of Strings is `String[]`.

```ruby
names = String["a", "b"]
Array.push(names, "c")
p(names)                     # => ["a", "b", "c"]
p(Array.size(String[]))      # => 0
```

```ruby error
Array.push(String[], 1)      # !> Array.push: an element must be String, but is Integer
```

## length, size

`String.length(x)`

`String.size(x)`

The number of characters (an Integer), not of bytes: `"héllo"` has 5 characters and 6 bytes (`bytesize`).

```ruby
p(String.length("hello"))    # => 5
p(String.size("héllo"))      # => 5
p(String.size(""))           # => 0
```

## bytesize

`String.bytesize(x)`

The number of bytes (an Integer) in the String's encoding.

```ruby
p(String.bytesize("héllo"))  # => 6
p(String.bytesize(""))       # => 0
```

## empty?

`String.empty?(x)`

True when the String has no characters.

```ruby
p(String.empty?(""))         # => true
p(String.empty?(" "))        # => false
```

## +

`String.+(x, Any)`

The function form of `a + b`: a new String with the characters of `a` followed by those of `b`. Both operands must be Strings; `"a" + 1` is a `type` problem statically (Ruby raises `TypeError`). Neither operand changes.

```ruby
s = "abc"
p(s + "d")                   # => "abcd"
p(String.+("a", "b"))        # => "ab"
p(s)                         # => "abc"
```

```ruby error
p("a" + 1)                   # !> the operands are (String, Integer)
```

## *

`String.*(x, Integer)`

The function form of `s * n`: a new String with `s` repeated `n` times (`""` for 0). A negative `n` is an `ArgumentError` (`negative argument`), from the operator as from the function form; it can be rescued.

```ruby
p("ab" * 3)                  # => "ababab"
p(String.*("-", 0))          # => ""
begin
  p("ab" * -1)
rescue ArgumentError => e
  puts(Exception.message(e))     # => negative argument
end
```

```ruby error
p(String.*("ab", -1))        # !> ArgumentError: String.*: negative argument -1
```

## %

`String.%(x, Any)`

The function form of `fmt % value`, Ruby's `format` with `fmt` as the format: `"%d items" % 3`. The right operand is one value (Integer, Float, String, Symbol, nil, true or false), a Tuple of values for several directives (`"%s-%s" % [a, b]`), or a Record or a Hash with Symbol keys for the named directives `%<name>d` and `%{name}` (`"%<a>05d" % {a: 42}`, `"%<a>05d" % Hash[a: 42]`); an Array is a `type` problem statically. The directives are Ruby's (`%d`, `%s`, `%f`, `%x`, `%05d`, `%-4s`, `%.2f`, `%p`, ...). A value that does not fit its directive (`"%d" % "x"`) or too few values is an `ArgumentError`; a name the Record or Hash does not have is a `KeyError` (`key<b> not found`); extra values are ignored.

```ruby
p("%05d|%-4s|%.2f|%x" % [42, "ab", 3.14159, 255])   # => "00042|ab  |3.14|ff"
p("%d items" % 3)            # => "3 items"
p("%s" % :sym)               # => "sym"
p("%p" % nil)                # => "nil"
p(String.%("%03d", 7))       # => "007"
p("%<a>05d" % {a: 42})       # => "00042"
p("%{a}-%<b>s" % {a: 1, b: "x"})     # => "1-x"
p("%<a>05d" % Hash[a: 42])   # => "00042"
```

```ruby error
p("%<b>d" % {a: 42})         # !> KeyError: Arithmetic.%: key<b> not found
```

```ruby error
p("%d %d" % 1)               # !> ArgumentError: Arithmetic.%: too few arguments
```

## ==, !=

`String.==(x, Any)`

`String.!=(x, Any)`

True when both are Strings with the same characters (`!=` is the negation); comparison is by content, not identity. A right operand of another type (an Integer, a Symbol, nil) is simply not equal, with the function forms as with the operators: `String.==("a", 1)` is false and `String.!=("a", 1)` is true (no error).

```ruby
p("a" == "a")                # => true
p("a" != "b")                # => true
p("1" == 1)                  # => false
p("a" == nil)                # => false
p(String.==("a", nil))       # => false
p(String.==("a", 1))         # => false
p(String.!=("a", 1))         # => true
```

## <, <=, >, >=

`String.<(x, Any)`

`String.<=(x, Any)`

`String.>(x, Any)`

`String.>=(x, Any)`

Compare two Strings byte by byte, as Ruby's: `"B" < "a"` because uppercase letters come first, `"10" < "9"`, and a prefix is smaller than the longer String. Both operands must be Strings; a String compared with another type is a `type` problem statically.

```ruby
p("a" < "b")                 # => true
p("B" >= "a")                # => false
p("10" < "9")                # => true
p("ab" < "abc")              # => true
p(String.<=("a", "a"))       # => true
```

```ruby error
p("a" < 1)                   # !> the operands are (String, Integer)
```

## <=>

`String.<=>(x, Any)`

The result of that comparison as -1, 0, or 1. Both operands must be Strings, so the result is never nil (Ruby gives nil for a non-String).

```ruby
p("a" <=> "b")               # => -1
p("a" <=> "a")               # => 0
p(String.<=>("b", "a"))      # => 1
```

## between?

`String.between?(x, String, String)`

True when `lo <= x <= hi` in the order of `<`.

```ruby
p(String.between?("b", "a", "c"))   # => true
p(String.between?("z", "a", "c"))   # => false
```

## clamp

`String.clamp(x, String, String)`

`x` when it lies between `lo` and `hi`, otherwise the nearer bound. `lo > hi` is an `ArgumentError`.

```ruby
p(String.clamp("b", "a", "c"))      # => "b"
p(String.clamp("z", "a", "c"))      # => "c"
```

```ruby error
p(String.clamp("b", "c", "a"))      # !> ArgumentError: String.clamp: min argument must be less than or equal to max argument
```

## casecmp

`String.casecmp(x, String)`

Compares the two Strings ignoring the case of ASCII letters: -1, 0, or 1 (an Integer). It is nil when the encodings of the two Strings are incompatible; using the result unchecked is a `nil` problem at `--strict` level 2.

```ruby
p(String.casecmp("a", "A"))         # => 0
p(String.casecmp("a", "B"))         # => -1
p(String.casecmp("a", String.encode("a", "UTF-16LE")))   # => nil
```

```ruby error
p(String.casecmp("a", "b") + 1)     # !> the operands may be nil
```

## casecmp?

`String.casecmp?(x, String)`

True when the two Strings are equal after Unicode case folding. The result is a Boolean, never nil: with incompatible encodings (where Ruby's method returns nil and `casecmp` gives nil) it is **false**.

```ruby
p(String.casecmp?("a", "A"))        # => true
p(String.casecmp?("a", "b"))        # => false
p(String.casecmp?("a", String.encode("a", "UTF-16LE")))   # => false
```

## =~

`String.=~(x, Any)`

The function form of `s =~ re`: the position (an Integer) of the first match of the Regexp `re` in `s`, or nil when there is none. The right operand must be a Regexp; a String is a `type` problem statically. The nil is a `nil` problem at `--strict` level 2 when used unchecked. There is no `$~`: use `String.match` to read the groups.

```ruby
p("hello" =~ /l+/)           # => 2
p("hello" =~ /z/)            # => nil
p(String.=~("ab", /b/))      # => 1
```

```ruby error
p(("abc" =~ /b/) + 1)        # !> the operands may be nil
```

## !~

`String.!~(x, Any)`

The function form of `s !~ re`: true when the Regexp does not match.

```ruby
p("hello" !~ /z/)            # => true
p(String.!~("ab", /b/))      # => false
```

## []

`String.[](x, Any, [Integer])`

The function form of `s[i]`, `s[i, n]` and `s[range]`. `s[i]` is the one-character String at position `i` (an Integer; a negative one counts from the end), or nil outside the String. `s[i, n]` is the substring of up to `n` characters starting at `i`: nil when `i` is past the end or `n` is negative, `""` when `i` equals the length. `s[range]` is the characters in the Range, nil when its start is past the end. The index must be an Integer or a Range: a String or a Float index is a `type` problem statically (Ruby's `s["b"]` and `s[/re/]` do not exist as operators; `String.slice(s, "b")` and `String.slice(s, /re/)` do), and a Range with a count is a `TypeError`. The result is `String | nil`; the nil is the nil of a miss (`index-nil`), reported only at `--strict` level 3.

```ruby
s = "hello"
p(s[1])                      # => "e"
p(s[-1])                     # => "o"
p(s[10])                     # => nil
p(s[1, 3])                   # => "ell"
p(s[5, 1])                   # => ""
p(s[6, 1])                   # => nil
p(s[1..2])                   # => "el"
p(s[2..])                    # => "llo"
p(String.[](s, 0))           # => "h"
```

```ruby error
p("abc"["b"])                # !> the index must be Integer, but is String
```

## slice

`String.slice(x, Integer|Range|String|Regexp, [Integer])`

`s[i]`, `s[i, n]` or `s[range]` written as an operation: the same results and the same nil (`index-nil`, level 3). It also takes what `slice!` takes, as Ruby's `slice`: a String gives its first occurrence (a new String) or nil, and a Regexp gives the first match, or, with a group number as the second argument, that group's String (nil when the group did not take part). A count after a String or a Range is a `TypeError`.

```ruby
s = "hello"
p(String.slice(s, 1))        # => "e"
p(String.slice(s, 1, 2))     # => "el"
p(String.slice(s, 1..2))     # => "el"
p(String.slice(s, 9))        # => nil
p(String.slice(s, "ll"))     # => "ll"
p(String.slice(s, "zz"))     # => nil
p(String.slice(s, /l+/))     # => "ll"
p(String.slice(s, /(l)(o)/, 2))      # => "o"
```

```ruby error
p(String.slice("hello", "ll", 1))    # !> TypeError: String.slice: no implicit conversion of String into Integer
```

## slice!

`String.slice!(x, Integer|Range|String|Regexp, [Integer])`

Removes the part `s[i]`, `s[i, n]` or `s[range]` from the subject **in place** and returns it. A String argument removes its first occurrence, a Regexp its first match. The result is nil when there is nothing to remove (an index past the end, a String or Regexp that does not occur), and the subject is then unchanged; using the result unchecked is a `nil` problem at `--strict` level 2.

```ruby
s = "hello"
p(String.slice!(s, 0))       # => "h"
p(String.slice!(s, /l+/))    # => "ll"
p(String.slice!(s, "zz"))    # => nil
p(s)                         # => "eo"
```

```ruby error
s = "hello"
c = String.slice!(s, 1)
p(String.upcase(c))          # !> argument 1 may be nil
```

## byteslice

`String.byteslice(x, Integer|Range, [Integer])`

The byte at byte offset `i` (one-byte String), the `n` bytes from `i`, or the bytes in a Range of byte offsets, in the subject's encoding; the result may be an invalid String when it cuts a multibyte character. nil when `i` (or the Range's start) is past the end or `n` is negative (`index-nil`, level 3). As Ruby's.

```ruby
p(String.byteslice("héllo", 1))      # => "\xC3"
p(String.byteslice("héllo", 1, 2))   # => "é"
p(String.byteslice("héllo", 1..2))   # => "é"
p(String.byteslice("hello", 9..10))  # => nil
p(String.byteslice("héllo", 9))      # => nil
```

## getbyte

`String.getbyte(x, Integer)`

The byte (an Integer 0..255) at byte offset `i`, negative from the end, or nil outside the String. Using the result unchecked is a `nil` problem at `--strict` level 2.

```ruby
s = "héllo"
p(String.getbyte(s, 0))      # => 104
p(String.getbyte(s, 1))      # => 195
p(String.getbyte(s, -1))     # => 111
p(String.getbyte(s, 99))     # => nil
```

```ruby error
p(String.getbyte("a", 5) + 1)        # !> the operands may be nil
```

## setbyte

`String.setbyte(x, Integer, Integer)`

Stores the byte `b` at byte offset `i` **in place** (the low 8 bits of `b`, as Ruby) and returns `b`. An offset outside the String is an `IndexError`.

```ruby
s = "abc"
p(String.setbyte(s, 0, 65))  # => 65
p(s)                         # => "Abc"
```

```ruby error
p(String.setbyte("abc", 10, 1))      # !> IndexError: String.setbyte: index 10 out of string
```

## bytesplice

`String.bytesplice(x, Integer, Integer, String)`

Replaces the `n` bytes from byte offset `i` with the String `str`, **in place**, and returns the subject. An offset outside the String is an `IndexError`; the offsets must fall on character boundaries.

```ruby
s = "hello"
p(String.bytesplice(s, 0, 2, "J"))   # => "Jllo"
p(s)                                 # => "Jllo"
```

```ruby error
p(String.bytesplice("abc", 10, 1, "x"))   # !> IndexError: String.bytesplice: index 10 out of string
```

## upcase, downcase, capitalize, swapcase

`String.upcase(x)`

`String.downcase(x)`

`String.capitalize(x)`

`String.swapcase(x)`

A new String with the letters in upper case, in lower case, with the first character in upper case and the rest in lower case, or with each letter's case swapped. Case mapping is Unicode's, as Ruby's (`"straße"` upcases to `"STRASSE"`).

```ruby
p(String.upcase("abc"))          # => "ABC"
p(String.downcase("ABC"))        # => "abc"
p(String.capitalize("hELLO"))    # => "Hello"
p(String.swapcase("Ab"))         # => "aB"
p(String.upcase("straße"))       # => "STRASSE"
```

## upcase!, downcase!, capitalize!, swapcase!

`String.upcase!(x)`

`String.downcase!(x)`

`String.capitalize!(x)`

`String.swapcase!(x)`

The same conversions **in place**. They return the subject when it changed, and nil when it was already in that form; using the result unchecked is a `nil` problem at `--strict` level 2.

```ruby
s = "Hello"
p(String.upcase!(s))         # => "HELLO"
p(s)                         # => "HELLO"
p(String.upcase!(s))         # => nil
p(String.capitalize!("Abc")) # => nil
```

```ruby error
s = "Hello"
r = String.upcase!(s)
p(String.size(r))            # !> argument 1 may be nil
```

## strip, lstrip, rstrip

`String.strip(x)`

`String.lstrip(x)`

`String.rstrip(x)`

A new String without the leading and trailing whitespace (`strip`), the leading only (`lstrip`), or the trailing only (`rstrip`). Whitespace is Ruby's: spaces, tabs, newlines, and NUL.

```ruby
p(String.strip("  a  "))     # => "a"
p(String.lstrip("  a  "))    # => "a  "
p(String.rstrip("  a  "))    # => "  a"
```

## strip!, lstrip!, rstrip!

`String.strip!(x)`

`String.lstrip!(x)`

`String.rstrip!(x)`

The same **in place**: the subject when something was removed, nil when there was nothing to remove (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "  a  "
p(String.strip!(s))          # => "a"
p(String.strip!(s))          # => nil
p(String.lstrip!("a"))       # => nil
```

## chomp

`String.chomp(x, [String])`

A new String without one trailing line end (`"\n"`, `"\r\n"` or `"\r"`); a String without one is returned unchanged. With `suffix`, that suffix is removed instead (as Ruby's: `""` removes every trailing newline).

```ruby
p(String.chomp("a\n"))       # => "a"
p(String.chomp("a\r\n"))     # => "a"
p(String.chomp("a"))         # => "a"
p(String.chomp("abc!", "!"))         # => "abc"
p(String.chomp("abc", "x"))          # => "abc"
p(String.chomp("abc\n\n", ""))       # => "abc"
```

## chomp!

`String.chomp!(x, [String])`

Removes one trailing line end **in place**, or, with `suffix`, removes that suffix. Returns the subject when something was removed and nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "a\n"
p(String.chomp!(s))          # => "a"
p(String.chomp!(s))          # => nil
p(String.chomp!("abc", "bc"))        # => "a"
p(String.chomp!("abc", "x"))         # => nil
```

```ruby error
p(String.chomp!("abc") + "!")        # !> the operands may be nil
```

## chop

`String.chop(x)`

A new String without its last character (`"\r\n"` counts as one). `""` gives `""`.

```ruby
p(String.chop("abc"))        # => "ab"
p(String.chop("a\r\n"))      # => "a"
p(String.chop(""))           # => ""
```

## chop!

`String.chop!(x)`

Removes the last character **in place**: the subject, or nil when it was empty (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "abc"
p(String.chop!(s))           # => "ab"
p(String.chop!(""))          # => nil
```

## chr

`String.chr(x)`

The first character as a String, `""` for an empty String (Ruby's `chr`).

```ruby
p(String.chr("abc"))         # => "a"
p(String.chr(""))            # => ""
```

## delete_prefix, delete_suffix

`String.delete_prefix(x, String)`

`String.delete_suffix(x, String)`

A new String without the leading `prefix` or the trailing `suffix`; when the String does not start (end) with it, an unchanged copy.

```ruby
p(String.delete_prefix("foobar", "foo"))   # => "bar"
p(String.delete_suffix("foobar", "bar"))   # => "foo"
p(String.delete_prefix("foobar", "x"))     # => "foobar"
```

## delete_prefix!, delete_suffix!

`String.delete_prefix!(x, String)`

`String.delete_suffix!(x, String)`

The same **in place**: the subject when the prefix (suffix) was there and removed, nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "foobar"
p(String.delete_prefix!(s, "foo"))   # => "bar"
p(String.delete_prefix!(s, "foo"))   # => nil
p(String.delete_suffix!(s, "ar"))    # => "b"
p(s)                                 # => "b"
```

## include?, start_with?, end_with?

`String.include?(x, String)`

`String.start_with?(x, String)`

`String.end_with?(x, String)`

True when `t` occurs in the String, when the String starts with `t`, or when it ends with `t`. Each takes exactly one String (Ruby's `start_with?` also takes several arguments and Regexps).

```ruby
s = "hello world"
p(String.include?(s, "wor"))     # => true
p(String.start_with?(s, "he"))   # => true
p(String.end_with?(s, "x"))      # => false
```

## index

`String.index(x, String|Regexp, [Integer])`

The character position (an Integer) of the first occurrence of the String `t`, or of the first match of the Regexp, at or after position `pos` (default 0; a negative `pos` counts from the end). nil when there is none; using it unchecked is a `nil` problem at `--strict` level 2. `""` is found at `pos`.

```ruby
s = "hello world"
p(String.index(s, "o"))          # => 4
p(String.index(s, "o", 5))       # => 7
p(String.index(s, /w./))         # => 6
p(String.index(s, "l", -3))      # => 9
p(String.index(s, "z"))          # => nil
```

```ruby error
s = "hello"
i = String.index(s, "o")
p(i + 1)                         # !> the operands may be nil
```

## rindex

`String.rindex(x, String|Regexp, [Integer])`

The position of the last occurrence of `t` (or last match of the Regexp) that starts at or before `pos` (default: the end). nil when there is none (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "hello world"
p(String.rindex(s, "o"))         # => 7
p(String.rindex(s, "o", 5))      # => 4
p(String.rindex(s, "z"))         # => nil
```

```ruby error
p(String.rindex("abc", "b") + 1) # !> the operands may be nil
```

## byteindex

`String.byteindex(x, String|Regexp, [Integer])`

As `index`, but the result and `pos` are **byte** offsets. nil when there is no occurrence (a `nil` problem at `--strict` level 2 when used unchecked). `pos` must fall on a character boundary: an offset inside a multibyte character is an `IndexError` (`offset 2 does not land on character boundary`), which can be rescued.

```ruby
p(String.index("héllo", "l"))        # => 2
p(String.byteindex("héllo", "l"))    # => 3
p(String.byteindex("héllo", "z"))    # => nil
p(String.byteindex("héllo", "l", 3)) # => 3
```

```ruby error
p(String.byteindex("héllo", "l", 2))   # !> IndexError: String.byteindex: offset 2 does not land on character boundary
```

## byterindex

`String.byterindex(x, String|Regexp, [Integer])`

As `rindex`, with byte offsets: the last occurrence starting at or before byte `pos`. nil when there is none (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
p(String.byterindex("héllo", "l"))      # => 4
p(String.byterindex("héllo", "l", 3))   # => 3
```

```ruby error
p(String.byterindex("abc", "b") + 1)    # !> the operands may be nil
```

## match

`String.match(x, String|Regexp, [Integer])`

The `MatchData` of the first match of the Regexp at or after position `pos` (default 0), or nil when it does not match; using the result unchecked (`m[1]` without an `if m`) is a `nil` problem at `--strict` level 2. A String pattern is compiled as a Regexp, as Ruby's (`"."` matches any character; an invalid pattern such as `"+"` is a `RegexpError`, which can be rescued). There are no `$~` and `$1`: read the groups from the MatchData with `m[0]`, `m[1]`, `m["name"]`.

```ruby
m = String.match("hello world", /(w)(o)/)
if m
  p(m[0])                      # => "wo"
  p(m[2])                      # => "o"
end
p(String.match("hello", "zzz"))      # => nil
```

```ruby error
p(String.match("a+c", "+"))  # !> RegexpError: String.match: target of repeat operator is not specified: /+/
```

```ruby error
m = String.match("abc", /b/)
p(m[0])                      # !> the operands may be nil (MatchData | nil)
```

## match?

`String.match?(x, String|Regexp, [Integer])`

True when the pattern matches at or after position `pos` (default 0), without building a MatchData. A String pattern is compiled as a Regexp; an invalid one is a `RegexpError`, as with `match`.

```ruby
p(String.match?("hello", /l+/))      # => true
p(String.match?("hello", "o", 8))    # => false
p(String.match?("abc", "b."))        # => true
begin
  p(String.match?("a+c", "+"))
rescue RegexpError => e
  puts(Exception.message(e))         # => target of repeat operator is not specified: /+/
end
```

## scan

`String.scan(x, String|Regexp)`

Every non-overlapping match, from left to right, as an Array. Without groups, an Array of the matched Strings. With groups, an Array of **Tuples** with one String per group (Ruby gives Arrays); a group that did not take part is nil in its position, the nil of a miss (`index-nil`, level 3).

```ruby
p(String.scan("a1b22", /\d+/))       # => ["1", "22"]
p(String.scan("abab", "ab"))         # => ["ab", "ab"]
p(String.scan("a1b22", /(\w)(\d)/))  # => [["a", "1"], ["b", "2"]]
p(String.scan("a1 b", /(\w)(\d)?/))  # => [["a", "1"], ["b", nil]]
```

## count

`String.count(x, String)`

The number of characters (an Integer) that belong to the set `chars`, written as in Ruby's `tr`: `"lo"` lists characters, `"a-z"` is a range, a leading `^` negates. Only one set is accepted (Ruby intersects several). A reversed range such as `"z-a"` is an `ArgumentError` (`invalid range "z-a" in string transliteration`), here as in `tr`, `delete` and `squeeze`.

```ruby
s = "hello world"
p(String.count(s, "lo"))     # => 5
p(String.count(s, "a-z"))    # => 10
p(String.count(s, "^l"))     # => 8
```

```ruby error
p(String.count("abc", "z-a"))    # !> ArgumentError: String.count: invalid range "z-a" in string transliteration
```

## partition, rpartition

`String.partition(x, String|Regexp)`

`String.rpartition(x, String|Regexp)`

Splits around the first (`partition`) or last (`rpartition`) occurrence of `sep`, a String or a Regexp, into the **Tuple** `[before, separator, after]` (Ruby gives an Array). When `sep` does not occur, `partition` gives `[s, "", ""]` and `rpartition` gives `["", "", s]`.

```ruby
p(String.partition("a=b=c", "="))    # => ["a", "=", "b=c"]
p(String.rpartition("a=b=c", "="))   # => ["a=b", "=", "c"]
p(String.partition("hello", /l+/))   # => ["he", "ll", "o"]
p(String.partition("abc", "x"))      # => ["abc", "", ""]
p(String.rpartition("abc", "x"))     # => ["", "", "abc"]
```

## sub, gsub

`String.sub(x, String|Regexp, [String|Hash]) [{ }]`

`String.gsub(x, String|Regexp, [String|Hash]) [{ }]`

A new String with the first match (`sub`) or every match (`gsub`) of `pattern` replaced. A String pattern is matched literally (`"."` is a period, not any character). The replacement is one of three: a **String**, in which `\0` is the whole match, `\1` the first group and `\k<name>` a named group; a **Hash** whose keys are matched Strings and whose values (shown with `to_s`) replace them, a match that is not a key being removed; or a **block** that receives the matched String (not a MatchData) and whose result, shown with `to_s`, is the replacement. Giving neither a replacement nor a block is an `ArgumentError` at run time (Ruby's enumerator form does not exist).

```ruby
s = "hello"
p(String.sub(s, "l", "L"))                 # => "heLlo"
p(String.gsub(s, "l", "L"))                # => "heLLo"
p(String.gsub(s, /l+/, "<\\0>"))           # => "he<ll>o"
p(String.gsub(s, /(l)(o)/, "\\2\\1"))      # => "helol"
p(String.gsub(s, /[el]/, Hash["e" => "3", "l" => 1]))   # => "h311o"
p(String.gsub(s, /l/) { |m| String.upcase(m) })         # => "heLLo"
p(String.sub(s, /l/) { |m| 7 })            # => "he7lo"
p(s)                                       # => "hello"
```

```ruby error
p(String.sub("abc", "b"))    # !> ArgumentError: String.sub: sub needs a replacement or a block
```

## sub!, gsub!

`String.sub!(x, String|Regexp, [String|Hash]) [{ }]`

`String.gsub!(x, String|Regexp, [String|Hash]) [{ }]`

The same replacement **in place**. They return the subject when something was replaced and nil when the pattern did not match (the subject unchanged); using the result unchecked is a `nil` problem at `--strict` level 2. The replacement forms are those of `sub` and `gsub`.

```ruby
s = "hello"
p(String.sub!(s, "l", "L"))      # => "heLlo"
p(s)                             # => "heLlo"
p(String.gsub!(s, "zz", "y"))    # => nil
String.gsub!(s, /l/i) { |m| "_" }
p(s)                             # => "he__o"
```

```ruby error
s = "hello"
p(String.sub!(s, "x", "y") + "!")    # !> the operands may be nil
```

## tr

`String.tr(x, String, String)`

A new String in which each character of the set `from` is replaced by the character at the same position in `to` (Ruby's `tr`): `"a-y"` is a range, a leading `^` in `from` negates, a `to` shorter than `from` repeats its last character, and an empty `to` deletes. A reversed range is an `ArgumentError` (`invalid range "z-a" in string transliteration`).

```ruby
p(String.tr("hello", "el", "ip"))    # => "hippo"
p(String.tr("hello", "a-y", "b-z"))  # => "ifmmp"
p(String.tr("hello", "^l", "*"))     # => "**ll*"
p(String.tr("hello", "lo", ""))      # => "he"
```

```ruby error
p(String.tr("abc", "z-a", "x"))      # !> ArgumentError: String.tr: invalid range "z-a" in string transliteration
```

## tr!

`String.tr!(x, String, String)`

`tr` **in place**: the subject when something changed, nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "hello"
p(String.tr!(s, "l", "L"))   # => "heLLo"
p(String.tr!(s, "z", "Z"))   # => nil
```

## tr_s

`String.tr_s(x, String, String)`

As `tr`, and then squeezes runs of the replaced characters into one (Ruby's `tr_s`).

```ruby
p(String.tr_s("hello", "l", "r"))      # => "hero"
p(String.tr_s("aabbcc", "a-c", "x"))   # => "x"
```

## tr_s!

`String.tr_s!(x, String, String)`

`tr_s` **in place**: the subject when something changed, nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "aabb"
p(String.tr_s!(s, "a", "x"))     # => "xbb"
p(String.tr_s!(s, "z", "x"))     # => nil
```

## delete

`String.delete(x, String, *String)`

A new String without the characters that belong to every set given (`tr` syntax: `"a-k"`, `"^l"`). Several sets intersect, as Ruby's: `delete("hello", "l", "o")` deletes nothing, since no character is in both sets. A reversed range is an `ArgumentError`.

```ruby
p(String.delete("hello", "l"))     # => "heo"
p(String.delete("hello", "a-k"))   # => "llo"
p(String.delete("hello", "^l"))    # => "ll"
p(String.delete("hello", "l", "o"))        # => "hello"
p(String.delete("hello", "a-z", "^l"))     # => "ll"
```

## delete!

`String.delete!(x, String, *String)`

Deletes **in place** the characters that belong to every set given (several sets intersect, as Ruby's). The subject when something was deleted, nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "hello"
p(String.delete!(s, "l"))              # => "heo"
p(String.delete!(s, "z"))              # => nil
p(String.delete!("hello", "l", "^l"))  # => nil
```

```ruby error
p(String.delete!("a", "z-a"))          # !> ArgumentError: String.delete!: invalid range "z-a"
```

## squeeze

`String.squeeze(x, *String)`

A new String in which runs of the same character are reduced to one; with sets, only runs of characters that belong to every set (several sets intersect, as Ruby's).

```ruby
p(String.squeeze("aaabbb  c"))         # => "ab c"
p(String.squeeze("aaabbb  c", "a"))    # => "abbb  c"
p(String.squeeze("aaabbb  c", "a-b"))  # => "ab  c"
p(String.squeeze("aaabbb  c", "a-b", "b"))     # => "aaab  c"
```

## squeeze!

`String.squeeze!(x, *String)`

`squeeze` **in place**, with any number of sets (their intersection, as Ruby's). The subject when something changed, nil otherwise (a `nil` problem at `--strict` level 2 when used unchecked).

```ruby
s = "aaabbb"
p(String.squeeze!(s))                # => "ab"
p(String.squeeze!(s))                # => nil
p(String.squeeze!("aabb", "a"))      # => "abb"
```

## split

`String.split(x, [String|Regexp], [Integer])`

Splits into an Array of Strings. Without `sep` or with `" "`, it splits on runs of whitespace and ignores leading whitespace (awk style); with another String, on each occurrence of it; with `""`, into characters; with a Regexp, on each match, and the Regexp's groups are included in the result (Ruby's rule). `limit` (default 0) bounds the number of pieces: a positive `limit` gives at most that many, the last holding the rest; 0 drops trailing empty Strings; a negative `limit` keeps them. There is no block form.

```ruby
p(String.split("a b  c"))              # => ["a", "b", "c"]
p(String.split("a,b,,c", ","))         # => ["a", "b", "", "c"]
p(String.split("a,b,,c", ",", 2))      # => ["a", "b,,c"]
p(String.split("a,b,,", ","))          # => ["a", "b"]
p(String.split("a,b,,", ",", -1))      # => ["a", "b", "", ""]
p(String.split("a1b2c", /\d/))         # => ["a", "b", "c"]
p(String.split("a1b", /(\d)/))         # => ["a", "1", "b"]
p(String.split("abc", ""))             # => ["a", "b", "c"]
p(String.split("", ","))               # => []
```

## chars

`String.chars(x)`

An Array of the characters, each a one-character String.

```ruby
p(String.chars("aé"))        # => ["a", "é"]
p(String.chars(""))          # => []
```

## lines

`String.lines(x)`

An Array of the lines, each keeping its `"\n"` (the last one may lack it).

```ruby
p(String.lines("a\nb\n"))    # => ["a\n", "b\n"]
p(String.lines("a\nb"))      # => ["a\n", "b"]
p(String.lines(""))          # => []
```

## bytes

`String.bytes(x)`

An Array of the bytes as Integers (0..255).

```ruby
p(String.bytes("aé"))        # => [97, 195, 169]
```

## codepoints

`String.codepoints(x)`

An Array of the Unicode code points as Integers.

```ruby
p(String.codepoints("aé"))   # => [97, 233]
```

## grapheme_clusters

`String.grapheme_clusters(x)`

An Array of the grapheme clusters (what a reader sees as one character: a base character with its combining marks), each a String.

```ruby
s = "éa"
p(String.length(s))                  # => 3
p(Array.size(String.grapheme_clusters(s)))                       # => 2
p(Array.map(String.grapheme_clusters(s)) { |g| String.length(g) })   # => [2, 1]
```

## each_char

`String.each_char(x) { }`

Calls the block with each character (a one-character String) in order and returns the subject. The block is required: a call without one is a static error (Ruby's enumerator form does not exist).

```ruby
r = String.each_char("ab") { |c| p(c) }
# => "a"
# => "b"
p(r)                         # => "ab"
```

```ruby error
String.each_char("ab")       # !> String.each_char requires a block
```

## each_line

`String.each_line(x) { }`

Calls the block with each line, keeping its `"\n"`, and returns the subject. The block is required; there is no separator argument (Ruby's `each_line(sep)`).

```ruby
String.each_line("a\nb") { |l| p(l) }
# => "a\n"
# => "b"
```

## each_byte

`String.each_byte(x) { }`

Calls the block with each byte (an Integer) and returns the subject. The block is required.

```ruby
String.each_byte("aé") { |b| p(b) }
# => 97
# => 195
# => 169
```

## each_codepoint

`String.each_codepoint(x) { }`

Calls the block with each code point (an Integer) and returns the subject. The block is required.

```ruby
String.each_codepoint("aé") { |c| p(c) }
# => 97
# => 233
```

## each_grapheme_cluster

`String.each_grapheme_cluster(x) { }`

Calls the block with each grapheme cluster (a String) and returns the subject. The block is required.

```ruby
String.each_grapheme_cluster("éa") { |g| p(String.length(g)) }
# => 2
# => 1
```

## upto

`String.upto(x, String) { }`

Calls the block with `x`, then `String.succ` of it, and so on up to and including `last`, as Ruby's `upto` (`"a".upto("e")`); the walk stops when a value gets longer than `last`, so nothing is yielded when `x` is already past it. Strings of digits count as numbers (`"9"` up to `"11"`). Returns the subject.

```ruby
String.upto("a", "c") { |s| p(s) }
# => "a"
# => "b"
# => "c"
String.upto("az", "bb") { |s| p(s) }
# => "az"
# => "ba"
# => "bb"
String.upto("9", "11") { |s| p(s) }
# => "9"
# => "10"
# => "11"
String.upto("b", "a") { |s| p(s) }
```

## succ, next

`String.succ(x)`

`String.next(x)`

A new String that is the successor of `x` in Ruby's sense: the rightmost letter or digit is incremented, with a carry to the left (`"az"` to `"ba"`, `"a9"` to `"b0"`, `"Zz"` to `"AAa"`). `""` gives `""`.

```ruby
p(String.succ("az"))         # => "ba"
p(String.next("Zz"))         # => "AAa"
p(String.succ("a9"))         # => "b0"
p(String.succ(""))           # => ""
```

## succ!, next!

`String.succ!(x)`

`String.next!(x)`

Replace the subject by its successor **in place** and return the subject (never nil).

```ruby
s = "az"
p(String.succ!(s))           # => "ba"
p(String.next!(s))           # => "bb"
p(s)                         # => "bb"
```

## reverse

`String.reverse(x)`

A new String with the characters in reverse order.

```ruby
p(String.reverse("abc"))     # => "cba"
```

## reverse!

`String.reverse!(x)`

Reverses the subject **in place** and returns it (never nil).

```ruby
s = "abc"
p(String.reverse!(s))        # => "cba"
p(s)                         # => "cba"
```

## ljust, rjust, center

`String.ljust(x, Integer, [String])`

`String.rjust(x, Integer, [String])`

`String.center(x, Integer, [String])`

A new String of `width` characters: the subject padded on the right (`ljust`), on the left (`rjust`), or on both sides (`center`, the extra padding going right) with repetitions of `pad` (default `" "`), cut to fit. A `width` not greater than the length gives an unchanged copy. An empty `pad` is an `ArgumentError` (`zero width padding`).

```ruby
p(String.ljust("ab", 5))         # => "ab   "
p(String.rjust("ab", 5, "0"))    # => "000ab"
p(String.center("ab", 6, "*"))   # => "**ab**"
p(String.ljust("ab", 5, "xy"))   # => "abxyx"
p(String.center("ab", 1))        # => "ab"
```

```ruby error
p(String.ljust("a", 3, ""))      # !> ArgumentError: String.ljust: zero width padding
```

## to_s

`String.to_s(x)`

The String itself. It exists so that `T.to_s(x)` can be written for every type.

```ruby
p(String.to_s("x"))          # => "x"
```

## to_i

`String.to_i(x, [Integer])`

The Integer written at the start of the String in base `base` (2..36, default 10), as Ruby's `to_i`: leading whitespace, a sign and underscores between digits are allowed, reading stops at the first other character, and a String with no digits gives 0 (never an error; `Integer(s)` in [Built-in operations](../09-builtins.md) raises instead). Base 0 reads a prefix: `0x` (16), `0b` (2), `0o` or a leading `0` (8). With base 16, a `0x` prefix is accepted. A base outside 2..36 (other than 0) is an `ArgumentError`.

```ruby
p(String.to_i("42"))         # => 42
p(String.to_i("  -12abc"))   # => -12
p(String.to_i("abc"))        # => 0
p(String.to_i("ff", 16))     # => 255
p(String.to_i("0x1f", 16))   # => 31
p(String.to_i("0b101", 0))   # => 5
p(String.to_i("012", 0))     # => 10
p(String.to_i("z", 36))      # => 35
```

```ruby error
p(String.to_i("1", 37))      # !> ArgumentError: String.to_i: invalid radix 37
```

## to_f

`String.to_f(x)`

The Float written at the start of the String (`"3.5e2"`, underscores allowed), 0.0 when there is none (never an error; `Float(s)` raises). A value too large for a Float is `Infinity`.

```ruby
p(String.to_f("3.5e2"))      # => 350.0
p(String.to_f("1_000.5"))    # => 1000.5
p(String.to_f("abc"))        # => 0.0
```

## to_r

`String.to_r(x)`

The Rational written at the start of the String: `"3/4"`, `"0.75"`, `"1e2"`. A String with no number gives `(0/1)`.

```ruby
p(String.to_r("3/4"))        # => (3/4)
p(String.to_r("0.75"))       # => (3/4)
p(String.to_r("abc"))        # => (0/1)
```

## to_c

`String.to_c(x)`

The Complex written at the start of the String (`"1+2i"`); `(0+0i)` when there is none.

```ruby
p(String.to_c("1+2i"))       # => (1+2i)
p(String.to_c("x"))          # => (0+0i)
```

## to_sym, intern

`String.to_sym(x)`

`String.intern(x)`

The Symbol with this name. Any String can become a Symbol; one that is not an identifier is shown quoted.

```ruby
p(String.to_sym("abc"))      # => :abc
p(String.intern("a b"))      # => :"a b"
```

## hex

`String.hex(x)`

The String read as a hexadecimal Integer, as Ruby's `hex`: an optional sign and `0x` prefix, reading stops at the first non-hex character, and 0 when there are no digits.

```ruby
p(String.hex("ff"))          # => 255
p(String.hex("0x1F"))        # => 31
p(String.hex("-a"))          # => -10
p(String.hex("zz"))          # => 0
```

## oct

`String.oct(x)`

The String read as an octal Integer, as Ruby's `oct`; a prefix `0x`, `0b` or `0o` switches the base, as Ruby's. 0 when there are no digits.

```ruby
p(String.oct("17"))          # => 15
p(String.oct("0x1f"))        # => 31
p(String.oct("0b11"))        # => 3
p(String.oct("9"))           # => 0
```

## ord

`String.ord(x)`

The code point (an Integer) of the first character. An empty String is an `ArgumentError`.

```ruby
p(String.ord("a"))           # => 97
p(String.ord("é"))           # => 233
```

```ruby error
p(String.ord(""))            # !> ArgumentError: String.ord: empty string
```

## sum

`String.sum(x, [Integer])`

The sum of the bytes modulo 2 to the power `bits` (default 16), Ruby's simple checksum.

```ruby
p(String.sum("abc"))         # => 294
p(String.sum("abc", 8))      # => 38
```

## crypt

`String.crypt(x, String)`

The one-way hash of the String with `salt` by the system's `crypt(3)`, as Ruby's. A salt shorter than two bytes is an `ArgumentError`. The result depends on the platform's libc.

```ruby
p(String.size(String.crypt("abc", "ab")) > 2)   # => true
```

```ruby error
p(String.crypt("abc", "a"))  # !> ArgumentError: String.crypt: salt too short (need >=2 bytes)
```

## concat

`String.concat(x, *String|Integer)`

Appends each argument to the subject **in place** and returns the subject. An Integer is appended as the character with that code point.

```ruby
s = "a"
p(String.concat(s, "b", 99, "d"))    # => "abcd"
p(s)                                 # => "abcd"
```

## append_as_bytes

`String.append_as_bytes(x, *String|Integer)`

Appends the **bytes** of each String argument, and each Integer as one byte (its low 8 bits), **in place** without converting encodings or checking validity, as Ruby's; the result may be an invalid String. Returns the subject.

```ruby
s = "a"
p(String.append_as_bytes(s, "é", 255))   # => "aé\xFF"
p(String.bytesize(s))                    # => 4
p(String.valid_encoding?(s))             # => false
```

## prepend

`String.prepend(x, *String)`

Inserts the arguments, in order, at the front of the subject **in place** and returns the subject.

```ruby
s = "c"
p(String.prepend(s, "a", "b"))   # => "abc"
p(s)                             # => "abc"
```

## insert

`String.insert(x, Integer, String)`

Inserts `str` **in place** before the character at position `i`; a negative `i` inserts after the character counted from the end, so -1 appends. Returns the subject. A position outside the String is an `IndexError`.

```ruby
s = "ac"
p(String.insert(s, 1, "b"))      # => "abc"
p(String.insert(s, -1, "d"))     # => "abcd"
p(String.insert(s, 0, "_"))      # => "_abcd"
```

```ruby error
p(String.insert("abc", 10, "x")) # !> IndexError: String.insert: index 10 out of string
```

## replace

`String.replace(x, String)`

Replaces the contents of the subject with those of `str`, **in place**, and returns the subject. Every variable holding the subject sees the new contents.

```ruby
s = "old"
t = s
String.replace(s, "new")
p(t)                         # => "new"
```

## clear

`String.clear(x)`

Removes every character **in place** and returns the subject (now `""`).

```ruby
s = "hello"
p(String.clear(s))           # => ""
p(String.empty?(s))          # => true
```

## encoding

`String.encoding(x)`

The name of the String's encoding as a String (`"UTF-8"`, `"ASCII-8BIT"`, ...). Ruby gives an Encoding object; Sake has no such type.

```ruby
p(String.encoding("é"))              # => "UTF-8"
p(String.encoding(String.b("é")))    # => "ASCII-8BIT"
```

## force_encoding

`String.force_encoding(x, String)`

Relabels the subject's bytes as encoding `enc` **in place** and returns the subject, as Ruby's `force_encoding`. The bytes are not converted; `valid_encoding?` tells whether they are valid in the new encoding. An unknown encoding name is an `ArgumentError`; a String that cannot be changed (a Hash key, a Symbol's name, ...) is a `TypeError`.

```ruby
s = String.b("\xC3\xA9")
p(String.encoding(s))                # => "ASCII-8BIT"
t = String.force_encoding(s, "UTF-8")
p(String.encoding(s))                # => "UTF-8"
p(Kernel.equal?(s, t))               # => true
p(s)                                 # => "é"
p(String.valid_encoding?(String.force_encoding("\xff", "UTF-8")))   # => false
```

```ruby error
p(String.force_encoding("a", "bogus"))   # !> ArgumentError: String.force_encoding: unknown encoding name - bogus
```

## encode

`String.encode(x, String, [String])`

A new String with the characters converted to the encoding `to`; `from` (default: the subject's encoding) says how to read the bytes. A character that `to` cannot represent, an invalid byte in the subject, or an unknown encoding name is an `EncodingError`.

```ruby
u = String.encode("é", "UTF-16LE")
p(String.encoding(u))                            # => "UTF-16LE"
p(String.bytesize(u))                            # => 2
p(String.encode("\xE9", "UTF-8", "ISO-8859-1"))  # => "é"
begin
  String.encode("é", "US-ASCII")
rescue EncodingError => e
  p(Exception.message(e))                        # => "U+00E9 from UTF-8 to US-ASCII"
end
```

## valid_encoding?

`String.valid_encoding?(x)`

True when the bytes are valid in the String's encoding.

```ruby
p(String.valid_encoding?("é"))       # => true
p(String.valid_encoding?("\xff"))    # => false
```

## ascii_only?

`String.ascii_only?(x)`

True when every character is ASCII (an empty String is).

```ruby
p(String.ascii_only?("abc"))         # => true
p(String.ascii_only?("é"))           # => false
```

## b

`String.b(x)`

A copy of the String with the same bytes labelled `ASCII-8BIT` (binary), so that its length is its byte count.

```ruby
b = String.b("é")
p(b)                         # => "\xC3\xA9"
p(String.length(b))          # => 2
```

## scrub

`String.scrub(x, [String])`

A new String in which every invalid byte sequence is replaced by `repl` (default: the replacement character `"�"`).

```ruby
p(String.scrub("a\xffb", "?"))       # => "a?b"
p(String.valid_encoding?(String.scrub("a\xffb")))   # => true
```

## scrub!

`String.scrub!(x, [String])`

`scrub` **in place**. Returns the subject, also when there was nothing to replace (unlike the other `!` forms it never gives nil, as Ruby's).

```ruby
s = "a\xffb"
p(String.scrub!(s, "!"))     # => "a!b"
p(String.scrub!("ok"))       # => "ok"
```

## unicode_normalize

`String.unicode_normalize(x, [Symbol])`

A new String in Unicode normalization form `form`: `:nfc` (default), `:nfd`, `:nfkc` or `:nfkd`. Another Symbol is an `ArgumentError`; a String in a non-Unicode encoding (a binary String) is an `EncodingError`.

```ruby
d = String.unicode_normalize("é", :nfd)
p(String.length(d))                          # => 2
p(String.length(String.unicode_normalize(d)))   # => 1
```

```ruby error
p(String.unicode_normalize("a", :bogus))     # !> ArgumentError: String.unicode_normalize: Invalid normalization form bogus
```

## unicode_normalize!

`String.unicode_normalize!(x, [Symbol])`

`unicode_normalize` **in place**; returns the subject (never nil).

```ruby
s = "é"
p(String.unicode_normalize!(s))      # => "é"
p(String.length(s))                  # => 1
```

## unicode_normalized?

`String.unicode_normalized?(x, [Symbol])`

True when the String is already in the form `form` (default `:nfc`).

```ruby
p(String.unicode_normalized?("é"))           # => true
p(String.unicode_normalized?("é", :nfd))     # => false
```

## dump

`String.dump(x)`

A new String that is a quoted, ASCII-only source form of the subject: non-printing and non-ASCII characters become escapes such as `\n` and `é`, and `"` and `\` are escaped. `undump` reverses it.

```ruby
p(String.dump("a\né"))  # => "\"a\\n\\u00E9\""
```

## undump

`String.undump(x)`

The String that `dump` produced the subject from: the quotes are removed and the escapes read. A String that is not in `dump`'s form is an `ArgumentError` with Ruby's message (Ruby's method raises RuntimeError; in Sake a RuntimeError comes only from `raise "msg"` and `Thread.raise`).

```ruby
p(String.undump("\"a\\n\""))         # => "a\n"
p(String.undump(String.dump("é")))   # => "é"
begin
  p(String.undump("abc"))
rescue ArgumentError => e
  puts(Exception.message(e))         # => invalid dumped string; not wrapped with '"' nor '"...".force_encoding("...")' form
end
```

```ruby error
p(String.undump("abc"))      # !> ArgumentError: String.undump: invalid dumped string
```

## unpack

`String.unpack(x, String)`

Decodes the bytes according to the `Array.pack` format `fmt` into an Array, as Ruby's `unpack`: `C` an unsigned byte, `v` a little-endian 16-bit Integer, `e` a little-endian Float, `a`/`A`/`Z` Strings, `*` repeating. The element type follows the directives (Integer, String, Float); a directive with no bytes left gives nil. An unknown directive is an `ArgumentError`.

```ruby
p(String.unpack("AB", "C*"))             # => [65, 66]
p(String.unpack("\x01\x00", "v"))        # => [1]
p(String.unpack("ab", "a1a1"))           # => ["a", "b"]
p(String.unpack("\x00\x00\x80\x3f", "e"))   # => [1.0]
p(String.unpack("", "C"))                # => [nil]
```

```ruby error
p(String.unpack("abc", "Z%"))            # !> ArgumentError: String.unpack: % is not supported
```

## unpack1

`String.unpack1(x, String)`

The first element of `unpack(x, fmt)`, or nil when there are no bytes for it; using the result unchecked is a `nil` problem at `--strict` level 2.

```ruby
p(String.unpack1("\x01\x00", "v"))   # => 1
p(String.unpack1("abc", "a*"))       # => "abc"
p(String.unpack1("", "C"))           # => nil
```

```ruby error
p(String.unpack1("ab", "C") + 1)     # !> the operands may be nil
```
