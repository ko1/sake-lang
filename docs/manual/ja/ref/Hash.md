# Hash

Hash はキーから値への対応で、挿入順を保ちます。Ruby の `{"a" => 1}` のようなリテラルはなく、`Hash["a" => 1, b: 2]`、`Hash[]`、`Hash.new(default)` で構築します（[値と型](../03-values.md)）。**`{k: v}` は Record であって Hash ではありません**（`{}` も空の Record で、静的に拒否されます。[Record](Record.md)）。`Hash[name: v]` と書いたキーは Symbol です。

キーに使えるのは Integer、Float、String、Symbol、true、false、nil、Time と、それらだけからなる Tuple、Record、Array、Hash、Set、Struct 値です。Regexp、Range、独自の等価性（`==` や `Comparable`）を定義した Struct 型の値はキーにできず、実行時に `TypeError` です。Tuple と Record のキーは格納時に複製されるので、元の値を後で書き換えてもキーは変わりません（Array などのキーは Ruby と同じく、書き換えると見つからなくなります）。`"a"` と `:a`、`1` と `1.0` は別のキーです。

`h[k]` は見つからないと nil（`Hash.new(default)` で作った Hash なら default）を返します。この nil をそのまま使うことは `--strict=3` でだけ `index-nil` として報告されます（level 2 は報告しません）。見つからないことを例外にしたいときは `Hash.fetch` を使います。`Hash.delete`、`Hash.key`、`Hash.dig`、`Hash.first`、`Hash.shift`、`Hash.find` などの nil は level 2 で報告されます。

ブロックを取る操作は、各要素を `[key, value]` の Tuple 1 つとして渡します。`|k, v|` と書けば分解され、`|kv|` なら Tuple のまま受け取ります。`each_with_object` は `|(k, v), memo|`、`reduce` は `|acc, (k, v)|` と書きます。繰り返しの順序は挿入順です。`to_a`、`sort_by`、`take`、`first` などが返す組も `[k, v]` の Tuple です。

検査器は Hash に、作られた場所ごとにキーの型と値の型を 1 つずつ与えます。`Hash.store` や `[]=` で別の型を入れると、その Hash の値の型は和になります（`Hash["a" => 1]` に `"x"` を入れると値は `Integer | String` で、`fetch` した値の `+ 1` は `type` の問題）。`transform_keys!`、`transform_values!` など要素の型を変える in-place 操作も同じです（下記）。

Hash に使える演算子は `==`、`!=` と添字 `h[k]`、`h[k] = v` です。`Hash.==(x, y)` などは演算子の関数形です（[演算子と添字](../05-operators.md)）。

## Hash[]

`Hash[*Any]`

`Hash[k => v, ...]` は新しい Hash を作ります。引数は `key => value` の組だけで（`Hash[name: v]` のラベル形はキーが Symbol）、組以外（`Hash[1]`、`Hash[{x: 1}]`）は静的なエラーです。`Hash[]` は空の Hash。同じキーを 2 度書くと後の値が残ります。キーにできない値は実行時に `TypeError`。他の `T[...]` と違い、Hash の Array ではなく Hash そのものを返します。

```ruby
h = Hash["a" => 1, b: 2]
p(h)                               # => {"a" => 1, b: 2}
p(Hash[])                          # => {}
p(Hash[1 => 2, 1 => 3])            # => {1 => 3}
p(Hash[[1, 2] => "t", nil => "n"])  # => {[1, 2] => "t", nil => "n"}
```

```ruby error
p(Hash[1])                         # !> Hash[...] takes `key => value` pairs, like `Hash["a" => 1]`
```

## new

`Hash.new([Any])`

空の Hash を作ります。`Hash.new(default)` は見つからないキーに対して `h[k]` が default を返す Hash です（Ruby と同じ）。default はそのオブジェクト 1 つを共有するので、`Hash.new(Array[])` の Array を `h["x"]` 経由で変更するとすべてのキーで見えますし、Hash 自体には何も格納されません。Ruby のブロック形 `Hash.new { |h, k| ... }` はありません（静的なエラー）。`Hash.fetch` は default を見ません。

