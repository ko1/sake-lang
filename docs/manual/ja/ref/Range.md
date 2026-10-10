# Range

Range は 2 つの端と、終端を含むかどうかの印の組です: `1..5` は 5 を含み、`1...5` は含みません。端は Integer、Float、String、nil のいずれかです（[値と型](../03-values.md)）: `1..` は終端の無い Range、`..5` は始端の無い Range です。終端の無い Range を行末に書くときは `r = (3..)` と括弧で囲みます。Ruby と同じく、`3..` の直後の改行は次の行へ続いてしまうからです。型の違う端の組（`1.."a"`）は実行時に `ArgumentError`。Range は値であり、変更する操作はありません。すべての結果は新しい値です。

検査器は端の型を Range とともに持ち（`Range[Integer]`）、その型でどの操作が使えるかが決まります:

- **値を順に辿る操作**（`each`、`map`、`to_a`、`select`、`find`、`count` など）には Integer か String で始まる Range が要ります。`"a".."e"` は Ruby の `String#succ` で進みます。それ以外の型の Range（`1.0..2.0` など）は静的に `type` の問題（`the Range's first value must be Integer|String, but is Float`）、実行時は `TypeError` です。
- `step`、`sum`、`size` は Integer で始まる Range だけを取ります。String の Range は `type` の問題です。
- Range 全体を使う操作（`to_a`、`map`、`sum`、`last`、`min`、`max` など）には**有限**の Range が要ります。終端の無い Range には `RangeError`（`cannot do this on an endless Range 1..`）を投げます。途中で止まれる操作（`each`、`find`、`take`、`first(r, n)`、`each_slice`、`bsearch`）は終端の無い Range も受け取り、`each` は `break` するまで走ります。
- `include?`、`cover?`、`member?`、`overlap?`、`begin`、`end`、`exclude_end?` は端だけを見るので、Float や終端の無いものも含めてどんな Range でも使えます。
- 始端が終端より大きい Range（`5..1`）には値がありません: 辿っても何も起きず、`to_a` は `[]`、`min` は nil です。`first`、`last`、`begin`、`end` は端をそのまま返します。

Range に使える演算子は `==` と `!=` です（2 つの Range は端と `exclude_end?` が同じなら等しい）。Range での添字（`a[1..3]`、`s[0...2]`）は Array と String の操作です（[演算子と添字](../05-operators.md)）。Range は Hash のキーや Set の要素にはできません（`TypeError`）。nil になりうる結果（`first`、`last`、`min`、`max`、`begin`、`end`、`find`、`find_index`、`bsearch`、`min_by`、`max_by`、`minmax` の要素）の型は `T | nil` で、未検査のまま使うと `--strict`（レベル 2）が報告します。レベル 3 の「外れの nil」に当たるものはありません。

操作の多くは Ruby の Enumerable のメソッドです。Ruby と違い、署名に `{ }` のある操作のブロックは**必須**（例外は `count` と `sum` で、ブロックは省略可能）、`reduce` と `inject` には初期値が要り、`each` や `map` などのブロックはちょうど 1 つの引数を取ります（`each_with_index`、`each_with_object`、`chunk_while`、`slice_when` は 2 つ）。引数の数が違うブロックは実行時に `ArgumentError` です。

## begin, end

`Range.begin(x)`

`Range.end(x)`

書かれたままの 2 つの端です（Ruby の `r.begin`、`r.end`）。`end` は除外される終端でも書かれた値を返します（`Range.end(1...5)` は 5、`Range.max(1...5)` は 4）。結果の型は `T | nil` です: 終端の無い Range の `end` と始端の無い Range の `begin` は nil なので、算術に使う前の検査を `--strict` が求めます。

```ruby
p(Range.begin(1..5))         # => 1
p(Range.end(1...5))          # => 5
p(Range.end(1..))            # => nil
p(Range.begin("a".."z"))     # => "a"
```

```ruby error
x = Range.begin(1..5)
p(x + 1)                     # !> the operands may be nil
```

## exclude_end?

`Range.exclude_end?(x)`

3 つの点で書いた Range（`1...5`）なら true、2 つ（`1..5`、`1..`）なら false。

```ruby
p(Range.exclude_end?(1..5))      # => false
p(Range.exclude_end?(1...5))     # => true
p(Range.exclude_end?(1..))       # => false
```

