# Array

Array は長さが変わる並びです。`Array[1, 2, 3]` が Array を作ります。Ruby の `[1, 2, 3]` は Array ですが、Sake のリテラル `[1, 2, 3]` は長さ固定の Tuple で、`Array.push` などに渡すと静的に拒否されます（[値と型](../03-values.md)）。`Integer[1, 2]`、`String[]`、`Point[p]` のような型付き Array は、要素の型が宣言された Array で、`Array.push`・`append`・`unshift`・`prepend`・`insert`・`concat`・`map!`・`fill`・`a[i] = v` などの書き込みが毎回検査されます（違う型は静的に `type` の問題、実行時は `TypeError`）。型付き Array にも、この章の操作がすべて使えます。`map`・`select`・`sort`・`first(a, n)`・`+` などが返す新しい Array には要素の型の宣言はありません。`dup` だけが要素の型を保ちます。

検査器は、1 つの Array（構築した場所）に対してプログラム全体で 1 つの要素型を与えます。`Array.map!` などの書き換えで別の型を入れると、以後その Array は両方の型を持つものとして扱われ、片方の型にしか合わない操作が `type`（partial）になります（[値と型](../03-values.md)）。

要素が無いことを nil で表す操作が 2 種類あります。「外した nil」（`x[k]`、`first`、`last`、`pop`、`shift`、`min`、`max`、`minmax`、`min_by`、`max_by`、`minmax_by`、`at`、`slice`、`slice!`、`dig`、`sample`、`delete_at`。空の Array や範囲外の添字）を未検査で使うのは `--strict=3` の `index-nil` の問題で、`--strict`（レベル 2）は見逃します。`find`、`index`、`find_index`、`rindex`、`bsearch`、`delete`、`uniq!` など、それ以外の nil はレベル 2 の `nil` の問題です（[概要](../01-overview.md)）。

Array に使える演算子は `+`、`-`、`*`、`==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>`（2 つの Array を辞書順に比べる）と添字 `a[i]`、`a[i, n]`、`a[range]`、`a[i] = v` です。`Array.+(x, y)` などはその演算子を関数の形で呼ぶものです（[演算子と添字](../05-operators.md)）。要素を比べる操作（`sort`、`min`、`max`、`<` など）は、要素が互いに比べられる型でなければなりません。Integer と Float は混ぜて比べられ、Tuple は要素ごとに、クラスのインスタンスはその型の `<=>`（`include Comparable`）で比べます。

ブロックを取る操作は Ruby と同じ形で書きます（`Array.map(xs) { |x| x * 2 }`）。Ruby の Enumerator（ブロック無しの `each` など）はありません。ブロックが省ける操作（`each_with_index`、`each_slice`、`each_cons`）は、ブロック無しでは結果を Array で返します。

## Array[]

`Array[*Any]`

要素を並べた新しい Array を作ります。要素の型は何でもよく、混ぜてもよく、以後どんな値でも追加できます（検査器は追加された値の型を要素型の和に加えます）。空の Array は `Array[]`。リテラル `[1, 2]` は Tuple なので、伸ばせる並びには必ず `Array[...]` を書きます。型付き Array は `Integer[1, 2]` のように型の名前で作ります（その型の章を参照）。

```ruby
xs = Array[1, "a"]
Array.push(xs, :sym)
p(xs)                          # => [1, "a", :sym]
e = Array[]
Array.push(e, 1)
p(e)                           # => [1]
p([1, 2] == Array[1, 2])       # => false
```

