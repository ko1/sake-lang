# Set

Set は重複の無い要素の集まりです。`Set[1, 2]` が Set を作ります（Ruby の `Set.new([1, 2])` にあたる `Set.new` はありません。[値と型](../03-values.md)）。要素は Hash のキーと同じ規則で区別されます: Integer, Float, String, Symbol, true, false, nil, Time と、それらからなる Tuple, Record, Array, Hash, Set, Struct 値が要素になれ、Regexp, Range, 自分の等価（`==` か `Comparable`）を定義した Struct 型の値は実行時に `TypeError` です。同じ要素かどうかは Ruby の Hash と同じく `hash` と `eql?` で決まるので、`1` と `1.0` は別の要素です。要素は追加した順に並び、反復もその順です。要素に使った String は複製が入るので、後で元の String を変えても Set は変わりません。

検査器は Set の要素の型を構築した場所ごとに追い、`Set.add` などの書き込みで広げます。ブロックを取る操作のブロックは、その要素の型の値を受け取ります。

Set に使える演算子は `|`（和）、`&`（積）、`-`（差）、`==`、`!=` です。`^`、`+`、`<`、`<=` などは使えず、部分集合の判定は `Set.subset?` などで行います。下の `Set.|(x, y)` などは演算子を関数の形で呼ぶものです（[演算子と添字](../05-operators.md)）。要素を取り出す多くの操作（`select`、`map`、`sort`、`to_a` など）は Set ではなく **Array** を返します。Ruby の `Set#select` が Set を返すのとは違います。

## Set[]

`Set[*Any]`

要素を並べて Set を作ります。他の型の `T[...]` が「T の Array」を作るのとは違い、`Set[...]` は **Set そのもの**を作ります。重複した要素は 1 つになります。要素になれない値（Regexp, Range, 自分の等価を定義した Struct 値）は実行時に `TypeError`。`Set[]` は空の Set で、後から `Set.add` で要素を入れると要素の型がそれに広がります。

```ruby
s = Set[1, 2, 2, 3]
p(s)                          # => Set[1, 2, 3]
p(Set[])                      # => Set[]
p(Set.size(Set[1, 1.0]))      # => 2
```

```ruby error
p(Set[/a/])                   # !> TypeError: Set[]: Regexp cannot be a Hash key or Set element
```

## length, size

`Set.length(x)`

`Set.size(x)`

要素の個数（Integer）。

```ruby
p(Set.size(Set[1, 2, 3]))     # => 3
p(Set.length(Set[]))          # => 0
```

## empty?

`Set.empty?(x)`

要素が無いとき true。

```ruby
p(Set.empty?(Set[]))          # => true
p(Set.empty?(Set[1]))         # => false
```

## include?, member?

`Set.include?(x, Any)`

`Set.member?(x, Any)`

値が要素にあるとき true。要素の比較は Hash のキーと同じ（`hash` と `eql?`）なので、`1` の入った Set に `1.0` はありません。Set の要素の型と違う型の値を聞いても静的な問題にはならず、false です。

```ruby
s = Set[1, 2]
p(Set.include?(s, 1))         # => true
p(Set.include?(s, 1.0))       # => false
p(Set.member?(s, "a"))        # => false
p(Set.include?(Set[[1, 2]], [1, 2]))   # => true
```

## add

`Set.add(x, Any)`

値を要素に加え、Set 自身を返します（その場で変更）。すでにある値なら何も変わりません。要素になれない値は実行時に `TypeError`。加えた値の型は、その Set の要素の型に加わります。

```ruby
s = Set[1]
p(Set.add(s, 2))              # => Set[1, 2]
p(Set.add(s, 2))              # => Set[1, 2]
p(s)                          # => Set[1, 2]
```

```ruby error
Set.add(Set[1], 1..2)         # !> TypeError: Set.add: Range cannot be a Hash key or Set element
```

## add?

`Set.add?(x, Any)`