## ==, !=

`Range.==(x, Any)`

`Range.!=(x, Any)`

両端が `==` で等しく、`exclude_end?` も一致するときに 2 つの Range は等しい（`!=` はその否定）。`1..5` と `1...5` は違います。演算子では、右側が Range 以外なら等しくありません（`(1..5) == 5` は false）。関数形 `Range.==(r, x)` は右側が Range の行しか持たず、別の型は実行時に `TypeError`（`no implementation for (Range, Integer)`）です。

```ruby
p((1..5) == (1..5))          # => true
p((1..5) == (1...5))         # => false
p((1..5) != (1...6))         # => true
p((1..5) == 5)               # => false
p(Range.==(1..5, 1..5))      # => true
```

```ruby error
p(Range.==(1..5, 5))         # !> TypeError: Range.==: no implementation for (Range, Integer)
```

## include?, cover?, member?

`Range.include?(x, Any)`

`Range.cover?(x, Any)`

`Range.member?(x, Any)`

値が両端の間にあれば true（`begin <= v <= end`、`...` なら `< end`）。3 つとも Ruby の `cover?` です: 端と比べるだけで Range を辿らないので、終端の無い Range、始端の無い Range、Float の Range でも使え、Integer の Range に Float も見つかります。String の Range を辿る Ruby の `include?` とは違い、ここでは `("a".."z")` に `"mm"` が含まれます（`"a" <= "mm" <= "z"` だから）。端と型の違う値（`1..5` に `"a"`、nil）は false。値に Range を渡すと、Ruby の `cover?` と同じく全体が内側にあるかを答えます。

```ruby
p(Range.include?(1..5, 5))       # => true
p(Range.include?(1...5, 5))      # => false
p(Range.cover?(1..5, 2.5))       # => true
p(Range.member?(1..5, 0))        # => false
p(Range.include?(1.., 100))      # => true
p(Range.cover?("a".."z", "mm"))  # => true
p(Range.include?(1..5, "a"))     # => false
p(Range.cover?(1..5, 2..3))      # => true
```

## overlap?

`Range.overlap?(x, Range)`

2 つの Range が少なくとも 1 つの値を共有するとき true（Ruby の `overlap?`）。除外された終端は数えません（`1...5` と `5..8` は重なりません）。端の型は何でもよく、型の違う Range 同士は重なりません。

```ruby
p(Range.overlap?(1..5, 3..8))        # => true
p(Range.overlap?(1..5, 6..8))        # => false
p(Range.overlap?(1...5, 5..8))       # => false
p(Range.overlap?(1.., 100..200))     # => true
p(Range.overlap?(1.0..2.0, 1.5..3.0))  # => true
```

## size

`Range.size(x)`

Range に含まれる Integer の個数（Integer）。Integer の Range だけに使えます: String の Range は `type` の問題（`the Range's first value must be Integer, but is String`）、Float になりうる Range（`1..2.5`）も同様です。終端の無い Range は `RangeError`。始端が終端より大きい Range の size は 0 です。String の Range には `count` を使います。

```ruby
p(Range.size(1..5))      # => 5
p(Range.size(1...5))     # => 4
p(Range.size(5..1))      # => 0
```

```ruby error
p(Range.size(1..))       # !> RangeError: Range.size: cannot do this on an endless Range 1..
```

## count

`Range.count(x) [{ }]`

ブロック無しなら Range を辿って数えた値の個数（Integer）、ブロック付きならブロックが真を返した値の個数。Integer と String の Range に使えます。有限の Range が要ります（`RangeError`）。Ruby の `count(v)` と違って値を渡す形は無く、`include?` を使います。

```ruby
p(Range.count("a".."c"))                        # => 3
p(Range.count(1..5) { |i| Integer.odd?(i) })    # => 3
```

## each

`Range.each(x) { }`

各値を順にブロックへ渡し、Range を返します。Integer の Range は 1 ずつ、String の Range は `String#succ` で進みます（`"az".."bc"` は `"az"`、`"ba"`、`"bb"`、`"bc"`）。終端の無い Range は `break` するまで走り、`break v` なら `v` が結果です。ブロックの引数は 1 つ。Float の Range は `type` の問題です。

