# Exceptions

組み込みの例外型です。組み込みの操作が実行時に失敗したときに投げるもので、プログラム自身も `raise E, "msg"` で投げられます。各型はフィールド `message` だけを持つ Struct 型として宣言されていて（[Struct 型](../07-structs.md)）、他の Struct 型と同じ操作が使えます:

- `E.new(message)` が例外値を作ります（`message` は普通 String ですが、型は検査されません）。`raise E, "msg"` は `raise E.new("msg")` の略、`raise E` はメッセージを型名にします。`raise "msg"` は `RuntimeError` です。`raise` は構文で、[例外とエラー](../08-exceptions.md)にあります。
- `E.message(e)` がメッセージを読み、`E.set_message(e, s)` が書き換えます（`e.E.message` も同じ）。古い `E.get_message` は拒まれ、`E.message` に直すよう案内されます。どの型の例外値でも読めるのが `Exception.message(e)` で、`rescue => e` のように型が和になっているときに使います。
- `rescue E => e` は列挙した型だけを捕まえます。例外型に階層は無いので、`rescue IOError` は `EOFError` を捕まえず、`rescue IndexError` は `KeyError` を捕まえません（Ruby とは違います）。複数は `rescue A, B => e`、すべては `rescue => e`（`rescue StandardError`、`rescue Exception` も同じ）です。
- `p(e)` は `#<E: message>`、`==` はフィールドで比べます。
- 組み込みの操作が投げた例外のメッセージは Ruby の文（`divided by 0`）で、rescue されずにプログラムを終えたときの報告には操作名も付きます（`ZeroDivisionError: Kernel.Rational: divided by 0`）。

`Math::DomainError` も組み込みの例外型で、`rescue Math::DomainError => e` と `raise Math::DomainError, "msg"` に書けますが、入れ子の名前なので `Math::DomainError.new(...)` と `Math::DomainError.message(e)` は書けません（`Exception.message(e)` で読みます）。`Math.sqrt(-1)`、`Math.log(-1)` などが投げます。`SystemStackError`（深すぎる再帰、`once` の再入）、`LocalJumpError`、`NotImplementedError` はプログラムの誤りで、rescue できず、`rescue` に書くのは静的エラーです。

型の誤り（`TypeError`）やパターンの不一致（`NoMatchingPatternError`）の多くは、実行前の検査が `type` の問題として止めるので、実行時に届くのは検査が見られなかった場所（`Any` を受ける操作、`--strict=0` で走らせたプログラム）だけです。

```ruby
begin
  Integer("x")
rescue ArgumentError, TypeError => e
  puts(Exception.message(e))       # => invalid value for Integer(): "x"
end
e = KeyError.new("missing")
p(e)                               # => #<KeyError: missing>
p(KeyError.message(e))             # => "missing"
KeyError.set_message(e, "other")
p(Exception.message(e))            # => "other"
p(e == KeyError.new("other"))      # => true
```

## RuntimeError

`RuntimeError.new(message)`

`raise "msg"`（型を書かない `raise`）が投げる型です。組み込みの操作では `Thread.raise(t, msg)` が相手のスレッドに投げます。プログラムの「その他の失敗」に使います。

```ruby
begin
  raise "plain"
rescue RuntimeError => e
  p(e)                             # => #<RuntimeError: plain>
end
```

## ArgumentError

`ArgumentError.new(message)`

引数の値が受け付けられないとき。投げる操作: `Integer`、`Float`、`Rational` の読めない String、`format` の引数の過不足や数でない値、`Array.sort`・`max`・`min`・`Tuple.max` などの比べられない要素、負のサイズ（`Array.first(a, -1)`）、`Integer ** 負の Integer`、`Regexp.new(s, flags)` の不正なフラグ、`Time.new`・`Time.at`・`Time.now` の範囲外の値や不正なゾーン、`Integer.to_s(n, base)` の不正な基数、`String.unpack` の不正な書式、`Zlib` の壊れたデータ、ブロックの引数の数の不一致。

