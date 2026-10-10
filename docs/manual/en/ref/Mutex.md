# Mutex

Mutex is the type of a lock for mutual exclusion between threads (Ruby's `Thread::Mutex`). `Mutex.new` makes one; `Mutex.synchronize(m) { ... }` holds it for the block. It is for updating state that threads share (a function's or the top level's variables, the contents of an Array or Hash) from several threads ([Thread](Thread.md), [Built-ins](../09-builtins.md)). There is no literal.

The lock is not reentrant: a `lock` by the thread that holds it is a `ThreadError` (`deadlock; recursive locking`). An `unlock` by a thread that does not hold it is a `ThreadError` too. `ThreadError` is a built-in exception that can be rescued ([Exceptions](../08-exceptions.md)).

The only operators on Mutexes are `==` and `!=` (equal for the same Mutex).

## new

`Mutex.new()`

A new Mutex that nobody holds.

```ruby
m = Mutex.new
p(m)                                # => #<Mutex>
p(Mutex.locked?(m))                 # => false
```

## synchronize

`Mutex.synchronize(x) { }`

Takes the lock, runs the block, releases the lock when the block ends (also by an exception), and returns the block's value. While another thread holds the lock it waits. Usually this form is all that is needed. Nesting `synchronize` on a Mutex the thread already holds stops the program with Ruby's `ThreadError` (unlike `lock`, it is not in a form that can be rescued).

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

Takes the lock and returns the Mutex, waiting while another thread holds it. A `ThreadError` when this thread already holds it. It pairs with `unlock`; `synchronize` is the usual form, since it cannot forget to release on an exception.

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

Releases the lock and returns the Mutex. A Mutex this thread does not hold (held by nobody, or by another thread) is a `ThreadError`.

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

Takes the lock and returns true when it is free; returns false without waiting when someone holds it (also when this thread holds it; no error).

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

True when any thread holds the lock.

```ruby
m = Mutex.new
p(Mutex.locked?(m))                 # => false
Mutex.lock(m)
p(Mutex.locked?(m))                 # => true
p(Thread.value(Thread.new { Mutex.locked?(m) }))   # => true
```

## owned?

`Mutex.owned?(x)`

True when the current thread holds the lock; false when another thread does.

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

Equal for the same Mutex (`!=` is the negation). Every `Mutex.new` is a different value.

```ruby
m = Mutex.new
p(m == m)                           # => true
p(m == Mutex.new)                   # => false
p(m != Mutex.new)                   # => true
```
