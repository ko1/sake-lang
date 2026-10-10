# Process

Process はこのプロセスの情報と時計を読む操作の集まりです。Ruby の `Process.pid` と `Process.clock_gettime` だけがあり、`fork`、`spawn`、`wait`、`kill` などはありません（子プロセスは [Open3](Open3.md) と `Kernel.system` で起こします）。Ruby の定数 `Process::CLOCK_MONOTONIC` は Sake では操作 `Process.CLOCK_MONOTONIC` です（`Math.PI` と同じく、Sake に値の定数は無いので。[組み込み](../09-builtins.md)）。

Process に演算子はありません。例は環境に依らない値だけを表示します。

## pid

`Process.pid()`

このプロセスの ID（正の Integer）。子プロセスから見た親の ID は `Open3` で `$PPID` を読めば得られます。

```ruby
p(Process.pid > 0)                  # => true
out, status = Open3.capture2("sh", "-c", "echo $PPID")
p(String.to_i(out) == Process.pid)  # => true
```

## clock_gettime

`Process.clock_gettime(Integer, [Symbol])`

時計 `clock`（下の 3 つの操作のどれかの値）の現在値を返します（Ruby の `Process.clock_gettime`）。経過時間を測るには `Process.CLOCK_MONOTONIC` を使います: 壁時計の調整で戻ることがありません。第 2 引数は Ruby と同じ単位の Symbol で、結果の型を決めます: 省略時と `:float_second`（既定）、`:float_millisecond`、`:float_microsecond` では Float、`:second`、`:millisecond`、`:microsecond`、`:nanosecond` では Integer です。検査器は Symbol リテラルで書かれた単位を読みます。変数に入れた単位では結果は `Integer | Float` になり、Integer や Float の操作に渡す前に `case`/`in` で分ける必要があります。知らない単位（`unexpected unit: bogus`）と知らない時計の番号（`Invalid argument - clock_gettime(999)`）は `ArgumentError` です。

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

`clock_gettime` に渡す時計の番号（Integer）。`CLOCK_REALTIME` は壁時計（1970-01-01 UTC からの秒。`Time.now` と同じ値）、`CLOCK_MONOTONIC` は起点が不定で決して戻らない時計（経過時間用）、`CLOCK_PROCESS_CPUTIME_ID` はこのプロセスが使った CPU 時間です。番号そのものは OS で決まり、Linux では 0、1、2 です。他の Ruby の時計（`CLOCK_THREAD_CPUTIME_ID` など）はありません。

```ruby
p(Process.CLOCK_REALTIME != Process.CLOCK_MONOTONIC)   # => true
wall = Process.clock_gettime(Process.CLOCK_REALTIME)
p(Float.abs(wall - Time.to_f(Time.now)) < 1.0)         # => true
p(Process.clock_gettime(Process.CLOCK_PROCESS_CPUTIME_ID) >= 0.0)   # => true
```
