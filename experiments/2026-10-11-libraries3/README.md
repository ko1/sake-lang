# 表記の総点検と、gem 18 本の移植（2026-10-11）

ko1 の依頼（2026-10-11 朝、数時間不在の間に）: (1) ライブラリ・例・ドキュメントに古い表記がないか総点検する、(2) ライブラリを増やして Sake を試せるようにし、Ruby と Sake を見比べて検討できるようにする。

## 方法

- エージェント 7 体（Claude、各 2 時間程度）。点検 2 体（ドキュメント、コード）は `audit-brief.md`、移植 5 体は `brief.md` を渡した。移植は手元に入っている gem に限り、Ruby 側の比較プログラムは本物の gem で動かす。比較プログラムは Ruby 版と Sake 版を行ごとに揃えて書く（同じ順序・変数名・コメント）よう指示した。
- 見比べるためのページ `tools/gen_compare.rb` を書いた。各ライブラリの `test/sakelib/NAME.rb` と `NAME.sake` を左右に並べ、移植ソースをタブで出す。GitHub Pages の `compare.html`（<https://ko1.github.io/sake-lang/compare.html>）と artifact（<https://claude.ai/artifact/WSpe7KSiXHWyVcjfGAmTTp>、`compare.html` を `--fragment` で生成）。
- エージェントが見つけた処理系のバグは私が直し、`test/samples/` に回帰テストを足した。

## 結果

### 点検

- ドキュメント（`audit-docs.md`）: README、spec、tutorial、guide、cheatsheet、マニュアル日英で、今の言語と合わない記述を直した（`Math::PI` は動く、`class B < A` は写し、入れ子の名前空間とクラス本体に書けるもの、Enum、`require "dir/*"`、短い endless def、「Struct 値」→「クラスのインスタンス」など）。
- コード（`audit-code.md`）: sakelib の平らな名前を入れ子に（`KNode` → `Kramdown::Element`、`ERBNode` → `ERB::Node`、`DateCore` → `Date::Core`、`HTTPartyClient` → `HTTParty::Client` など）、長い `def f = expr` を約 20 箇所 `def ... end` に、古いコメント（「Struct 型」「include は借りる」、既にある機能を「無い」と書いたもの）を直した。出力は変わらない。

### 移植した gem（18 本、すべて Ruby の gem と同じ出力）

| gem | 操作数 | Ruby の行数 → Sake の行数（コード行） | 主な欠落と理由 |
|---|---|---|---|
| jmespath | search と 26 関数 | 2033 → 925 | Struct/IO のデータ（反射が無い） |
| hana | 13 | 196 → 223 | 例外の継承が無い |
| msgpack | 約 50 | 267（+C 約 2030）→ 471 | `register_type`（クラスと Proc を値で渡す） |
| pstore | 12 | 220 → 150 | Marshal でなく JSON に保存、flock なし |
| crass | 約 31 | 1017 → 889 | IO 入力 |
| useragent | 約 50 | 1147 → 920 | `ua.chrome` 式の method_missing |
| mini_mime | 15 | 148 → 123 | なし（gem のデータファイルを読む） |
| erubi | 6 + 18 オプション | 210 → 192 | capture エンジン（eval と値としてのブロック）。src は Ruby と一致、render は Sake の ERB で解釈 |
| protocol_hpack | 27 | 約 426（+表 575）→ 約 387（+表 52） | Huffman は状態機械でなくビット単位 |
| simpleidn | 9 | 173（+表 6528）→ 168（+表 717） | なし |
| websocket | 約 45 | 973 → 545 | 古い draft、`from_hash` |
| net_smtp | 約 60 | 618 → 391 | STARTTLS（接続済みソケットを TLS にできない） |
| fugit | 約 45 | 約 930 → 884 | 名前付きタイムゾーン、`Fugit::Nat` |
| rss | 約 60（25 クラス） | 約 4300 → 656 | RSS 1.0、拡張モジュール |
| rainbow | 31 | 559 → 129 | ラッパごとの on/off |
| addressable | 約 95 | 約 2350 → 1363 | テンプレートのプロセッサ（`respond_to?`） |
| public_suffix | 約 45 | 287 → 288 | `default_rule:` |
| unicode_display_width | 10 | 258 → 318（約 120 は Marshal 読み） | 非 UTF-8 |

