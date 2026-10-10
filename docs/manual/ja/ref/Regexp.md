# Regexp

Regexp は正規表現です。リテラル `/\d+/` と、Ruby と同じフラグ `i`（大文字小文字を区別しない）、`m`（`.` が改行にも一致）、`x`（空白とコメントを無視）、`n`（バイト列として扱う。`/a/n` のエンコーディングは US-ASCII）が使えます。`/a#{x}/` で String を埋め込めます。文字列から組み立てるには `Regexp.new(s, flags)`。文法は Ruby（Onigmo）のものそのままで、名前付きグループ `(?<name>...)` も使えます（[値と型](../03-values.md)）。

Ruby との大きな違いは、一致の結果がグローバルに残らないことです。`$~`、`$1`、`Regexp.last_match` は存在せず、`/(?<y>\d+)/ =~ s` が局所変数 `y` を作ることもありません（静的なエラー）。一致の結果は `Regexp.match` が返す MatchData を変数に置いて読みます（[MatchData](MatchData.md)）。

Regexp に使える演算子は `=~`（String との一致位置、無ければ nil）、`==`、`!=` です。String 側の `s =~ re`、`s !~ re` もあります。`String.match`、`match?`、`scan`、`sub`、`gsub`、`split`、`index` なども Regexp を取ります（[演算子と添字](../05-operators.md)）。Regexp は Hash のキーや Set の要素にはなれません（`TypeError`）。

## new

`Regexp.new(String, [String])`

ソースの String から Regexp を作ります。第 2 引数はフラグの文字を並べた String（省略時 ""）で、リテラルと同じ `i`、`m`、`x`、`n` が使えます。それ以外の文字は実行時に `ArgumentError`。ソースが正規表現として正しくなければ `RegexpError` で、rescue できます（Ruby の `Regexp.new(s, Regexp::IGNORECASE)` のような Integer のフラグは取りません）。ソースの特殊文字をそのまま一致させたいときは `Regexp.escape` を通します。

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

String の中の正規表現の特殊文字（`.`、`*`、`(`、空白など）をバックスラッシュで逃がした String。`Regexp.new(Regexp.escape(s))` が、`s` そのものに一致する Regexp です。

```ruby
p(Regexp.escape("a.b*c"))                                 # => "a\\.b\\*c"
word = "a.b"
re = Regexp.new(Regexp.escape(word))
p(Regexp.match?(re, "a.b"))                               # => true
p(Regexp.match?(re, "axb"))                               # => false
```

## source

`Regexp.source(x)`

正規表現のソース（String）。フラグは含みません。埋め込みは展開済みの形です。

```ruby
p(Regexp.source(/\d+/))        # => "\\d+"
p(Regexp.source(/a b/x))       # => "a b"
x = "c"
p(Regexp.source(/a#{x}/i))     # => "ac"
```

## options

`Regexp.options(x)`

フラグをビットで表した Integer（Ruby と同じ: `i` が 1、`x` が 2、`m` が 4、`n` が 32）。

```ruby
p(Regexp.options(/a/))         # => 0
p(Regexp.options(/a/i))        # => 1
p(Regexp.options(/a/imx))      # => 7
p(Regexp.options(/a/n))        # => 32
```

## casefold?

`Regexp.casefold?(x)`

フラグ `i` が付いているとき true。

```ruby
p(Regexp.casefold?(/a/i))      # => true
p(Regexp.casefold?(/a/))       # => false
```

## encoding

`Regexp.encoding(x)`

正規表現のエンコーディングの名前（String）。ASCII だけのソースは "US-ASCII"、非 ASCII 文字を含むと "UTF-8"、`/.../n` は "US-ASCII"（バイト列として一致します）。

```ruby
p(Regexp.encoding(/a/))        # => "US-ASCII"
p(Regexp.encoding(/あ/))       # => "UTF-8"
p(Regexp.encoding(/a/n))       # => "US-ASCII"
```

## fixed_encoding?

`Regexp.fixed_encoding?(x)`

エンコーディングが固定されているとき true（非 ASCII 文字を含むソース）。ASCII だけのソースと `/.../n` は false で、どのエンコーディングの String にも一致を試せます。Ruby と同じです。

```ruby
p(Regexp.fixed_encoding?(/a/))     # => false
p(Regexp.fixed_encoding?(/あ/))    # => true
```

## timeout

`Regexp.timeout(x)`

その Regexp に設定された一致のタイムアウト（秒、Float）か **nil**。Sake ではタイムアウトを設定する手段が無いので常に nil で、`--strict`（レベル 2）は確かめずに使うと報告します。

```ruby
p(Regexp.timeout(/a/))         # => nil
```

## names

`Regexp.names(x)`

名前付きグループの名前の Array（String。現れた順、重複は 1 つ）。名前付きグループが無ければ空の Array。

```ruby
p(Regexp.names(/(?<y>\d+)-(?<m>\d+)/))    # => ["y", "m"]
p(Regexp.names(/(\d+)/))                  # => []
```

## named_captures

`Regexp.named_captures(x)`

名前付きグループの名前（String）から、その番号の Array への Hash。同じ名前を 2 度使うと番号が 2 つ並びます。

```ruby
p(Regexp.named_captures(/(?<y>\d+)-(?<m>\d+)/))   # => {"y" => [1], "m" => [2]}
p(Regexp.named_captures(/(?<a>.)(?<a>.)/))        # => {"a" => [1, 2]}
p(Regexp.named_captures(/(a)/))                   # => {}
```

## match

`Regexp.match(x, String, [Integer])`

String の中で最初に一致した箇所の MatchData。一致しなければ **nil** で、`--strict`（レベル 2）は確かめずに使うと報告します（`if m` や `or raise` で確かめます）。第 3 引数は探し始める位置（文字単位。省略時 0、負なら末尾から）。`String.match(s, re)` も同じです。Ruby と違い `$~` には何も残りません。

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

一致するところがあれば true。MatchData を作らないので、一致したかだけを知りたいときはこちらが軽いです。第 3 引数は探し始める位置。

```ruby
p(Regexp.match?(/\d+/, "a1"))         # => true
p(Regexp.match?(/\d+/, "abc"))        # => false
p(Regexp.match?(/\d/, "1abc", 1))     # => false
```

## =~

`Regexp.=~(x, Any)`

`re =~ s` の関数形。最初に一致した位置（Integer、文字単位）か、一致しなければ **nil**（`--strict` レベル 2 で報告）。右側は String でなければなりません。`s =~ re` も同じ結果で、`s !~ re` は一致しないとき true。Ruby と違い、名前付きグループが局所変数になることはなく、`$~` も残りません。

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

2 つの Regexp のソースとフラグが同じとき true（`!=` はその否定）。右側が Regexp 以外なら等しくありません。

```ruby
p(/a/ == /a/)                  # => true
p(/a/ == /a/i)                 # => false
p(/a/ != /b/)                  # => true
p(/a/ == "a")                  # => false
```

## union

`Regexp.union(*String|Regexp|Array)`

引数のどれかに一致する Regexp。String は `escape` した上で、Regexp はそのフラグを保ったまま `|` でつなぎます。引数が無ければ何にも一致しない `/(?!)/`。パターンは個々に並べるか、Ruby と同じく String と Regexp の Array を **1 つ**だけ渡します（`Regexp.union(Array["a", "b"])`）。他の引数と並べた Array や、String でも Regexp でもない要素は実行時に `TypeError` です。

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
