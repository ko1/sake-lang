# MatchData

A MatchData is the result of a regular-expression match. `Regexp.match(re, s)` and `String.match(s, re)` return one, or nil when there is no match, so it is checked before use ([Regexp](Regexp.md)). Ruby's globals `$~` and `$1` do not exist; the MatchData is kept in a variable and indexed ([Values and types](../03-values.md)).

Groups are numbered as in Ruby: 0 is the whole match, and the `(...)` groups count from 1. A named group `(?<name>...)` can also be read by its name (a String). As in Ruby, once there is a named group, plain `(...)` groups do not count as groups. A group that did not take part in the match (an `(a)?` that matched nothing) is nil.

The only operator on a MatchData is the index `m[k]`; `m[k] = v` is not available ([Operators and indexing](../05-operators.md)). A MatchData itself cannot be a Hash key.

## []

`MatchData.[](x, Any)`

The function form of `m[k]`. With an Integer `k`, the String of that group (0 is the whole match; a negative value counts from the end); with a String or Symbol, the String of the group of that name. A group that did not take part and an **index out of range** give nil, whereas an **unknown name** is an `IndexError` at run time. The nil is that of `x[k]` (an index miss), so `--strict` level 2 does not report using it unchecked; level 3 (`index-nil`) does. An index that is neither an Integer nor a String is a `TypeError`.

```ruby
m = Regexp.match(/(?<y>\d+)-(?<m>\d+)?/, "ab 12- cd") or raise("no match")
p(m[0])                       # => "12-"
p(m[1])                       # => "12"
p(m[2])                       # => nil
p(m[9])                       # => nil
p(m["y"])                     # => "12"
p(m[:y])                      # => "12"
p(MatchData.[](m, -1))        # => nil
```

```ruby error
m = Regexp.match(/(?<y>\d+)/, "12") or raise("no match")
p(m["z"])                     # !> IndexError: MatchData.[]: undefined group name reference: z
```

## captures

`MatchData.captures(x)`

The Array of the Strings of groups 1 onwards (the whole match is not included). A group that did not take part is nil, so the element type is String or nil.

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.captures(m))      # => ["12", nil]
```

## named_captures

`MatchData.named_captures(x)`

A Hash from each named group's name (a String) to the String it matched (nil when it did not take part). Empty when there are no named groups.

```ruby
m = Regexp.match(/(?<y>\d+)-(?<m>\d+)?/, "12-") or raise("no match")
p(MatchData.named_captures(m))    # => {"y" => "12", "m" => nil}
```

## names

`MatchData.names(x)`

The Array of the named groups' names (as `Regexp.names`).

```ruby
m = Regexp.match(/(?<y>\d+)-(?<m>\d+)?/, "12-") or raise("no match")
p(MatchData.names(m))         # => ["y", "m"]
```

## to_a

`MatchData.to_a(x)`

The Array of the whole match and every group (`m[0]`, `m[1]`, ...). A group that did not take part is nil.

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.to_a(m))          # => ["12-", "12", nil]
```

## to_s

`MatchData.to_s(x)`

The String of the whole match (as `m[0]`, but never nil).

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.to_s(m))          # => "12"
```

## values_at

`MatchData.values_at(x, *Integer)`

The Array of the Strings of the given group numbers (in the manner of `Array.values_at`). A group that did not take part and a number out of range give nil. Only Integers are accepted, not names (a `type` problem statically).

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.values_at(m, 0, 2, 9))    # => ["12-", nil, nil]
p(MatchData.values_at(m))             # => []
```

## match

`MatchData.match(x, Integer)`

The String of the group with that number (nil when it did not take part; reported at `--strict` level 2). It differs from `m[i]` in that a number out of range is an `IndexError` at run time rather than nil.

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.match(m, 1))      # => "12"
p(MatchData.match(m, 2))      # => nil
```

```ruby error
m = Regexp.match(/(a)/, "a") or raise("no match")
p(MatchData.match(m, 5))      # !> IndexError: MatchData.match: index 5 out of matches
```

## match_length

`MatchData.match_length(x, Integer)`

The number of characters the group with that number matched (an Integer). Nil when it did not take part (reported at `--strict` level 2); a number out of range is an `IndexError`.

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.match_length(m, 1))   # => 2
p(MatchData.match_length(m, 2))   # => nil
```

## pre_match, post_match

`MatchData.pre_match(x)`

`MatchData.post_match(x)`

The String before the match and the String after it (Ruby's `` $` `` and `$'`).

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.pre_match(m))     # => "ab "
p(MatchData.post_match(m))    # => " cd"
```

## begin, end

`MatchData.begin(x, Integer)`

`MatchData.end(x, Integer)`

The position where the group with that number starts and where it ends (Integers in characters; `end` is one past the last character). The checker types them as Integer, but for a group that did not take part they return **nil** at run time, which is not reported statically: check `m[i]` first when the group is optional. A number out of range is an `IndexError`.

```ruby
m = Regexp.match(/(\d+)-(\d+)/, "ab 12-34") or raise("no match")
p(MatchData.begin(m, 0))      # => 3
p(MatchData.end(m, 0))        # => 8
p(MatchData.begin(m, 2))      # => 6
p(MatchData.end(m, 2))        # => 8
```

## offset

`MatchData.offset(x, Integer)`

The Tuple `[begin, end]` of the group with that number. A group that did not take part gives `[nil, nil]`; a number out of range is an `IndexError`.

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "ab 12-") or raise("no match")
p(MatchData.offset(m, 1))     # => [3, 5]
p(MatchData.offset(m, 2))     # => [nil, nil]
```

```ruby error
m = Regexp.match(/(a)/, "a") or raise("no match")
p(MatchData.offset(m, 5))     # !> IndexError: MatchData.offset: index 5 out of matches
```

## bytebegin, byteend

`MatchData.bytebegin(x, Integer)`

`MatchData.byteend(x, Integer)`

The byte versions of `begin` and `end` (Integers). They differ from the character positions in a String with multibyte characters. A group that did not take part gives nil (reported at `--strict` level 2); a number out of range is an `IndexError`.

```ruby
m = Regexp.match(/(い)/, "あいう") or raise("no match")
p(MatchData.begin(m, 1))      # => 1
p(MatchData.bytebegin(m, 1))  # => 3
p(MatchData.byteend(m, 1))    # => 6
```

## byteoffset

`MatchData.byteoffset(x, Integer)`

The byte version of `offset`: the Tuple `[bytebegin, byteend]`. A group that did not take part gives `[nil, nil]`.

```ruby
m = Regexp.match(/(い)/, "あいう") or raise("no match")
p(MatchData.byteoffset(m, 1))     # => [3, 6]
p(MatchData.offset(m, 1))         # => [1, 2]
```

## length, size

`MatchData.length(x)`

`MatchData.size(x)`

The number of groups plus one (the whole match included; the length of `to_a`).

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.size(m))          # => 3
p(MatchData.length(m))        # => 3
```

## regexp

`MatchData.regexp(x)`

The Regexp that made this match.

```ruby
m = Regexp.match(/\d+/i, "12") or raise("no match")
p(MatchData.regexp(m))        # => /\d+/i
```

## string

`MatchData.string(x)`

The whole String the match was tried on. It is frozen: an in-place change such as `String.upcase!` is a `TypeError`.

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.string(m))        # => "ab 12 cd"
```