```ruby error
xs = [1, 2]
Array.push(xs, 3)              # !> `[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`
```

## new

`Array.new(Integer, [Any]) [{ }]`

長さ `n` の新しい Array を作ります。`Array.new(n)` は nil が n 個、`Array.new(n, v)` は同じ値 `v` が n 個（同じ 1 つの値を共有します。`Array.new(2, Array[])` の 2 要素は同じ Array です）、`Array.new(n) { |i| ... }` は添字 i ごとにブロックの値です。要素の型は nil、`v` の型、またはブロックの結果の型です。負の `n` は `ArgumentError`。

```ruby
p(Array.new(3))                        # => [nil, nil, nil]
p(Array.new(2, "a"))                   # => ["a", "a"]
p(Array.new(3) { |i| i * i })          # => [0, 1, 4]
rows = Array.new(2, Array[])
Array.push(Array.fetch(rows, 0), 1)
p(rows)                                # => [[1], [1]]
rows2 = Array.new(2) { |i| Array[] }
Array.push(Array.fetch(rows2, 0), 1)
p(rows2)                               # => [[1], []]
```

```ruby error
Array.new(-1)                          # !> ArgumentError: Array.new: negative size -1
```

## dup

`Array.dup(x)`

同じ要素を持つ新しい Array を返します（浅いコピー。要素は共有します）。型付き Array の複製は同じ要素の型を持つ型付き Array です。この章の他の操作が返す新しい Array と違い、要素型の宣言を保つのはこの操作だけです。

```ruby
xs = Integer[1, 2]
ys = Array.dup(xs)
Array.push(ys, 3)
p(xs)                          # => [1, 2]
p(ys)                          # => [1, 2, 3]
```

```ruby error
ys = Array.dup(Integer[1])
Array.push(ys, "s")            # !> Array.push: an element must be Integer, but is String
```

## to_a

`Array.to_a(x)`

主語そのもの（同じ Array）を返します。コピーではありません。`Tuple.to_a` や `Set.to_a`、`Hash.to_a` など他の型から Array を得る操作と形を揃えるためのものです。

```ruby
xs = Array[1, 2]
p(Array.to_a(xs))                          # => [1, 2]
p(Kernel.equal?(Array.to_a(xs), xs))       # => true
```

## length, size

`Array.length(x)`

`Array.size(x)`

要素の個数（Integer）。

```ruby
p(Array.size(Array[3, 1, 2]))      # => 3
p(Array.length(Array[]))           # => 0
```

## empty?

`Array.empty?(x)`

要素が 1 つも無いとき true。

```ruby
p(Array.empty?(Array[]))           # => true
p(Array.empty?(Array[1]))          # => false
```

## []

`Array.[](x, Any, [Integer])`

`a[i]`、`a[i, n]`、`a[range]` の関数形。`a[i]` は位置 `i`（Integer。負の値は末尾から）の要素で、範囲外なら nil です。その nil は「外した nil」で、未検査で使うのは `--strict=3` の `index-nil` の問題（レベル 2 では報告されません）。`a[i, n]` は位置 i から n 個、`a[range]` はその範囲の要素を新しい Array で返し、開始位置が末尾を越えているときは nil です。例外にしたいときは `Array.fetch` を使います。添字が Integer でも Range でもない値は `TypeError`。

```ruby
xs = Array[3, 1, 2]
p(xs[1])                       # => 1
p(xs[-1])                      # => 2
p(xs[9])                       # => nil
p(xs[1, 2])                    # => [1, 2]
p(xs[0..1])                    # => [3, 1]
p(xs[5, 1])                    # => nil
p(Array.[](xs, 0))             # => 3
p(Array.[](xs, 0, 2))          # => [3, 1]
```

## []=

`Array.[]=(x, Any, Any)`

`a[i] = v` の関数形。位置 `i` の要素を `v` に置き換え、`v` を返します。末尾より先に書くと、Ruby と同じく間が nil で埋まります。型付き Array では `v` の型が検査され（静的に `type`、実行時は `TypeError`）、nil は要素になれないので末尾より先への書き込みは `IndexError` です。負の添字が先頭より前なら `IndexError`。

```ruby
xs = Array[1]
xs[3] = 2
p(xs)                          # => [1, nil, nil, 2]
xs[-1] = 5
p(xs)                          # => [1, nil, nil, 5]
p(Array.[]=(xs, 0, 0))         # => 0
```

```ruby error
is = Integer[1]
is[3] = 2                      # !> IndexError: Array.[]=: index 3 is past the end of Integer[] (length 1); the gap would be nil
```

## at

`Array.at(x, Integer)`

位置 `i` の要素（`a[i]` と同じ。負の値は末尾から）。範囲外は nil で、「外した nil」としてレベル 3 だけが報告します。

```ruby
xs = Array[3, 1, 2]
p(Array.at(xs, 0))             # => 3
p(Array.at(xs, -1))            # => 2
p(Array.at(xs, 9))             # => nil
```

## fetch

`Array.fetch(x, Integer, [Any])`

位置 `i` の要素を返します。範囲外のときは、`default` があればそれを、無ければ `IndexError` を上げます。結果が nil になることはないので（default が nil でなければ）、`--strict` で添字の nil 検査を避けたいときに使います。結果の型は要素型（default があればその型との和）です。

```ruby
xs = Array[3, 1, 2]
p(Array.fetch(xs, 1))          # => 1
p(Array.fetch(xs, -1))         # => 2
p(Array.fetch(xs, 9, 0))       # => 0
```

```ruby error
Array.fetch(Array[3, 1, 2], 9)     # !> IndexError: Array.fetch: index 9 outside of array bounds: -3...3
```

## first, last

`Array.first(x, [Integer])`

`Array.last(x, [Integer])`

`first(a)` は先頭、`last(a)` は末尾の要素で、空の Array では nil（「外した nil」。レベル 3 だけが報告します）。`first(a, n)`、`last(a, n)` は先頭・末尾から n 個を新しい Array で返します（要素が足りなければあるだけ。nil にはなりません）。負の n は `ArgumentError`。

```ruby
xs = Array[3, 1, 2]
p(Array.first(xs))             # => 3
p(Array.last(xs))              # => 2
p(Array.first(xs, 2))          # => [3, 1]
p(Array.last(xs, 5))           # => [3, 1, 2]
p(Array.first(Array[]))        # => nil
p(Array.last(Array[], 2))      # => []
```

```ruby error
Array.first(Array[1], -1)      # !> ArgumentError: Array.first: negative size -1
```

## slice

`Array.slice(x, Integer|Range, [Integer])`

`a[i]`、`a[i, n]`、`a[range]` と同じ結果を返します: `slice(a, i)` は要素か nil、`slice(a, i, n)` と `slice(a, range)` は新しい Array か nil（開始位置が末尾を越えたとき）。`a[i]` と同じく、この nil は「外した nil」で、未検査で使うのは `--strict=3` の `index-nil` の問題です（レベル 2 では報告されません）。例外にしたいときは `Array.fetch` を使います。

```ruby
xs = Array[3, 1, 2]
p(Array.slice(xs, 1))          # => 1
p(Array.slice(xs, 1, 5))       # => [1, 2]
p(Array.slice(xs, 1..))        # => [1, 2]
p(Array.slice(xs, 9))          # => nil
y = Array.slice(xs, 0)
p(y + 1) if y                  # => 4
```

## dig

`Array.dig(x, Integer, *Any)`

位置 `i` の要素か nil（`a[i]` と同じ）。添字を 2 つ以上与えると、Ruby の `dig` のように入れ子を順に掘ります: 2 つ目以降の添字は 1 つ前で得た値に当て（Array なら Integer の位置、Hash ならそのキー）、途中で nil になればそのまま nil です。途中の値は Array、Tuple、Hash のどれかでなければならず、他の型（Integer、String、Record など）は静的に `type` の問題、検査を通さずに実行すれば `TypeError`（`Integer cannot be dug into (not an Array, a Tuple, or a Hash)`）です。Array や Tuple に Integer 以外の添字を当てると `TypeError`。nil は「外した nil」で、レベル 3 だけが報告します。

```ruby
xs = Array[Array[1, 2], Array[3]]
p(Array.dig(xs, 0))            # => [1, 2]
p(Array.dig(xs, 5))            # => nil
p(Array.dig(xs, 0, 1))         # => 2
p(Array.dig(xs, 1, 5))         # => nil
p(Array.dig(xs, 5, 0))         # => nil
p(Array.dig(Array[Hash[a: 1]], 0, :a))     # => 1
p(Array.dig(Array[[1, "x"]], 0, 1))        # => "x"
p(Array.dig(Array[[1, "x"]], 0, 5))        # => nil
```

```ruby error
p(Array.dig(Array[Array[1, 2]], 0, 1, 2))  # !> Array.dig: the value must be Array|Hash|Tuple, but is Integer
```

```ruby error
p(Array.dig(Array[Array[1]], 0, "k"))      # !> TypeError: Array.dig: an index into Array must be Integer, got String
```

## values_at

`Array.values_at(x, *Integer)`

与えた位置の要素を並べた新しい Array。範囲外の位置は nil になります（要素型は要素型と nil の和）。

```ruby
xs = Array[3, 1, 2]
p(Array.values_at(xs, 0, 2, 7))    # => [3, 2, nil]
```

## fetch_values

`Array.fetch_values(x, *Integer)`

与えた位置の要素を並べた新しい Array。範囲外の位置があれば `IndexError`（nil にはなりません）。

```ruby
p(Array.fetch_values(Array[3, 1, 2], 0, 2))    # => [3, 2]
```

```ruby error
Array.fetch_values(Array[3, 1, 2], 0, 9)       # !> IndexError: Array.fetch_values: index 9 outside of array bounds: -3...3
```

## push, append

`Array.push(x, *Any)`

`Array.append(x, *Any)`

末尾に値を追加して（何個でも）、主語を返します。その場で変更します。型付き Array では各値の型を検査します（静的に `type`、実行時は `TypeError`）。検査器は追加された値の型をその Array の要素型に加えます。Ruby の `<<` はありません。

```ruby
xs = Array[1]
p(Array.push(xs, 2, 3))        # => [1, 2, 3]
p(Array.append(xs, 4))         # => [1, 2, 3, 4]
```

```ruby error
Array.push(Integer[1, 2], "x")     # !> Array.push: an element must be Integer, but is String
```

## unshift, prepend

`Array.unshift(x, *Any)`

`Array.prepend(x, *Any)`

先頭に値を追加して（何個でも、与えた順のまま）、主語を返します。その場で変更します。型付き Array では型を検査します。

```ruby
xs = Array[3]
p(Array.unshift(xs, 1, 2))     # => [1, 2, 3]
p(Array.prepend(xs, 0))        # => [0, 1, 2, 3]
```

## insert

`Array.insert(x, Integer, *Any)`

位置 `i` の前に値を差し込み（何個でも）、主語を返します。`i` が長さと等しければ末尾に追加します。負の `i` は末尾から数えます（`-1` なら末尾に追加、`-size - 1` なら先頭）。`i` が長さより大きいとき、Ruby は間を nil で埋めますが、Sake では `IndexError` です（型付きでない Array でも。nil を黙って作らないためです）。`-size - 1` より小さい負の `i`（先頭より前）も `IndexError`。型付き Array では差し込む値の型を検査します（静的に `type`、実行時は `TypeError`）。

```ruby
xs = Array[1, 2, 3]
p(Array.insert(xs, 1, 9, 9))   # => [1, 9, 9, 2, 3]
p(Array.insert(xs, -2, 7))     # => [1, 9, 9, 2, 7, 3]
p(Array.insert(xs, 6, 8))      # => [1, 9, 9, 2, 7, 3, 8]
```

```ruby error
Array.insert(Array[1], 3, 2)   # !> IndexError: Array.insert: index 3 is past the end of the Array (length 1); the gap would be nil
```

```ruby error
Array.insert(Array[1, 2], -4, 0)   # !> IndexError: Array.insert: index -4 is before the start of the Array (length 2)
```

```ruby error
Array.insert(Integer[1], 0, "a")   # !> Array.insert: an element must be Integer, but is String
```

## concat

`Array.concat(x, Array)`

もう 1 つの Array の要素をすべて末尾に追加して、主語を返します。その場で変更します（`+` は新しい Array を作ります）。型付き Array では要素の型を検査します。

```ruby
xs = Array[1]
p(Array.concat(xs, Array[2, 3]))   # => [1, 2, 3]
```

```ruby error
Array.concat(Integer[1], Array["a"])   # !> Array.concat: an element must be Integer, but is String
```

## fill

`Array.fill(x, Any)`

すべての要素を `v` に置き換え、主語を返します（長さは変わりません）。Ruby の範囲やブロックの形はありません。型付き Array では `v` の型を検査します（静的に `type`、検査を通らずに実行すれば `TypeError`）。

```ruby
xs = Array[1, 2, 3]
p(Array.fill(xs, 0))           # => [0, 0, 0]
```

```ruby error
Array.fill(Integer[1], "a")    # !> Array.fill: an element must be Integer, but is String
```

## replace

`Array.replace(x, Array)`

主語の内容をもう 1 つの Array の要素で置き換え、主語を返します（`a = other` と違い、同じ Array を共有している場所すべてに見えます）。型付き Array では要素の型を検査します（静的に `type`、実行時は `TypeError`）。

```ruby
xs = Array[1, 2, 3]
ys = xs
p(Array.replace(xs, Array[9]))     # => [9]
p(ys)                              # => [9]
```

```ruby error
Array.replace(Integer[1], Array["a"])  # !> Array.replace: an element must be Integer, but is String
```

## pop

`Array.pop(x)`

末尾の要素を取り除いて返します。空の Array では nil（「外した nil」。レベル 3 だけが報告します）。Ruby の `pop(n)` はありません。

```ruby
xs = Array[1, 2]
p(Array.pop(xs))               # => 2
p(xs)                          # => [1]
p(Array.pop(Array[]))          # => nil
```

## shift

`Array.shift(x, [Integer])`

`shift(a)` は先頭の要素を取り除いて返し、空の Array では nil（「外した nil」。レベル 3 だけが報告します）。`shift(a, n)` は先頭から n 個を取り除いて新しい Array で返します（足りなければあるだけ。nil にはなりません）。負の n は `ArgumentError`。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.shift(xs))             # => 1
p(Array.shift(xs, 2))          # => [2, 3]
p(xs)                          # => [4]
p(Array.shift(Array[]))        # => nil
p(Array.shift(Array[], 2))     # => []
```

## delete

`Array.delete(x, Any)`

`v` と `==` で等しい要素をすべて取り除き、`v` を返します。1 つも無ければ nil（レベル 2 の `nil` の問題）。

```ruby
xs = Array[1, 2, 1, 3]
p(Array.delete(xs, 1))         # => 1
p(xs)                          # => [2, 3]
p(Array.delete(xs, 42))        # => nil
```

## delete_at

`Array.delete_at(x, Integer)`

位置 `i` の要素を取り除いて返します。範囲外なら nil（「外した nil」。レベル 3 だけが報告します）。

```ruby
xs = Array[1, 2, 3]
p(Array.delete_at(xs, 1))      # => 2
p(xs)                          # => [1, 3]
p(Array.delete_at(xs, 99))     # => nil
```

## slice!

`Array.slice!(x, Integer|Range, [Integer])`

`slice` と同じものを返し、同時にそれを主語から取り除きます: `slice!(a, i)` は要素か nil、`slice!(a, i, n)` と `slice!(a, range)` は新しい Array か nil。nil は「外した nil」で、レベル 3 だけが報告します。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.slice!(xs, 1, 2))      # => [2, 3]
p(xs)                          # => [1, 4]
p(Array.slice!(xs, 0))         # => 1
p(Array.slice!(xs, 5))         # => nil
p(Array.slice!(xs, 0..0))      # => [4]
p(xs)                          # => []
```

