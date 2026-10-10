# Regexp

A Regexp is a regular expression. The literal `/\d+/` takes Ruby's flags: `i` (ignore case), `m` (`.` also matches a newline), `x` (ignore whitespace and comments), `n` (match bytes; `/a/n` has the encoding US-ASCII). `/a#{x}/` embeds a String. `Regexp.new(s, flags)` builds one from a String. The syntax is Ruby's (Onigmo) as it is, named groups `(?<name>...)` included ([Values and types](../03-values.md)).

The main difference from Ruby is that a match leaves nothing behind globally: `$~`, `$1` and `Regexp.last_match` do not exist, and `/(?<y>\d+)/ =~ s` does not create a local variable `y` (a static error). The result of a match is the MatchData that `Regexp.match` returns, kept in a variable and read from there ([MatchData](MatchData.md)).

The operators on Regexps are `=~` (the position of a match in a String, or nil), `==` and `!=`. The String forms `s =~ re` and `s !~ re` exist too. `String.match`, `match?`, `scan`, `sub`, `gsub`, `split`, `index` and others also take a Regexp ([Operators and indexing](../05-operators.md)). A Regexp cannot be a Hash key or a Set element (`TypeError`).

## new

`Regexp.new(String, [String])`

Makes a Regexp from a source String. The second argument is a String of flag letters ("" by default): the literal's `i`, `m`, `x` and `n`; any other letter is an `ArgumentError` at run time. A source that is not a valid regular expression is a `RegexpError`, which can be rescued (Ruby's Integer flags such as `Regexp::IGNORECASE` are not taken). To match the special characters of the source literally, pass it through `Regexp.escape`.

```ruby
p(Regexp.new("a.b"))                        # => /a.b/
re = Regexp.new("ab+", "i")
p(re)                                       # => /ab+/i
p(Regexp.match?(re, "ABB"))                 # => true
p(Regexp.options(Regexp.new("a", "mi")))    # => 5
p(Regexp.new("a", "n"))                     # => /a/n
begin
  p(Regexp.new("("))
rescue RegexpError => e
  puts(Exception.message(e))                # => end pattern with unmatched parenthesis: /(/
end
```

```ruby error
p(Regexp.new("a", "q"))        # !> ArgumentError: Regexp.new: unknown regexp option: q
```

```ruby error
p(Regexp.new("("))             # !> RegexpError: Regexp.new: end pattern with unmatched parenthesis: /(/
```

## escape

`Regexp.escape(String)`

The String with the regular-expression special characters (`.`, `*`, `(`, space, ...) escaped with backslashes. `Regexp.new(Regexp.escape(s))` is the Regexp that matches `s` itself.

```ruby
p(Regexp.escape("a.b*c"))                                 # => "a\\.b\\*c"
word = "a.b"
re = Regexp.new(Regexp.escape(word))
p(Regexp.match?(re, "a.b"))                               # => true
p(Regexp.match?(re, "axb"))                               # => false
```

## source

`Regexp.source(x)`

The source of the regular expression (a String), without the flags. Embedded expressions appear expanded.

```ruby
p(Regexp.source(/\d+/))        # => "\\d+"
p(Regexp.source(/a b/x))       # => "a b"
x = "c"
p(Regexp.source(/a#{x}/i))     # => "ac"
```

## options

`Regexp.options(x)`