```ruby
counts = Hash.new(0)
counts["x"] += 1
counts["x"] += 1
p(counts)                          # => {"x" => 2}
p(counts["none"])                  # => 0
p(Hash.new["none"])                # => nil
d = Hash.new(Array[])
Array.push(d["a"], 1)
p(d["b"])                          # => [1]
p(d)                               # => {}
```

```ruby error
h = Hash.new { |hh, k| 0 }         # !> Hash.new does not take a block
```

## default, set_default

`Hash.default(x)`

`Hash.set_default(x, Any)`

`default` は見つからないキーに `h[k]` が返す値（`Hash.new(default)` の default。無ければ nil）。`set_default(h, v)` はそれを `v` に変えて `v` を返します（Ruby の `h.default = v`）。検査器は `h[k]` の型に default の型を加えます。

```ruby
h = Hash.new(0)
p(Hash.default(h))                 # => 0
p(Hash.default(Hash[]))            # => nil
Hash.set_default(h, 5)
p(h["q"])                          # => 5
```

## []

`Hash.[](x, Any)`

`h[k]` の関数形。キー `k` の値を返します。無ければ default（通常 nil）。この nil は `--strict=3` でだけ `index-nil` として報告されます。キーの型は何でもよく、どんな値でも静的な問題にはなりません。`Hash.new(default)` の Hash では default の型が結果に加わるので、`Hash.new(0)` の `h[k] + 1` は level 3 でも通ります。

```ruby
h = Hash["a" => 1, [1, 2] => "t"]
p(h["a"])                          # => 1
p(h[[1, 2]])                       # => "t"
p(h["zz"])                         # => nil
p(Hash.[](h, "a"))                 # => 1
```

## []=, store

`Hash.[]=(x, Any, Any)`

`Hash.store(x, Any, Any)`

`h[k] = v` とその関数形。キー `k` に値 `v` を結び付け、`v` を返します。新しいキーは末尾に加わり、既存のキーは値だけ変わって位置は動きません。キーにできない値は `TypeError`。検査器はこの Hash のキーの型・値の型に `k`、`v` の型を加えます。

```ruby
h = Hash["a" => 1]
h["b"] = 2
p(Hash.store(h, "a", 10))          # => 10
p(h)                               # => {"a" => 10, "b" => 2}
```

```ruby error
Hash.store(Hash[], /x/, 1)         # !> TypeError: Hash.store: Regexp cannot be a Hash key or Set element
```

## fetch

`Hash.fetch(x, Any, [Any])`

キー `k` の値を返します。無いときは、第 3 引数 `default` があればそれを返し、無ければ `KeyError`（Ruby と同じ。ブロック形はありません）。`Hash.new(default)` の default は使いません。結果の型は値の型と `default` の型の和で、値が nil でなければ nil になりえないので、`h[k]` の代わりに使えば `--strict=3` の `index-nil` も出ません。

```ruby
h = Hash["a" => 1]
p(Hash.fetch(h, "a"))              # => 1
p(Hash.fetch(h, "zz", 0))          # => 0
p(Hash.fetch(h, "a") + 1)          # => 2
```

```ruby error
p(Hash.fetch(Hash["a" => 1], "b")) # !> KeyError: Hash.fetch: key not found: "b"
```

## dig

`Hash.dig(x, Any)`

キー `k` の値、無ければ nil（default は見ません）。Ruby の `dig` はキーを何個でも取って掘り進みますが、Sake のは 1 個だけで、`h[k]` との違いは nil が level 2 で報告される点です。入れ子を掘るには、`if` で確かめてから次の `dig` を呼びます。

```ruby
h = Hash["a" => Hash["b" => 1]]
inner = Hash.dig(h, "a")
if inner
  p(Hash.dig(inner, "b"))          # => 1
end
p(Hash.dig(h, "zz"))               # => nil
```

```ruby error
p(Hash.dig(Hash["a" => 1], "a") + 1)   # !> the operands may be nil
```

## fetch_values

`Hash.fetch_values(x, *Any)`

