# Symbol

Symbol は名前そのものを値にしたもので、リテラル `:name` が作ります（空白などを含む名前は `:"hello world"`。[値と型](../03-values.md)）。同じ名前の Symbol は常に同じ 1 つの値で、Hash のキー（`Hash[name: 1]` のラベルは Symbol キー）や `case`/`in` の分岐の目印に使います。String から作るには `String.to_sym(s)`（`String.intern`）、String に戻すには `Symbol.to_s`。Ruby の `%i[a b]` はまだ使えず（静的に拒否）、Symbol の Array は `Symbol[:a, :b]` と書きます。

Ruby の `Symbol#to_proc`（`&:name`）はありません。ブロックは値ではないので、`Array.map(xs, &:to_s)` は静的に拒否され、`{ |x| Integer.to_s(x) }` と書きます（[関数とブロック](../04-functions.md)）。

`case s in :a ... in :b ... end` のようにリテラルで分岐するとき、`s` がリテラル以外から来た Symbol（`String.to_sym` の結果など）なら、`--strict=3` は取りこぼす値があることを `exhaustive` として報告します（`else` を足します。[制御構造](../06-control.md)）。

Symbol に使える演算子は `==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>` で、比較は Symbol 同士に限ります（右側が String や Integer だと `<` などは静的に `type` の問題）。`:a == "a"` は false で、関数形 `Symbol.==(:a, "a")` も false です。`Symbol.<(x, y)` などはその演算子の関数形です（[演算子と添字](../05-operators.md)）。

文字列風の操作（`upcase`、`slice`、`match`、`start_with?` など）は、名前を String として処理した結果を返します。Symbol を返すもの（`upcase` など）と String を返すもの（`slice`）があります。どれも Symbol 自体を変えません（Symbol は不変です）。

## Symbol[]

`Symbol[*Any]`

**Symbol の Array** を作ります。`Integer[]` と同じ型付き Array で、要素はすべて Symbol でなければならず、`Array.push` などの書き込みも毎回検査されます。Symbol 以外は静的に `type` の問題、実行時は `TypeError`。空の Symbol の Array は `Symbol[]`。

```ruby
syms = Symbol[:a, :b]
Array.push(syms, :c)
p(syms)                            # => [:a, :b, :c]
p(Array.size(Symbol[]))            # => 0
```

```ruby error
Array.push(Symbol[:a], "x")        # !> Array.push: an element must be Symbol, but is String
```

## to_s, id2name, name

`Symbol.to_s(x)`

`Symbol.id2name(x)`

`Symbol.name(x)`

名前を String で返します。`to_s` と `id2name` は毎回新しい（書き換えられる）String を返し、`name` は Symbol が持つ名前そのものを返すので、Ruby と同じく凍結されていて、`String.upcase!` などで書き換えると `TypeError` です。

```ruby
p(Symbol.to_s(:hello))             # => "hello"
p(Symbol.id2name(:"with space"))   # => "with space"
s = Symbol.to_s(:abc)
String.upcase!(s)
p(s)                               # => "ABC"
p(Symbol.name(:abc))               # => "abc"
```

```ruby error
s = Symbol.name(:abc)
String.upcase!(s)                  # !> TypeError: String.upcase!: cannot change this String in place
```

## to_sym, intern

`Symbol.to_sym(x)`

`Symbol.intern(x)`

その Symbol 自身を返します（Ruby と同じ）。String から Symbol を作るのは `String.to_sym`、`String.intern` です。

```ruby
p(Symbol.to_sym(:a))               # => :a
p(Symbol.intern(:a) == :a)         # => true
p(String.to_sym("a") == :a)        # => true
```

## length, size

`Symbol.length(x)`

`Symbol.size(x)`

名前の文字数（Integer。バイト数ではありません）。

```ruby
p(Symbol.length(:hello))           # => 5
p(Symbol.size(:日本))              # => 2
```

## empty?

`Symbol.empty?(x)`

名前が空（`:""`）なら true。

```ruby
p(Symbol.empty?(:""))              # => true
p(Symbol.empty?(:a))               # => false
```

## encoding

`Symbol.encoding(x)`

名前のエンコーディングの名前を String で返します（Ruby は Encoding オブジェクトを返します）。ASCII だけの名前は `"US-ASCII"`、それ以外は `"UTF-8"`。

```ruby
p(Symbol.encoding(:hello))         # => "US-ASCII"
p(Symbol.encoding(:日本))          # => "UTF-8"
```

## upcase, downcase, capitalize, swapcase

`Symbol.upcase(x)`

`Symbol.downcase(x)`

`Symbol.capitalize(x)`

`Symbol.swapcase(x)`

名前を大文字に・小文字に・先頭だけ大文字（残りは小文字）に・大小反転にした新しい Symbol を返します。Ruby の `String` の同名の操作と同じで、Unicode の文字も変換されます。オプション引数（`:ascii` など）はありません。

```ruby
p(Symbol.upcase(:hello))           # => :HELLO
p(Symbol.downcase(:HeLLo))         # => :hello
p(Symbol.capitalize(:hello_world)) # => :Hello_world
p(Symbol.swapcase(:HeLLo))         # => :hEllO
p(Symbol.downcase(:ÀB))            # => :àb
```

## succ, next

`Symbol.succ(x)`

`Symbol.next(x)`

名前を Ruby の `String#succ` で 1 つ進めた新しい Symbol（`:a` → `:b`、`:az` → `:ba`、`:zz` → `:aaa`、`:a9` → `:b0`）。