`add` と同じですが、その値がすでにあったときは **nil** を返します（新しく加えたときは Set 自身）。戻り値は Set か nil なので、`--strict`（レベル 2）は確かめずに使うと報告します。「初めて見た値か」の判定に使います。

```ruby
s = Set[1]
p(Set.add?(s, 2))             # => Set[1, 2]
p(Set.add?(s, 2))             # => nil
```

```ruby error
s = Set[1]
x = Set.add?(s, 2)
p(Set.size(x))                # !> argument 1 may be nil
```

## delete

`Set.delete(x, Any)`

値を要素から取り除き、Set 自身を返します（その場で変更）。無い値なら何も変わりません。Ruby と同じです。

```ruby
s = Set[1, 2, 3]
p(Set.delete(s, 2))           # => Set[1, 3]
p(Set.delete(s, 99))          # => Set[1, 3]
```

## delete?

`Set.delete?(x, Any)`

`delete` と同じですが、その値が無かったときは **nil** を返します（取り除いたときは Set 自身）。戻り値は `--strict`（レベル 2）で確かめずに使うと報告されます。

```ruby
s = Set[1, 2]
p(Set.delete?(s, 2))          # => Set[1]
p(Set.delete?(s, 2))          # => nil
```

## merge

`Set.merge(x, Set)`

もう一方の Set の要素をすべて加え、Set 自身を返します（その場で変更）。引数は Set でなければなりません（Array は静的に `type` の問題。Ruby の `merge` は任意の列挙を取ります）。新しい Set が欲しいときは `|` か `union` を使います。

```ruby
s = Set[1, 2]
p(Set.merge(s, Set[2, 3]))    # => Set[1, 2, 3]
p(s)                          # => Set[1, 2, 3]
```

```ruby error
Set.merge(Set[1], Array[2])   # !> argument 2 must be Set, but is Array
```

## subtract

`Set.subtract(x, Any)`

引数に含まれる要素をすべて取り除き、Set 自身を返します（その場で変更）。引数は Set、Array、Tuple、Range のいずれかです。検査器は調べず（署名は `Any`）、それ以外は実行時に `TypeError`（`argument 2 must be Set, Array, Tuple, or Range, got Integer`）。新しい Set が欲しいときは `-` か `difference` を使います。

```ruby
s = Set[1, 2, 3, 4, 5]
p(Set.subtract(s, Set[1]))    # => Set[2, 3, 4, 5]
p(Set.subtract(s, Array[2]))  # => Set[3, 4, 5]
p(Set.subtract(s, [3]))       # => Set[4, 5]
p(Set.subtract(s, 4..4))      # => Set[5]
p(s)                          # => Set[5]
```

```ruby error
Set.subtract(Set[1, 2], 1)    # !> TypeError: Set.subtract: argument 2 must be Set, Array, Tuple, or Range, got Integer
```

## replace

`Set.replace(x, Set)`

要素をすべてもう一方の Set の要素に置き換え、Set 自身を返します（その場で変更）。もう一方の要素の型がこの Set の要素の型に加わります。

```ruby
s = Set[1, 2]
p(Set.replace(s, Set[7, 8]))  # => Set[7, 8]
p(s)                          # => Set[7, 8]
```

## clear

`Set.clear(x)`

要素をすべて取り除き、空になった Set 自身を返します。

```ruby
s = Set[1, 2]
p(Set.clear(s))               # => Set[]
p(Set.empty?(s))              # => true
```

## |, union

`Set.|(x, Any)`

`Set.union(x, Set)`

和集合: 両方の要素をすべて持つ **新しい** Set。`a | b` の関数形が `Set.|`。右側は Set でなければならず、Array などは静的に `type` の問題です。結果の要素の型は両方の要素の型の和です。

```ruby
a = Set[1, 2]
b = Set[2, 3]
p(a | b)                      # => Set[1, 2, 3]
p(Set.union(a, b))            # => Set[1, 2, 3]
p(a)                          # => Set[1, 2]
```

