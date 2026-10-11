# 関数とブロック

この章は `def` で定義する関数と、呼び出しに渡すブロックを述べます。どちらにも型は書きません。呼び出し先は実行前に決まるので、引数の数とキーワードの名前は実行前に検査されます。

## 関数

関数は `def` で定義し、引数の数とキーワード名で呼び出しが検査されます。1 行の `def f(x) = 式` と、`end` で閉じる形のどちらも書けます。Ruby のスタイルと同じく、1 行の形は短い式に使い、何段かある本体は `def ... end` に書きます。

```ruby
def area(w, h) = w * h
def describe(n)
  return "negative" if n < 0
  Integer.to_s(n)
end
p(area(3, 4))        # => 12
p(describe(-1))      # => "negative"
p(describe(7))       # => "7"
```

### 位置引数と既定値

必須の位置引数を先に、既定値付きの省略可能な引数をその後に並べます。既定値は Ruby と同じく、呼び出しがその引数を与えなかったときに、前の引数の後で評価されます。前の引数を使えます。

```ruby
def f(a, b = 1, c = b + 1) = [a, b, c]
p(f(10))             # => [10, 1, 2]
p(f(10, 5))          # => [10, 5, 6]
p(f(10, 5, 0))       # => [10, 5, 0]
```

- **数。** 呼び出しは、必須の引数の数から全部の数までの引数を与えます。合わない数は実行前のエラーです。
- **順序。** 引数は書いた順に評価されます。

```ruby error
def area(w, h) = w * h
p(area(3))           # !> wrong number of arguments for area (given 1, expected 2)
```

### キーワード引数

キーワード引数は引数の列の最後に置きます。必須（`w:`）か既定値付き（`h: w`）で、省略可能な位置引数と自由に混ぜられます。

```ruby
def greet(name, greeting = "Hello", punct: "!") = "#{greeting}, #{name}#{punct}"
p(greet("Ruby"))                     # => "Hello, Ruby!"
p(greet("Ruby", punct: "?"))         # => "Hello, Ruby?"
p(greet("Ruby", "Hi", punct: "."))   # => "Hi, Ruby."
punct = "!!"
p(greet("Sake", punct:))             # => "Hello, Sake!!"
```

呼び出し先は実行前に分かるので、検査器は `k: v` を名前で引数に届けます。次はどれも実行前のエラーです。

- 未知のキーワード、同じキーワードの重複、必須キーワードの欠落。
- キーワード引数の無い関数への `k: v`。暗黙の Hash 引数は無いので、Hash が欲しければ `Hash[k: v]`、Record が欲しければ `{k: v}` と書きます。

```ruby error
def size(w:, h: w) = w * h
p(size(w: 3, d: 2))  # !> size has no keyword parameter `d`
p(size(h: 3))        # !> size needs keyword argument `w:`
```

- **`f(k:)`** は Ruby と同じく変数 `k` を渡します。
- **組み込み。** いくつかの組み込みも Ruby のキーワードを取り、同じく検査されます: `Time.at(t, in: "+09:00")`、`Dir.glob(pat, base: dir)`。リファレンスでは `[k: T]` と書かれます。

### `*rest`: 残りの位置引数

省略可能な引数の後の `*rest` は、残りの位置引数を新しい Array に集めます。`*rest` を持つ関数は任意個の引数で呼べます。呼び出しの側では `*xs` が Tuple か Array を広げて渡します。

```ruby
def join(sep, *parts) = Array.join(parts, sep)
p(join("-"))                  # => ""
p(join("-", "a", "b", "c"))   # => "a-b-c"
xs = ["x", "y"]
p(join("+", *xs))             # => "x+y"
```

