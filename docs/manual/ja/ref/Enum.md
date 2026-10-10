# Enum

Enum は Ruby の Enumerable を短い名前にした module で、prelude（`sakelib/prelude.sake`。どのプログラムも最初に読む）が Sake で定義しています。`Enum.map(x) { }` などの関数は mixin 関数で、第 1 引数の型でディスパッチします（[プログラムの構造](../02-program.md)の「module の関数の呼び方」）。Array・Hash・Set・Range は Enum を include していて、自分の操作で答えます: `Enum.map(xs)` は xs が Array なら `Array.map(xs)`、`Enum.each(h) { |k, v| }` は `Hash.each` です。組み込み型には何も写されません。それ以外の型（Integer、Tuple、String）の値を渡すのは実行前に `type` の問題、実行時は `TypeError` です。Tuple は Enum を include しません（長さと位置ごとの型が決まっているので、添字と分解で扱います）。

自分のクラスは `include Enum` と `def each(c) = ... yield(v) ...` を書けば参加します。Enum の他の関数はすべて `each` の上に書かれているので、クラスに写され（[include](../02-program.md)）、`C.map(c) { }`、`C.count(c)`、`Enum.first(c)` のどれでも呼べます。クラス自身が同名の関数を定義していればそれが勝ちます。

```ruby
class Deck
  include Enum
  attr_reader cards
  def each(d) = Array.each(@cards) { |c| yield(c) }
end
d = Deck.new(Array["A", "K", "Q", "J"])
p(Deck.map(d) { |c| String.downcase(c) })     # => ["a", "k", "q", "j"]
p(Enum.count(d))                              # => 4
p(Enum.select(Array[3, 1, 2]) { |v| v > 1 })  # => [3, 2]
```

```ruby error
p(Enum.map(5) { |v| v })                      # !> Enum.map dispatches on its first argument, which is Integer; the types that include Enum are Array, Hash, Set, Range
```

結果が nil になりうる関数（`find`、`first`、`min_by`、`max_by`）は、自分のクラスの写しでは `nil | T` を返し、検査しないで使うと level 2 で報告されます。組み込み型にディスパッチしたときは、その型の操作の規則に従います（`Array.first` の「外れの nil」は level 3）。以下の各節は Enum 自身の定義を述べ、組み込み型では同名の操作（[Array](Array.md)、[Hash](Hash.md)、[Set](Set.md)、[Range](Range.md)）が走ります。

## each

`Enum.each(x)`

必須の関数です。Enum を include するクラスが `def each(c)` を定義し、各要素に `yield(v)` します（Hash のように 2 つ渡してもよい）。`Enum.each(x) { }` は x の型の `each` にディスパッチします。定義していないクラスは、呼び出しが届く場所で `type` の問題、実行時は `NotImplementedError` です。

```ruby
Enum.each(Hash[a: 1, b: 2]) { |k, v| puts("#{k}: #{v}") }
# => a: 1
# => b: 2
```

## map

`Enum.map(x) { }`

各要素をブロックの値に写した Array を返します。

```ruby
p(Enum.map(1..3) { |v| v * v })               # => [1, 4, 9]
p(Enum.map(Set[1, 2]) { |v| -v })             # => [-1, -2]
```

## select, filter

`Enum.select(x) { }`

`Enum.filter(x) { }`

ブロックが真を返した要素の Array を返します。

```ruby
p(Enum.select(Array[1, 2, 3, 4]) { |v| v % 2 == 0 })   # => [2, 4]
p(Enum.filter(1..6) { |v| v > 4 })                     # => [5, 6]
```

## reject

`Enum.reject(x) { }`

ブロックが偽を返した要素の Array を返します。

```ruby
p(Enum.reject(Array[1, 2, 3, 4]) { |v| v % 2 == 0 })   # => [1, 3]
```

## filter_map

`Enum.filter_map(x) { }`

各要素にブロックを適用し、真の結果だけを集めた Array を返します（nil と false は落ちます）。

```ruby
p(Enum.filter_map(Array["1", "x", "3"]) { |s| String.to_i(s) if String.match?(s, /\A\d+\z/) })   # => [1, 3]
```

## flat_map

`Enum.flat_map(x) { }`

ブロックが返す Array（か Tuple）を 1 段つなげた Array を返します。

```ruby
p(Enum.flat_map(Array[1, 2]) { |v| Array[v, v * 10] })   # => [1, 10, 2, 20]
```

## find, detect

`Enum.find(x) { }`

`Enum.detect(x) { }`

ブロックが真を返す最初の要素を返します。無ければ nil（自分のクラスでは level 2、`Array.find` などでは level 2）。

```ruby
p(Enum.find(Array[3, 8, 5]) { |v| v > 4 })    # => 8
p(Enum.detect(1..3) { |v| v > 9 })            # => nil
```

## reduce, inject

`Enum.reduce(x, init) { }`