```ruby error
p(Set[1] | Array[2])          # !> Bitwise.|: the operands are (Set@L1[Integer], Array@L1[Integer])
```

## &, intersection

`Set.&(x, Any)`

`Set.intersection(x, Set)`

積集合: 両方にある要素だけの **新しい** Set。`a & b` の関数形が `Set.&`。右側は Set でなければなりません。

```ruby
a = Set[1, 2, 3]
b = Set[2, 3, 4]
p(a & b)                      # => Set[2, 3]
p(Set.intersection(a, b))     # => Set[2, 3]
```

## -, difference

`Set.-(x, Any)`

`Set.difference(x, Set)`

差集合: 左にあって右に無い要素の **新しい** Set。`a - b` の関数形が `Set.-`。右側は Set でなければなりません。

```ruby
a = Set[1, 2, 3]
b = Set[2]
p(a - b)                      # => Set[1, 3]
p(Set.difference(a, b))       # => Set[1, 3]
p(a)                          # => Set[1, 2, 3]
```

## ==, !=

`Set.==(x, Any)`

`Set.!=(x, Any)`

2 つの Set が同じ要素を持つとき true（順序は関係ありません。`!=` はその否定）。右側が Set 以外（Array や nil）なら等しくありません。

```ruby
p(Set[1, 2] == Set[2, 1])     # => true
p(Set[1, 2] == Set[1])        # => false
p(Set[1] != Set[1])           # => false
p(Set[1, 2] == Array[1, 2])   # => false
```

## subset?, superset?

`Set.subset?(x, Set)`

`Set.superset?(x, Set)`

`subset?` は x のすべての要素が引数の Set にあるとき true、`superset?` はその逆です。等しい Set 同士も true。引数は Set でなければなりません（Array は静的に `type` の問題）。Ruby の `<=`、`>=` 演算子は Set には使えないので、これらの関数を使います。

```ruby
a = Set[1, 2]
b = Set[1, 2, 3]
p(Set.subset?(a, b))          # => true
p(Set.subset?(a, a))          # => true
p(Set.superset?(b, a))        # => true
p(Set.superset?(a, b))        # => false
```

```ruby error
p(Set[1] <= Set[1, 2])        # !> Comparable.<=: the operands are (Set@L1[Integer], Set@L1[Integer])
```

## proper_subset?, proper_superset?

`Set.proper_subset?(x, Set)`

`Set.proper_superset?(x, Set)`

真部分集合の判定: `subset?`、`superset?` と同じですが、等しい Set 同士は false です（Ruby の `<`、`>`）。

```ruby
a = Set[1, 2]
b = Set[1, 2, 3]
p(Set.proper_subset?(a, b))   # => true
p(Set.proper_subset?(a, a))   # => false
p(Set.proper_superset?(b, a)) # => true
```

## disjoint?, intersect?

`Set.disjoint?(x, Set)`

`Set.intersect?(x, Set)`

`intersect?` は共通の要素が 1 つでもあるとき true、`disjoint?` はその否定です。

```ruby
p(Set.intersect?(Set[1, 2], Set[2, 3]))   # => true
p(Set.disjoint?(Set[1, 2], Set[2, 3]))    # => false
p(Set.disjoint?(Set[1], Set[9]))          # => true
```

## each, each_entry

`Set.each(x) { }`

`Set.each_entry(x) { }`

要素を加えた順にブロックへ 1 つずつ渡し、Set 自身を返します。ブロックは必須です（Ruby のようにブロック無しで Enumerator を得ることはできません）。

```ruby
s = Set[3, 1, 2]
Set.each(s) { |x| puts(x) }
# => 3
# => 1
# => 2
p(Set.each_entry(s) { |x| x })   # => Set[3, 1, 2]
```

## each_with_index

`Set.each_with_index(x) { }`

要素とその位置（0 から）をブロックへ渡し、Set 自身を返します。