```ruby
r = Range.each(1..3) { |i| puts(i) }     # => 1
                                         # => 2
                                         # => 3
p(r)                                     # => 1..3
Range.each("a".."c") { |s| print(s) }    # => abc
puts("")
x = Range.each(1..) { |i| break i * 10 if i > 2 }
p(x)                                     # => 30
```

```ruby error
Range.each(1.0..2.0) { |f| p(f) }        # !> the Range's first value must be Integer|String, but is Float
```

## each_with_index

`Range.each_with_index(x) { }`

各値とその位置（0, 1, 2, ...）をブロックへ渡し、Range を返します。ブロックの引数は 2 つ。終端の無い Range には `break` が要ります。

```ruby
r = Range.each_with_index("a".."c") { |s, i| p([s, i]) }   # => ["a", 0]
                                                            # => ["b", 1]
                                                            # => ["c", 2]
p(r)                                                        # => "a".."c"
```

## each_entry

`Range.each_entry(x) { }`

`each` と同じです: Ruby の `Enumerable#each_entry` で、それに合わせて書かれたプログラムのために残してあります。Range を返します。

```ruby
p(Range.each_entry(1..3) { |i| puts(i) })    # => 1
                                             # => 2
                                             # => 3
                                             # => 1..3
```

## reverse_each

`Range.reverse_each(x) { }`

各値を終端から始端へ向かってブロックへ渡し、Range を返します。有限の Range が要ります（`RangeError`）。

```ruby
p(Range.reverse_each(1..3) { |i| puts(i) })  # => 3
                                             # => 2
                                             # => 1
                                             # => 1..3
```

## step

`Range.step(x, Integer) { }`

始端、始端 + 刻み、... と Range の中にある間ブロックへ渡し、Range を返します。Integer の Range だけに使えます（String や Float の Range は `type`）。終端の無い Range には `break` が要ります。負の刻みは下る Range を辿り（`10..1` に -3 で 10, 7, 4, 1）、上る Range では何も渡しません。刻み 0 は Ruby の `ArgumentError`（`step can't be 0`）で失敗します。

```ruby
p(Range.step(1..10, 3) { |i| puts(i) })    # => 1
                                           # => 4
                                           # => 7
                                           # => 10
                                           # => 1..10
Range.step(1...9, 4) { |i| p(i) }          # => 1
                                           # => 5
```

```ruby error
Range.step("a".."z", 2) { |s| p(s) }       # !> the Range's first value must be Integer, but is String
```

## each_slice

`Range.each_slice(x, Integer) { }`

値を n 個ずつの Array にしてブロックへ渡し（最後は足りなければ短い）、Range を返します。終端の無い Range には `break` が要ります。0 以下の大きさは `ArgumentError`。

```ruby
p(Range.each_slice(1..7, 3) { |a| p(a) })    # => [1, 2, 3]
                                             # => [4, 5, 6]
                                             # => [7]
                                             # => 1..7
```

## each_cons

`Range.each_cons(x, Integer) { }`

連続する n 個の値の窓を Array としてブロックへ渡し、Range を返します。値が n 個に足りなければブロックは呼ばれません。0 以下の大きさは `ArgumentError`。

```ruby
p(Range.each_cons(1..4, 2) { |a| p(a) })     # => [1, 2]
                                             # => [2, 3]
                                             # => [3, 4]
                                             # => 1..4
```

## each_with_object

`Range.each_with_object(x, Any) { }`

各値と渡したオブジェクトをブロックへ渡し、そのオブジェクトを返します。容器を埋めるのに使います。Ruby と同じく、ブロックが新しい値を返してもオブジェクトは変わりません（`Range.each_with_object(1..3, 0) { |i, acc| acc + i }` は 0 を返す。`reduce` を使う）。終端の無い Range には `break` が要ります。

```ruby
a = Range.each_with_object(1..3, Array[]) { |i, acc| Array.push(acc, i * i) }
p(a)                                         # => [1, 4, 9]
```

## cycle

`Range.cycle(x, Integer) { }`

Range を n 回繰り返して辿り、nil を返します。n が 0 以下なら何もしません。有限の Range が要ります（`RangeError`）。引数無しの Ruby の `cycle` と違い、回数は必須です。

```ruby
p(Range.cycle(1..2, 2) { |i| puts(i) })      # => 1
                                             # => 2
                                             # => 1
                                             # => 2
                                             # => nil
```

## to_a, entries