## clear

`Array.clear(x)`

すべての要素を取り除き、主語（空になった Array）を返します。

```ruby
xs = Array[1, 2]
p(Array.clear(xs))             # => []
p(xs)                          # => []
```

## each, each_entry

`Array.each(x) { }`

`Array.each_entry(x) { }`

各要素を順にブロックに渡し、主語を返します。ブロックは必須です（Ruby の Enumerator を返す形はありません）。`break v` でその場で終わり、`v` が結果になります。`each_entry` は `each` と同じです。

```ruby
xs = Array[1, 2, 3]
r = Array.each(xs) { |x| puts(x) }
# => 1
# => 2
# => 3
p(r)                                   # => [1, 2, 3]
p(Array.each(xs) { |x| break x if x == 2 })    # => 2
```

## each_with_index

`Array.each_with_index(x) [{ }]`

ブロックに要素と添字（0 から）を渡し、主語を返します。ブロック無しでは Ruby の Enumerator ではなく、`[要素, 添字]` の Tuple を並べた新しい Array を返します。

```ruby
xs = Array["a", "b"]
Array.each_with_index(xs) { |s, i| puts("#{i}:#{s}") }
# => 0:a
# => 1:b
p(Array.each_with_index(xs))           # => [["a", 0], ["b", 1]]
```

## each_index

`Array.each_index(x) { }`

添字 0 から長さ-1 までを順にブロックに渡し、主語を返します。

```ruby
xs = Array["a", "b"]
Array.each_index(xs) { |i| puts(i) }
# => 0
# => 1
```

## reverse_each

`Array.reverse_each(x) { }`

末尾から順に各要素をブロックに渡し、主語を返します。

```ruby
Array.reverse_each(Array[1, 2, 3]) { |x| puts(x) }
# => 3
# => 2
# => 1
```

## each_slice, each_cons

`Array.each_slice(x, Integer) [{ }]`

`Array.each_cons(x, Integer) [{ }]`

`each_slice(a, n)` は要素を n 個ずつに切った Array を、`each_cons(a, n)` は連続する n 個の窓を順にブロックに渡し、主語を返します。ブロック無しでは Ruby の Enumerator ではなく、それらの Array を並べた新しい Array を返します（`each_cons` で n が長さを越えると `[]`）。n は 1 以上でなければならず、0 や負の n は `ArgumentError` です。