```ruby
p(Symbol.succ(:a))                 # => :b
p(Symbol.next(:az))                # => :ba
p(Symbol.succ(:zz))                # => :aaa
p(Symbol.succ(:a9))                # => :b0
```

## start_with?, end_with?

`Symbol.start_with?(x, String)`

`Symbol.end_with?(x, String)`

名前が String `s` で始まる・終わるなら true。引数は String で、Symbol を渡すのは静的に `type` の問題です（Ruby の複数引数や Regexp の形はありません）。

```ruby
p(Symbol.start_with?(:hello, "he"))   # => true
p(Symbol.end_with?(:hello, "lo"))     # => true
p(Symbol.start_with?(:hello, "x"))    # => false
```

```ruby error
p(Symbol.start_with?(:abc, :a))    # !> Symbol.start_with?: argument 2 must be String, but is :a
```

## slice

`Symbol.slice(x, Integer, [Integer])`

名前の一部を String で返します。`slice(s, i)` は位置 `i` の 1 文字（負の値は末尾から）、`slice(s, i, n)` は位置 `i` から `n` 文字。範囲外なら nil（Ruby の `String#slice` と同じで、`i` が長さに等しいときの `slice(s, i, n)` は `""`）。結果は nil になりうるので、そのまま使うと level 2 で報告されます。Range や String を添字にする形はありません（静的に `type` の問題）。

```ruby
p(Symbol.slice(:hello, 1))         # => "e"
p(Symbol.slice(:hello, -1))        # => "o"
p(Symbol.slice(:hello, 1, 3))      # => "ell"
p(Symbol.slice(:hello, 10))        # => nil
p(Symbol.slice(:abc, 3, 1))        # => ""
```

```ruby error
p(Symbol.slice(:abc, 0..1))        # !> Symbol.slice: argument 2 must be Integer, but is Range[Integer]
```

## match

`Symbol.match(x, Regexp|String)`

名前にパターンを当て、最初に一致した MatchData を返します。一致しなければ nil（level 2 で報告）。パターンが String なら正規表現のソースとして扱います（Ruby と同じ）。

```ruby
m = Symbol.match(:hello, /l+/)
p(m)                               # => #<MatchData "ll">
if m
  p(MatchData.to_s(m))             # => "ll"
end
p(Symbol.match(:hello, "l+"))      # => #<MatchData "ll">
p(Symbol.match(:hello, /z/))       # => nil
```

## match?

`Symbol.match?(x, Regexp|String)`

名前がパターンに一致すれば true。MatchData を作らないので、一致したかどうかだけが要るときはこちらを使います。

```ruby
p(Symbol.match?(:hello, /ell/))    # => true
p(Symbol.match?(:hello, "x"))      # => false
```

## casecmp

`Symbol.casecmp(x, Symbol)`

大文字小文字を区別せず（ASCII の範囲で）2 つの Symbol の名前を比べ、-1、0、1 を返します。引数は Symbol でなければなりません（String は静的に `type` の問題）。Ruby の `casecmp` が比べられないときに nil を返すことに合わせて結果の型は `Integer | nil` なので、そのまま計算に使うと level 2 で報告されます。

```ruby
p(Symbol.casecmp(:a, :A))          # => 0
p(Symbol.casecmp(:a, :B))          # => -1
p(Symbol.casecmp(:b, :A))          # => 1
```

```ruby error
p(Symbol.casecmp(:a, "b"))         # !> Symbol.casecmp: argument 2 must be Symbol, but is String
```

## casecmp?

`Symbol.casecmp?(x, Symbol)`

大文字小文字を区別せず（Unicode の case folding で）2 つの Symbol の名前が等しければ true。`casecmp` と違い、結果は Boolean で nil にはなりません: Ruby のメソッドが nil を返すところ（エンコーディングが互換でないとき）は false です。

```ruby
p(Symbol.casecmp?(:a, :A))         # => true
p(Symbol.casecmp?(:a, :b))         # => false
p(Symbol.casecmp?(:Straße, :STRASSE))   # => true
```

## ==, !=

`Symbol.==(x, Any)`

`Symbol.!=(x, Any)`

同じ名前の Symbol なら true（`!=` はその否定）。右側が Symbol でないもの（String、Integer、nil）なら、演算子でも関数形でもただ等しくないだけです: `Symbol.==(:a, "a")` は false で、誤りにはなりません。

```ruby
p(:a == :a)                        # => true
p(:a != :b)                        # => true
p(:a == "a")                       # => false
p(Symbol.==(:a, :a))               # => true
p(Symbol.==(:a, "a"))              # => false
p(Symbol.!=(:a, "a"))              # => true
```

## <, <=, >, >=

`Symbol.<(x, Any)`

`Symbol.<=(x, Any)`

`Symbol.>(x, Any)`

`Symbol.>=(x, Any)`

2 つの Symbol の名前を String として比べます（Ruby と同じ、バイト順）。右側は Symbol でなければならず、String や Integer は静的に `type` の問題です。

```ruby
p(:a < :b)                         # => true
p(:b >= :c)                        # => false
p(Symbol.<=(:a, :a))               # => true
```

```ruby error
p(:a < "a")                        # !> which the left operand's type does not support
```

## <=>

`Symbol.<=>(x, Any)`

名前の比較の結果を -1、0、1 で返します。規則は `<` と同じで、右側は Symbol に限ります。`Array.sort_by` のキーに使えます。

```ruby
p(:a <=> :b)                       # => -1
p(:aa <=> :b)                      # => -1
p(Symbol.<=>(:a, :a))              # => 0
```