```ruby
Set.each_with_index(Set["a", "b"]) { |x, i| puts("#{i}: #{x}") }
# => 0: a
# => 1: b
```

## each_with_object

`Set.each_with_object(x, Any) { }`

要素と第 2 引数の値をブロックへ渡して回り、第 2 引数の値を返します。累積用の Array や Hash を渡す形で使います。

```ruby
a = Set.each_with_object(Set[1, 2], Array[]) { |x, acc| Array.push(acc, x * 2) }
p(a)                          # => [2, 4]
```

## reverse_each

`Set.reverse_each(x) { }`

要素を加えた順の逆にブロックへ渡し、Set 自身を返します。

```ruby
Set.reverse_each(Set[1, 2, 3]) { |x| puts(x) }
# => 3
# => 2
# => 1
```

## each_slice, each_cons

`Set.each_slice(x, Integer) { }`

`Set.each_cons(x, Integer) { }`

`each_slice` は要素を n 個ずつの Array に切ってブロックへ渡し（最後は短くてよい）、`each_cons` は連続する n 個の Array を 1 つずつずらして渡します。どちらも Set 自身を返します。n が 0 以下なら `ArgumentError`。

```ruby
s = Set[1, 2, 3, 4]
Set.each_slice(s, 3) { |a| p(a) }
# => [1, 2, 3]
# => [4]
Set.each_cons(s, 3) { |a| p(a) }
# => [1, 2, 3]
# => [2, 3, 4]
```

```ruby error
Set.each_slice(Set[1], 0) { |a| p(a) }   # !> ArgumentError: Set.each_slice: invalid slice size
```

## cycle

`Set.cycle(x, Integer) { }`

要素の列を n 回繰り返してブロックへ渡し、**nil** を返します。回数は必須です（Ruby の無限の `cycle` はありません）。n が 0 以下なら何もしません。

```ruby
Set.cycle(Set[1, 2], 2) { |x| print(x) }
puts("")
# => 1212
p(Set.cycle(Set[1], 0) { |x| p(x) })   # => nil
```

## map, collect

`Set.map(x) { }`

`Set.collect(x) { }`

各要素にブロックを適用した結果の **Array**（Set ではありません。要素の順に並び、重複もそのまま）。要素の型はブロックの結果の型です。

```ruby
p(Set.map(Set[1, 2, 3]) { |x| x * 10 })        # => [10, 20, 30]
p(Set.collect(Set[1, 2, 3]) { |x| x % 2 })     # => [1, 0, 1]
```

## map!, collect!

`Set.map!(x) { }`

`Set.collect!(x) { }`

各要素をブロックの結果に置き換え、Set 自身を返します（その場で変更）。結果が重なれば要素は減ります。ブロックの結果の型が要素の型に加わります。要素になれない値を返すと実行時に `TypeError`。

```ruby
s = Set[1, 2, 3]
p(Set.map!(s) { |x| x % 2 })  # => Set[1, 0]
p(s)                          # => Set[1, 0]
```

## flat_map, collect_concat

`Set.flat_map(x) { }`

`Set.collect_concat(x) { }`

ブロックは各要素に対して **Array か Tuple** を返し、それらをつなげた 1 つの Array が結果です。ブロックがどちらでもない値を返すと実行時に `TypeError`（`the block must return an Array or a Tuple, got Integer`。Ruby のように値をそのまま並べはしません）。

```ruby
p(Set.flat_map(Set[1, 2]) { |x| Array[x, x * 10] })   # => [1, 10, 2, 20]
p(Set.flat_map(Set[1, 2]) { |x| [x, x * 10] })        # => [1, 10, 2, 20]
```

```ruby error
Set.flat_map(Set[1]) { |x| x }    # !> TypeError: Set.flat_map: the block must return an Array or a Tuple, got Integer
```

## select, filter, find_all

`Set.select(x) { }`

`Set.filter(x) { }`

`Set.find_all(x) { }`