```ruby
xs = Array[1, 2, 3]
p(Array.each_slice(xs, 2))             # => [[1, 2], [3]]
p(Array.each_cons(xs, 2))              # => [[1, 2], [2, 3]]
Array.each_slice(xs, 2) { |s| p(s) }
# => [1, 2]
# => [3]
p(Array.each_cons(xs, 2) { |s| s })    # => [1, 2, 3]
p(Array.each_cons(xs, 5))              # => []
```

```ruby error
Array.each_slice(Array[1], 0)          # !> ArgumentError: Array.each_slice: invalid slice size
```

## each_with_object

`Array.each_with_object(x, Any) { }`

各要素と `memo` をブロックに渡し（この順）、最後に `memo` を返します。`memo` の型が結果の型です。`reduce` と違い、ブロックの値は使いません（`memo` をその場で変更して溜めます）。

```ruby
xs = Array[1, 2, 3]
p(Array.each_with_object(xs, Array[]) { |x, acc| Array.push(acc, x * 2) })   # => [2, 4, 6]
```

## cycle

`Array.cycle(x, Integer) { }`

全要素を n 回繰り返してブロックに渡し、nil を返します。Ruby の無限に繰り返す形（引数無し）はなく、n は必須です。n が 0 以下なら何もしません。

```ruby
p(Array.cycle(Array[1, 2], 2) { |x| puts(x) })
# => 1
# => 2
# => 1
# => 2
# => nil
```

## map, collect

`Array.map(x) { }`

`Array.collect(x) { }`

各要素にブロックを適用した結果を並べた新しい Array。要素の型はブロックの結果の型で、要素型の宣言はありません（型付き Array から作っても、何でも追加できます）。

```ruby
xs = Array[1, 2, 3]
p(Array.map(xs) { |x| x * 2 })             # => [2, 4, 6]
p(Array.collect(xs) { |x| Integer.to_s(x) })   # => ["1", "2", "3"]
p(xs)                                      # => [1, 2, 3]
```

## map!, collect!

`Array.map!(x) { }`

`Array.collect!(x) { }`

各要素をブロックの値で置き換え、主語を返します。その場で変更します。検査器は 1 つの Array に 1 つの要素型を与えるので、元と違う型を入れると、以後その Array は両方の型を持つものとして扱われ、片方にしか合わない操作が `type` の問題になります。同じ型への写像に使い、型を変えるなら `map`（新しい Array）を使います。型付き Array では結果の型を検査します（静的に `type`、実行時は `TypeError`）。

```ruby
xs = Array[1, 2, 3]
p(Array.map!(xs) { |x| x * 2 })        # => [2, 4, 6]
p(Array.collect!(xs) { |x| x + 1 })    # => [3, 5, 7]
p(xs)                                  # => [3, 5, 7]
```

```ruby error
xs = Array[1, 2, 3]
Array.map!(xs) { |x| Integer.to_s(x) }
p(Array.sum(xs))               # !> Array.sum: an element must be Integer|Float|Rational|Complex, but can be String
```

## flat_map

`Array.flat_map(x) { }`

各要素にブロックを適用し、その結果の並びをつなげた新しい Array。ブロックは Array か Tuple を返さなければならず、他の値は実行時に `TypeError` です。Ruby のように Array 以外の値をそのまま並べることはありません。

```ruby
p(Array.flat_map(Array[1, 2]) { |x| Array[x, x * 10] })   # => [1, 10, 2, 20]
p(Array.flat_map(Array[1, 2]) { |x| [x, x] })             # => [1, 1, 2, 2]
```

```ruby error
Array.flat_map(Array[1]) { |x| x }    # !> TypeError: Array.flat_map: the block must return an Array or a Tuple, got Integer
```

## filter_map

`Array.filter_map(x) { }`

各要素にブロックを適用し、nil と false 以外の結果を並べた新しい Array（`map` と `compact` を合わせたもの。要素型から nil は除かれます）。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.filter_map(xs) { |x| x * 10 if x > 2 })    # => [30, 40]
p(Array.filter_map(xs) { |x| x > 2 })              # => [true, true]
```

## select, filter, find_all

`Array.select(x) { }`

`Array.filter(x) { }`

`Array.find_all(x) { }`

ブロックが真（nil と false 以外）を返した要素を並べた新しい Array。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.select(xs) { |x| x > 2 })      # => [3, 4]
p(Array.filter(xs) { |x| x > 2 })      # => [3, 4]
p(Array.find_all(xs) { |x| x > 2 })    # => [3, 4]
```

## select!, filter!, keep_if

`Array.select!(x) { }`

`Array.filter!(x) { }`

`Array.keep_if(x) { }`

ブロックが真を返した要素だけを残します（その場で変更）。`keep_if` は常に主語を返します。`select!`、`filter!` は 1 つも取り除かなかったとき nil を返し（Ruby と同じ）、その結果を未検査で使うのはレベル 2 の `nil` の問題です。

```ruby
xs = Array[1, 2, 3]
p(Array.select!(xs) { |x| x > 1 })     # => [2, 3]
p(Array.select!(xs) { |x| x > 1 })     # => nil
p(Array.keep_if(xs) { |x| x > 1 })     # => [2, 3]
p(Array.keep_if(xs) { |x| x > 2 })     # => [3]
p(xs)                                  # => [3]
```

## reject

`Array.reject(x) { }`

ブロックが真を返した要素を除いた新しい Array。

```ruby
p(Array.reject(Array[1, 2, 3, 4]) { |x| x > 2 })   # => [1, 2]
```

## reject!, delete_if

`Array.reject!(x) { }`

`Array.delete_if(x) { }`

ブロックが真を返した要素を取り除きます（その場で変更）。`delete_if` は常に主語を返します。`reject!` は 1 つも取り除かなかったとき nil を返し（Ruby と同じ）、その結果を未検査で使うのはレベル 2 の `nil` の問題です。

```ruby
xs = Array[1, 2, 3]
p(Array.reject!(xs) { |x| x > 2 })     # => [1, 2]
p(Array.reject!(xs) { |x| x > 2 })     # => nil
p(Array.delete_if(xs) { |x| x > 5 })   # => [1, 2]
p(Array.delete_if(xs) { |x| x > 1 })   # => [1]
```

## partition

`Array.partition(x) { }`

ブロックが真を返した要素の Array と、残りの Array の 2 要素 Tuple `[selected, rest]` を返します。多重代入で受けます。

```ruby
evens, odds = Array.partition(Array[1, 2, 3, 4]) { |x| Integer.even?(x) }
p(evens)                       # => [2, 4]
p(odds)                        # => [1, 3]
```

## group_by

`Array.group_by(x) { }`

ブロックの値をキーとし、そのキーになった要素の Array を値とする Hash を返します（最初に現れた順）。キーは Hash のキーになれる値でなければなりません（Regexp などは `TypeError`。[値と型](../03-values.md)）。

```ruby
p(Array.group_by(Array[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => [1, 3], 0 => [2, 4]}
```

## chunk_while, slice_when

`Array.chunk_while(x) { }`

`Array.slice_when(x) { }`