列挙したキーの値を順に並べた Array を返します。無いキーがあれば `KeyError`（default は見ません）。要素の型は値の型で、nil にはなりません。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.fetch_values(h, "b", "a"))  # => [2, 1]
```

```ruby error
p(Hash.fetch_values(Hash["a" => 1], "a", "zz"))   # !> KeyError: Hash.fetch_values: key not found: "zz"
```

## values_at

`Hash.values_at(x, *Any)`

列挙したキーの値を順に並べた Array を返します。無いキーの位置は default（通常 nil）です。要素の型は `値 | nil` なので、要素をそのまま使うと level 2 で報告されます。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.values_at(h, "a", "zz"))    # => [1, nil]
p(Hash.values_at(Hash.new(9), "x"))   # => [9]
```

## key?, has_key?, include?, member?

`Hash.key?(x, Any)`

`Hash.has_key?(x, Any)`

`Hash.include?(x, Any)`

`Hash.member?(x, Any)`

キー `k` があれば true。値が nil でも true です（`h[k]` が nil でも区別できます）。4 つは同じ操作です。

```ruby
h = Hash["a" => nil]
p(Hash.key?(h, "a"))               # => true
p(Hash.include?(h, "b"))           # => false
p(h["a"])                          # => nil
```

## value?, has_value?

`Hash.value?(x, Any)`

`Hash.has_value?(x, Any)`

`v` と `==` で等しい値があれば true。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.value?(h, 2))               # => true
p(Hash.has_value?(h, 3))           # => false
```

## key

`Hash.key(x, Any)`

値が `v` と等しい最初のキーを返します。無ければ nil（level 2 で報告）。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 2]
p(Hash.key(h, 2))                  # => "b"
p(Hash.key(h, 9))                  # => nil
```

## assoc, rassoc

`Hash.assoc(x, Any)`

`Hash.rassoc(x, Any)`

`assoc(h, k)` はキー `k` の組 `[k, v]`、`rassoc(h, v)` は値が `v` の最初の組 `[k, v]` を Tuple で返します。無ければ nil（level 2 で報告）。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.assoc(h, "a"))              # => ["a", 1]
p(Hash.rassoc(h, 2))               # => ["b", 2]
p(Hash.assoc(h, "zz"))             # => nil
```

## length, size

`Hash.length(x)`

`Hash.size(x)`

組の個数（Integer）。

```ruby
p(Hash.size(Hash["a" => 1, "b" => 2]))   # => 2
p(Hash.length(Hash[]))                   # => 0
```

## empty?

`Hash.empty?(x)`

組が 1 つも無ければ true。

```ruby
p(Hash.empty?(Hash[]))             # => true
p(Hash.empty?(Hash.new(0)))        # => true
p(Hash.empty?(Hash["a" => 1]))     # => false
```

## count

`Hash.count(x) [{ }]`

ブロックなしなら組の個数（`size` と同じ）、ブロックがあれば `[k, v]` を受けて真を返した組の個数（Integer）。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.count(h))                   # => 3
p(Hash.count(h) { |k, v| v >= 2 })   # => 2
```

## keys

`Hash.keys(x)`

キーを挿入順に並べた新しい Array。要素の型はキーの型です。型付き Array ではないので、他の型の値も push できます。

```ruby
h = Hash["b" => 2, "a" => 1]
p(Hash.keys(h))                    # => ["b", "a"]
p(Hash.keys(Hash[]))               # => []
```

## values

`Hash.values(x)`

値を挿入順に並べた新しい Array。要素の型は値の型です。

```ruby
h = Hash["b" => 2, "a" => 1]
p(Hash.values(h))                  # => [2, 1]
```

## to_a

`Hash.to_a(x)`

組を `[k, v]` の Tuple にして挿入順に並べた新しい Array。Ruby の `to_a` が返す内側の Array は、Sake では Tuple です。

```ruby
h = Hash[1 => "x", 2 => "y"]
p(Hash.to_a(h))                    # => [[1, "x"], [2, "y"]]
Array.each(Hash.to_a(h)) { |k, v| p(k) }   # => 1
                                           # => 2
```

## flatten

`Hash.flatten(x)`

キーと値を交互に並べた新しい Array `[k1, v1, k2, v2, ...]`。Ruby の `flatten` の深さ 1 と同じで、値の Array や Tuple は開きません（深さの引数はありません）。要素の型はキーの型と値の型の和です。

```ruby
p(Hash.flatten(Hash[1 => "x", 2 => "y"]))        # => [1, "x", 2, "y"]
p(Hash.flatten(Hash["a" => Array[1, 2]]))        # => ["a", [1, 2]]
```