ブロックが真を返した要素の **Array**（Ruby の `Set#select` は Set を返しますが、Sake では Array です）。Set が欲しいときは `select!` でその場で絞るか、`Set[*...]` ではなく `Array.to_set` を使います。

```ruby
s = Set[1, 2, 3, 4]
p(Set.select(s) { |x| Integer.even?(x) })      # => [2, 4]
p(Set.filter(s) { |x| x > 3 })                 # => [4]
p(Set.find_all(s) { |x| x < 0 })               # => []
```

## reject

`Set.reject(x) { }`

ブロックが偽を返した要素の **Array**（`select` の逆）。

```ruby
p(Set.reject(Set[1, 2, 3, 4]) { |x| Integer.even?(x) })   # => [1, 3]
```

## select!, filter!, reject!

`Set.select!(x) { }`

`Set.filter!(x) { }`

`Set.reject!(x) { }`

`select!`、`filter!` はブロックが偽の要素を、`reject!` はブロックが真の要素をその場で取り除きます。何か取り除いたときは Set 自身、**何も変わらなかったときは nil** を返します（Ruby と同じ）。戻り値は `--strict`（レベル 2）で確かめずに使うと報告されます。常に Set を返す形は `keep_if`、`delete_if` です。

```ruby
s = Set[1, 2, 3, 4]
p(Set.select!(s) { |x| x > 1 })    # => Set[2, 3, 4]
p(Set.select!(s) { |x| x > 1 })    # => nil
p(Set.reject!(s) { |x| x > 3 })    # => Set[2, 3]
p(Set.filter!(s) { |x| x < 9 })    # => nil
p(s)                               # => Set[2, 3]
```

## keep_if, delete_if

`Set.keep_if(x) { }`

`Set.delete_if(x) { }`

`keep_if` はブロックが真の要素だけを残し、`delete_if` はブロックが真の要素を取り除きます（その場で変更）。どちらも常に Set 自身を返します。

```ruby
s = Set[1, 2, 3, 4]
p(Set.keep_if(s) { |x| x > 1 })        # => Set[2, 3, 4]
p(Set.delete_if(s) { |x| x > 3 })      # => Set[2, 3]
p(Set.delete_if(s) { |x| x > 9 })      # => Set[2, 3]
```

## filter_map

`Set.filter_map(x) { }`

各要素にブロックを適用し、nil と false でない結果だけを集めた Array。結果の要素の型からは nil が除かれます。

```ruby
p(Set.filter_map(Set[1, 2, 3, 4]) { |x| Integer.even?(x) ? x * 10 : nil })   # => [20, 40]
```

## partition

`Set.partition(x) { }`

ブロックが真の要素の Array と偽の要素の Array の Tuple `[yes, no]`。

```ruby
ev, od = Set.partition(Set[1, 2, 3, 4]) { |x| Integer.even?(x) }
p(ev)                         # => [2, 4]
p(od)                         # => [1, 3]
```

## group_by

`Set.group_by(x) { }`

ブロックの結果をキー、その結果になった要素の Array を値とする Hash。キーになれない値を返すと実行時に `TypeError`。

```ruby
p(Set.group_by(Set[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => [1, 3], 0 => [2, 4]}
```

## classify

`Set.classify(x) { }`

`group_by` と同じ分け方で、値が Array ではなく **Set** の Hash を返します（Ruby の `Set#classify`）。

```ruby
p(Set.classify(Set[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => Set[1, 3], 0 => Set[2, 4]}
```

## tally

`Set.tally(x)`

要素をキー、その個数を値とする Hash。Set の要素は重複しないので値はすべて 1 です（Array から来た操作で、形をそろえるためにあります）。

```ruby
p(Set.tally(Set["a", "b"]))   # => {"a" => 1, "b" => 1}
```

## chunk_while, slice_when

`Set.chunk_while(x) { }`

`Set.slice_when(x) { }`

