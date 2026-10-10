# Queue

Queue is a thread-safe first-in, first-out queue for passing values between threads (Ruby's `Thread::Queue`). `Queue.push(q, x)` adds at the end; `Queue.pop(q)` takes from the front, waiting until someone pushes when the queue is empty. `Queue.close(q)` says that nothing more will come, and `pop` on a closed, empty Queue is nil. This is the producer-consumer pattern ([Thread](Thread.md), [Built-ins](../09-builtins.md)). There is no literal and no size limit (no `SizedQueue`).

**Element type.** To the checker, a Queue's element type is the union of everything pushed to it. The type of `Queue.pop` is that plus nil, and `--strict` (level 2) reports using it unchecked as a `nil` problem: `while (x = Queue.pop(q))` is the usual form.

The only operators on Queues are `==` and `!=` (equal for the same Queue).

## new

`Queue.new()`

A new, empty Queue.

```ruby
q = Queue.new
p(q)                                # => #<Queue>
p(Queue.empty?(q))                  # => true
```

## push

`Queue.push(x, Any)`

Adds the value at the end and returns the Queue. Any value can be pushed, nil too, but a nil cannot be told from "closed and empty" by `pop`. A push to a closed Queue is an `IOError` (Ruby's `ClosedQueueError`).

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

Takes the value at the front and returns it. When the Queue is empty it waits until someone pushes or the Queue is closed; closed and empty, it returns nil without waiting. With a number of seconds as the second argument it returns nil when nothing arrives within that time (0 does not wait). The result is always "the element type | nil", checked at level 2.

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

Closes the Queue and returns it. Afterwards `push` is an `IOError`, `pop` returns the remaining values in order and then nil, and every waiting `pop` wakes up with nil. Closing again does nothing.

```ruby
q = Queue.new
Queue.push(q, 1)
p(Queue.close(q) == q)              # => true
p(Queue.pop(q))                     # => 1
p(Queue.pop(q))                     # => nil
```

## closed?

`Queue.closed?(x)`

True when the Queue has been closed.

```ruby
q = Queue.new
p(Queue.closed?(q))                 # => false
Queue.close(q)
p(Queue.closed?(q))                 # => true
```

## size

`Queue.size(x)`

The number of values currently in the Queue (an Integer).

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

True when nothing is in the Queue.

```ruby
q = Queue.new
p(Queue.empty?(q))                  # => true
Queue.push(q, 1)
p(Queue.empty?(q))                  # => false
```

## ==, !=

`Queue.==(x, Any)`

`Queue.!=(x, Any)`

Equal for the same Queue (`!=` is the negation). Every `Queue.new` is a different value.

```ruby
q = Queue.new
p(q == q)                           # => true
p(q == Queue.new)                   # => false
p(q != Queue.new)                   # => true
```