`Range.to_a(x)`

`Range.entries(x)`

すべての値を持つ新しい Array。Integer か String の Range（それ以外は `type`）で、有限なもの（`RangeError`）が要ります。Array の要素の型は端の型です。

```ruby
p(Range.to_a(1..5))          # => [1, 2, 3, 4, 5]
p(Range.to_a(1...5))         # => [1, 2, 3, 4]
p(Range.entries("a".."e"))   # => ["a", "b", "c", "d", "e"]
p(Range.to_a(5..1))          # => []
```

```ruby error
p(Range.to_a(1..))           # !> RangeError: Range.to_a: cannot do this on an endless Range 1..
```

## first

`Range.first(x, [Integer])`

個数無しなら Range の始端を、中身にかかわらず返します（`Range.first(5..1)` は 5、`Range.first(1...1)` は 1、`Range.first(1.0..2.0)` は 1.0）。型は `T | nil` で、算術の前の検査を `--strict` が求めます。nil になるのは始端の無い Range の場合ですが、それは Ruby の `RangeError` で失敗します。個数 n 付きなら先頭 n 個の値の新しい Array（Range が短ければそれだけ）。Range を辿るので Integer か String の Range が要ります。終端の無い Range でも使えます。負の個数は `RangeError`。

```ruby
p(Range.first(1..5))         # => 1
p(Range.first(1..5, 2))      # => [1, 2]
p(Range.first(1..5, 10))     # => [1, 2, 3, 4, 5]
p(Range.first(1.., 3))       # => [1, 2, 3]
p(Range.first("a".."c", 2))  # => ["a", "b"]
```

## last

`Range.last(x, [Integer])`

個数無しなら書かれた終端を `Range.end` と同じく返します（なので Ruby と同じく `Range.last(1...5)` は 5）。個数 n 付きなら末尾 n 個の値の新しい Array で、除外された終端は入りません（`Range.last(1...5, 2)` は `[3, 4]`）。有限の Range が要ります（終端の無い Range は個数無しでも `RangeError`）。個数無しの結果は `T | nil`。負の個数は `RangeError`。

```ruby
p(Range.last(1..5))          # => 5
p(Range.last(1...5))         # => 5
p(Range.last(1..5, 2))       # => [4, 5]
p(Range.last(1...5, 2))      # => [3, 4]
p(Range.last("a".."c"))      # => "c"
```

```ruby error
p(Range.last(1..))           # !> RangeError: Range.last: cannot do this on an endless Range 1..
```

## take

`Range.take(x, Integer)`

先頭 n 個の値の新しい Array（足りなければ全部）。`first(r, n)` と同じです。終端の無い Range でも使えます。負の n は `ArgumentError`。

```ruby
p(Range.take(1..10, 3))      # => [1, 2, 3]
p(Range.take(1.., 3))        # => [1, 2, 3]
p(Range.take(1..3, 10))      # => [1, 2, 3]
```

## drop

`Range.drop(x, Integer)`

先頭 n 個を除いた残りの値の新しい Array（残りが無ければ空）。有限の Range が要ります（`RangeError`）。負の n は `ArgumentError`。

```ruby
p(Range.drop(1..5, 2))       # => [3, 4, 5]
p(Range.drop(1..5, 10))      # => []
```

## take_while

`Range.take_while(x) { }`

始端から、ブロックが初めて偽を返した値の直前までの新しい Array。ブロックがいずれ偽を返すなら、終端の無い Range でも使えます。

```ruby
p(Range.take_while(1..10) { |i| i < 4 })   # => [1, 2, 3]
p(Range.take_while(1..) { |i| i < 4 })     # => [1, 2, 3]
```

## drop_while

`Range.drop_while(x) { }`

ブロックが初めて偽を返した値から終端までの新しい Array。終端の無い Range は拒否されませんが、結果が終わらないので、この操作は戻ってきません。

```ruby
p(Range.drop_while(1..6) { |i| i < 4 })    # => [4, 5, 6]
```

## map, collect

`Range.map(x) { }`

`Range.collect(x) { }`

値ごとのブロックの結果を集めた新しい Array。有限の Integer か String の Range が要ります。Array の要素の型はブロックの結果の型です。

```ruby
n = 4
p(Range.map(1..n) { |i| i * i })                 # => [1, 4, 9, 16]
p(Range.collect("a".."c") { |s| String.upcase(s) })   # => ["A", "B", "C"]
```