The flags as bits in an Integer (as Ruby's: `i` is 1, `x` is 2, `m` is 4, `n` is 32).

```ruby
p(Regexp.options(/a/))         # => 0
p(Regexp.options(/a/i))        # => 1
p(Regexp.options(/a/imx))      # => 7
p(Regexp.options(/a/n))        # => 32
```

## casefold?

`Regexp.casefold?(x)`

True when the flag `i` is set.

```ruby
p(Regexp.casefold?(/a/i))      # => true
p(Regexp.casefold?(/a/))       # => false
```

## encoding

`Regexp.encoding(x)`

The name of the Regexp's encoding (a String). An ASCII-only source is "US-ASCII", a source with non-ASCII characters "UTF-8", and `/.../n` "US-ASCII" (it matches bytes).

```ruby
p(Regexp.encoding(/a/))        # => "US-ASCII"
p(Regexp.encoding(/あ/))       # => "UTF-8"
p(Regexp.encoding(/a/n))       # => "US-ASCII"
```

## fixed_encoding?

`Regexp.fixed_encoding?(x)`

True when the encoding is fixed (a source with non-ASCII characters). An ASCII-only source and `/.../n` are false and can be matched against Strings of any encoding. As Ruby's.

```ruby
p(Regexp.fixed_encoding?(/a/))     # => false
p(Regexp.fixed_encoding?(/あ/))    # => true
```

## timeout

`Regexp.timeout(x)`

The match timeout set on this Regexp (seconds, a Float) or **nil**. Sake has no way to set one, so it is always nil, and `--strict` (level 2) reports using it unchecked.

```ruby
p(Regexp.timeout(/a/))         # => nil
```

## names

`Regexp.names(x)`

The Array of the named groups' names (Strings, in order of appearance, each once). Empty when there are no named groups.

```ruby
p(Regexp.names(/(?<y>\d+)-(?<m>\d+)/))    # => ["y", "m"]
p(Regexp.names(/(\d+)/))                  # => []
```

## named_captures

`Regexp.named_captures(x)`

A Hash from each named group's name (a String) to the Array of its group numbers. A name used twice lists two numbers.

```ruby
p(Regexp.named_captures(/(?<y>\d+)-(?<m>\d+)/))   # => {"y" => [1], "m" => [2]}
p(Regexp.named_captures(/(?<a>.)(?<a>.)/))        # => {"a" => [1, 2]}
p(Regexp.named_captures(/(a)/))                   # => {}
```

## match

`Regexp.match(x, String, [Integer])`

The MatchData of the first match in the String. Without a match the result is **nil**, which `--strict` (level 2) reports when used unchecked (check it with `if m` or `or raise`). The third argument is the position to start searching from (in characters; 0 by default, negative counts from the end). `String.match(s, re)` is the same. Unlike Ruby, nothing is left in `$~`.

```ruby
re = /(?<y>\d+)-(?<m>\d+)/
m = Regexp.match(re, "on 2026-10")
if m
  p(m["y"])                               # => "2026"
end
p(Regexp.match(re, "none"))               # => nil
n = Regexp.match(/\d/, "a1b2", 2) or raise("no digit")
p(n[0])                                   # => "2"
```

```ruby error
m = Regexp.match(/a/, "a")
p(m[0])                                   # !> the operands may be nil (MatchData | nil)
```

## match?

`Regexp.match?(x, String, [Integer])`

True when there is a match. It builds no MatchData, so it is the lighter choice when only the fact of a match matters. The third argument is the position to start from.

```ruby
p(Regexp.match?(/\d+/, "a1"))         # => true
p(Regexp.match?(/\d+/, "abc"))        # => false
p(Regexp.match?(/\d/, "1abc", 1))     # => false
```

## =~

`Regexp.=~(x, Any)`

The function form of `re =~ s`. The position of the first match (an Integer, in characters), or **nil** when there is none (reported at `--strict` level 2). The right operand must be a String. `s =~ re` gives the same result, and `s !~ re` is true when there is no match. Unlike Ruby, named groups do not become local variables and `$~` is not set.

```ruby
p(/b/ =~ "abc")                # => 1
p(/z/ =~ "abc")                # => nil
p("abc" =~ /c/)                # => 2
p("abc" !~ /z/)                # => true
p(Regexp.=~(/b/, "abc"))       # => 1
```

```ruby error
if /(?<y>\d+)/ =~ "12"
  p(y)                         # !> named captures do not create local variables in Sake
end
```

## ==, !=

`Regexp.==(x, Any)`

`Regexp.!=(x, Any)`

True when the two Regexps have the same source and flags (`!=` is the negation). A right operand that is not a Regexp is never equal.

```ruby
p(/a/ == /a/)                  # => true
p(/a/ == /a/i)                 # => false
p(/a/ != /b/)                  # => true
p(/a/ == "a")                  # => false
```

## union

`Regexp.union(*String|Regexp|Array)`

A Regexp that matches any of the arguments: Strings are escaped, Regexps keep their flags, and all are joined with `|`. With no arguments it is `/(?!)/`, which matches nothing. The patterns are listed one by one, or, as Ruby allows, given as **one** Array of Strings and Regexps (`Regexp.union(Array["a", "b"])`); an Array among other arguments, or an element that is neither a String nor a Regexp, is a `TypeError` at run time.

```ruby
p(Regexp.union("a.b", /c/i))                              # => /a\.b|(?i-mx:c)/
p(Regexp.match?(Regexp.union("cat", "dog"), "hotdog"))    # => true
p(Regexp.union())                                         # => /(?!)/
p(Regexp.union(Array["a", "b"]))                          # => /a|b/
p(Regexp.union(Array["a.b", /c/]))                        # => /a\.b|(?-mix:c)/
```

```ruby error
p(Regexp.union("a", Array["b"]))    # !> TypeError: Regexp.union: no implicit conversion of Array into String
```