## to_h

`Hash.to_h(x)`

その Hash 自身を返します（Ruby の `Hash#to_h` と同じで、複製ではありません）。ブロック形はありません。複製には `Hash.dup`。

```ruby
h = Hash["a" => 1]
p(Hash.to_h(h))                    # => {"a" => 1}
p(Kernel.equal?(Hash.to_h(h), h))  # => true
```

## dup

`Hash.dup(x)`

同じ組を持つ新しい Hash（浅い複製。キーと値のオブジェクトは共有）。default も引き継ぎます。一方への `store` や `delete` は他方に影響しません。

```ruby
h = Hash.new(0)
Hash.store(h, "a", 1)
h2 = Hash.dup(h)
Hash.store(h2, "b", 2)
p(h)                               # => {"a" => 1}
p(h2)                              # => {"a" => 1, "b" => 2}
p(h2["zz"])                        # => 0
```

## first

`Hash.first(x)`

最初に挿入された組 `[k, v]` を Tuple で返します。空なら nil（level 2 で報告）。Ruby の `first(n)` の形はなく、先頭 n 組は `Hash.take`。

```ruby
p(Hash.first(Hash["a" => 1, "b" => 2]))   # => ["a", 1]
p(Hash.first(Hash[]))                     # => nil
```

## take, drop

`Hash.take(x, Integer)`

`Hash.drop(x, Integer)`

`take(h, n)` は先頭 n 組、`drop(h, n)` は先頭 n 組を除いた残りを、`[k, v]` の Tuple の Array で返します。Hash は変わりません。n が組の数より大きくても構いません。負の n は `ArgumentError`。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.take(h, 2))                 # => [["a", 1], ["b", 2]]
p(Hash.drop(h, 2))                 # => [["c", 3]]
p(Hash.drop(h, 5))                 # => []
```

```ruby error
p(Hash.take(Hash["a" => 1], -1))   # !> ArgumentError: Hash.take: attempt to take negative size
```

## each, each_pair

`Hash.each(x) { }`

`Hash.each_pair(x) { }`

各組についてブロックを挿入順に呼び、Hash 自身を返します。ブロックは `[k, v]` の Tuple を受け取ります（`|k, v|` で分解）。ブロックは必須です（ブロック無しで Enumerator を返す Ruby の形はありません）。

```ruby
h = Hash["a" => 1, "b" => 2]
Hash.each(h) { |k, v| p(k + Integer.to_s(v)) }   # => "a1"
                                                 # => "b2"
Hash.each_pair(h) { |kv| p(kv) }                 # => ["a", 1]
                                                 # => ["b", 2]
r = Hash.each(h) { |k, v| nil }
p(Kernel.equal?(r, h))                           # => true
```

## each_key

`Hash.each_key(x) { }`

各キーについてブロックを呼び、Hash 自身を返します。ブロックはキーだけを受け取ります。

```ruby
Hash.each_key(Hash["a" => 1, "b" => 2]) { |k| p(k) }   # => "a"
                                                       # => "b"
```

## each_value

`Hash.each_value(x) { }`

各値についてブロックを呼び、Hash 自身を返します。ブロックは値だけを受け取ります。

```ruby
Hash.each_value(Hash["a" => 1, "b" => 2]) { |v| p(v * 10) }   # => 10
                                                              # => 20
```

## each_with_object

`Hash.each_with_object(x, Any) { }`

`memo` を引き回しながら各組についてブロックを呼び、最後に `memo` を返します。ブロックは `[k, v]` の Tuple と `memo` の 2 つを受け取るので、`|(k, v), memo|` と書きます。結果の型は `memo` の型です。

```ruby
h = Hash["a" => 1, "b" => 2]
ks = Hash.each_with_object(h, Array[]) { |(k, v), acc| Array.push(acc, k) }
p(ks)                              # => ["a", "b"]
```

## map

`Hash.map(x) { }`

各組について `[k, v]` を渡してブロックを呼び、その結果を並べた新しい Array を返します。Ruby と同じく結果は Hash ではなく Array です（Hash を得るなら `transform_values` や `to_h`）。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.map(h) { |k, v| k + Integer.to_s(v) })   # => ["a1", "b2"]
p(Hash.map(h) { |kv| kv })                      # => [["a", 1], ["b", 2]]
```

