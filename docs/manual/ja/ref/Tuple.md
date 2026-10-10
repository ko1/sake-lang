# Tuple

Tuple は長さが固定で、位置ごとに型が決まった並びです。リテラル `[1, "a"]` が Tuple を作ります（Ruby の `[1, "a"]` は Array ですが、Sake では `Array[1, "a"]` が Array です。[値と型](../03-values.md)）。要素の個数と各位置の型は値の型の一部で、検査器は添字の範囲と位置の型を静的に見ます。伸ばす・縮めることはできません。可変長の並びには Array を使います。

多重代入 `a, b = t` と Tuple パターン `in [Integer, String]` が Tuple を分解します。関数の `return a, b` は Tuple を返します。

Tuple に使える演算子は `==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>`（2 つの Tuple を辞書順に比べる）と添字 `t[i]`、`t[i] = v` です。ここに挙げた `Tuple.<(x, y)` などは、その演算子を関数の形で呼ぶものです（[演算子と添字](../05-operators.md)）。

## Tuple[]

`Tuple[*Any]`

**Tuple の Array** を作ります（Tuple そのものではありません）。`Integer[]` や `String[]` と同じ型付き Array で、要素はすべて Tuple でなければならず、`Array.push` などの書き込みも毎回検査されます。Tuple 以外の要素は静的に `type` の問題、実行時は `TypeError` です。空の Tuple の Array は `Tuple[]` です。

```ruby
pairs = Tuple[[1, "a"], [2, "b"]]
Array.push(pairs, [3, "c"])
p(pairs)                   # => [[1, "a"], [2, "b"], [3, "c"]]
p(Array.size(Tuple[]))     # => 0
```

```ruby error
Array.push(Tuple[], 1)     # !> Array.push: an element must be Tuple, but is Integer
```

## []

`Tuple.[](x, Any)`

`t[i]` の関数形。位置 `i`（Integer。負の値は末尾から）の要素を返します。戻り値の型はその位置の型です。Tuple の長さは型の一部なので、範囲外の添字は Array のように nil にならず、静的に `type` の問題（`the index is outside the Tuple`）、実行時は `IndexError` です。添字に Range は使えません（`TypeError`）。

```ruby
t = [1, "a", 2.5]
p(t[0])                    # => 1
p(t[-1])                   # => 2.5
p(Tuple.[](t, 1))          # => "a"
```

```ruby error
t = [1, 2]
p(t[5])                    # !> the index is outside the Tuple
```

## []=

`Tuple.[]=(x, Any, Any)`

`t[i] = v` の関数形。位置 `i` の要素を `v` に置き換え、`v` を返します。その位置の型と違う型の値は静的に `type` の問題、実行時は `TypeError` です。範囲外の添字は `IndexError`。

```ruby
t = [1, "a"]
t[0] = 10
Tuple.[]=(t, 1, "b")
p(t)                       # => [10, "b"]
```

```ruby error
t = [1, 2]
t[0] = "x"                 # !> the value must be Integer, but is String
```

## length, size

`Tuple.length(x)`

`Tuple.size(x)`

要素の個数（Integer）。Tuple の長さは型から分かるので、検査器にとっては定数です。

```ruby
p(Tuple.size([1, "a", 2.5]))     # => 3
p(Tuple.length([]))              # => 0
```

## max, min

`Tuple.max(x)`

`Tuple.min(x)`

要素のうち最大・最小のものを返します（Ruby の `[a, b].max`）。各位置の型は分かっているので、要素が互いに比べられるかは静的に見ます: 比べられない組（Integer と String など）は `type` の問題（`elements compared in order may be (Integer, String), which cannot be compared`）、nil になり得る位置は `nil` の問題です。検査器に見えない比較の失敗（`Float.NAN` など）は実行時に `ArgumentError`。Integer と Float は混ぜて比べられます。空の Tuple `[]` では nil です。要素が Struct 値なら、その型の `<=>`（`include Comparable`）で比べます。結果の型は各位置の型の和で、空でない Tuple では nil になりません。

```ruby
p(Tuple.max([3, 1, 2]))          # => 3
p(Tuple.min([3, 1, 2]))          # => 1
p(Tuple.max([2, 1.5]))           # => 2
p(Tuple.max([3, 1]) + 1)         # => 4
p(Tuple.max([]))                 # => nil
```

```ruby error
p(Tuple.max([1, "a"]))           # !> Tuple.max: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
p(Tuple.max([1.0, Float.NAN]))   # !> ArgumentError: Tuple.max: cannot compare elements of types Float
```

## minmax

`Tuple.minmax(x)`

最小と最大の 2 要素の Tuple `[min, max]` を返します。比較の規則は `min`、`max` と同じです（比べられない組は静的に `type` の問題）。

```ruby
lo, hi = Tuple.minmax([3, 1, 2])
p([lo, hi])                      # => [1, 3]
```

## to_a

`Tuple.to_a(x)`

同じ要素を持つ新しい Array を返します。元の Tuple とは独立で、Array の方は伸ばせます。要素の型は Tuple の各位置の型の和になります。

```ruby
t = [1, "a"]
a = Tuple.to_a(t)
Array.push(a, :x)
p(a)                             # => [1, "a", :x]
p(t)                             # => [1, "a"]
```

## ==, !=

`Tuple.==(x, Any)`

`Tuple.!=(x, Any)`

2 つの Tuple が同じ長さで、各位置の要素が `==` で等しいときに true（`!=` はその否定）。右側が Tuple 以外の値（Array や nil）なら等しくありません。`Array[1, 2]` と `[1, 2]` は型が違うので等しくありません。

```ruby
p([1, 2] == [1, 2])              # => true
p([1, 2] != [1, 2, 3])           # => true
p([1, 2] == Array[1, 2])         # => false
```

## <, <=, >, >=

`Tuple.<(x, Any)`

`Tuple.<=(x, Any)`

`Tuple.>(x, Any)`

`Tuple.>=(x, Any)`

2 つの Tuple を辞書順に比べます: 先頭から順に要素を比べ、最初に違った位置で決まり、すべて等しければ短い方が小さい。各位置の組は互いに比べられる型でなければならず、比べられない組は静的に `type` の問題（`elements compared in order may be (Integer, String)`）です。右側は Tuple でなければなりません。

```ruby
p([1, 2] < [1, 3])               # => true
p([2] > [1, 9])                  # => true
p([1] < [1, 0])                  # => true
p(Tuple.<=([1, 2], [1, 2]))      # => true
```

```ruby error
p([1, 2] < [1, "a"])             # !> which cannot be compared
```

## <=>

`Tuple.<=>(x, Any)`

辞書順の比較の結果を -1、0、1 で返します。比較の規則は `<` と同じです。`Array.sort_by` のキーに Tuple を返すと、この順で並びます。

```ruby
p([1, 2] <=> [1, 2])             # => 0
p([1, 2] <=> [1, 2, 3])          # => -1
p(Array.sort_by(Array["bb", "a", "c"]) { |s| [String.size(s), s] })   # => ["a", "c", "bb"]
```
