# Process

Process is the group of operations that read information about this process and its clocks. Only Ruby's `Process.pid` and `Process.clock_gettime` exist; there is no `fork`, `spawn`, `wait`, or `kill` (child processes are started with [Open3](Open3.md) and `Kernel.system`). Ruby's constant `Process::CLOCK_MONOTONIC` is the operation `Process.CLOCK_MONOTONIC` in Sake (as `Math.PI` is: Sake has no value constants, see [Built-ins](../09-builtins.md)).

Process has no operators. The examples print only values that do not depend on the environment.

## pid

`Process.pid()`

The ID of this process (a positive Integer). A child started with `Open3` sees it as `$PPID`.

```ruby
p(Process.pid > 0)                  # => true
out, status = Open3.capture2("sh", "-c", "echo $PPID")
p(String.to_i(out) == Process.pid)  # => true
```

## clock_gettime

`Process.clock_gettime(Integer, [Symbol])`

The current value of the clock `clock` (the value of one of the three operations below), Ruby's `Process.clock_gettime`. To measure elapsed time use `Process.CLOCK_MONOTONIC`: it never goes back when the wall clock is adjusted. The second argument is a unit Symbol, as Ruby's, and decides the result's type: without it or with `:float_second` (the default), `:float_millisecond`, `:float_microsecond` the result is a Float; with `:second`, `:millisecond`, `:microsecond`, `:nanosecond` it is an Integer. The checker reads the unit when it is written as a literal Symbol; a unit held in a variable gives `Integer | Float`, which a `case`/`in` has to split before an Integer or Float operation takes it. An unknown unit (`unexpected unit: bogus`) and an unknown clock number (`Invalid argument - clock_gettime(999)`) are an `ArgumentError`.

```ruby
t0 = Process.clock_gettime(Process.CLOCK_MONOTONIC)
t1 = Process.clock_gettime(Process.CLOCK_MONOTONIC)
p(t1 >= t0)                         # => true
p(Process.clock_gettime(Process.CLOCK_REALTIME) > 1.0e9)   # => true
ms = Process.clock_gettime(Process.CLOCK_MONOTONIC, :millisecond)
p(ms > 0)                           # => true
p(Integer.to_s(ms) == "#{ms}")      # => true
f = Process.clock_gettime(Process.CLOCK_MONOTONIC, :float_millisecond)
p(Float.floor(f) >= 0)              # => true
```

```ruby error
Process.clock_gettime(Process.CLOCK_MONOTONIC, :bogus)   # !> ArgumentError: Process.clock_gettime: unexpected unit: bogus
```

```ruby error
Process.clock_gettime(999)          # !> ArgumentError: Process.clock_gettime: Invalid argument - clock_gettime(999)
```

```ruby error
unit = :millisecond
p(Integer.to_s(Process.clock_gettime(Process.CLOCK_MONOTONIC, unit)))   # !> Integer.to_s: argument 1 must be Integer, but can be Float
```

## CLOCK_REALTIME, CLOCK_MONOTONIC, CLOCK_PROCESS_CPUTIME_ID

`Process.CLOCK_REALTIME()`

`Process.CLOCK_MONOTONIC()`

`Process.CLOCK_PROCESS_CPUTIME_ID()`

The clock numbers (Integers) for `clock_gettime`. `CLOCK_REALTIME` is the wall clock (seconds since 1970-01-01 UTC, the value of `Time.now`); `CLOCK_MONOTONIC` has an arbitrary origin and never goes back (for elapsed time); `CLOCK_PROCESS_CPUTIME_ID` is the CPU time this process has used. The numbers themselves are the OS's (0, 1, and 2 on Linux). Ruby's other clocks (`CLOCK_THREAD_CPUTIME_ID`, ...) do not exist.

```ruby
p(Process.CLOCK_REALTIME != Process.CLOCK_MONOTONIC)   # => true
wall = Process.clock_gettime(Process.CLOCK_REALTIME)
p(Float.abs(wall - Time.to_f(Time.now)) < 1.0)         # => true
p(Process.clock_gettime(Process.CLOCK_PROCESS_CPUTIME_ID) >= 0.0)   # => true
```