## flat_map

`Hash.flat_map(x) { }`

各組についてブロックを呼び、ブロックが返した Array をすべてつなげた新しい Array を返します。ブロックは **Array** を返さなければならず、Tuple やスカラーを返すと実行時に `TypeError`（Ruby は Array 以外をそのまま並べます）。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.flat_map(h) { |k, v| Array[k, v] })   # => ["a", 1, "b", 2]
```

```ruby error
Hash.flat_map(Hash["a" => 1]) { |k, v| [k, v] }   # !> TypeError: Hash.flat_map: the block must return an Array, got Tuple
```

## filter_map

`Hash.filter_map(x) { }`

各組についてブロックを呼び、nil と false 以外の結果を並べた新しい Array を返します。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.filter_map(h) { |k, v| v > 1 ? k : nil })   # => ["b", "c"]
```

## select, filter

`Hash.select(x) { }`

`Hash.filter(x) { }`

ブロックが真を返した組だけを持つ新しい Hash を返します（Ruby と同じく結果は Hash）。元の Hash は変わりません。キー・値の型は元と同じです。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.select(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
p(Hash.filter(h) { |k, v| k == "a" })   # => {"a" => 1}
p(h)                                 # => {"a" => 1, "b" => 2, "c" => 3}
```

## reject

`Hash.reject(x) { }`

ブロックが真を返した組を除いた新しい Hash を返します。元の Hash は変わりません。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.reject(h) { |k, v| v > 1 })   # => {"a" => 1}
```

## partition

`Hash.partition(x) { }`

ブロックが真を返した組と偽を返した組を、それぞれ `[k, v]` の Tuple の Array にして、2 要素の Tuple `[真の組, 偽の組]` で返します。多重代入で受けます。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
odd, even = Hash.partition(h) { |k, v| Integer.odd?(v) }
p(odd)                             # => [["a", 1], ["c", 3]]
p(even)                            # => [["b", 2]]
```

## group_by

`Hash.group_by(x) { }`

各組についてブロックを呼び、その結果をキー、同じ結果になった組 `[k, v]` の Tuple の Array を値とする新しい Hash を返します。ブロックの結果はキーにできる値でなければなりません。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
g = Hash.group_by(h) { |k, v| v % 2 }
p(g)                               # => {1 => [["a", 1], ["c", 3]], 0 => [["b", 2]]}
p(Hash.fetch(g, 0))                # => [["b", 2]]
```

## find, detect

`Hash.find(x) { }`

`Hash.detect(x) { }`

ブロックが最初に真を返した組 `[k, v]` を Tuple で返します。無ければ nil で、level 2 では nil のまま多重代入や添字に使うと報告されるので、`if` で確かめます。

```ruby
h = Hash["a" => 1, "b" => 2]
kv = Hash.find(h) { |k, v| v == 2 }
if kv
  k, v = kv
  p(k)                             # => "b"
end
p(Hash.detect(h) { |k, v| v == 9 })   # => nil
```

```ruby error
kv = Hash.find(Hash["a" => 1]) { |k, v| v == 1 }
k, v = kv                          # !> multiple assignment: argument 1 may be nil
```

## min_by, max_by

`Hash.min_by(x) { }`

`Hash.max_by(x) { }`

ブロックの結果が最小・最大になる組 `[k, v]` を Tuple で返します。空なら nil（level 2 で報告）。ブロックの結果同士は比べられなければならず、Integer と String などが混ざると実行時に `ArgumentError`。

```ruby
h = Hash["a" => 3, "b" => 1, "c" => 2]
p(Hash.min_by(h) { |k, v| v })     # => ["b", 1]
p(Hash.max_by(h) { |k, v| v })     # => ["a", 3]
p(Hash.max_by(Hash[]) { |k, v| v })   # => nil
```

```ruby error
Hash.min_by(Hash["a" => 1, "b" => "x"]) { |k, v| v }   # !> ArgumentError: Hash.min_by: cannot compare block results of types Integer, String
```

## sort_by

`Hash.sort_by(x) { }`

ブロックの結果の昇順に組を並べ、`[k, v]` の Tuple の Array で返します（Ruby と同じく Hash ではなく Array）。比べられない結果の組は `ArgumentError`。降順にはブロックで符号を反転するか `Array.reverse` を使います。Tuple を返せば辞書順です（[Tuple](Tuple.md)）。

```ruby
h = Hash["a" => 3, "b" => 1, "c" => 2]
p(Hash.sort_by(h) { |k, v| v })    # => [["b", 1], ["c", 2], ["a", 3]]
p(Hash.sort_by(h) { |k, v| -v })   # => [["a", 3], ["c", 2], ["b", 1]]
```

```ruby error
Hash.sort_by(Hash["a" => 1, "b" => "x"]) { |k, v| v }   # !> ArgumentError: Hash.sort_by: cannot compare block results of types Integer, String
```

## any?, all?, none?

`Hash.any?(x) { }`

`Hash.all?(x) { }`

`Hash.none?(x) { }`

ブロックが真を返す組が 1 つでもあるか（`any?`）、すべての組で真か（`all?`）、1 つも無いか（`none?`）。ブロックは必須です（Ruby のブロック無しの形はなく、静的なエラー。空かどうかは `empty?`）。空の Hash では `any?` は false、`all?` と `none?` は true。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.any?(h) { |k, v| v > 1 })   # => true
p(Hash.all?(h) { |k, v| v > 1 })   # => false
p(Hash.none?(h) { |k, v| v > 5 })  # => true
```

```ruby error
p(Hash.any?(Hash["a" => 1]))       # !> Hash.any? requires a block
```

## one?

`Hash.one?(x) { }`

ブロックが真を返す組がちょうど 1 つなら true。ブロックは必須です。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.one?(h) { |k, v| v == 2 })  # => true
p(Hash.one?(h) { |k, v| v > 0 })   # => false
```

