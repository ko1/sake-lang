# 例外とエラー

Sake の例外は Ruby と同じ字面で書きます: `raise` で投げ、`begin`/`rescue`/`else`/`ensure` で受け、`retry` でやり直します。違いは 2 つです。例外型は普通のクラスで、型どうしに階層が無いこと。そして検査器が、各関数からどの例外が漏れうるかを実行前に追うことです。この章の前半が例外の書き方、後半が静的エラーと実行時エラーの種類の一覧です。エラーの表示形式は[概要と実行](01-overview.md)にあります。

## 例外

```ruby
ParseError = Exception.new(:line)        # フィールド: message, line

def parse(s)
  raise ParseError.new("empty", 1) if s == ""
  Integer(s)
end

begin
  parse("")
rescue ParseError => e
  p(ParseError.line(e))                  # => 1
rescue KeyError, IndexError => e
  p(Exception.message(e))
rescue => e                              # rescue できるすべての例外
  raise                                  # 再送出
else
  p(:ok)                                 # 何も投げられなかったとき
ensure
  p(:ensure)                             # => :ensure
end
```

形は Ruby のままです。以下の節で、例外型の宣言、`raise` と `rescue` の各形、検査器が見るもの、捕まえられなかったときの振る舞いを順に述べます。

### 例外型の宣言

例外型はクラスです（[クラス](07-classes.md)）。最初のフィールドが `message` で、その後に自分で宣言したフィールドが続きます。他のクラスと同じく `Name.new("msg", ...)`、`Name.message(e)`、`Name.field(e)`、関数の中の `@field` が使えます。

```ruby
class ParseError < Exception
  attr_reader line
end

e = ParseError.new("empty", 1)
p(ParseError.message(e))                 # => "empty"
p(ParseError.line(e))                    # => 1
p(e)                                     # => #<ParseError: empty line=1>
```

- **2 つの書き方。** `class Name < Exception` に `attr_reader field` の行を書く形と、その略記 `Name = Exception.new(:field, ...)` は同じものです。
- **階層は無い。** 例外型どうしに親子関係はありません。`rescue IOError` は `EOFError` を捕まえず、`rescue IndexError` は `KeyError` を捕まえません。
- **組み込みの例外型。** 組み込みの操作が投げる型で、フィールドは `message` だけです: `RuntimeError`、`ArgumentError`、`TypeError`、`KeyError`、`IndexError`、`ZeroDivisionError`、`RangeError`、`IOError`、`EOFError`、`RegexpError`、`FloatDomainError`、`EncodingError`、`ThreadError`、`NoMatchingPatternError`、`Math::DomainError`。それぞれの詳細は[組み込みリファレンスの Exceptions](ref/Exceptions.md)にあります。

### raise の形

`raise` は構文で、操作ではありません。4 つの形があります。

| 書いたもの | 投げるもの |
|---|---|
| `raise "msg"` | `RuntimeError` |
| `raise T, "msg"` | `T.new("msg")`。T のフィールドは `message` だけ |
| `raise value` | その例外値 |
| `raise`（rescue 節の中で） | 今受けている例外の再送出 |

```ruby
begin
  raise "boom"
rescue => e
  p(e)                                   # => #<RuntimeError: boom>
end
begin
  raise KeyError, "no such key"
rescue KeyError => e
  p(e)                                   # => #<KeyError: no such key>
end
begin
  raise IndexError.new("out")
rescue IndexError => e
  p(Exception.message(e))                # => "out"
end
```

`message` 以外のフィールドを持つ型は `raise T, "msg"` では投げられません。値を作って `raise T.new(...)` と書きます。

```ruby error
E = Exception.new(:code)
raise E, "msg"                           # !> E has fields besides message; raise it with `raise E.new(...)`
```

### rescue

`rescue A, B => e` は列挙した型だけを捕まえます。階層が無いので、書いた型がそのまま捕まえる型です。

