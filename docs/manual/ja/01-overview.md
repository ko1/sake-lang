# 概要と実行

Sake（/seɪk/）は、型を書く場所を変えてみるための実験的な言語です。構文は Ruby のまま、型は**操作**に書き、変数・引数・返り値・フィールドには書きません。

```ruby
String.upcase(name)        # Sake
name.upcase                # Ruby の書き方。Sake では静的エラー（上の形を hint で示す）
```

この本は、v0 インタプリタ（`bin/sake`）が実装している言語の参照マニュアルです。入門には [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md) を、短い要約には [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md)（約 1 万トークン。AI に渡す用）を、設計の経緯には `DESIGN.md` を参照してください。

## 原則

1. **Ruby の構文。** Sake のプログラムは Prism が構文解析できる Ruby のプログラムです。Ruby の構文の部分集合を受け付け、いくつかの構文には別の意味を与えます。
2. **型は操作に書き、束縛には書かない。** 操作は `Type.op(subject, args...)` と、型を付けて呼びます。変数・引数・返り値・フィールドに型注釈はありません。
3. **呼び出し先は実行前にすべて決まる。** レシーバによる動的なディスパッチ、`method_missing`、リフレクションはありません。名前の誤りはプログラム全体について実行前に報告されます。
4. **値は型タグを持ち、すべての操作がそれを検査する。** 型の誤りは、その値を受け取った操作の行で報告されます。この検査は常に有効です。

## 実行

```
bin/sake FILE.sake              # 検査してから実行
bin/sake -c FILE.sake           # 検査のみ
bin/sake --strict FILE.sake     # より厳しく検査（レベル 2）してから実行
bin/sake --strict=3 FILE.sake   # レベル 0〜4、または項目名: --strict=type,nil
bin/sake --types FILE.sake      # 実験的: 推論した型を表示する
bin/sake --dump=ast FILE.sake   # 解決済みのプログラム（SakeAST）を表示する
```

| 終了コード | 意味 |
|---|---|
| 0 | 成功 |
| 1 | 実行時エラー |
| 2 | 実行前に問題が見つかった（何も実行していない） |

インタプリタは Ruby で書かれ、Ruby 4.0 を必要とします（4.0.2 と Prism 1.9.0 で試験）。他の依存はありません。

## 厳格さ（`--strict`）

`--strict` は、実行前にプログラムを止める問題の種類を選びます。各項目はプログラム全体の型推論から報告され、報告されなかったものは実行時に各操作が検査します。

| レベル | オプション | 項目 | 実行前に止めるもの |
|---|---|---|---|
| 0 | `--strict=0` | （無し） | 構文、名前、引数の数、ブロック、値へのメソッド呼び出し、禁止構文、`T[...]` のリテラルの型（常に検査） |
| 1 | 既定 | `type`, `rescue` | nil 以外の、操作に合わない型の値（`"" + 1`、または 1 か `""` を返す `pick() + 1`）。begin 本体が決して投げない例外の `rescue` |
| 2 | `--strict` | 上に加えて `nil`, `mixed` | nil かもしれない値を検査なしに使うこと（ただし「外れ」の nil は除く: `x[k]`、`Array.dig`、`Hash.dig`、`MatchData.begin`/`end`、空の容器への `Array.first`, `last`, `pop`, `shift`, `min`, `max`, `minmax`, `at`, `slice`, `sample`, `delete_at`, `Set.first`, `min`, `max`, `min_by`, `max_by`）。`mixed` の報告（下記） |
| 3 | `--strict=3` | 上に加えて `index-nil`, `exhaustive` | 「外れ」の nil を検査なしに使うこと。開いた型（String、Integer、リテラルで書かれていない Symbol など）の値が、どのリテラルの分岐にも取られないかもしれない `case`/`in` |
| 4 | `--strict=4` | 上のすべてと `unrescued` | rescue されずにトップレベルまで届くかもしれない `raise`（プログラム向け。ライブラリの raise は呼び出し側のためのもの） |

- **`mixed`。** 合わない型のすべてが、合う型と一緒に、あるクラスの 1 つのフィールド（またはフィールドに入った容器の要素）に現れる型の報告です。検査器はフィールドに構築場所ごとの型を与えますが（[クラス](07-classes.md)）、1 つの場所で作ったインスタンスを別の値に使うと（1 つの関数が作る Heap を Integer 用と Job 用に使う）型がそこで出会います。その報告は誤りではなく出会いである可能性が高いので、レベル 2 からプログラムを止め、レベル 1 では警告として印字します。代償として、本当に誤った型がフィールドに入った場合（Integer の port に `Config.new("h", "eighty")`）も `mixed` になります。そのような値は格納する場所、`initialize` で検査してください（`@port => Integer`）。
- **項目名で選ぶ。** `--strict=type,nil` はその項目だけを選びます。`--strict=2,index-nil` はレベルに項目を足し、`--strict=3,-index-nil` は引きます。
- **ラベル。** 各報告は `[type]` のように項目名で終わります。
- **関数の中のエラー。** 多相な関数の中の報告には、そこに至った呼び出しを示す hint が付きます。
- **到達しない分岐。** 分岐は評価されないので、決して走らない分岐の問題も報告されます（Erlang の Dialyzer と同じ）。
- **内部エラー。** 型推論自体が失敗したときは、警告を出して型検査を飛ばし、プログラムを実行します。
- **要素の組が多すぎるとき。** Array や Tuple の比較（`<`、`<=>`、ソート）は要素型の各組が比較できるか検査します。1 つの比較の要素型の組が 50,000 を超えると、その比較の要素は検査せず、比較の行に警告を出します。

## 静的エラーの形式

静的エラーは位置順にまとめて報告され、何も実行されません。

```
FILE:LINE:COLUMN: error: MESSAGE
  hint: SUGGESTION
```

## 実行時エラーの形式

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

種類の一覧は [例外とエラー](08-exceptions.md) にあります。
