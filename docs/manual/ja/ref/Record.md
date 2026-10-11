# Record

Record はフィールド名と値の組の集まりで、リテラル `{x: 1, y: "a"}` が作ります（[値と型](../03-values.md)）。Ruby ではこの書き方は Hash ですが、Sake では **Record であって Hash ではありません**。Hash は `Hash[x: 1]` で作ります（[Hash](Hash.md)）。`{}`（空）と `{"a" => 1}`（`=>` 形）は静的に拒否されます。

Record の型はその (フィールド名, 型) の集合で、`{x: Integer, y: String}` のように表されます。同じ集合を持つ Record は同じ型です。フィールドの順序は型に関係なく、`{y: 2, x: 1}` は `{x: 1, y: 2}` と表示されます。クラスのインスタンスとは別物です（クラスは名前で、Record 型は構造で区別されます。[クラス](../07-classes.md)）。

フィールドはパターンで読みます: `r => {x:, y: name}` は局所変数 `x` にフィールド `x`、`name` にフィールド `y` を束縛します。一部のフィールドだけを挙げてもよく、`case r in {x:} ... end` も同じパターンです。無いフィールドを挙げると静的に `type` の問題（実行時なら `KeyError`）、Record でない値に当てても静的に `type` の問題（実行時なら `TypeError`）です。フィールドへの書き込み（`r.x = v`、`r[:x] = v`）はまだありません（どちらも静的に拒否。`Indexable.[]=` は Record を受け付けません）。

Record に使える演算子は `==`、`!=` です（同じフィールドの集合を持ち、各値が等しいとき true）。添字 `r[:x]` はありません。

この章の 3 つの操作は、Record をデータとして扱う（任意の Record を歩く）ためのものです。引数の型は `Any` で、Record 以外を渡すと実行時に `TypeError` です。結果のフィールド順はフィールド名の順（表示と同じ）です。

## keys

`Record.keys(Any)`

フィールド名を Symbol にした新しい Array を返します。順序はフィールド名の順で、リテラルに書いた順ではありません。

```ruby
r = {x: 1, y: "a"}
p(Record.keys(r))                  # => [:x, :y]
p(Record.keys({y: 2, x: 1}))       # => [:x, :y]
```

```ruby error
p(Record.keys(Hash[x: 1]))         # !> TypeError: Record.keys: argument 1 must be a Record, got Hash
```

## values

`Record.values(Any)`

フィールドの値を `keys` と同じ順に並べた新しい Array を返します。Record とは独立で、Array の方は伸ばせます。要素の型は各フィールドの型の和です。

```ruby
r = {x: 1, y: "a"}
vs = Record.values(r)
p(vs)                              # => [1, "a"]
Array.push(vs, 3)
p(r)                               # => {x: 1, y: "a"}
```

## to_h

`Record.to_h(Any)`

フィールド名を Symbol キーとする新しい Hash を返します。検査器にとってキーの型は Symbol、値の型は各フィールドの型の和なので、フィールドの型が違う Record では `h[:x]` の値をそのまま計算に使うと `type` の問題になります（Hash は値の型を 1 つしか持てないため）。フィールドの型がそろっていれば普通の Hash として使えます。入れ子の Record は Record のまま値になります。

```ruby
r = {x: 1, y: 2}
h = Record.to_h(r)
p(h)                               # => {x: 1, y: 2}
p(Hash.fetch(h, :x) + Hash.fetch(h, :y))   # => 3
p(Record.to_h({name: "a", pos: {x: 1}}))   # => {name: "a", pos: {x: 1}}
```

```ruby error
h = Record.to_h({x: 1, y: "a"})
p(Hash.fetch(h, :x) + 1)           # !> which the left operand's type does not support
```