すべてを捕まえるには `rescue => e` と書きます。`rescue StandardError => e` と `rescue Exception => e` も同じ意味です。このとき `e` の型は和なので、型ごとに処理を分けるには `case e in A ...` で絞ります（[制御構造とパターン](06-control.md)）。

```ruby
def check(x)
  raise ArgumentError, "negative" if x < 0
  x
end
begin
  check(-1)
rescue ArgumentError, ZeroDivisionError => e
  v = case e
      in ArgumentError then "argument"
      in ZeroDivisionError then "zero"
      end
  p(v)                                   # => "argument"
end
```

### メッセージを読む

`Exception.message(e)` は、どの型の例外値からもメッセージを読みます。`e` の型が和のときに使います。型が決まっているなら `ParseError.message(e)` でも同じです。

組み込みの操作が投げた例外のメッセージは Ruby の文です。rescue されずにプログラムを終えたときの報告には、操作名も付きます（`ZeroDivisionError: Arithmetic./: divided by 0`）。

```ruby
begin
  p(1 / 0)
rescue ZeroDivisionError => e
  p(Exception.message(e))                # => "divided by 0"
end
```

### プログラムの誤り

`SystemStackError`、`LocalJumpError`、`NotImplementedError` はプログラムの誤りで、rescue できません。`rescue` に書くのは静的エラーです。

```ruby error
begin
  p(1)
rescue SystemStackError => e             # !> SystemStackError cannot be rescued: it is a program error, which the checks before running report
  p(e)
end
```

`TypeError`（誤った型の値を受けた操作）と `NoMatchingPatternError` は Ruby と同じく rescue できます。ただし、それらが報告する型の誤りの多くは、実行前の検査が止めます（[概要と実行](01-overview.md)）。次の例は既定のレベルでは `type` の問題として実行前に止まります。`--strict=0` で走らせると `len(1)` は `TypeError` を投げ、他の例外と同じく rescue できて、メッセージは `"argument 1 must be String, got Integer"` です。

```ruby error
def len(x)
  String.length(x)                       # !> String.length: argument 1 must be String, but is Integer [type]
end
begin
  len(1)
rescue TypeError => e
  p(Exception.message(e))
end
```

### 他の形

`def f ... rescue ... end`、修飾子の `expr rescue fallback`、`retry` は Ruby と同じです。`ensure` は begin ブロックを離れるときに 1 度走ります。`return` や `exit` で離れるときも走ります。

```ruby
def safe_div(a, b)
  a / b
rescue ZeroDivisionError
  0
end
p(safe_div(6, 0))                        # => 0

n = Integer("x") rescue -1
p(n)                                     # => -1

tries = 0
begin
  tries += 1
  raise "again" if tries < 3
rescue RuntimeError
  retry
end
p(tries)                                 # => 3
```

### 例外の流れの検査

検査器は、明示的に `raise` した型のうちどれが各関数から出うるかを追います。2 つの項目がこれを使います（レベルは[概要と実行](01-overview.md)）。

- **`rescue`（レベル 1、既定）。** begin 本体が決して投げない型の rescue 節を報告します。`ZeroDivisionError` のような組み込みの種類は普通の操作から来うるので、常にありうるとみなし、報告しません。
- **`unrescued`（レベル 4）。** rescue されずにトップレベルまで届きうる `raise` を報告します。`raise: RuntimeError may reach the top level without being rescued [unrescued]` のような報告です。

```ruby error
ParseError = Exception.new(:line)
begin
  p(Integer("1"))
rescue ParseError => e                   # !> rescue ParseError: the begin body never raises ParseError [rescue]
  p(e)
end
```

### 捕まえられなかった例外

rescue されなかった例外は、実行時エラーと同じ形でプログラムを終えます: `FILE:LINE: in FUNCTION: ParseError: message`。終了コードは 1 です。

```ruby error
def check(x)
  raise ArgumentError, "x must be positive" if x <= 0   # !> ArgumentError: x must be positive
  x
end
check(0)
```

### デッドロック