- **要素の型。** `rest` は 1 つの Array なので、要素は 1 つの型です。すべての呼び出しが渡すものの和になります。位置ごとの型を保ちたければ Tuple を 1 つ渡します: `notify("stock", ["AAPL", 120])` と呼び、関数の中で `name, price = event` と分けます。
- **組む場所。** 呼び出し先が分かるので、Array は呼び出しの場で組まれます。
- **順序。** 引数は必須、省略可能、`*rest`、キーワード、`**opts` の順です。`*rest` の後の位置引数と、名前の無い `*` は実行前のエラーです。
- **`*xs` の行き先。** `*xs` は `*rest` と、任意個の引数を取る組み込み（`puts`、`format`、`Array[...]`、`Array.push` など）にだけ渡せます。必須や省略可能な引数を `*xs` で埋めることはできません。

```ruby error
def f(*rest, z) = z   # !> parameters after `*rest` are not supported: required, optional, `*rest`, keywords, `**opts`, in that order
```

### `**opts`: 残りのキーワード

最後の `**opts` は、引数の名前ではないキーワードを Symbol キーの Hash に集めます。これも呼び出しの場で組まれます。

```ruby
def tag(name, **opts) = [name, opts]
p(tag("div"))                            # => ["div", {}]
p(tag("div", id: "main", hidden: true))  # => ["div", {id: "main", hidden: true}]
```

- **綴り間違い。** `**opts` を持つ関数はどのキーワードも受けるので、綴り間違いはそこではエラーになりません。
- **名前の無い `**`** は実行前のエラーです。
- **渡し直し。** 集めたキーワードを `f(**opts)` と次の関数に渡すことはまだできません。

### ブロック引数 `&b`

`&b`（または `&` だけ）は、関数が受けたブロックを別の呼び出しに渡すためだけの引数です。「ブロック」の節で述べます。

### mixin 関数の定義の一致

module の mixin 関数は第 1 引数の型の定義にディスパッチします（[プログラムの構造と名前解決](02-program.md)）。そのため、各型の定義は引数の数、キーワードの名前、`*rest` / `**opts` の有無が一致しなければなりません。一致しなければ呼び出しの場で実行前のエラーです。

```ruby error
module Shape
  def area(s) = raise NotImplementedError
end
class Sq
  include Shape
  attr_reader side
  def area(s) = @side * @side
end
class Rect
  include Shape
  attr_reader w, h
  def area(r, scale) = @w * @h * scale
end
p(Shape.area(Sq.new(2)))   # !> Shape.area dispatches to Rect.area, whose arguments or block differ from Shape.area
```

### 返り値

関数の値は最後の式の値か、`return expr` の値です。`return a, b` は Tuple `[a, b]` を返すので、呼び出し側で `a, b = f(...)` と受けられます。

```ruby
def minmax(xs) = return Array.min(xs), Array.max(xs)
lo, hi = minmax(Array[3, 1, 2])
p([lo, hi])          # => [1, 3]
```

### 多相

関数は多相です。型を書かないので、その中の操作が受け付けるどんな引数でも動きます。型エラーは、失敗した操作の行で表面化します。検査器はその行を報告し、どの呼び出しからそこに届いたかをヒントに出します。

```ruby
def twice(x) = x + x
p(twice(2))          # => 4
p(twice("ab"))       # => "abab"
p(twice(1.5))        # => 3.0
```

```ruby error
def twice(x) = x + x   # !> Arithmetic.+: the operands are (:a, :a), which the left operand's type does not support
p(twice(:a))
```

### ローカル変数

各関数は自分のスコープを持ちます。トップレベルのローカル変数には触れません。

```ruby error
count = 10
def bump = count + 1   # !> undefined local variable or function `count`
```

Ruby と同じく、代入が字面上は前にあって、まだ実行されていないローカルを読むと `nil` です。

```ruby
def f
  x = 1 if false
  p(x)               # => nil
end
f
```

### 再帰

再帰は可能です。深さが 10,000 を超えると `SystemStackError` になります。`bin/sake` は大きなスタックのスレッドでプログラムを走らせるので、Ruby のスタックではなくこの上限が効きます。長いバックトレースは途中が省略されます。

```ruby
def fact(n) = n <= 1 ? 1 : n * fact(n - 1)
p(fact(20))          # => 2432902008176640000
def down(n) = n == 0 ? 0 : down(n - 1)
p(down(9_000))       # => 0
```

