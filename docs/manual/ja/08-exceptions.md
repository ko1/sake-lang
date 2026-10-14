# 例外とエラー

Sake の例外は Ruby と同じ字面で書きます: `raise` で投げ、`begin`/`rescue`/`else`/`ensure` で受け、`retry` でやり直します。違いは 2 つです。例外型は普通のクラスで、型をまとめるのは継承ではなくモジュールであること。そして検査器が、各関数からどの例外が漏れうるかを実行前に追うことです。この章の前半が例外の書き方、後半が静的エラーと実行時エラーの種類の一覧です。エラーの表示形式は[概要と実行](01-overview.md)にあります。

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
- **まとめるのはモジュール。** `class B < A` は書き写しで、`rescue A` は B を捕まえません。例外型をまとめるには、モジュールを include させて `rescue M` と書きます（[下](#モジュールでまとめる)）。組み込みの型は Ruby の親子関係のとおりで、`rescue IndexError` は `KeyError` を、`rescue IOError` は `EOFError` を、`rescue RangeError` は `FloatDomainError` を、`rescue ArgumentError` は `Math::DomainError` も捕まえます。`class ConvError < RangeError` のように組み込みの例外を親に書いたクラスも、`rescue RangeError` で捕まります。
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

`rescue A, B => e` は列挙した型を捕まえます。書いた名前がモジュールなら、それを include した例外型を、組み込みの親（`IndexError` など）なら Ruby の子も捕まえます。

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


### モジュールでまとめる

Ruby のライブラリは、例外を `class Error < StandardError` の子にして `rescue MyLib::Error` でまとめて受けます。Sake では親をモジュールにして、各例外型に include させます。`rescue M => e` は M を include したすべての例外型（M を include したモジュールを include する型も）を捕まえ、`e` の型はそれらの和です。モジュールの関数 `M.f(e)` は、型ごとの定義に振り分けられます。

```ruby
module ParseFailure
  def describe(e) = "parse: " + Exception.message(e)
end
class BadToken < StandardError
  include ParseFailure
end
class Unclosed < StandardError
  include ParseFailure
  attr_reader line
end
def parse(s)
  raise BadToken, "bad token" if s == "?"
  raise Unclosed.new("unclosed", 3) if s == "("
  s
end
begin
  parse("(")
rescue ParseFailure => e
  p(ParseFailure.describe(e))            # => "parse: unclosed"
  case e
  in Unclosed then p(Unclosed.line(e))   # => 3
  in BadToken then p("token")
  end
end
```

モジュールは投げられません（`raise ParseFailure, "x"` は静的エラー）。Ruby で親クラス自身も投げているなら、具体的な型を 1 つ足して include させます。レベル 1 は、前の `rescue M` がもう受けている型の `rescue A` で止めます。begin の本体がモジュールのどの型も投げない `rescue M` は `unused-rescue` の警告です。

```ruby error
module ParseFailure
end
class BadToken < StandardError
  include ParseFailure
end
def parse(s)
  raise BadToken, "bad token" if s == "?"
  s
end
begin
  parse("?")
rescue ParseFailure => e
  p(1)
rescue BadToken => e                     # !> rescue BadToken: an earlier rescue (ParseFailure) already catches it [rescue]
  p(2)
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

### バックトレースと原因

`Exception.backtrace(e)` は、例外が投げられたときの呼び出しの列を、Ruby と同じ `"FILE:LINE:in 'FUNCTION'"` の String の Array で返します。内側が先です。まだ投げていない例外値（`E.new` で作っただけのもの）では nil です。`raise e` や引数のない `raise` で投げ直しても、最初に投げたときの列のままです。

`Exception.cause(e)` は、`e` が投げられたときに rescue 節で扱っていた例外を返します。無ければ nil です。どちらも nil になりうるので、`--strict` では使う前に確かめます。

Ruby と違い、組み込みの操作の中の行（Ruby の `'Integer#/'` など）は列に入りません。

```ruby
def parse(s)
  Integer(s)
rescue ArgumentError
  raise "not a number: #{s}"
end

begin
  parse("x")
rescue => e
  bt = Exception.backtrace(e)
  p(Array.map(bt) { |l| String.sub(l, /\A.*?:/, "") }) if bt   # => ["4:in 'parse'", "8:in '<main>'"]
  c = Exception.cause(e)
  p(c) if c                                # => #<ArgumentError: invalid value for Integer(): "x">
end
p(Exception.backtrace(RuntimeError.new("not raised")))   # => nil
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

- **`unused-rescue`（レベル 1〜4 で警告。レベル 0 は型推論を走らせない）。** begin 本体が決して投げない型の rescue 節を報告します。`ZeroDivisionError` のような組み込みの種類は普通の操作から来うるので、常にありうるとみなし、報告しません。プログラムは走ります。防御的な `rescue` は普通に書くもので、投げるものがあるかはプログラム全体で決まるからです（一部のアプリしか投げない例外を受けるライブラリの `rescue`）。`--strict=2,unused-rescue` でエラーになります。関連する `rescue` 項目（レベル 1）は、前の節が既に捕まえる節で止めます。
- **`unrescued`（レベル 4）。** rescue されずにトップレベルまで届きうる `raise` を報告します。`raise: RuntimeError may reach the top level without being rescued [unrescued]` のような報告です。

```ruby
ParseError = Exception.new(:line)
begin
  p(Integer("1"))                        # => 1
rescue ParseError => e                   # warning: the begin body never raises ParseError [unused-rescue]
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
h = Hash.of("a" => 1)
p(Hash.fetch(h, "b"))                    # !> KeyError: Hash.fetch: key not found: "b"
```