隣り合う 2 要素をブロックに渡し、`chunk_while` はブロックが真の間を 1 つの区間に、`slice_when` はブロックが真のところで区切ります。結果は Array の Array です。

```ruby
s = Set[1, 2, 4, 5, 7]
p(Set.chunk_while(s) { |a, b| b == a + 1 })   # => [[1, 2], [4, 5], [7]]
p(Set.slice_when(s) { |a, b| b > a + 1 })     # => [[1, 2], [4, 5], [7]]
```

## slice_before, slice_after

`Set.slice_before(x) { }`

`Set.slice_after(x) { }`

ブロックが真を返す要素の直前（`slice_before`）または直後（`slice_after`）で区切った、Array の Array。

```ruby
s = Set[1, 2, 3, 4]
p(Set.slice_before(s) { |x| x == 3 })   # => [[1, 2], [3, 4]]
p(Set.slice_after(s) { |x| x == 2 })    # => [[1, 2], [3, 4]]
```

## find, detect

`Set.find(x) { }`

`Set.detect(x) { }`

ブロックが真を返した最初の要素。どの要素も真にならなければ **nil** で、`--strict`（レベル 2）は確かめずに使うと報告します。

```ruby
s = Set[1, 2, 3]
p(Set.find(s) { |x| x > 1 })      # => 2
p(Set.detect(s) { |x| x > 9 })    # => nil
```

```ruby error
x = Set.find(Set[1]) { |v| v > 0 }
p(x + 1)                          # !> the operands may be nil
```

## find_index

`Set.find_index(x) { }`

ブロックが真を返した最初の要素の位置（Integer、加えた順で 0 から）。無ければ **nil**（`--strict` レベル 2 で報告）。

```ruby
s = Set["a", "b", "c"]
p(Set.find_index(s) { |x| x == "c" })   # => 2
p(Set.find_index(s) { |x| x == "z" })   # => nil
```

## any?, all?, none?, one?

`Set.any?(x) { }`

`Set.all?(x) { }`

`Set.none?(x) { }`

`Set.one?(x) { }`

ブロックが真を返す要素が、1 つ以上ある・すべてである・1 つも無い・ちょうど 1 つあるとき true。ブロックは必須です（Ruby のブロック無しの形はありません。空かどうかは `empty?`）。

```ruby
s = Set[1, 2, 3]
p(Set.any?(s) { |x| x > 2 })      # => true
p(Set.all?(s) { |x| x > 2 })      # => false
p(Set.none?(s) { |x| x > 9 })     # => true
p(Set.one?(s) { |x| x == 1 })     # => true
```

```ruby error
p(Set.any?(Set[1]))               # !> Set.any? requires a block
```

## count

`Set.count(x) [{ }]`

ブロック無しなら要素の個数、ブロック付きならブロックが真を返した要素の個数（Integer）。

```ruby
s = Set[1, 2, 3]
p(Set.count(s))                   # => 3
p(Set.count(s) { |x| x > 1 })     # => 2
```

## sum

`Set.sum(x, [Integer|Float|Rational|Complex])`

要素の和。初期値（省略時 0）に要素を順に足します。要素と初期値は数でなければならず、初期値に String などを渡すのは静的に `type` の問題、数でない要素は実行時に `TypeError`（`String can't be coerced into Integer`）です（Ruby の `sum("")` で String をつなぐ形はありません。`join` を使います）。空の Set では初期値。

```ruby
p(Set.sum(Set[1, 2, 3]))          # => 6
p(Set.sum(Set[1, 2], 0.5))        # => 3.5
p(Set.sum(Set[]))                 # => 0
```

```ruby error
p(Set.sum(Set["a", "b"], ""))     # !> argument 2 must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Set.reduce(x, Any) { }`

`Set.inject(x, Any) { }`

初期値から始め、ブロックに累積値と要素を渡して畳み込みます。初期値は **必須** です（Ruby の、最初の要素を初期値にする形はありません）。結果の型は初期値とブロックの結果の型から決まります。