`Enum.inject(x, init) { }`

`init` から始めて、各要素でブロックを `yield(acc, v)` と呼び、最後の累積値を返します。Ruby と違い、初期値は省略できません（要素型だけから結果の型が決まらないため。[Array](Array.md) の `reduce` と同じ）。

```ruby
p(Enum.reduce(Array[1, 2, 3], 0) { |acc, v| acc + v })     # => 6
p(Enum.inject(1..4, 1) { |acc, v| acc * v })               # => 24
```

## sum

`Enum.sum(x, [init]) [{ }]`

要素の和（ブロックがあればブロックの値の和）を返します。`init`（既定 0）から足し始めます。組み込み型では要素は数か `Arithmetic` を include する型の値でなければなりません（[Array](Array.md)）。

```ruby
p(Enum.sum(1..4))                             # => 10
p(Enum.sum(Array[1, 2, 3]) { |v| v * 10 })      # => 60
```

## count

`Enum.count(x) [{ }]`

要素の数、ブロックがあればブロックが真を返した要素の数を返します。

```ruby
p(Enum.count(Set[1, 2, 3]))                   # => 3
p(Enum.count(1..10) { |v| v % 3 == 0 })       # => 3
```

## include?

`Enum.include?(x, v)`

`==` で等しい要素があれば true。

```ruby
p(Enum.include?(1..5, 3))                     # => true
p(Enum.include?(Array["a"], "b"))             # => false
```

## any?, all?, none?, one?

`Enum.any?(x) [{ }]`

`Enum.all?(x) [{ }]`

`Enum.none?(x) [{ }]`

`Enum.one?(x) [{ }]`

ブロックが真を返す要素が 1 つ以上ある / すべて / 無い / ちょうど 1 つ、のとき true。ブロックが無ければ要素自身の真偽を見ます。

```ruby
xs = Array[1, 2, 3]
p(Enum.any?(xs) { |v| v > 2 })                # => true
p(Enum.all?(xs) { |v| v > 2 })                # => false
p(Enum.none?(xs) { |v| v > 5 })               # => true
p(Enum.one?(xs) { |v| v > 2 })                # => true
```

## min_by, max_by

`Enum.min_by(x) { }`

`Enum.max_by(x) { }`

ブロックの値が最小 / 最大の要素を返します。空なら nil。ブロックの値は互いに比べられる型でなければなりません（検査器が静的に見ます）。

```ruby
words = Array["pear", "fig", "banana"]
p(Enum.min_by(words) { |w| String.length(w) })   # => "fig"
p(Enum.max_by(words) { |w| String.length(w) })   # => "banana"
```

## sort_by

`Enum.sort_by(x) { }`

ブロックの値の昇順に並べた Array を返します。

```ruby
p(Enum.sort_by(Array["bb", "a", "ccc"]) { |s| -String.length(s) })   # => ["ccc", "bb", "a"]
```

## to_a

`Enum.to_a(x)`

要素を並べた新しい Array を返します。

```ruby
p(Enum.to_a(1..3))                            # => [1, 2, 3]
p(Enum.to_a(Hash[a: 1]))                      # => [[:a, 1]]
```

## first

`Enum.first(x, [n])`

最初の要素（空なら nil）、`n` を与えれば最初の `n` 個の Array を返します。

```ruby
p(Enum.first(Array[7, 8, 9]))                 # => 7
p(Enum.first(1..10, 3))                       # => [1, 2, 3]
```

## take, drop

`Enum.take(x, n)`

`Enum.drop(x, n)`

最初の `n` 個の Array / 最初の `n` 個を除いた Array を返します。

```ruby
p(Enum.take(1..5, 2))                         # => [1, 2]
p(Enum.drop(1..5, 2))                         # => [3, 4, 5]
```

## group_by

`Enum.group_by(x) { }`

ブロックの値をキーに、同じ値になった要素の Array を値にした Hash を返します。

```ruby
p(Enum.group_by(1..6) { |v| v % 3 })          # => {1 => [1, 4], 2 => [2, 5], 0 => [3, 6]}
```

## partition

`Enum.partition(x) { }`

ブロックが真を返した要素の Array と、偽を返した要素の Array の Tuple `[yes, no]` を返します。

```ruby
yes, no = Enum.partition(1..6) { |v| v > 3 }
p(yes)                                        # => [4, 5, 6]
p(no)                                         # => [1, 2, 3]
```

## each_with_object

`Enum.each_with_object(x, memo) { }`

各要素でブロックを `yield(v, memo)` と呼び、`memo` を返します。

```ruby
p(Enum.each_with_object(Array[1, 2], Array[]) { |v, m| Array.unshift(m, v) })   # => [2, 1]
```

## compact

`Enum.compact(x)`

nil を除いた要素の Array を返します。

```ruby
p(Enum.compact(Array[1, nil, 2]))             # => [1, 2]
```