すべてのスレッドが待ちになると、プログラムは Sake の `ThreadError` で終わります。何も push されない `Queue.pop`、自分の中で再び取る `Mutex.synchronize`、互いを待つ `Thread.join` がその例です（[組み込み操作](09-builtins.md)）。

```ruby error
q = Queue.new
Queue.pop(q)                             # !> ThreadError: deadlock: every thread is waiting
```

## 静的エラーの種類

静的エラーは位置順にまとめて報告され、何も実行されません。終了コードは 2 です。形式は[概要と実行](01-overview.md)にあります。

| 種類 | 例 |
|---|---|
| 構文エラー | Prism が解析できないもの |
| 未定義の型、操作、関数 | `String.upcse(s)` |
| 引数の数の誤り | |
| ブロックの過不足 | 取らないところへのブロック、必要なところでの欠落 |
| 値へのメソッド呼び出し | `name.upcase` |
| 禁止構文 | 下記 |
| 未対応の構文 | 付録 [Ruby との違いと未対応のもの](a1-ruby.md) |
| 二重定義 | |
| `T[...]` のリテラルの型の不一致 | `Integer["a"]` |
| `--strict` で選んだ項目 | 既定では、型が合わない値 |

禁止構文は、`send`、`public_send`、`__send__`、`method_missing`、`define_method`、`eval` の仲間、`instance_variable_get`/`set`、`const_get`/`set`、`binding`、`self`、そしてクラスの関数の外の `@x` です。どれも呼び出し先を実行時まで決められなくするか、Sake に無い概念（インスタンスの状態）を指すものです。

## 実行時エラーの種類

実行時エラーは、その操作の行でプログラムを止めます。終了コードは 1 です。どれも例外なので `rescue` できます。例外は `SystemStackError` と、すべてのスレッドが待ちになって検出されるデッドロックです（`Mutex.synchronize` の再入の `ThreadError` は rescue できます）。

| 種類 | 投げるもの |
|---|---|
| `TypeError` | 誤った型の値を受けた操作（下記） |
| `IndexError` | 範囲の外の添字（下記） |
| `ArgumentError` | ブロックの引数の数。負のサイズ。`Integer ** 負`。`sort` で比べられない値 |
| `ZeroDivisionError` | Integer の `/` か `%` のゼロ除算 |
| `KeyError` | 無いキーの `Hash.fetch`。無いフィールドを名乗る Record パターン |
| `RangeError` | 有限の Range が要る操作に終端の無い Range |
| `RegexpError` | 不正なパターンの `Regexp.new` |
| `IOError` | ファイル・ディレクトリ・ソケットの失敗（下記） |
| `EOFError` | 組み込みは投げません（下記） |
| `EncodingError` | エンコーディングの合わない String の操作 |
| `FloatDomainError` | NaN や Infinity の Integer への変換 |
| `Math::DomainError` | `Math.sqrt(-1)` など |
| `SystemStackError` | 10,000 より深い再帰 |
| `ThreadError` | デッドロック |

- **`TypeError`。** 誤った型の値を受けた操作。左のオペランドの型が支えない演算子。型付き Array への別の型の書き込み。Tuple でも Array でもない値からの多重代入。
- **`IndexError`。** Tuple の外の添字。Array の外の `Array.fetch`。T の Array の末尾の先への書き込み（`xs[5] = 3`。隙間が nil になるため）。
- **`IOError`。** `File.read`、`Dir.mkdir` などの失敗。Ruby では `Errno::ENOENT` などで、メッセージは Ruby のものです。ソケットのエラー（拒否、リセット、未知のホスト）も `IOError` です。
- **`EOFError`。** 組み込みの操作は投げません。終端の読み出しは nil や `""` を返し、Ruby の EOFError は `IOError` に畳みます。型としては存在するので `rescue` に書けます。

```ruby error
h = Hash["a" => 1]
p(Hash.fetch(h, "b"))                    # !> KeyError: Hash.fetch: key not found: "b"
```