```ruby error
p(Range.map(1..) { |i| i })                      # !> RangeError: Range.map: cannot do this on an endless Range 1..
```

## flat_map, collect_concat

`Range.flat_map(x) { }`

`Range.collect_concat(x) { }`

ブロックが返した Array を 1 段つなげた新しい Array。ブロックは Array を返さなければならず、他の値は `TypeError`（`the block must return an Array`）です。有限の Range が要ります。

```ruby
p(Range.flat_map(1..3) { |i| Array[i, i] })      # => [1, 1, 2, 2, 3, 3]
```

```ruby error
p(Range.flat_map(1..2) { |i| i })                # !> TypeError: Range.flat_map: the block must return an Array, got Integer
```

## select, filter, find_all

`Range.select(x) { }`

`Range.filter(x) { }`

`Range.find_all(x) { }`

ブロックが真を返した値の新しい Array。有限の Integer か String の Range が要ります。Array の要素の型は端の型です。

```ruby
p(Range.select(1..6) { |i| Integer.even?(i) })   # => [2, 4, 6]
p(Range.filter("a".."e") { |s| s > "c" })        # => ["d", "e"]
```

## reject

`Range.reject(x) { }`

ブロックが偽を返した値の新しい Array。`select` の補集合です。有限の Range が要ります。

```ruby
p(Range.reject(1..6) { |i| Integer.even?(i) })   # => [1, 3, 5]
```

## filter_map

`Range.filter_map(x) { }`

ブロックの結果のうち nil と false を除いた新しい Array（Ruby の `filter_map`）。検査器は要素の型から nil を外すので、この Array は nil 検査なしで使えます。有限の Range が要ります。

```ruby
p(Range.filter_map(1..6) { |i| Integer.even?(i) ? i * 10 : nil })   # => [20, 40, 60]
```

## partition

`Range.partition(x) { }`

2 つの Array の Tuple: ブロックが真を返した値たち、それから残り。有限の Range が要ります。

```ruby
evens, odds = Range.partition(1..6) { |i| Integer.even?(i) }
p(evens)                                         # => [2, 4, 6]
p(odds)                                          # => [1, 3, 5]
```

## group_by

`Range.group_by(x) { }`

ブロックの結果ごとに、その結果を与えた値の Array を対応づけた Hash（初出の順）。有限の Range が要ります。キーの型はブロックの結果の型、値の型は端の型の Array です（無いキーの `h[k]` は他の Hash と同じく nil）。

```ruby
h = Range.group_by(1..6) { |i| i % 3 }
p(h)                                             # => {1 => [1, 4], 2 => [2, 5], 0 => [3, 6]}
p(h[1])                                          # => [1, 4]
```

## chunk_while, slice_when

`Range.chunk_while(x) { }`

`Range.slice_when(x) { }`

値を連なりに切り分けた Array の Array。ブロックは隣り合う 2 つの値を受け取り、`chunk_while` はブロックが真の間同じ連なりに入れ、`slice_when` はブロックが真のところで新しい連なりを始めます。有限の Range が要ります。

```ruby
p(Range.chunk_while(1..5) { |a, b| b != 3 })         # => [[1, 2], [3, 4, 5]]
p(Range.slice_when(1..6) { |a, b| Integer.even?(b) })  # => [[1], [2, 3], [4, 5], [6]]
```

## slice_before, slice_after

`Range.slice_before(x) { }`

`Range.slice_after(x) { }`

ブロックが真を返した値の前（または後）で値を切り分けた Array の Array。有限の Range が要ります。

```ruby
p(Range.slice_before(1..6) { |i| Integer.even?(i) })  # => [[1], [2, 3], [4, 5], [6]]
p(Range.slice_after(1..6) { |i| Integer.even?(i) })   # => [[1, 2], [3, 4], [5, 6]]
```

## find, detect

`Range.find(x) { }`

`Range.detect(x) { }`

ブロックが初めて真を返した値。無ければ nil。結果は `T | nil` なので、使う前の検査を `--strict` が求めます。どれかの値がブロックを満たすなら終端の無い Range でも使えます。満たさなければ探索は終わりません。