隣り合う 2 要素 `(a, b)` をブロックに渡して並びを切り分け、切り分けた Array を並べた新しい Array を返します。`chunk_while` はブロックが真の間を同じ塊にまとめ、`slice_when` はブロックが真のところで切ります。

```ruby
xs = Array[1, 2, 4, 5, 7]
p(Array.chunk_while(xs) { |a, b| b == a + 1 })    # => [[1, 2], [4, 5], [7]]
p(Array.slice_when(xs) { |a, b| b != a + 1 })     # => [[1, 2], [4, 5], [7]]
```

## take, drop

`Array.take(x, Integer)`

`Array.drop(x, Integer)`

`take(a, n)` は先頭 n 個、`drop(a, n)` は先頭 n 個を除いた残りを新しい Array で返します（足りなければあるだけ）。負の n は `ArgumentError`。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.take(xs, 2))           # => [1, 2]
p(Array.drop(xs, 2))           # => [3, 4]
p(Array.take(xs, 9))           # => [1, 2, 3, 4]
```

## take_while, drop_while

`Array.take_while(x) { }`

`Array.drop_while(x) { }`

先頭からブロックが真を返す間の要素を取る（`take_while`）、または捨てて残りを返す（`drop_while`）新しい Array。

```ruby
xs = Array[1, 2, 3, 4]
p(Array.take_while(xs) { |x| x < 3 })  # => [1, 2]
p(Array.drop_while(xs) { |x| x < 3 })  # => [3, 4]
```

## include?

`Array.include?(x, Any)`

`v` と `==` で等しい要素があるとき true。クラスのインスタンスはその型の等しさで比べます（[演算子と添字](../05-operators.md)）。

```ruby
p(Array.include?(Array[1, 2], 2))          # => true
p(Array.include?(Array[1, 2], nil))        # => false
p(Array.include?(Array[[1, 2]], [1, 2]))   # => true
```

## index, rindex

`Array.index(x, Any)`

`Array.rindex(x, Any)`

`v` と `==` で等しい最初（`index`）・最後（`rindex`）の要素の位置（Integer）。無ければ nil で、レベル 2 の `nil` の問題です。Ruby のブロック形はなく、条件で探すなら `find_index`。

```ruby
xs = Array[3, 1, 4, 1]
p(Array.index(xs, 1))          # => 1
p(Array.rindex(xs, 1))         # => 3
p(Array.index(xs, 9))          # => nil
```

```ruby error
i = Array.index(Array[1, 2], 2)
p(i + 1)                       # !> the operands may be nil
```

## find_index

`Array.find_index(x) { }`

ブロックが真を返す最初の要素の位置（Integer）。無ければ nil（レベル 2 の `nil` の問題）。

```ruby
p(Array.find_index(Array[3, 1, 4]) { |x| x > 3 })   # => 2
p(Array.find_index(Array[3, 1, 4]) { |x| x > 9 })   # => nil
```

## find, detect

`Array.find(x) { }`

`Array.detect(x) { }`

ブロックが真を返す最初の要素。無ければ nil で、レベル 2 の `nil` の問題です（空の Array でも nil です。要素が無いことと見つからないことを区別しません）。

```ruby
xs = Array[3, 1, 4]
p(Array.find(xs) { |x| x > 3 })        # => 4
p(Array.detect(xs) { |x| x > 30 })     # => nil
```

```ruby error
y = Array.find(Array[3, 1, 4]) { |x| x > 1 }
p(y + 1)                       # !> the operands may be nil
```

## rfind

`Array.rfind(x) { }`

ブロックが真を返す最後の要素。無ければ nil（レベル 2 の `nil` の問題）。Ruby 4.0 の `Array#rfind` に対応し、それより前の Ruby の上では使えません。

```ruby
p(Array.rfind(Array[3, 1, 4, 1, 5]) { |x| x < 4 })    # => 1
```

## bsearch, bsearch_index

`Array.bsearch(x) { }`

`Array.bsearch_index(x) { }`

ソート済みの Array を二分探索し、要素（`bsearch`）またはその位置（`bsearch_index`）を返します。Ruby と同じ 2 つのモードがあります: ブロックが true/false を返すなら true になる最初の要素（find-minimum）、Integer（`<=>` の結果）を返すなら 0 になる要素（find-any）。見つからなければ nil（レベル 2 の `nil` の問題）。ソートされていない Array では結果は定まりません。

```ruby
xs = Array[1, 3, 5, 7]
p(Array.bsearch(xs) { |x| x >= 4 })        # => 5
p(Array.bsearch_index(xs) { |x| x >= 4 })  # => 2
p(Array.bsearch(xs) { |x| 3 <=> x })       # => 3
p(Array.bsearch(xs) { |x| x >= 40 })       # => nil
```

## assoc, rassoc

`Array.assoc(x, Any)`

`Array.rassoc(x, Any)`

要素が Tuple や Array の並び（組の表）から、1 番目の項目が `k` に等しい（`assoc`）、2 番目の項目が `v` に等しい（`rassoc`）最初の要素を返します。無ければ nil（レベル 2 の `nil` の問題）。Ruby の `assoc` は Array の要素だけを見ますが、Sake の組は普通 Tuple なので Tuple も見ます。

```ruby
pairs = Array[[1, "a"], [2, "b"]]
p(Array.assoc(pairs, 2))       # => [2, "b"]
p(Array.rassoc(pairs, "a"))    # => [1, "a"]
p(Array.assoc(pairs, 9))       # => nil
```

## count

`Array.count(x, [Any]) [{ }]`

`count(a)` は要素の個数、`count(a, v)` は `v` と `==` で等しい要素の個数、`count(a) { |x| ... }` はブロックが真を返す要素の個数（Integer）。

```ruby
xs = Array[3, 1, 4, 1]
p(Array.count(xs))                     # => 4
p(Array.count(xs, 1))                  # => 2
p(Array.count(xs) { |x| x > 1 })       # => 2
```

## any?, all?, none?, one?

`Array.any?(x) { }`

`Array.all?(x) { }`

`Array.none?(x) { }`

`Array.one?(x) { }`

ブロックが真を返す要素が、1 つ以上ある（`any?`）、すべてである（`all?`）、1 つも無い（`none?`）、ちょうど 1 つである（`one?`）とき true。ブロックは必須です（Ruby のブロック無しの形やパターン引数はありません）。空の Array では `all?` と `none?` が true、`any?` と `one?` が false です。

```ruby
xs = Array[3, 1, 4]
p(Array.any?(xs) { |x| x > 3 })        # => true
p(Array.all?(xs) { |x| x > 0 })        # => true
p(Array.none?(xs) { |x| x > 4 })       # => true
p(Array.one?(xs) { |x| x > 3 })        # => true
p(Array.all?(Array[]) { |x| x > 0 })   # => true
```

```ruby error
Array.any?(Array[1])           # !> Array.any? requires a block
```

## sum

`Array.sum(x, [Any]) [{ }]`

要素の和。ブロックがあれば各要素をブロックの値に写してから足します。`init`（既定 0）から足し始め、空の Array では `init` そのものが結果です。要素と `init` は数（Integer、Float、Rational、Complex）か、`Arithmetic` を include して `+` を定義したクラスの値でなければならず、それ以外は静的に `type` の問題、実行時は `TypeError`（String の連結には `join` を使います）。Float の和が欲しいときは `sum(a, 0.0)` と書くと、空でも Float になります。