```ruby
p(Set.reduce(Set[1, 2, 3], 0) { |acc, x| acc + x })     # => 6
p(Set.inject(Set[1, 2, 3], 1) { |acc, x| acc * x })     # => 6
```

```ruby error
p(Set.reduce(Set[1]) { |a, b| a + b })   # !> wrong number of arguments for Set.reduce (given 1, expected 2)
```

## min, max

`Set.min(x)`

`Set.max(x)`

最小・最大の要素。要素は互いに比べられなければなりません: 比べられない型が要素の型に混ざる Set（`Set[1, "a"]`）は検査器が静的に `type` の問題として退け、nil になりうる要素は `nil` の問題です。検査器に見えないとき（`Set[1.0, Float.NAN]`）は実行時に `ArgumentError`（`cannot compare the elements`）。空の Set では **nil** で、`Array.min` と同じ外れの nil です: 確かめずに使うことは `--strict=3` でだけ報告されます。

```ruby
s = Set[3, 1, 2]
p(Set.min(s))                     # => 1
p(Set.max(s))                     # => 3
p(Set.max(Set[]))                 # => nil
```

```ruby error
p(Set.min(Set[1, "a"]))           # !> Set.min: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
p(Set.min(Set[1.0, Float.NAN]))   # !> ArgumentError: Set.min: cannot compare the elements
```

## minmax

`Set.minmax(x)`

最小と最大の Tuple `[min, max]`。空の Set では `[nil, nil]` で、これは外れの nil です（要素を確かめずに使うことは `--strict=3` でだけ報告）。比較の規則は静的な検査を含めて `min`、`max` と同じ。

```ruby
lo, hi = Set.minmax(Set[3, 1, 2])
p([lo, hi])                       # => [1, 3]
p(Set.minmax(Set[]))              # => [nil, nil]
```

## min_by, max_by

`Set.min_by(x) { }`

`Set.max_by(x) { }`

ブロックの結果が最小・最大になる要素。ブロックの結果同士は比べられなければならず、比べられない型が結果の型に混ざるブロックは `min` と同じく静的に退けられます（`type`）。空の Set では **nil** で、外れの nil です（`--strict=3` でだけ報告）。

```ruby
s = Set["bb", "a", "ccc"]
p(Set.min_by(s) { |x| String.size(x) })   # => "a"
p(Set.max_by(s) { |x| String.size(x) })   # => "ccc"
p(Set.max_by(Set[]) { |x| x })            # => nil
```

```ruby error
p(Set.min_by(Set[1, 2]) { |x| x == 1 ? 1 : "a" })   # !> Set.min_by: elements compared in order may be (Integer, String), which cannot be compared
```

## minmax_by

`Set.minmax_by(x) { }`

ブロックの結果で見た最小と最大の要素の Tuple。空の Set では `[nil, nil]`（外れの nil、レベル 3）。ブロックの結果の検査は `min_by` と同じ。

```ruby
p(Set.minmax_by(Set[1, 2, 3]) { |x| -x })   # => [3, 1]
```

## sort

`Set.sort(x)`

要素を昇順に並べた Array。要素は互いに比べられなければなりません: 比べられない型が要素の型に混ざる Set は静的に退けられ（`type`）、nil になりうる要素は `nil` の問題です。検査器に見えないとき（`Set[1.0, Float.NAN]`）は実行時に `ArgumentError`（`cannot compare the elements`）。

```ruby
p(Set.sort(Set[3, 1, 2]))         # => [1, 2, 3]
```

```ruby error
p(Set.sort(Set[1, "a"]))          # !> Set.sort: elements compared in order may be (Integer, String), which cannot be compared
```

## sort_by

`Set.sort_by(x) { }`

ブロックの結果の昇順に要素を並べた Array。Tuple を返すと辞書順で並びます。ブロックの結果同士は比べられなければならず、比べられない型が結果の型に混ざると静的に退けられます（`type`）。