```ruby error
def down(n) = n == 0 ? 0 : down(n - 1)
p(down(20_000))      # !> SystemStackError: stack level too deep
```

## ブロック

ブロックは、組み込みの操作か、`yield` するユーザ関数に渡します。繰り返しの多くは `Array.each` などのブロックを取る操作で書きます。

```ruby
xs = Array[1, 2, 3]
p(Array.map(xs) { |x| x * 2 })      # => [2, 4, 6]
Hash.each(Hash[a: 1, b: 2]) do |k, v|
  puts "#{k}=#{v}"                  # => a=1
                                    # => b=2
end
Integer.times(3) { p it }           # => 0
                                    # => 1
                                    # => 2
```

### 値ではない

ブロックは第二級です。変数に格納することも、関数から返すこともできません。`proc`、`lambda`、`->` はありません。

```ruby error
f = proc { |x| x }   # !> undefined function `proc`
```

### 引数

`|a, b|` に名前を並べます。`it` と `_1` … `_9` は Ruby と同じです。

```ruby
p(Array.map(Array[1, 2]) { _1 * 10 })   # => [10, 20]
p(Array.map(Array[1, 2]) { it + 1 })    # => [2, 3]
```

### 分解

ブロックが 2 つ以上の引数を宣言し、1 つの Tuple か Array を受けると、その要素が引数になります。足りないものは nil、余りは捨てます。Ruby と同じです。引数自身も `( )` で分解できます。

```ruby
pairs = Array[["a", 1], ["b", 2]]
Array.each(pairs) { |name, n| p("#{name}=#{n}") }              # => "a=1"
                                                               # => "b=2"
Array.each_with_index(pairs) { |(name, n), i| p([i, name]) }   # => [0, "a"]
                                                               # => [1, "b"]
p(Array.inject(pairs, 0) { |acc, (k, v)| acc + v })            # => 3
Array.each(Array[[1, 2]]) { |a, b, c| p([a, b, c]) }           # => [1, 2, nil]
```

### rest 引数

`|a, *rest|`（`|a, *rest, z|`、`|*all|` も）は残りの引数、または分解した Tuple / Array の残りの要素を新しい Array に集めます。`a, *rest = x` と同じです。`|*all|` だけでは分解しません。

```ruby
Array.each(Array[[1, 2, 3]]) { |a, *rest| p([a, rest]) }      # => [1, [2, 3]]
Array.each(Array[[1, 2, 3]]) { |a, *rest, z| p([a, rest, z]) } # => [1, [2], 3]
Array.each(Array[[1, 2, 3]]) { |*all| p(all) }                # => [[1, 2, 3]]
```

### 引数の数

引数の無いブロックは渡された引数を無視します。それ以外で引数の数が合わないブロック呼び出しは、実行時の `ArgumentError` です。rest 引数があれば、他の引数より少ないときだけです。

```ruby
Integer.times(2) { puts "hi" }      # => hi
                                    # => hi
```

```ruby error
Array.each_with_index(Array["a"]) { |x| p(x) }   # !> ArgumentError: block takes 1 parameter(s) but was given 2
```

### スコープ

ブロックは囲むローカル変数を読み書きできます。

```ruby
sum = 0
Array.each(Array[1, 2, 3]) { |x| sum += x }
p(sum)               # => 6
```

### `yield` と省略可能なブロック

`yield(args...)` は今の関数に渡されたブロックを呼びます。関数の外の `yield` は構文エラーです。`yield` を含む関数は、呼び出しごとにブロックを受けなければなりません。

```ruby error
def each_twice(xs)
  Array.each(xs) { |x| yield x; yield x }
end
each_twice(Array[1, 2])   # !> each_twice uses `yield` but no block is given
```

`block_given?` は今の関数がブロックを受けたかを言います。それを検査する関数はブロック無しで呼べます。

```ruby
def info(msg = nil) = puts(block_given? ? yield : msg)
info("plain")                 # => plain
info { "from block" }         # => from block
```