```ruby
begin
  Array.sort(Array[1, "a"])
rescue ArgumentError => e
  puts(Exception.message(e))       # => cannot compare elements of types Integer, String
end
begin
  2 ** -1
rescue ArgumentError => e
  puts(Exception.message(e))       # => Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
end
```

## TypeError

`TypeError.new(message)`

値の型が合わないとき: 操作が受け取った引数が違う型、左のオペランドの型が支えない演算子、型付き Array（`Integer[]` など）への違う型の書き込み、Tuple でも Array でもない値からの多重代入、Hash のキー・Set の要素・`ARGV` の要素である凍結された String のその場での変更、`Exception.message` に例外でない値。これらの大半は実行前の検査が静的に止めるので、実行時に届くのは検査が通した場所だけです。

```ruby
begin
  Exception.message(1)
rescue TypeError => e
  puts(Exception.message(e))       # => Exception.message: argument 1 must be an exception, got Integer
end
```

```ruby error
Array.push(Integer[], "a")         # !> Array.push: an element must be Integer, but is String
```

## KeyError

`KeyError.new(message)`

無いキー: `Hash.fetch`（既定値もブロックも無いとき）、`Hash.fetch_values`、`ENV.fetch`、無いフィールドを名乗る Record パターン。`format` の `%<name>` の無いキーは `ArgumentError` です。

```ruby
h = Hash["a" => 1]
begin
  Hash.fetch(h, "b")
rescue KeyError => e
  puts(Exception.message(e))       # => key not found: "b"
end
p(Hash.fetch(h, "b", 0))           # => 0
```

## IndexError

`IndexError.new(message)`

範囲外の添字: `Array.fetch`、Tuple の外の添字（実行時に届いたもの。リテラルの添字は静的に止まります）、T の Array の末尾の先への書き込み（`Integer[1, 2][5] = 1`。隙間が nil になるため）、`Array.insert` の範囲外の位置。`x[k]` は範囲外で nil を返し、例外にはなりません。

```ruby
def at(t, i) = t[i]
begin
  at([1, 2], 5)
rescue IndexError => e
  puts(Exception.message(e))       # => index 5 is outside a Tuple of length 2
end
begin
  Array.fetch(Array[3, 1], 9)
rescue IndexError => e
  puts(Exception.message(e))       # => index 9 outside of array bounds: -2...2
end
```

## ZeroDivisionError

`ZeroDivisionError.new(message)`

Integer（と Rational）のゼロ除算: `/`、`%`、`Integer.divmod`、`div`、`modulo`、`remainder`、`ceildiv`、`Rational(a, 0)`、`Rational.quo`。Float の `1.0 / 0` は Ruby と同じく Infinity で、例外にはなりません。

```ruby
begin
  7 % 0
rescue ZeroDivisionError => e
  puts(Exception.message(e))       # => divided by 0
end
p(1.0 / 0)                         # => Infinity
```

## RangeError

`RangeError.new(message)`

値が表せる範囲の外: 有限の Range が要る操作に終端の無い Range（`Range.to_a(1..)`、`Range.last(1..)`、`Range.sort` など）、`Integer.chr` の文字にならない Integer。

```ruby
begin
  Range.to_a(1..)
rescue RangeError => e
  puts(Exception.message(e))       # => cannot do this on an endless Range 1..
end
```

## FloatDomainError

`FloatDomainError.new(message)`

NaN や Infinity を Integer や Rational にしようとしたとき: `Float.to_i`、`Arithmetic.to_i`、`Arithmetic.round`・`floor`・`ceil`・`truncate`、`Float.to_r`、`Float.rationalize`。メッセージは値の名前です。現在 `Arithmetic` の操作と `Integer(x)` からのものは Ruby の例外がそのまま出てプログラムを止め、rescue できません（処理系の不具合）。