## sum

`Hash.sum(x, [Integer|Float|Rational|Complex]) { }`

各組についてブロックを呼び、その結果を `init`（省略時 0）に足し合わせます。ブロックは必須で（Ruby のブロック無しの形はありません）、`init` は数値に限ります（String を渡すのは静的に `type` の問題。文字列の連結は `reduce`）。結果の型は `init` とブロックの結果の数値型から決まります。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.sum(h) { |k, v| v })        # => 3
p(Hash.sum(h, 0.5) { |k, v| v })   # => 3.5
p(Hash.sum(Hash[]) { |k, v| 1 })   # => 0
```

```ruby error
Hash.sum(Hash["a" => "x"], "") { |k, v| v }   # !> argument 2 must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Hash.reduce(x, Any) { }`

`Hash.inject(x, Any) { }`

初期値 `init` から始めて、各組について `|acc, (k, v)|` でブロックを呼び、その結果を次の `acc` にして、最後の結果を返します。初期値は必須です（Ruby の省略形はありません）。結果の型は `init` とブロックの結果の型の和です。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.reduce(h, 0) { |acc, (k, v)| acc + v })    # => 3
p(Hash.inject(h, "") { |acc, (k, v)| acc + k })   # => "ab"
```

## transform_values

`Hash.transform_values(x) { }`

各値にブロックを適用した結果を値とする新しい Hash を返します。ブロックは値だけを受け取ります。キーはそのまま、元の Hash は変わりません。結果の値の型はブロックの結果の型なので、型を変える変換はこちらを使います（in-place の `transform_values!` と違って元の型と和になりません）。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.transform_values(h) { |v| Integer.to_s(v) })   # => {"a" => "1", "b" => "2"}
p(h)                                                 # => {"a" => 1, "b" => 2}
```

## transform_keys

`Hash.transform_keys(x) { }`

