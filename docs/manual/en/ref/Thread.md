# Thread

Thread is the type of a thread that runs a block concurrently. `Thread.new { ... }` makes one; `Thread.value(t)` or `Thread.join(t)` waits for its end. It is Ruby's `Thread` (a Ruby thread), but only the operations listed here exist: no `Thread#[]`, `status`, `priority`, or `Thread.pass`. There is no Thread literal; values come from `Thread.new` and `Thread.current` ([Values and types](../03-values.md), [Built-ins](../09-builtins.md)).

- **Variables.** A block shares the variables around it, but for a thread the variables of the blocks around `Thread.new` (their parameters and locals) and the thread block's own are copied when the thread starts; the function's (or the top level's) variables stay shared. A shared counter is updated inside `Mutex.synchronize` ([Mutex](Mutex.md)).
- **Leaving the block.** `break` and `return` out of a thread block are a `LocalJumpError`; `next v` ends it with `v`.
- **Errors.** An exception inside a thread is not reported there; it is raised in the caller of `Thread.value` or `Thread.join`. A thread that ended with an error that no `Thread.value` / `Thread.join` read is reported on stderr when the program ends (the exit status is not changed): `PATH: a thread ended with an error that no Thread.value / Thread.join read:` followed by the error's report, indented. Every thread stops when the main program ends; one that is still running then is not reported.
- **Checking.** The checker runs the block once, at `Thread.new`, and makes its value the type of `Thread.value`. Interleavings are not analyzed; each operation still checks its arguments at run time.

The only operators on Threads are `==` and `!=` (equal for the same thread).

## new

`Thread.new() { }`

Starts the block in a new thread and returns the Thread at once. The block's value is the thread's value (`Thread.value`). The block is required and takes no parameters.

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

Waits for the thread to end and returns the block's value (Ruby's `t.value`), the same value on every call. When the thread ended with an exception, that exception is raised here (on every call). A thread stopped by `Thread.kill` has the value nil. The result has the block's type; a block that may return nil gets the `nil` check. A thread cannot wait for itself (`Thread.current`): that is a `ThreadError` (`Target thread must not be current thread`).

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

```ruby error
Thread.value(Thread.current)        # !> ThreadError: Thread.value: Target thread must not be current thread
```

When the program ends without any `value` or `join` having read a thread that raised, the error is reported on stderr (the program's exit status stays 0). The checker requires an empty stderr, so this is shown as it appears in a terminal:

```
t = Thread.new { raise ArgumentError, "boom" }
Thread.join(Thread.new { 1 })
p(1)                                # 1, then on stderr:
                                    # ex.sake: a thread ended with an error that no Thread.value / Thread.join read:
                                    #   ex.sake:1: in <main>: ArgumentError: boom
```

## join

`Thread.join(x, [Integer|Float|Rational])`

Waits for the thread to end and returns the thread. With a number of seconds as the second argument, it stops waiting after that time and returns nil when the thread is still running (the thread goes on). Only the two-argument form is `Thread | nil`, checked at level 2: `if Thread.join(t, 5)` tells whether the thread finished in time (`Timeout.timeout` of `sakelib` is built this way). The thread's exception is raised here, as with `value`. A thread cannot wait for itself (`ThreadError`).

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

True while the thread is running (has not ended).

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

The running thread (the main program's, or one made by `Thread.new`). All values for the same thread are `==`.

```ruby
me = Thread.current
p(Thread.current == me)             # => true
t = Thread.new { Thread.current }
p(Thread.value(t) == t)             # => true
p(Thread.value(t) == me)            # => false
```

## kill

`Thread.kill(x)`

Stops the thread where it is and returns the thread (Ruby's `t.kill`). Its `ensure` clauses run. A killed thread's `value` is nil and its `alive?` false. A thread that has already ended is left alone.

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

Raises a `RuntimeError` with the message in the thread, where it is, and returns the thread. Unless the thread rescues it, the thread ends with it and the caller of `value` or `join` gets that `RuntimeError` (`Timeout.timeout` of `sakelib` interrupts a block this way). A thread that has already ended is left alone. In a program that calls `Thread.raise`, the checker counts `Thread.value` and `Thread.join` as raising `RuntimeError`, so `rescue RuntimeError => e` around them is accepted (in a program without `Thread.raise` it is a `rescue` problem: the body never raises it).

```ruby
q = Queue.new
t = Thread.new { Queue.pop(q) }
p(Thread.raise(t, "stop") == t)     # => true
begin
  Thread.value(t)
rescue RuntimeError => e
  p(e)                              # => #<RuntimeError: stop>
end
begin
  Thread.join(t)
rescue RuntimeError => e
  p(Exception.message(e))           # => "stop"
end
done = Thread.new { 1 }
Thread.join(done)
Thread.raise(done, "late")
p(Thread.value(done))               # => 1
```

## ==, !=

`Thread.==(x, Any)`

`Thread.!=(x, Any)`

Two values are equal when they are the same thread (`!=` is the negation). A value that is not a Thread is never equal.

```ruby
t = Thread.new { 1 }
p(t == t)                           # => true
p(t != Thread.new { 2 })            # => true
p(t == 1)                           # => false
```
