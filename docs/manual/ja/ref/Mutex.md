# Mutex

Mutex はスレッドの間で排他をとる錠の型です（Ruby の `Thread::Mutex` そのもの）。`Mutex.new` が作り、`Mutex.synchronize(m) { ... }` がブロックの間だけ錠を持ちます。スレッドが共有する変数（関数やトップレベルの変数、Array や Hash の中身）を複数のスレッドから更新するときに使います（[Thread](Thread.md)、[組み込み](../09-builtins.md)）。リテラルはありません。

錠は再入できません: 持っているスレッドがもう一度 `lock` すると `ThreadError`（`deadlock; recursive locking`）です。持っていないスレッドが `unlock` するのも `ThreadError`。`ThreadError` は rescue できる組み込みの例外です（[例外](../08-exceptions.md)）。

Mutex に使える演算子は `==`、`!=` だけです（同じ Mutex なら等しい）。

## new

`Mutex.new()`

新しい、誰も持っていない Mutex を返します。

```ruby
m = Mutex.new
p(m)                                # => #<Mutex>
p(Mutex.locked?(m))                 # => false
```

## synchronize

`Mutex.synchronize(x) { }`

錠を取り、ブロックを走らせ、ブロックが終わると（例外で抜けても）錠を離し、ブロックの値を返します。他のスレッドが持っている間は待ちます。普通はこの形だけで足ります。自分が持っている Mutex の `synchronize` を入れ子にすると Ruby の `ThreadError` でプログラムが止まります（`lock` と違い、rescue できる形になりません）。

```ruby
m = Mutex.new
count = 0
ths = Array.map(Array[1, 2, 3, 4]) { |i|
  Thread.new { Array.each(Array.new(100, 0)) { |_| Mutex.synchronize(m) { count += 1 } } }
}
Array.each(ths) { |t| Thread.join(t) }
p(count)                            # => 400
r = Mutex.synchronize(m) { p(Mutex.locked?(m)); "val" }   # => true
p(r)                                # => "val"
p(Mutex.locked?(m))                 # => false
```

## lock

`Mutex.lock(x)`

錠を取り、Mutex を返します。他のスレッドが持っていれば離されるまで待ちます。自分が既に持っていれば `ThreadError`。`unlock` と組にして使いますが、例外で抜けるときに離し忘れないよう、`synchronize` が普通です。

```ruby
m = Mutex.new
p(Mutex.lock(m) == m)               # => true
p(Mutex.locked?(m))                 # => true
Mutex.unlock(m)
```

```ruby error
m = Mutex.new
Mutex.lock(m)
Mutex.lock(m)                       # !> ThreadError: Mutex.lock: deadlock; recursive locking
```

## unlock

`Mutex.unlock(x)`

錠を離し、Mutex を返します。持っていない（誰も持っていない、または他のスレッドが持っている）Mutex は `ThreadError`。

```ruby
m = Mutex.new
Mutex.lock(m)
p(Mutex.unlock(m) == m)             # => true
p(Mutex.locked?(m))                 # => false
```

```ruby error
m = Mutex.new
Mutex.unlock(m)                     # !> ThreadError: Mutex.unlock: Attempt to unlock a mutex which is not locked
```

## try_lock

`Mutex.try_lock(x)`

錠が空いていれば取って true、誰かが持っていれば待たずに false を返します（自分が持っているときも false で、エラーにはなりません）。

```ruby
m = Mutex.new
p(Mutex.try_lock(m))                # => true
p(Mutex.try_lock(m))                # => false
other = Thread.new { Mutex.try_lock(m) }
p(Thread.value(other))              # => false
Mutex.unlock(m)
p(Mutex.try_lock(m))                # => true
```

## locked?

`Mutex.locked?(x)`

どのスレッドかに関わらず、誰かが錠を持っていれば true。

```ruby
m = Mutex.new
p(Mutex.locked?(m))                 # => false
Mutex.lock(m)
p(Mutex.locked?(m))                 # => true
p(Thread.value(Thread.new { Mutex.locked?(m) }))   # => true
```

## owned?

`Mutex.owned?(x)`

今のスレッドが錠を持っていれば true。他のスレッドが持っているときは false。

```ruby
m = Mutex.new
p(Mutex.owned?(m))                  # => false
Mutex.lock(m)
p(Mutex.owned?(m))                  # => true
p(Thread.value(Thread.new { Mutex.owned?(m) }))    # => false
```

## ==, !=

`Mutex.==(x, Any)`

`Mutex.!=(x, Any)`

同じ Mutex なら等しい（`!=` はその否定）。`Mutex.new` の結果はそれぞれ別の値です。

```ruby
m = Mutex.new
p(m == m)                           # => true
p(m == Mutex.new)                   # => false
p(m != Mutex.new)                   # => true
```