各キーにブロックを適用した結果をキーとする新しい Hash を返します。ブロックはキーだけを受け取り、その結果はキーにできる値でなければなりません（`TypeError`）。2 つのキーが同じ結果になったときは後の組の値が残ります。元の Hash は変わりません。Ruby の Hash 引数の形（`transform_keys(a: :b)`）はありません。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.transform_keys(h) { |k| String.to_sym(k) })   # => {a: 1, b: 2}
p(Hash.transform_keys(Hash["a" => 1, "A" => 2]) { |k| String.downcase(k) })   # => {"a" => 2}
```

## transform_values!

`Hash.transform_values!(x) { }`

各値をブロックの結果に置き換え、Hash 自身を返します。検査器は Hash に 1 つの値の型を与えるので、型を変える変換（Integer から String）をするとその Hash の値の型は `Integer | String` の和になり、以後どちらか片方にしか合わない操作が `type`（partial）として報告されます。型を変えるなら新しい Hash を作る `transform_values` を使います。

```ruby
h = Hash["a" => 1, "b" => 2]
r = Hash.transform_values!(h) { |v| v * 10 }
p(h)                               # => {"a" => 10, "b" => 20}
p(Kernel.equal?(r, h))             # => true
```

```ruby error
h = Hash["a" => 1]
Hash.transform_values!(h) { |v| Integer.to_s(v) }   # !> argument 1 must be Integer, but can be String
```

## transform_keys!

`Hash.transform_keys!(x) { }`

各キーをブロックの結果に置き換え、Hash 自身を返します。結果はキーにできる値でなければなりません（`TypeError`）。`transform_values!` と同じく、型を変える変換はキーの型を和にするので、`Array.each(Hash.keys(h))` などで片方の型の操作を使うと `type` の問題です。型を変えるなら `transform_keys`。

```ruby
h = Hash["a" => 1, "b" => 2]
Hash.transform_keys!(h) { |k| String.upcase(k) }
p(h)                               # => {"A" => 1, "B" => 2}
```

```ruby error
h = Hash["a" => 1]
Hash.transform_keys!(h) { |k| String.to_sym(k) }   # !> argument 1 must be String, but can be Symbol
```

## merge

`Hash.merge(x, Hash)`

2 つの Hash の組を合わせた新しい Hash を返します。同じキーは第 2 引数の値が勝ちます。どちらも変わりません。第 2 引数は Hash でなければならず、Record（`{a: 2}`）を渡すのは静的に `type` の問題です。Ruby のブロック形（衝突時の値を決める）はありません。結果のキー・値の型は両方の和です。

```ruby
a = Hash["a" => 1, "b" => 2]
b = Hash["b" => 20, "c" => 3]
p(Hash.merge(a, b))                # => {"a" => 1, "b" => 20, "c" => 3}
p(a)                               # => {"a" => 1, "b" => 2}
```

```ruby error
p(Hash.merge(Hash["a" => 1], {a: 2}))   # !> Hash.merge: argument 2 must be Hash, but is {a: Integer}
```

## merge!, update

`Hash.merge!(x, Hash)`

`Hash.update(x, Hash)`

第 2 引数の組を第 1 引数の Hash に書き込み（同じキーは上書き）、第 1 引数自身を返します。検査器は第 1 引数のキー・値の型に第 2 引数の型を加えます。ブロック形はありません。

```ruby
h = Hash["a" => 1]
Hash.merge!(h, Hash["b" => 2])
p(Hash.update(h, Hash["a" => 10])) # => {"a" => 10, "b" => 2}
p(h)                               # => {"a" => 10, "b" => 2}
```

## replace

`Hash.replace(x, Hash)`

第 1 引数の中身をすべて第 2 引数の組に置き換え、第 1 引数自身を返します。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.replace(h, Hash["z" => 26]))   # => {"z" => 26}
p(h)                                  # => {"z" => 26}
```

## compact

`Hash.compact(x)`

値が nil の組を除いた新しい Hash を返します。結果の値の型から nil が取れます。

```ruby
h = Hash["a" => 1, "b" => nil]
p(Hash.compact(h))                 # => {"a" => 1}
p(h)                               # => {"a" => 1, "b" => nil}
```

## compact!

`Hash.compact!(x)`

値が nil の組をその場で取り除き、Hash 自身を返します。1 つも取り除かなかったときは nil（Ruby と同じ）で、戻り値をそのまま使うと level 2 で報告されます。

```ruby
h = Hash["a" => 1, "b" => nil]
p(Hash.compact!(h))                # => {"a" => 1}
p(Hash.compact!(h))                # => nil
```

```ruby error
p(Hash.size(Hash.compact!(Hash["a" => 1])))   # !> Hash.size: argument 1 may be nil
```

## slice

`Hash.slice(x, *Any)`