```ruby
p(Range.find(1..10) { |i| i * i > 10 })      # => 4
p(Range.detect(1..10) { |i| i > 100 })       # => nil
p(Range.find(1..) { |i| i * i > 10 })        # => 4
s = Range.find("a".."e") { |c| c > "b" }
if s
  p(String.upcase(s))                        # => "C"
end
```

## find_index

`Range.find_index(x) { }`

ブロックが初めて真を返した値の位置（0, 1, 2, ...）。無ければ nil（`Integer | nil`）。Ruby の `find_index(v)` と違い、ブロックが必須で値を渡す形はありません。見つかるなら終端の無い Range でも使えます。

```ruby
p(Range.find_index(1..10) { |i| i * i > 10 })  # => 3
p(Range.find_index(1..10) { |i| i > 100 })     # => nil
```

## bsearch

`Range.bsearch(x) { }`

Integer の Range の二分探索（Ruby と同じ）: find-minimum モードでは、求める値とそれより上のすべての値でブロックが true を返すようにし、結果はそのような最小の値です。ブロックが一度も true にならなければ nil（`T | nil`）。終端の無い Range でも使えます。String の Range は実行時に `ArgumentError`（`can't do binary search for String`）。

```ruby
p(Range.bsearch(1..100) { |i| i * i >= 50 })   # => 8
p(Range.bsearch(1..100) { |i| i > 1000 })      # => nil
p(Range.bsearch(1..) { |i| i * i >= 50 })      # => 8
```

## all?, any?, none?, one?

`Range.all?(x) { }`

`Range.any?(x) { }`

`Range.none?(x) { }`

`Range.one?(x) { }`

ブロックがすべての値で真か、少なくとも 1 つで真か、どれでも偽か、ちょうど 1 つで真か。Ruby と違ってブロックは必須です（ブロック無しの `any?` やパターン引数はありません）。有限の Range が要ります（`RangeError`）。値の無い Range では `all?` と `none?` が true、`any?` と `one?` が false。

```ruby
p(Range.all?(1..5) { |i| i > 0 })    # => true
p(Range.any?(1..5) { |i| i > 4 })    # => true
p(Range.none?(1..5) { |i| i > 5 })   # => true
p(Range.one?(1..5) { |i| i == 3 })   # => true
p(Range.any?(5..1) { |i| true })     # => false
```

## reduce, inject

`Range.reduce(x, Any) { }`

`Range.inject(x, Any) { }`

値を畳み込みます: ブロックは累積値と次の値を受け取り、その結果が新しい累積値になります。結果は最後の累積値です。初期値は**必須**で（初期値無しの Ruby の `inject` は `wrong number of arguments` の問題）、結果の型は初期値の型とブロックの結果の型の和です。シンボル形（`reduce(:+)`）は無く、それには `sum` を使います。有限の Range が要ります。

```ruby
p(Range.reduce(1..5, 0) { |acc, i| acc + i })                   # => 15
p(Range.inject(1..5, 1) { |acc, i| acc * i })                   # => 120
p(Range.reduce(1..3, "") { |acc, i| acc + Integer.to_s(i) })    # => "123"
p(Range.reduce(5..1, 7) { |acc, i| acc + i })                   # => 7
```

```ruby error
p(Range.inject(1..5) { |acc, i| acc + i })   # !> wrong number of arguments for Range.inject (given 1, expected 2)
```

## sum

`Range.sum(x, [Integer|Float|Rational|Complex]) [{ }]`

値（ブロック付きならブロックの結果）の合計に初期値（省略時 0）を足したもの。Integer の Range だけ（String の Range は `type`）で、有限なもの（`RangeError`）が要ります。結果の型は初期値とブロックに従います: Integer の値に Integer の初期値なら Integer、Float の初期値なら Float。Ruby の `Range#sum` と同じく、Integer の Range に Rational の初期値を与えると Float になり（`Range.sum(1..3, 2r)` は 8.0）、Complex の初期値は失敗します。数でない結果を返すブロックは `type` の問題です。

```ruby
p(Range.sum(1..100))                 # => 5050
p(Range.sum(1..10, 100))             # => 155
p(Range.sum(1..3) { |i| i * 2 })     # => 12
p(Range.sum(1..3, 0.5))              # => 6.5
p(Range.sum(1..0))                   # => 0
```

```ruby error
p(Range.sum("a".."c"))               # !> the Range's first value must be Integer, but is String
```