- **分岐の解析。** 検査器は呼び出しごとにブロックの有無を知っているので、取られる分岐だけを解析します。`&&`、`||`、`!` の中の `block_given?` も同じです。
- **届かないはずの `yield`。** ブロック無しで届く `yield`（またはブロックが要る呼び出しへの `&b`）は `type` レベルのエラーです。実行時は `LocalJumpError` で、rescue はできません。

### ブロックを渡す: `&b`

`def f(xs, &b) = Array.map(xs, &b)` は自分のブロックを別の呼び出しに渡します。`&` だけでも書けます。`b` は `&b` としてしか使えません。

```ruby
def twice(xs, &b) = Array.map(xs, &b)
p(twice(Array[1, 2]) { |x| x * 2 })      # => [2, 4]
def each_pair(h, &) = Hash.each(h, &)
each_pair(Hash[a: 1]) { |k, v| p([k, v]) }   # => [:a, 1]
```

- **ブロック無しの呼び出し。** Ruby と同じく、ブロックを渡すだけの関数はブロック無しで呼べます。その先のブロックが要る呼び出しに何も届かなければ、`type` レベルのエラーです。
- **`break`。** 渡されたブロックの中の `break` は、ブロックが書かれた呼び出し（上の `twice(...)`）を終えます。

```ruby error
def twice(xs, &b) = Array.map(xs, &b)   # !> the block passed on is missing here, and this call needs one
p(twice(Array[1, 2]))
```

### `next`・`break`・`return`

Ruby と同じ 3 つの抜け方があります。

| 書き方 | 終えるもの | 値 |
|---|---|---|
| `next [v]` | 今のブロック呼び出し | `v`（既定 `nil`）がブロックの値 |
| `break [v]` | ブロックを渡した呼び出し | `v`（既定 `nil`）がその呼び出しの値 |
| `return [v]` | 囲む**関数** | `v` が関数の値 |

```ruby
xs = Array[1, 2, 3, 4]
p(Array.map(xs) { |x| next 0 if x % 2 == 0; x })   # => [1, 0, 3, 0]
p(Array.each(xs) { |x| break x if x > 2 })          # => 3
p(Array.each(xs) { |x| x })                         # => [1, 2, 3, 4]
def first_big(xs)
  Array.each(xs) { |x| return x if x > 2 }
  nil
end
p(first_big(xs))                                    # => 3
```

- **`while` の中。** ブロックの中の `while` の中では、`break` は `while` を抜けます。
- **型。** 検査器は `break` の値を呼び出しの結果型に加えます。

> [!NOTE]
> ブロックの引数とローカルは、囲む関数のフレームに属します。ブロックを**スレッドで後から**走らせる関数（concurrent-ruby 風の `post { ... }`）に渡すと、スレッドが走る時点の値（ループ変数の最後の値）を読みます。Ruby ではブロック引数は呼び出しごとに新しい値です。スレッドを使わない限り違いは観測できません（`TODO.md`）。

## once

`once { ... }` はブロックの値を与えます。ブロックはプログラムのその場所に最初に到達したときに走り、その後そこを通るたびに、プログラム全体・すべてのスレッドで同じ値を返します。値の定数が無い Sake で、表や名前付きの値を 1 度だけ計算する方法です。

```ruby
def table = once { puts "computing"; Array.map(Array[1, 2, 3]) { |i| i * i } }
p(table)             # => computing
                     # => [1, 4, 9]
p(table)             # => [1, 4, 9]
Array.push(table, 16)
p(table)             # => [1, 4, 9, 16]
```

- **共有。** 値は Ruby の定数と同じく共有されます。上のように、`once` が保持する Array は変えられます。
- **再入。** 計算中に自分の `once` に再び到達するブロックはプログラムの誤りで、`SystemStackError` です。
- **型。** 実行前の検査では、その型はそれを計算しうるすべての呼び出しでのブロックの結果の和です。

```ruby error
def loop_once = once { loop_once }
p(loop_once)         # !> SystemStackError: once: the block reached its own once again while computing it
```