```ruby
p(Set.sort_by(Set["bb", "a", "ccc"]) { |x| String.size(x) })   # => ["a", "bb", "ccc"]
p(Set.sort_by(Set[1, 2, 3]) { |x| -x })                        # => [3, 2, 1]
```

```ruby error
p(Set.sort_by(Set[1, 2]) { |x| x == 1 ? 1 : "a" })   # !> Set.sort_by: elements compared in order may be (Integer, String), which cannot be compared
```

## first

`Set.first(x)`

最初に加えた要素。空の Set では **nil** で、`Array.first` と同じ外れの nil です: 確かめずに使うことは `--strict=3` でだけ報告されます。個数を指定する形はありません（`take` を使います）。

```ruby
p(Set.first(Set[3, 1]))           # => 3
p(Set.first(Set[]))               # => nil
```

## take, drop

`Set.take(x, Integer)`

`Set.drop(x, Integer)`

先頭の n 要素の Array、先頭の n 要素を除いた残りの Array。n が負なら `ArgumentError`。

```ruby
s = Set[1, 2, 3, 4]
p(Set.take(s, 2))                 # => [1, 2]
p(Set.drop(s, 2))                 # => [3, 4]
p(Set.take(s, 9))                 # => [1, 2, 3, 4]
```

```ruby error
p(Set.take(Set[1], -1))           # !> ArgumentError: Set.take: attempt to take negative size
```

## take_while, drop_while

`Set.take_while(x) { }`

`Set.drop_while(x) { }`

先頭からブロックが真の間の要素の Array、その残りの Array。

```ruby
s = Set[1, 2, 3, 1]
p(Set.take_while(s) { |x| x < 3 })    # => [1, 2]
p(Set.drop_while(s) { |x| x < 3 })    # => [3]
```

## to_a, entries

`Set.to_a(x)`

`Set.entries(x)`

要素を加えた順に並べた新しい Array。Array を変えても Set は変わりません。

```ruby
s = Set[3, 1]
a = Set.to_a(s)
Array.push(a, 9)
p(a)                              # => [3, 1, 9]
p(s)                              # => Set[3, 1]
p(Set.entries(s))                 # => [3, 1]
```

## to_set

`Set.to_set(x)`

Set 自身を返します（複製ではありません）。Array の `Array.to_set` と形をそろえるための操作です。

```ruby
s = Set[1]
Set.add(Set.to_set(s), 2)
p(s)                              # => Set[1, 2]
```

## uniq

`Set.uniq(x)`

要素の Array。Set に重複は無いので `to_a` と同じです。

```ruby
p(Set.uniq(Set[1, 2]))            # => [1, 2]
```

## compact

`Set.compact(x)`

nil を除いた要素の Array。

```ruby
p(Set.compact(Set[1, nil, 2]))    # => [1, 2]
```

## flatten

`Set.flatten(x)`

要素の Set を再帰的に開いた **新しい Set**（Ruby の `Set#flatten`）。Array の要素は開きません。

```ruby
p(Set.flatten(Set[1, Set[2, Set[3]]]))   # => Set[1, 2, 3]
p(Set.flatten(Set[1, 2]))                # => Set[1, 2]
```

## zip

`Set.zip(x, *Array)`

要素と各 Array の同じ位置の要素を組にした Tuple の Array。Array が短ければ nil が入ります。引数は Array でなければなりません（Set は静的に `type` の問題）。

```ruby
p(Set.zip(Set[1, 2, 3], Array["a", "b"]))   # => [[1, "a"], [2, "b"], [3, nil]]
p(Set.zip(Set[1, 2]))                       # => [[1], [2]]
```

## join

`Set.join(x, [String])`

要素を `to_s` でつなげた String。区切り（省略時 ""）を間に入れます。要素の Array は中まで開いてつなげます。

```ruby
s = Set[1, 2, 3]
p(Set.join(s))                    # => "123"
p(Set.join(s, ", "))              # => "1, 2, 3"
```