## min, max

`Range.min(x)`

`Range.max(x)`

最小と最大の値。値の無い Range（`5..1`）では nil で、型は `T | nil` です。`max` は除外された終端を数えません（`Range.max(1...5)` は 4）。有限の Range が要ります（`RangeError`）。終端を含む Float の Range はどちらも受け取ります（`Range.max(1.0..2.5)` は 2.5。Ruby と同じ）。終端を除く Float の Range の `max` は Ruby の `TypeError`（`cannot exclude non Integer end value`）で失敗します。

```ruby
p(Range.min(1..5))           # => 1
p(Range.max(1...5))          # => 4
p(Range.max(5..1))           # => nil
p(Range.min("a".."c"))       # => "a"
p(Range.max(1.0..2.5))       # => 2.5
```

```ruby error
x = Range.min(1..5)
p(x + 1)                     # !> the operands may be nil
```

## minmax

`Range.minmax(x)`

Tuple `[min, max]`。値の無い Range では両方 nil です。`min`、`max` と違って Range を辿るので、Integer か String の Range（Float の Range は `type` の問題）で、有限なものが要ります。

```ruby
lo, hi = Range.minmax(1..5)
p([lo, hi])                  # => [1, 5]
p(Range.minmax(5..1))        # => [nil, nil]
```

## min_by, max_by

`Range.min_by(x) { }`

`Range.max_by(x) { }`

ブロックの結果が最小（最大）になる値。値の無い Range では nil（`T | nil`）。有限の Range が要ります。

```ruby
p(Range.min_by(1..5) { |i| -i })               # => 5
p(Range.max_by("a".."e") { |s| String.ord(s) })  # => "e"
p(Range.min_by(5..1) { |i| i })                # => nil
```

## minmax_by

`Range.minmax_by(x) { }`

ブロックの結果が最小になる値と最大になる値の Tuple。値の無い Range では `[nil, nil]`。有限の Range が要ります。

```ruby
p(Range.minmax_by(1..5) { |i| -i })    # => [5, 1]
```

## sort

`Range.sort(x)`

値を昇順に並べた新しい Array。Range では `to_a` と同じです。有限の Integer か String の Range が要ります。

```ruby
p(Range.sort(1..3))          # => [1, 2, 3]
p(Range.sort(3..1))          # => []
```

## sort_by

`Range.sort_by(x) { }`

ブロックの結果の順に値を並べた新しい Array。有限の Range が要ります。

```ruby
p(Range.sort_by(1..5) { |i| -i })                    # => [5, 4, 3, 2, 1]
p(Range.sort_by("a".."c") { |s| -String.ord(s) })    # => ["c", "b", "a"]
```

## uniq

`Range.uniq(x)`

重複を除いた値の新しい Array。Range に重複は無いので `to_a` と同じです。有限の Integer か String の Range が要ります。

```ruby
p(Range.uniq(1..3))          # => [1, 2, 3]
```

## compact

`Range.compact(x)`

nil を除いた値の新しい Array。Range に nil は無いので `to_a` と同じです。有限の Integer か String の Range が要ります。

```ruby
p(Range.compact(1..3))       # => [1, 2, 3]
```

## tally

`Range.tally(x)`

各値をその出現回数に対応づけた Hash。Range では常に 1 です。有限の Integer か String の Range が要ります。

```ruby
p(Range.tally("a".."c"))     # => {"a" => 1, "b" => 1, "c" => 1}
```

## to_set

`Range.to_set(x)`

値の新しい Set。有限の Integer か String の Range が要ります。

```ruby
p(Range.to_set(1..3))        # => Set[1, 2, 3]
```

## zip

`Range.zip(x, *Array)`

Tuple の新しい Array: i 番目の Tuple は Range の i 番目の値と、渡した各 Array の i 番目の要素を持ちます。短い Array のところは nil です（Tuple の型にそう出ます）。Array を渡さなければ各 Tuple は値 1 つです。有限の Integer か String の Range が要ります。

```ruby
p(Range.zip(1..3, Array["a", "b", "c"]))     # => [[1, "a"], [2, "b"], [3, "c"]]
p(Range.zip(1..3, Array[10, 20]))            # => [[1, 10], [2, 20], [3, nil]]
p(Range.zip(1..2))                           # => [[1], [2]]
```