### 見つかった処理系のバグ（直した）

1. `s["b"]`、`s[/re/]`、`s[/re/, 1]`（String の String・Regexp 添字）が型エラーだった。仕様として「演算子としては無い」と書いてあったが、`String.slice` は同じものを取り、移植 2 体がつまずいたので Ruby に合わせて通した。**仕様の変更なので ko1 の判断を仰ぐ**（戻すのは型規則 2 行と実行時 1 行）。
2. `Array.flatten` が Tuple を展開しなかった（`String.scan` のグループの組が平らにならない）。これも仕様として書かれていたが、Ruby の `[[1, 2], [3, 4]].flatten` の慣用に合わせて展開するようにした。**同じく判断を仰ぐ**。
3. `if u` などの真偽判定が、クラスに定義された `==` を `false` 相手に呼んでいた（`Values.truthy?` の `v == false`）。同一性の比較にした。
4. `x&.T.f`（連鎖の段の `&.`）が受理され、nil で止まらない `.` として走っていた。静的エラーにした。
5. `include ::Comparable` の `::` が読み捨てられ、外側の名前空間の `Comparable` を指していた。先頭の `::` は最上位から解決するようにした。
6. 定数に値を代入したときのエラー文が「Struct.new のクラスだけ」と言っていた（`Exception.new` もクラス定義も書ける）。文言を直した。

### 直していないもの（TODO に記録）

- `initialize` から呼んだ補助関数がフィールドを設定しても、検査器は「nil かもしれない」と見る（3 体が報告）。設定は `initialize` の本体に書く必要がある。
- `def port(h)` がクラスの `attr_reader port` を黙って置き換える（Ruby と同じだが、逆向き（フィールドが mixin の関数を隠す）は分かりにくい）。
- 入れ子の名前空間の中で、外側の名前空間の関数は修飾が要る（`A.f`）。型名は外側まで探す。Ruby でも `B` の中の素の `f` は `B` のメソッドなので Ruby と同じだが、型名との非対称は分かりにくい。
- 例外の階層が無いので `rescue WebSocket::Error` で下位の例外を捕まえられない（4 体が要望）。設計判断（DESIGN.md）。

## 利用感（エージェントの報告から）

- **よかった点**: 4 本は最初に通った実行で Ruby と一致した。mixin（`include` と `M.f(x)` の振り分け）は Ruby のクラス階層の読み替えとして素直に書けた（useragent の 15 のブラウザクラス、public_suffix の Rule）。検査器が本当の漏れを見つけた（addressable で `omit(:bogus)` の `case` の枝が無かった）。
- **Ruby の定数が関数になる**: 同じクラスの中でも `Template.EXPRESSION` と修飾が要り、裸の大文字名は型と読まれる。
- **1 つの名前に 1 つの関数**: クラスメソッドとインスタンスメソッドが同名のとき（`URI.join`、`Net::SMTP.start`）、片方を改名するか引数の型で振り分ける。
- **長い名前**: `WebSocket::Frame::Incoming::Client.type(f)` のように、入れ子の名前を毎回書くので行が Ruby の 2〜3 倍に伸びる（websocket の報告）。
- **エラーの場所**: 引数が原因の型エラーがライブラリ内部の行で報告され、「reached by the call at line N」だけが呼び出し側を指す。合併型が大きいと（Hash の構築場所が 40 個など）メッセージが途中で切れ、肝心の nil が見えない。
- **フィールドの初期化**: `initialize` の無いクラスは全フィールドが必須になるので、組み立て型のクラスには空の `def initialize(x) end` が要る（rss で 7 クラス）。
- **リテラル**: `[...]` が Tuple なので表のリテラルが何度も壊れた。Record は `p` でキーを整列して出すので、Ruby の `to_h` の出力に合わせるには Hash にする。
- **検査の時間**: jmespath の検査に約 15 秒（負荷の高いマシンで）。実行は速い。

## ファイル

- `brief.md`、`audit-brief.md`: エージェントへの指示
- `audit-docs.md`、`audit-code.md`: 点検の変更一覧
- `compare.html`: 比較ページ（artifact 用に生成したもの。`ruby tools/gen_compare.rb --fragment` で再生成できるので git には入れない）
- 移植の詳細は各 `sakelib/notes/<gem>.md`