```ruby
p(Array.sum(Array[1, 2, 3]))                       # => 6
p(Array.sum(Array[]))                              # => 0
p(Array.sum(Array[], 0.0))                         # => 0.0
p(Array.sum(Array[1, 2.5]))                        # => 3.5
p(Array.sum(Array[1, 2], 10))                      # => 13
p(Array.sum(Array["a", "bb"]) { |s| String.size(s) })  # => 3
```

```ruby error
Array.sum(Array["a", "b"])     # !> Array.sum: an element must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Array.reduce(x, Any) { }`

`Array.inject(x, Any) { }`

`init` から始めて、累積値と各要素をブロックに渡し（この順）、その値を次の累積値にして、最後の累積値を返します。Ruby と違い `init` は必須です（省くと引数の個数の静的エラー）。空の Array では `init` が結果です。Ruby の Symbol を渡す形（`inject(:+)`）はありません。結果の型は `init` の型とブロックの結果の型の和です。

```ruby
p(Array.reduce(Array[1, 2, 3], 0) { |acc, x| acc + x })     # => 6
p(Array.inject(Array[1, 2, 3], 1) { |acc, x| acc * x })     # => 6
p(Array.reduce(Array[], 0) { |acc, x| acc + x })            # => 0
p(Array.reduce(Array["a", "b"], "") { |acc, x| acc + x })   # => "ab"
```

```ruby error
Array.reduce(Array[1, 2]) { |acc, x| acc + x }    # !> wrong number of arguments for Array.reduce (given 1, expected 2)
```

## min, max

`Array.min(x)`

`Array.max(x)`

最小・最大の要素。空の Array では nil（「外した nil」。レベル 3 だけが報告します）。要素は互いに比べられなければなりません: 比べられない型の組（Integer と String など）が要素型にあれば静的に `type` の問題（`elements compared in order may be (Integer, String), which cannot be compared`）、要素が nil になり得れば `nil` の問題です。検査器に見えない比較の失敗（`Float.NAN` など）は実行時に `ArgumentError`。Integer と Float は混ぜて比べられます。クラスのインスタンスはその型の `<=>`（`include Comparable`）で比べます。Ruby の `min(n)` やブロック形はありません。

```ruby
xs = Array[3, 1, 4, 1, 5]
p(Array.min(xs))               # => 1
p(Array.max(xs))               # => 5
p(Array.max(Array[2, 1.5]))    # => 2
p(Array.min(Array[]))          # => nil
```

```ruby error
Array.min(Array[1, "a"])       # !> Array.min: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
Array.max(Array[1.0, Float.NAN])   # !> ArgumentError: Array.max: cannot compare elements of types Float
```

## minmax

`Array.minmax(x)`

最小と最大の 2 要素 Tuple `[min, max]`。空の Array では `[nil, nil]` で、各位置の型は要素型と nil の和です（`min`、`max` と同じ「外した nil」で、レベル 3 だけが報告します）。比較の規則は `min`、`max` と同じで、比べられない型の組は静的に `type` の問題、実行時の失敗は `ArgumentError`。

```ruby
p(Array.minmax(Array[3, 1, 4]))    # => [1, 4]
p(Array.minmax(Array[]))           # => [nil, nil]
lo, hi = Array.minmax(Array[3, 1, 4])
p(lo + hi)                         # => 5
```

## min_by, max_by

`Array.min_by(x) { }`

`Array.max_by(x) { }`

ブロックの値が最小・最大になる要素。空の Array では nil（「外した nil」。`min`、`max` と同じくレベル 3 だけが報告します）。ブロックの値どうしが比べられなければならず、比べられない型の組は静的に `type` の問題、検査器に見えない失敗は実行時に `ArgumentError`。

```ruby
ws = Array["bb", "a", "ccc"]
p(Array.min_by(ws) { |s| String.size(s) })     # => "a"
p(Array.max_by(ws) { |s| String.size(s) })     # => "ccc"
p(Array.min_by(Array[]) { |s| s })             # => nil
```

```ruby error
Array.min_by(Array[1, "a"]) { |x| x }  # !> Array.min_by: elements compared in order may be (Integer, String), which cannot be compared
```

## minmax_by

`Array.minmax_by(x) { }`

ブロックの値が最小になる要素と最大になる要素の 2 要素 Tuple。空の Array では `[nil, nil]`（各位置は「外した nil」で、レベル 3 だけが報告します）。比較の規則は `min_by`、`max_by` と同じです。

```ruby
lo, hi = Array.minmax_by(Array["bb", "a", "ccc"]) { |s| String.size(s) }
p([lo, hi])                    # => ["a", "ccc"]
```

## tally

`Array.tally(x)`

各要素をキー、その出現回数（Integer）を値とする Hash を返します（最初に現れた順）。要素は Hash のキーになれる値でなければなりません（`TypeError`）。

```ruby
p(Array.tally(Array["a", "b", "a"]))   # => {"a" => 2, "b" => 1}
```

## sort, sort!

`Array.sort(x)`

`Array.sort!(x)`

要素を昇順に並べた新しい Array（`sort`）、または主語をその場で並べ替えて返します（`sort!`）。Ruby の比較ブロックは取れず（静的エラー）、別の順で並べるには `sort_by` を使います。要素は互いに比べられなければなりません: 比べられない型の組が要素型にあれば静的に `type` の問題、要素が nil になり得れば `nil` の問題（nil を除くには `compact`）。検査器に見えない比較の失敗（`Float.NAN` など）は実行時に `ArgumentError`。Integer と Float は混ぜて比べられ、Tuple は要素ごとに、クラスのインスタンスはその型の `<=>` で比べます。

```ruby
xs = Array[3, 1, 2]
p(Array.sort(xs))              # => [1, 2, 3]
p(xs)                          # => [3, 1, 2]
p(Array.sort!(xs))             # => [1, 2, 3]
p(xs)                          # => [1, 2, 3]
p(Array.sort(Array[[2, "a"], [1, "b"]]))   # => [[1, "b"], [2, "a"]]
```

```ruby error
Array.sort(Array[1, 2]) { |a, b| b <=> a }     # !> Array.sort does not take a block
```

```ruby error
Array.sort(Array[1, "a"])      # !> Array.sort: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
Array.sort(Array[1, nil])      # !> Array.sort: argument elements may be nil
```

```ruby error
Array.sort(Array[1.0, Float.NAN])  # !> ArgumentError: Array.sort: cannot compare elements of types Float
```

## sort_by, sort_by!

`Array.sort_by(x) { }`

`Array.sort_by!(x) { }`

ブロックの値（キー）の昇順に並べた新しい Array（`sort_by`）、または主語をその場で並べ替えて返します（`sort_by!`）。キーどうしが比べられなければならず、比べられない型の組は静的に `type` の問題、nil になり得るキーは `nil` の問題、検査器に見えない失敗は実行時に `ArgumentError`。降順は負のキーで、複数のキーは Tuple `[k1, k2]` で表します（Tuple は辞書順）。

