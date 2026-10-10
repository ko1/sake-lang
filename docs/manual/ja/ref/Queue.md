# Queue

Queue はスレッドの間で値を渡す、スレッド安全な先入れ先出しの待ち行列です（Ruby の `Thread::Queue` そのもの）。`Queue.push(q, x)` が末尾に加え、`Queue.pop(q)` が先頭を取り出し、空なら誰かが push するまで待ちます。`Queue.close(q)` が「もう来ない」を伝え、閉じて空になった Queue の `pop` は nil です。これで生産者・消費者のパターンが書けます（[Thread](Thread.md)、[組み込み](../09-builtins.md)）。リテラルはなく、長さの上限（Ruby の `SizedQueue`）はありません。

**要素の型。** 検査器にとって Queue の要素型は、その Queue に push されたものすべての和です。`Queue.pop` の型はそれに nil を加えたもので、`--strict`（レベル 2）はそのまま使うことを `nil` の問題として報告します: `while (x = Queue.pop(q))` で受けるのが普通の形です。

Queue に使える演算子は `==`、`!=` だけです（同じ Queue なら等しい）。

## new

`Queue.new()`

新しい空の Queue を返します。

```ruby
q = Queue.new
p(q)                                # => #<Queue>
p(Queue.empty?(q))                  # => true
```

## push

`Queue.push(x, Any)`

値を末尾に加え、Queue を返します。どんな値でも加えられ、nil も加えられますが、nil は `pop` 側で「閉じて空」と区別できません。閉じた Queue への push は `IOError`（Ruby では `ClosedQueueError`）。

```ruby
q = Queue.new
p(Queue.push(q, 1) == q)            # => true
Queue.push(q, "two")
p(Queue.size(q))                    # => 2
```

```ruby error
q = Queue.new
Queue.close(q)
Queue.push(q, 1)                    # !> IOError: Queue.push: push to a closed Queue
```

## pop

`Queue.pop(x, [Integer|Float|Rational])`

先頭の値を取り出して返します。空なら、誰かが push するか Queue が閉じられるまで待ちます。閉じていて空なら待たずに nil。第 2 引数に秒数を与えると、その時間待っても何も来なければ nil を返します（0 なら待ちません）。結果は常に「要素の型 | nil」で、レベル 2 で検査されます。

```ruby
q = Queue.new
Queue.push(q, 1)
Queue.push(q, 2)
p(Queue.pop(q))                     # => 1
p(Queue.pop(q, 5))                  # => 2
p(Queue.pop(q, 0.01))               # => nil
workers = Array.map(Array[1, 2]) { |i|
  Thread.new { total = 0; while (x = Queue.pop(q)); total += x; end; total }
}
Array.each(Array[1, 2, 3, 4, 5, 6]) { |i| Queue.push(q, i) }
Queue.close(q)
p(Array.sum(Array.map(workers) { |w| Thread.value(w) }))   # => 21
```

```ruby error
q = Queue.new
Queue.push(q, 1)
p(Queue.pop(q) + 1)                 # !> the operands may be nil
```

## close

`Queue.close(x)`

Queue を閉じて返します。以後の `push` は `IOError`、`pop` は残りを順に返した後 nil を返し、待っている `pop` はすべて nil で起きます。もう一度閉じても何も起きません。

```ruby
q = Queue.new
Queue.push(q, 1)
p(Queue.close(q) == q)              # => true
p(Queue.pop(q))                     # => 1
p(Queue.pop(q))                     # => nil
```

## closed?

`Queue.closed?(x)`

閉じられていれば true。

```ruby
q = Queue.new
p(Queue.closed?(q))                 # => false
Queue.close(q)
p(Queue.closed?(q))                 # => true
```

## size

`Queue.size(x)`

今入っている値の個数（Integer）。

```ruby
q = Queue.new
p(Queue.size(q))                    # => 0
Queue.push(q, :a)
Queue.push(q, :b)
p(Queue.size(q))                    # => 2
Queue.pop(q)
p(Queue.size(q))                    # => 1
```

## empty?

`Queue.empty?(x)`

何も入っていなければ true。

```ruby
q = Queue.new
p(Queue.empty?(q))                  # => true
Queue.push(q, 1)
p(Queue.empty?(q))                  # => false
```

## ==, !=

`Queue.==(x, Any)`

`Queue.!=(x, Any)`

同じ Queue なら等しい（`!=` はその否定）。`Queue.new` の結果はそれぞれ別の値です。

```ruby
q = Queue.new
p(q == q)                           # => true
p(q == Queue.new)                   # => false
p(q != Queue.new)                   # => true
```
