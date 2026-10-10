# MatchData

MatchData は正規表現が一致した結果です。`Regexp.match(re, s)` と `String.match(s, re)` が返し、一致しなかったときは nil なので、まず確かめてから使います（[Regexp](Regexp.md)）。Ruby の `$~`、`$1` のようなグローバルは無く、MatchData を変数に置いて添字で読みます（[値と型](../03-values.md)）。

グループは Ruby と同じ番号です: 0 が一致全体、1 から順に `(...)` のグループ。名前付きグループ `(?<name>...)` は名前（String）でも読めます。Ruby と同じく、名前付きグループが 1 つでもあると、名前の無い `(...)` はグループとして数えません。一致に参加しなかったグループ（`(a)?` が空振りしたとき）は nil です。

MatchData に使える演算子は添字 `m[k]` だけで、`m[k] = v` はできません（[演算子と添字](../05-operators.md)）。MatchData 自体は Hash のキーにはなれません。

## []

`MatchData.[](x, Any)`

`m[k]` の関数形。`k` が Integer ならその番号のグループの String（0 は一致全体、負の値は末尾から）、String か Symbol ならその名前のグループの String です。一致に参加しなかったグループと、**範囲外の番号**は nil。一方、**無い名前**は実行時に `IndexError` です。戻り値は `x[k]` の nil（添字外れの nil）なので、`--strict` のレベル 2 では確かめずに使っても報告されず、レベル 3（`index-nil`）で報告されます。Integer と String 以外の添字は `TypeError`。

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

グループ 1 以降の String の Array（一致全体は含みません）。参加しなかったグループは nil で、要素の型は String か nil です。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.captures(m))      # => ["12", nil]
```

## named_captures

`MatchData.named_captures(x)`

名前付きグループの名前（String）から一致した String（参加しなければ nil）への Hash。名前付きグループが無ければ空の Hash。

```ruby
m = Regexp.match(/(?<y>\d+)-(?<m>\d+)?/, "12-") or raise("no match")
p(MatchData.named_captures(m))    # => {"y" => "12", "m" => nil}
```

## names

`MatchData.names(x)`

名前付きグループの名前の Array（`Regexp.names` と同じ）。

```ruby
m = Regexp.match(/(?<y>\d+)-(?<m>\d+)?/, "12-") or raise("no match")
p(MatchData.names(m))         # => ["y", "m"]
```

## to_a

`MatchData.to_a(x)`

一致全体とすべてのグループの Array（`m[0]`、`m[1]`、...）。参加しなかったグループは nil。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.to_a(m))          # => ["12-", "12", nil]
```

## to_s

`MatchData.to_s(x)`

一致全体の String（`m[0]` と同じですが、nil にはなりません）。

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.to_s(m))          # => "12"
```

## values_at

`MatchData.values_at(x, *Integer)`

指定した番号のグループの String を並べた Array（Ruby の `Array.values_at` と同じ要領）。参加しなかったグループと範囲外の番号は nil。番号は Integer だけで、名前は取れません（静的に `type` の問題）。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.values_at(m, 0, 2, 9))    # => ["12-", nil, nil]
p(MatchData.values_at(m))             # => []
```

## match

`MatchData.match(x, Integer)`

番号のグループの String（参加しなければ nil。「外れの nil」（`index-nil`）なので `--strict` レベル 3 でのみ報告）。`m[i]` との違いは、範囲外の番号が nil ではなく実行時に `IndexError` になることです。

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

番号のグループが一致した文字数（Integer）。参加しなければ nil（「外れの nil」、`index-nil`、レベル 3）、範囲外の番号は `IndexError`。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.match_length(m, 1))   # => 2
p(MatchData.match_length(m, 2))   # => nil
```

## pre_match, post_match

`MatchData.pre_match(x)`

`MatchData.post_match(x)`

一致した箇所より前の String と後の String（Ruby の `` $` `` と `$'`）。

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.pre_match(m))     # => "ab "
p(MatchData.post_match(m))    # => " cd"
```

## begin, end

`MatchData.begin(x, Integer)`

`MatchData.end(x, Integer)`

番号のグループが一致した始めの位置と終わりの位置（文字単位の Integer。`end` は最後の文字の次）。参加しなかったグループでは **nil** です。結果の型は `Integer | nil` で、この nil は「外れの nil」（`index-nil`）なので `--strict` レベル 3 でのみ報告されます（`bytebegin`、`byteend`、`offset`、`byteoffset`、`match`、`match_length` の nil も同じです）。範囲外の番号は `IndexError`（`index 5 out of matches`）で、rescue できます。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "ab 12-") or raise("no match")
p(MatchData.begin(m, 0))      # => 3
p(MatchData.end(m, 0))        # => 6
p(MatchData.begin(m, 1))      # => 3
p(MatchData.end(m, 1))        # => 5
p(MatchData.begin(m, 2))      # => nil
b = MatchData.begin(m, 2)
if b
  p(b)
else
  puts("group 2 did not take part")      # => group 2 did not take part
end
```

```ruby error
m = Regexp.match(/(a)/, "a") or raise("no match")
p(MatchData.begin(m, 5))      # !> IndexError: MatchData.begin: index 5 out of matches
```

## offset

`MatchData.offset(x, Integer)`

番号のグループの `[begin, end]` の Tuple。参加しなかったグループは `[nil, nil]`、範囲外の番号は `IndexError`。

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

`begin`、`end` のバイト単位の版（Integer）。マルチバイト文字を含む String で文字の位置と違ってきます。参加しなかったグループは nil（「外れの nil」、`index-nil`、レベル 3）、範囲外の番号は `IndexError`。

```ruby
m = Regexp.match(/(い)/, "あいう") or raise("no match")
p(MatchData.begin(m, 1))      # => 1
p(MatchData.bytebegin(m, 1))  # => 3
p(MatchData.byteend(m, 1))    # => 6
```

## byteoffset

`MatchData.byteoffset(x, Integer)`

`offset` のバイト単位の版: `[bytebegin, byteend]` の Tuple。参加しなかったグループは `[nil, nil]`。

```ruby
m = Regexp.match(/(い)/, "あいう") or raise("no match")
p(MatchData.byteoffset(m, 1))     # => [3, 6]
p(MatchData.offset(m, 1))         # => [1, 2]
```

## length, size

`MatchData.length(x)`

`MatchData.size(x)`

グループの個数 + 1（一致全体を含む。`to_a` の長さ）。

```ruby
m = Regexp.match(/(\d+)-(\d+)?/, "12-") or raise("no match")
p(MatchData.size(m))          # => 3
p(MatchData.length(m))        # => 3
```

## regexp

`MatchData.regexp(x)`

この一致を作った Regexp。

```ruby
m = Regexp.match(/\d+/i, "12") or raise("no match")
p(MatchData.regexp(m))        # => /\d+/i
```

## string

`MatchData.string(x)`

一致を試した String 全体。凍結されていて、`String.upcase!` のようなその場の変更は `TypeError` です。

```ruby
m = Regexp.match(/\d+/, "ab 12 cd") or raise("no match")
p(MatchData.string(m))        # => "ab 12 cd"
```