```ruby
ws = Array["bb", "a", "ccc"]
p(Array.sort_by(ws) { |s| -String.size(s) })           # => ["ccc", "bb", "a"]
p(Array.sort_by(Array["bb", "a", "c"]) { |s| [String.size(s), s] })   # => ["a", "c", "bb"]
xs = Array[3, 1, 2]
p(Array.sort_by!(xs) { |x| -x })                       # => [3, 2, 1]
p(xs)                                                  # => [3, 2, 1]
```

## reverse, reverse!

`Array.reverse(x)`

`Array.reverse!(x)`

要素を逆順にした新しい Array（`reverse`）、または主語をその場で逆順にして返します（`reverse!`）。

```ruby
xs = Array[1, 2, 3]
p(Array.reverse(xs))           # => [3, 2, 1]
p(xs)                          # => [1, 2, 3]
p(Array.reverse!(xs))          # => [3, 2, 1]
p(xs)                          # => [3, 2, 1]
```

## rotate, rotate!

`Array.rotate(x, [Integer])`

`Array.rotate!(x, [Integer])`

先頭の n 個（既定 1）を末尾に回した新しい Array（`rotate`）、または主語をその場で回して返します（`rotate!`）。負の n は逆方向に回します。

```ruby
xs = Array[1, 2, 3]
p(Array.rotate(xs))            # => [2, 3, 1]
p(Array.rotate(xs, 2))         # => [3, 1, 2]
p(Array.rotate(xs, -1))        # => [3, 1, 2]
p(Array.rotate!(xs))           # => [2, 3, 1]
p(xs)                          # => [2, 3, 1]
```

## shuffle, shuffle!

`Array.shuffle(x)`

`Array.shuffle!(x)`

要素を無作為に並べ替えた新しい Array（`shuffle`）、または主語をその場で並べ替えて返します（`shuffle!`）。

```ruby
xs = Array[1, 2, 3]
p(Array.size(Array.shuffle(xs)))       # => 3
p(Array.sort(Array.shuffle!(xs)))      # => [1, 2, 3]
```

## sample

`Array.sample(x)`

無作為に選んだ 1 要素。空の Array では nil（「外した nil」。レベル 3 だけが報告します）。Ruby の `sample(n)` はありません。

```ruby
p(Array.sample(Array[7]))      # => 7
p(Array.sample(Array[]))       # => nil
```

## uniq, uniq!

`Array.uniq(x)`

`Array.uniq!(x)`

重複する要素（`==` で等しいもの。最初のものを残す）を除いた新しい Array（`uniq`）、または主語からその場で除いて返します（`uniq!`）。`uniq!` は 1 つも除かなかったとき nil を返し（Ruby と同じ）、その結果を未検査で使うのはレベル 2 の `nil` の問題です。Ruby のブロック形はありません。

```ruby
p(Array.uniq(Array[1, 2, 1, 3, 2]))    # => [1, 2, 3]
xs = Array[1, 1]
p(Array.uniq!(xs))                     # => [1]
p(Array.uniq!(xs))                     # => nil
```

```ruby error
p(Array.size(Array.uniq!(Array[1, 1])))    # !> Array.size: argument 1 may be nil
```

## compact, compact!

`Array.compact(x)`

`Array.compact!(x)`

nil の要素を除いた新しい Array（`compact`。要素型から nil が除かれます）、または主語からその場で除いて返します（`compact!`）。`compact!` は nil が 1 つも無かったとき nil を返し、その結果を未検査で使うのはレベル 2 の `nil` の問題です。

```ruby
p(Array.compact(Array[1, nil, 2]))     # => [1, 2]
xs = Array[1, nil]
p(Array.compact!(xs))                  # => [1]
p(Array.compact!(xs))                  # => nil
```

## flatten, flatten!

`Array.flatten(x)`

`Array.flatten!(x)`

入れ子の Array をすべて展開して平らにした新しい Array（`flatten`）、または主語をその場で平らにして返します（`flatten!`）。Ruby と同じく要素の Tuple も展開します（`String.scan` のグループの組を平らにするなど。2026-10-11 から）。`flatten!` は入れ子が無かったとき nil を返し、その結果を未検査で使うのはレベル 2 の `nil` の問題です。Ruby の深さ引数はありません。

```ruby
p(Array.flatten(Array[1, Array[2, Array[3]], 4]))     # => [1, 2, 3, 4]
p(Array.flatten(Array[[1, 2], 3]))                    # => [1, 2, 3]
xs = Array[1, Array[2]]
p(Array.flatten!(xs))                                 # => [1, 2]
p(Array.flatten!(xs))                                 # => nil
```

## zip

`Array.zip(x, *Array)`

主語の各要素と、他の Array の同じ位置の要素を組にした Tuple を並べた新しい Array。長さは主語の長さで、他の Array が短ければ nil で埋まり（その位置の型は要素型と nil の和）、長ければ余りは捨てます。Ruby と違い組は Array ではなく Tuple です。

```ruby
p(Array.zip(Array[1, 2, 3], Array["a", "b"]))              # => [[1, "a"], [2, "b"], [3, nil]]
p(Array.zip(Array[1, 2], Array["a", "b"], Array[:x, :y]))  # => [[1, "a", :x], [2, "b", :y]]
```

## product

`Array.product(x, Array)`

主語の要素と他の Array の要素のすべての組み合わせ `[a, b]`（Tuple）を並べた新しい Array。Ruby と違い、他の Array は 1 つだけで、組は Tuple です。

```ruby
p(Array.product(Array[1, 2], Array["a", "b"]))    # => [[1, "a"], [1, "b"], [2, "a"], [2, "b"]]
p(Array.product(Array[1], Array[]))               # => []
```

## transpose

`Array.transpose(x)`

Array の Array を行列と見て、行と列を入れ替えた新しい Array を返します。行は Array でも Tuple でもよく（`zip` の結果のような Tuple の並びも転置できます）、結果の行は Array です。行はすべて同じ長さでなければならず、長さが違えば `IndexError`。Array でも Tuple でもない要素は `TypeError`。

```ruby
p(Array.transpose(Array[Array[1, 2], Array[3, 4]]))   # => [[1, 3], [2, 4]]
p(Array.transpose(Array.zip(Array[1, 2], Array["a", "b"])))   # => [[1, 2], ["a", "b"]]
```

```ruby error
Array.transpose(Array[Array[1, 2], Array[3]])  # !> IndexError: Array.transpose: element size differs (1 should be 2)
```

## combination, repeated_combination

`Array.combination(x, Integer)`

`Array.repeated_combination(x, Integer)`

要素から n 個を選ぶ組み合わせ（`combination`。同じ要素は 1 度まで）、または重複を許す組み合わせ（`repeated_combination`）を Array で並べた新しい Array を返します（Ruby の Enumerator ではなく Array）。n が長さを越えると `combination` は `[]`。

```ruby
p(Array.combination(Array[1, 2, 3], 2))           # => [[1, 2], [1, 3], [2, 3]]
p(Array.repeated_combination(Array[1, 2], 2))     # => [[1, 1], [1, 2], [2, 2]]
p(Array.combination(Array[1, 2], 5))              # => []
```

## permutation, repeated_permutation

`Array.permutation(x, [Integer])`

`Array.repeated_permutation(x, Integer)`