列挙したキーの組だけを持つ新しい Hash を返します。無いキーは無視され、順序は列挙した順です。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.slice(h, "c", "a", "zz"))   # => {"c" => 3, "a" => 1}
```

## except

`Hash.except(x, *Any)`

列挙したキーの組を除いた新しい Hash を返します。無いキーは無視されます。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.except(h, "a", "zz"))       # => {"b" => 2, "c" => 3}
```

## invert

`Hash.invert(x)`

値をキー、キーを値にした新しい Hash を返します。値はキーにできるものでなければならず（`TypeError`）、同じ値が複数あれば後の組が残ります。結果のキーの型と値の型は元の値の型とキーの型です。

```ruby
p(Hash.invert(Hash["a" => 1, "b" => 2]))        # => {1 => "a", 2 => "b"}
p(Hash.invert(Hash["a" => 1, "b" => 1]))        # => {1 => "b"}
```

```ruby error
Hash.invert(Hash["a" => /x/])      # !> TypeError: Hash.invert: Regexp cannot be a Hash key or Set element
```

## delete

`Hash.delete(x, Any)`

キー `k` の組を取り除き、その値を返します。無ければ nil で、level 2 で報告されます（default は見ません）。Ruby のブロック形はありません。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.delete(h, "a"))             # => 1
p(Hash.delete(h, "zz"))            # => nil
p(h)                               # => {"b" => 2}
```

```ruby error
h = Hash["a" => 1]
p(Hash.delete(h, "a") + 1)         # !> the operands may be nil
```

## delete_if

`Hash.delete_if(x) { }`

ブロックが真を返した組をその場で取り除き、Hash 自身を返します（取り除かなくても nil にはなりません。`reject!` との違い）。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.delete_if(h) { |k, v| v > 1 })   # => {"a" => 1}
p(Hash.delete_if(h) { |k, v| false })   # => {"a" => 1}
```

## keep_if

`Hash.keep_if(x) { }`

ブロックが真を返した組だけをその場で残し、Hash 自身を返します（変化が無くても nil にはなりません。`select!` との違い）。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.keep_if(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
```

## select!, filter!

`Hash.select!(x) { }`

`Hash.filter!(x) { }`

ブロックが真を返した組だけをその場で残し、Hash 自身を返します。1 つも取り除かなかったときは nil（Ruby と同じ）で、戻り値をそのまま使うと level 2 で報告されます。常に Hash を返す形は `keep_if`。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.select!(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
p(Hash.filter!(h) { |k, v| v > 1 })   # => nil
p(h)                                  # => {"b" => 2, "c" => 3}
```

## reject!

`Hash.reject!(x) { }`

ブロックが真を返した組をその場で取り除き、Hash 自身を返します。1 つも取り除かなかったときは nil（level 2 で報告）。常に Hash を返す形は `delete_if`。

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.reject!(h) { |k, v| v > 2 })   # => {"a" => 1, "b" => 2}
p(Hash.reject!(h) { |k, v| v > 5 })   # => nil
```

## shift

`Hash.shift(x)`

最初に挿入された組を取り除き、`[k, v]` の Tuple で返します。空なら nil（default は見ません。level 2 で報告）。

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.shift(h))                   # => ["a", 1]
p(h)                               # => {"b" => 2}
Hash.shift(h)
p(Hash.shift(h))                   # => nil
```

## clear

`Hash.clear(x)`

すべての組を取り除き、Hash 自身（空）を返します。default はそのままです。

```ruby
h = Hash["a" => 1]
p(Hash.clear(h))                   # => {}
p(Hash.empty?(h))                  # => true
```

## ==, !=

`Hash.==(x, Any)`

`Hash.!=(x, Any)`

2 つの Hash が同じキーの集合を持ち、各キーの値が `==` で等しいときに true（`!=` はその否定）。挿入順は関係ありません。default も見ません。演算子 `h == nil` は false ですが、関数形 `Hash.==(h, nil)` は右側が Hash でないと実行時に `TypeError` です。Record `{a: 1}` と `Hash[a: 1]` は型が違うので等しくありません。

```ruby
a = Hash["a" => 1, "b" => 2]
p(a == Hash["b" => 2, "a" => 1])   # => true
p(a != Hash["a" => 1])             # => true
p(Hash.==(a, Hash[]))              # => false
p(Hash[a: 1] == {a: 1})            # => false
```