```ruby
begin
  Float.to_i(Float.INFINITY)
rescue FloatDomainError => e
  puts(Exception.message(e))       # => Infinity
end
begin
  Float.to_r(Float.NAN)
rescue FloatDomainError => e
  puts(Exception.message(e))       # => NaN
end
```

## IOError

`IOError.new(message)`

入出力の失敗: `File.read`、`File.write`、`File.open`、`Dir.mkdir`、`Dir.children` など File と Dir の操作（Ruby の `Errno::ENOENT` などがこの 1 つの型になり、メッセージは Ruby のもの）、閉じた IO への操作、ソケットのエラー（接続拒否、リセット、未知のホスト、タイムアウト）、閉じた Queue への `Queue.push`。

```ruby
begin
  File.read("no-such-file")
rescue IOError => e
  puts(Exception.message(e))       # => No such file or directory @ rb_sysopen - no-such-file
end
q = Queue.new
Queue.close(q)
begin
  Queue.push(q, 1)
rescue IOError => e
  puts(Exception.message(e))       # => push to a closed Queue
end
```

## EOFError

`EOFError.new(message)`

入力の終わりに達した読み出し。Ruby では `IO#readline` などが投げますが、Sake の読み出し操作（`IO.read(io, n)`、`IO.gets`、`IO.getc`、`gets`）は終わりで nil を返すので、現在これを投げる組み込みの操作はありません。プログラム自身の「もう入力が無い」に使えます。`IOError` とは別の型で、`rescue IOError` では捕まりません。

```ruby
def next_token(xs) = Array.shift(xs) || raise(EOFError, "no more tokens")
begin
  next_token(Array[])
rescue EOFError => e
  puts(Exception.message(e))       # => no more tokens
end
```

## EncodingError

`EncodingError.new(message)`

文字列のエンコーディングの誤り: `String.encode` で変換できないバイト、エンコーディングの合わない String の連結や比較など、操作の中で Ruby が `EncodingError`（`Encoding::UndefinedConversionError` など）を出したもの。

```ruby
begin
  String.encode("\xff", "UTF-16")
rescue EncodingError => e
  puts(Exception.message(e))       # => "\xFF" on UTF-8
end
```

## RegexpError

`RegexpError.new(message)`

不正な正規表現: 式を埋め込んだリテラル `/#{s}/` のパターンが不正なとき、`Regexp.new(s)` の不正なパターン。リテラルに直接書いたパターンは構文エラーとして実行前に止まります。

```ruby
s = "("
begin
  r = /#{s}/
rescue RegexpError => e
  puts(Exception.message(e))       # => end pattern with unmatched parenthesis: /(/
end
```

## NoMatchingPatternError

`NoMatchingPatternError.new(message)`

`case`/`in` のどの枝にも値が合わず `else` も無いとき、`x => pattern` が合わないとき。検査器は値の型から合う枝が無いことを静的に見つけて `type` の問題として止めるので（下の例）、実行時に投げられるのは検査が通した場所、たとえば `--strict=0` で走らせたプログラムです。メッセージは合わなかった値を述べます。

```ruby error
def kind(x)
  case x
  in Integer then "int"
  end
end
kind("s")                          # !> case/in: no `in` branch matches String
```

## ThreadError

`ThreadError.new(message)`

スレッドの操作の誤り: 持っている Mutex をもう一度 `Mutex.lock`、持っていない Mutex の `Mutex.unlock`。すべてのスレッドが待ちになるデッドロックも Sake の `ThreadError` としてプログラムを終えます（[例外とエラー](../08-exceptions.md)）。

```ruby
m = Mutex.new
Mutex.lock(m)
begin
  Mutex.lock(m)
rescue ThreadError => e
  puts(Exception.message(e))       # => deadlock; recursive locking
end
begin
  Mutex.unlock(Mutex.new)
rescue ThreadError => e
  puts(Exception.message(e))       # => Attempt to unlock a mutex which is not locked
end
```