要素から n 個を選んで並べる順列を Array で並べた新しい Array を返します。`permutation(a)` の n の既定は全要素です。`repeated_permutation` は同じ要素を繰り返して選べます（n は必須）。

```ruby
p(Array.permutation(Array[1, 2, 3], 2))   # => [[1, 2], [1, 3], [2, 1], [2, 3], [3, 1], [3, 2]]
p(Array.permutation(Array[1, 2]))         # => [[1, 2], [2, 1]]
p(Array.repeated_permutation(Array[1, 2], 2))     # => [[1, 1], [1, 2], [2, 1], [2, 2]]
```

## union, intersection, difference

`Array.union(x, *Array)`

`Array.intersection(x, *Array)`

`Array.difference(x, *Array)`

集合のように扱った結果の新しい Array を返します（順序は主語の順、`==` で比べます）。`union` は主語と他の Array すべての要素を重複を除いて並べ（要素型は全部の和）、`intersection` は他の Array すべてに含まれる要素だけを重複を除いて、`difference` は他の Array のどれにも含まれない要素を（重複はそのまま）残します。他の Array は何個でも（0 個でも）与えられます。

```ruby
a = Array[1, 2, 3]
b = Array[2, 3, 4]
p(Array.union(a, b))                   # => [1, 2, 3, 4]
p(Array.union(Array[1, 1]))            # => [1]
p(Array.intersection(a, b))            # => [2, 3]
p(Array.intersection(a, b, Array[3]))  # => [3]
p(Array.difference(a, b))              # => [1]
p(Array.difference(Array[1, 2, 2, 3], Array[2], Array[3]))    # => [1]
```

## intersect?

`Array.intersect?(x, Array)`

2 つの Array に共通する要素が 1 つでもあるとき true。

```ruby
p(Array.intersect?(Array[1, 2], Array[2, 3]))  # => true
p(Array.intersect?(Array[1, 2], Array[9]))     # => false
```

## join

`Array.join(x, [String])`

各要素を `to_s` で文字列にして、`sep`（既定 `""`）で区切ってつなげた String。`to_s` は `puts` と同じ規則で、nil は空、Array と Tuple は `inspect` の形、クラスのインスタンスはその型の `to_s` です（[値と型](../03-values.md)）。

```ruby
p(Array.join(Array[1, 2, 3], ", "))            # => "1, 2, 3"
p(Array.join(Array[1, "a", nil, :s, [1, 2]]))  # => "1as[1, 2]"
p(Array.join(Array[]))                         # => ""
```

## to_h

`Array.to_h(x)`

`[key, value]` の Tuple の並びから Hash を作ります。要素はすべて 2 要素の Tuple でなければならず（Array は不可）、他の値は `TypeError`。同じキーが複数あれば後のものが残ります。キーは Hash のキーになれる値でなければなりません。Ruby のブロック形はありません。

```ruby
p(Array.to_h(Array[[:a, 1], [:b, 2]]))     # => {a: 1, b: 2}
p(Array.to_h(Array[[1, "a"], [1, "b"]]))   # => {1 => "b"}
p(Array.to_h(Array[]))                     # => {}
```

```ruby error
Array.to_h(Array[1, 2])        # !> TypeError: Array.to_h: Array.to_h needs [key, value] Tuples, got Integer
```

## to_set

`Array.to_set(x)`

要素を集めた新しい Set（重複は 1 つに）。要素は Set の要素になれる値でなければなりません（`TypeError`）。

```ruby
p(Array.to_set(Array[1, 2, 1]))    # => Set[1, 2]
```

## pack

`Array.pack(x, String)`

Ruby の `Array#pack`。要素を書式 `fmt` に従ってバイト列（String）にします。不正な書式は `ArgumentError`、書式に合わない要素（`"C*"` に String など）は `TypeError`。逆は `String.unpack`。

```ruby
p(Array.pack(Array[65, 66], "C*"))     # => "AB"
p(Array.pack(Array[1, 2], "n*"))       # => "\x00\x01\x00\x02"
```

```ruby error
Array.pack(Array["a"], "C")    # !> TypeError: Array.pack: no implicit conversion of String into Integer
```

## +, -, *

`Array.+(x, Any)`

`Array.-(x, Any)`

`Array.*(x, Any)`

`a + b` は 2 つの Array をつなげた新しい Array（要素型は和。`concat` はその場で変更します）。`a - b` は `b` に含まれる要素（`==` で等しいもの）をすべて除いた新しい Array（`difference` と同じ）。`a * n` は `a` を n 回繰り返した新しい Array で、負の n は `ArgumentError`。右側は `+`、`-` では Array、`*` では Integer でなければならず、Tuple や String（Ruby の `a * ","` は `join`）は静的に `type` の問題です。

```ruby
a = Array[1, 2, 3]
b = Array[2, 3, 4]
p(a + b)                       # => [1, 2, 3, 2, 3, 4]
p(a - b)                       # => [1]
p(Array[1, 2, 2] - Array[2])   # => [1]
p(a * 2)                       # => [1, 2, 3, 1, 2, 3]
p(Array.+(a, Array[9]))        # => [1, 2, 3, 9]
p(Array.*(a, 0))               # => []
```

```ruby error
p(Array[1] + [2])              # !> which the left operand's type does not support
```

## ==, !=

`Array.==(x, Any)`

`Array.!=(x, Any)`

2 つの Array が同じ長さで、各位置の要素が `==` で等しいときに true（`!=` はその否定）。右側が Array 以外の値（Tuple や nil）なら等しくありません。`[1, 2]` は Tuple なので `Array[1, 2]` とは等しくありません。

```ruby
a = Array[1, 2, 3]
p(a == Array[1, 2, 3])         # => true
p(a != Array[1, 2])            # => true
p(a == [1, 2, 3])              # => false
p(a == nil)                    # => false
p(Array.==(a, a))              # => true
```

## <, <=, >, >=

`Array.<(x, Any)`

`Array.<=(x, Any)`

`Array.>(x, Any)`

`Array.>=(x, Any)`

2 つの Array を辞書順に比べます: 先頭から順に要素を比べ、最初に違った位置で決まり、すべて等しければ短い方が小さい。要素は互いに比べられる型でなければならず、比べられない組は静的に `type` の問題（`which cannot be compared`）、実行時は `ArgumentError`。右側は Array でなければなりません（Tuple は `type` の問題）。

```ruby
p(Array[1, 2] < Array[1, 3])           # => true
p(Array[1, 2] < Array[1, 2, 0])        # => true
p(Array[2] > Array[1, 9])              # => true
p(Array[1, 2] <= Array[1, 2])          # => true
p(Array.>=(Array[1], Array[1]))        # => true
```

```ruby error
p(Array[1, "a"] < Array[1, 2])         # !> which cannot be compared
```

## <=>

`Array.<=>(x, Any)`

辞書順の比較の結果を -1、0、1 で返します。比較の規則は `<` と同じです。比べられない組は静的に `type` の問題で、検査を通らずに実行すれば（`--strict=0`）nil になります（`<` などは `ArgumentError`）。

```ruby
a = Array[1, 2, 3]
p(a <=> Array[1, 2, 4])        # => -1
p(a <=> a)                     # => 0
p(Array.<=>(a, Array[1]))      # => 1
```
