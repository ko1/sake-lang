# Thread

Thread はブロックを並行に走らせるスレッドの型です。`Thread.new { ... }` が作り、`Thread.value(t)` か `Thread.join(t)` で終わりを待ちます。Ruby の `Thread` と同じ仕組み（Ruby のスレッドそのもの）ですが、操作はここに挙げたものだけで、`Thread#[]`、`status`、`priority`、`Thread.pass` などはありません。Thread のリテラルはなく、値は `Thread.new` と `Thread.current` から来ます（[値と型](../03-values.md)、[組み込み](../09-builtins.md)）。

- **変数。** ブロックは周りの変数を共有しますが、スレッドでは `Thread.new` を囲むブロックの変数（引数とローカル）とスレッドブロック自身の変数は開始時に複製され、関数（トップレベル）の変数は共有のままです。共有カウンタは `Mutex.synchronize` の中で更新します（[Mutex](Mutex.md)）。
- **抜け方。** スレッドブロックからの `break` と `return` は `LocalJumpError` です。`next v` が `v` で終えます。
- **エラー。** スレッドの中の例外はそこでは報告されず、`Thread.value` か `Thread.join` を呼んだ側で上がります。待たれないスレッドは黙って終わり、メインプログラムが終わるとすべてのスレッドが止まります。
- **検査。** 検査器はブロックを `Thread.new` の場所で 1 度走らせ、その値を `Thread.value` の型にします。実行の交互は解析せず、各操作が実行時に引数を検査します。

Thread に使える演算子は `==`、`!=` だけです（同じスレッドなら等しい）。

## new

`Thread.new() { }`

ブロックを新しいスレッドで走らせ始め、すぐに Thread を返します。ブロックの値がスレッドの値（`Thread.value`）です。ブロックは必須で、引数は受け取りません。

```ruby
t = Thread.new { 1 + 2 }
p(t)                                # => #<Thread>
p(Thread.value(t))                  # => 3
ws = Array.map(Array[1, 2, 3]) { |i| Thread.new { i * 10 } }
p(Array.map(ws) { |w| Thread.value(w) })   # => [10, 20, 30]
```

```ruby error
t = Thread.new { return 1 }         # !> `return` outside a function
```

## value

`Thread.value(x)`

スレッドが終わるのを待ち、ブロックの値を返します（Ruby の `t.value`）。何度呼んでも同じ値です。スレッドが例外で終わっていれば、その例外がここで上がります（何度でも）。`Thread.kill` で止められたスレッドの値は nil です。結果の型はブロックの型で、nil を返しうるブロックなら `nil` の検査を受けます。自分自身（`Thread.current`）を待つことはできず、Ruby の `ThreadError` でプログラムが止まります。

```ruby
t = Thread.new { "done" }
p(Thread.value(t))                  # => "done"
p(Thread.value(t))                  # => "done"
e = Thread.new { raise ArgumentError, "boom" }
begin
  Thread.value(e)
rescue ArgumentError => err
  p(Exception.message(err))         # => "boom"
end
```

```ruby error
t = Thread.new { raise ArgumentError, "boom" }
Thread.value(t)                     # !> ArgumentError: boom
```

## join

`Thread.join(x, [Integer|Float|Rational])`

スレッドが終わるのを待ち、スレッドを返します。第 2 引数に秒数を与えると、その時間を過ぎても終わらないときは待つのをやめて nil を返します（スレッドは走り続けます）。結果は 2 引数のときだけ `Thread | nil` で、レベル 2 で検査されます: `if Thread.join(t, 5)` で「時間内に終わった」が分かります（`sakelib` の `Timeout.timeout` はこう作られています）。スレッドの例外は `value` と同じくここで上がります。自分自身を待つことはできません。

```ruby
q = Queue.new
t = Thread.new { Queue.pop(q) }
p(Thread.join(t, 0.01))             # => nil
p(Thread.alive?(t))                 # => true
Queue.push(q, :go)
p(Thread.join(t) == t)              # => true
p(Thread.join(t, 1) == t)           # => true
```

## alive?

`Thread.alive?(x)`

スレッドがまだ走っている（終わっていない）なら true。

```ruby
q = Queue.new
t = Thread.new { Queue.pop(q) }
p(Thread.alive?(t))                 # => true
Queue.push(q, 1)
Thread.join(t)
p(Thread.alive?(t))                 # => false
p(Thread.alive?(Thread.current))    # => true
```

## current

`Thread.current()`

今走っているスレッド（メインプログラムのスレッド、または `Thread.new` で作ったもの）。同じスレッドを表す値はすべて `==` です。

```ruby
me = Thread.current
p(Thread.current == me)             # => true
t = Thread.new { Thread.current }
p(Thread.value(t) == t)             # => true
p(Thread.value(t) == me)            # => false
```

## kill

`Thread.kill(x)`

スレッドを今いる場所で止め、スレッドを返します（Ruby の `t.kill`）。`ensure` 節は走ります。止めたスレッドの `value` は nil、`alive?` は false。既に終わっているスレッドには何もしません。

```ruby
q = Queue.new
t = Thread.new { Queue.pop(q) }
p(Thread.kill(t) == t)              # => true
Thread.join(t)
p(Thread.alive?(t))                 # => false
p(Thread.value(t))                  # => nil
```

## raise

`Thread.raise(x, String)`

スレッドの今いる場所で `RuntimeError`（メッセージ付き）を起こし、スレッドを返します。スレッドの中で rescue されなければスレッドはそれで終わり、`value` や `join` を呼んだ側でその `RuntimeError` が上がります（`sakelib` の `Timeout.timeout` はこれでブロックを中断します）。既に終わっているスレッドには何もしません。検査器は `Thread.value` が `RuntimeError` を投げることを知らないので、`rescue RuntimeError` はレベル 1 の `rescue` の問題として報告されます: `rescue => e` で捕まえ、`Exception.message(e)` で見分けます。

```ruby
q = Queue.new
t = Thread.new { Queue.pop(q) }
p(Thread.raise(t, "stop") == t)     # => true
begin
  Thread.value(t)
rescue => e
  p(e)                              # => #<RuntimeError: stop>
end
done = Thread.new { 1 }
Thread.join(done)
Thread.raise(done, "late")
p(Thread.value(done))               # => 1
```

## ==, !=

`Thread.==(x, Any)`

`Thread.!=(x, Any)`

2 つの値が同じスレッドなら等しい（`!=` はその否定）。Thread 以外の値とは等しくありません。

```ruby
t = Thread.new { 1 }
p(t == t)                           # => true
p(t != Thread.new { 2 })            # => true
p(t == 1)                           # => false
```
