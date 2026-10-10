# 例外とエラー

## 例外

```ruby
ParseError = Exception.new(:line)        # フィールド: message, line

begin
  raise ParseError.new("empty", 1)
rescue ParseError => e
  ParseError.line(e)
rescue KeyError, IndexError => e
  Exception.message(e)
rescue => e                              # rescue できるすべての例外
  raise                                  # 再送出
else
  ...                                    # 何も投げられなかったとき
ensure
  ...                                    # 常に 1 度
end
```

- **例外型。** `attr_reader field` を持つ `class Name < Exception`（または `Name = Exception.new(:field, ...)`）が例外型を宣言します。最初のフィールドが `message` の Struct 型なので、`Name.new("msg", ...)`、`Name.message`、`Name.field`、`@field` が他の Struct 型と同じく使えます。例外型に階層はありません。
- **組み込みの例外型。** 操作が投げるもので、`message` だけを持ちます: `RuntimeError`, `ArgumentError`, `TypeError`, `KeyError`, `IndexError`, `ZeroDivisionError`, `RangeError`, `IOError`, `EOFError`, `RegexpError`, `FloatDomainError`, `EncodingError`, `ThreadError`, `NoMatchingPatternError`, `Math::DomainError`。
- **`raise` の形:**
  - `raise "msg"` は `RuntimeError` を投げます。
  - `raise T, "msg"` は `T.new("msg")` を投げます。T は `message` 以外のフィールドを持たないもの。
  - `raise value` は例外値を投げます。
  - rescue 節の中の裸の `raise` は再送出です。
- **`rescue`。** `rescue A, B => e` は列挙した型だけを捕まえます（階層が無いので）。`rescue => e`、`rescue StandardError => e`、`rescue Exception => e` は rescue できるすべての例外を捕まえ、`e` は和なので `case e in A ...` で絞ります。
- **メッセージを読む。** `Exception.message(e)` はどの例外値のメッセージも読みます。組み込みの操作が投げた例外では Ruby の文（`divided by 0`）で、rescue されなかったものの報告には操作名も付きます（`ZeroDivisionError: Arithmetic./: divided by 0`）。
- **プログラムの誤り。** `SystemStackError`、`LocalJumpError`、`NotImplementedError` は rescue できず、`rescue` に書くのは静的エラーです。`TypeError`（誤った型の値を受けた操作）と `NoMatchingPatternError` は Ruby と同じく rescue できます。実行前の検査はそれらが報告する型の誤りを止め（[概要](01-overview.md)）、実行時の検査の失敗（例えば `--strict=0` で走らせたプログラムで）は他と同じ例外です。
- **他の形。** `def f ... rescue ... end`、`expr rescue fallback`、`retry` は Ruby と同じです。`ensure` は begin ブロックを離れるときに 1 度走ります。
- **例外の流れ。** 型推論は、明示的に raise した型のうちどれが各関数から出うるかを追います。
  - `rescue`（レベル 1）は、begin 本体が決して投げない型の rescue 節を報告します。`ZeroDivisionError` のような組み込みの種類は普通の操作から来うるので、常にありうるとみなします。
  - `unrescued`（レベル 4）は、トップレベルまで届きうる `raise` を報告します。
- **捕まえられなかった例外。** 実行時エラーと同じようにプログラムを終えます: `FILE:LINE: in FUNCTION: ParseError: message`。
- **デッドロック。** すべてのスレッドが待ちになると（何も push されない `Queue.pop`、自分の中の `Mutex.synchronize`）、Sake の `ThreadError` で終わります。

## 静的エラーの種類

静的エラーは位置順にまとめて報告され、何も実行されません。

- 構文エラー（Prism から）
- 未定義の型、操作、関数
- 引数の数の誤り
- 取らないところへのブロック、必要なところでのブロックの欠落
- 値へのメソッド呼び出し
- 禁止構文: `send`、`public_send`、`__send__`、`method_missing`、`define_method`、`eval` の仲間、`instance_variable_get`/`set`、`const_get`/`set`、`binding`、`self`、Struct 型の関数の外の `@x`
- 未対応の構文
- 二重定義
- `T[...]` のリテラルの型の不一致
- `--strict` で選んだ項目（既定では、型が合わない値）

## 実行時エラーの種類

| 種類 | 投げるもの |
|---|---|
| `TypeError` | 誤った型の値を受けた操作。左のオペランドの型が支えない演算子。型付き Array への書き込み。Tuple でも Array でもない値からの多重代入 |
| `IndexError` | Tuple の外の添字。Array の外の `Array.fetch`。T の Array の末尾の先への書き込み |
| `ArgumentError` | ブロックの引数の数。負のサイズ。`Integer ** 負`。`sort` で比べられない値 |
| `ZeroDivisionError` | Integer の `/` か `%` のゼロ除算 |
| `KeyError` | 無いキーの `Hash.fetch`。無いフィールドを名乗る Record パターン |
| `RangeError` | 有限の Range が要る操作に終端の無い Range |
| `RegexpError` | 不正なパターンの `Regexp.new` |
| `IOError` | `File.read`、`Dir.mkdir` などの失敗（Ruby の `Errno::ENOENT` など。メッセージは Ruby のもの）。ソケットのエラー（拒否、リセット、未知のホスト） |
| `EOFError` | 組み込みは投げません（終端の読み出しは nil や `""` を返し、Ruby の EOFError は `IOError` に畳みます）。`rescue` に書くことはできます |
| `FloatDomainError` | NaN や Infinity の Integer への変換 |
| `Math::DomainError` | `Math.sqrt(-1)` など |
| `SystemStackError` | 10,000 より深い再帰 |
| `ThreadError` | デッドロック |
