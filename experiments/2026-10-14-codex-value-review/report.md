# 結論

Sakeには価値がある。ただし、現状その価値は「AIが実用コードを書くための新言語」にはなく、型情報を利用箇所へ置く設計を最後まで押し通し、その利点と破綻点を大量の実験で可視化した研究成果にある。一般利用・人手での開発には、利益より制約と生態系コストの方が大きい。ネイティブ性能は有望だが、型を操作に書く記法そのものの成果ではない。

## 検証範囲

指定文書、500本コーパス、AI評価、ネイティブ、Web、ライブラリ移植の報告を読んだ。さらに次を実行した。

- examplesの59本: 59/59成功、177 assertions。
- 小テスト: 209/210成功。残る1件はsandboxがsocket作成を禁止したためで、言語上の失敗ではない。
- CSV、Base64、digest、Liquid、kramdown、JMESPath、Sinatraの7組: Sakeをstrict=2で実行し、実Rubyライブラリ版と出力一致。
- [確認用プログラム](tmp-review/locality.sake#L1) は通常実行・strict=2とも成功。`s.strip` は実際に拒否され、`String.strip(s)` と `s.String.strip` がhintになった。
- `sabic`で再帰fibをRust経由でコンパイルし、結果6765を確認した。
- ライブラリ全94比較テストは、テスト中に作業ディレクトリへファイルを書くものがあるため、指定された書込制約に従って全実行はしていない。

# 1. コアアイデア

### 確認したこと

Sakeの原理は単に「型推論するRuby」ではない。束縛側への型注釈を禁止し、`T.op(x)` の `T` を型情報源にする設計である。[DESIGN.md:24](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/DESIGN.md#L24) は、型を一度宣言する代わりに利用ごとに反復し、その冗長さを整合性検査に使うと明記している。

これは完全に新しい意味論ではない。Elixir/ErlangやOCamlでは以前から `String.upcase(s)` や `String.length s` のようにモジュール修飾された関数を呼ぶ。Rustにも完全修飾呼び出しがある。リポジトリ自身も、新規性を「Elixirの慣習を、型と第1引数の一致を検査する強制規則にした小さな差」と評価している。[comparison.md:31](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/docs/comparison.md#L31) 実装された推論器も、当初想定した後ろ向き推論ではなく前向き抽象解釈であり、設計文書は解析技法自体の新規性を否定している。[DESIGN.md:175](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/DESIGN.md#L175)

最も効く例は、操作対象と同名メソッドが多い箇所である。

```ruby
def normalize(user)
  String.upcase(String.strip(User.name(user)))
end
```

この1行から、`name`、`strip`、`upcase`の探索先は分かる。Rubyの

```ruby
def normalize(user)
  user.name.strip.upcase
end
```

では、動的には各返り値のクラスを追わないと呼び先が確定しない。スペル、引数数、明らかな型違いを起動前に検査できることも実益である。

一方、API境界の説明力は逆に弱い。

```ruby
def headline(post)
  String.upcase(String.strip(Post.title(post)))
end
```

この本体は局所的に明瞭だが、`headline`が何を受け取り何を返すかは宣言にない。RBSなら本体を短く保ったまま、

```rbs
def headline: (Post) -> String
```

と一度だけ契約を書ける。RBSはメソッド、フィールド、継承・mixinまで記述する言語である。[RBS公式](https://github.com/ruby/rbs) OCamlも局所推論とモジュール署名を分け、規模が大きい場合の別コンパイルと境界文書化を解いている。[OCaml公式](https://ocaml.org/docs/compiler-frontend)

### 判断

新規性は「小さいが本物」である。ただし新しい型システムではなく、既存のmodule-qualified functionを必須にし、束縛注釈を禁止した未探索の組合せである。

得るものは三つある。

1. 呼出箇所で要求型と探索名前空間が見える。
2. `x`の供給型が不明でも、`String.upcase(x)`から要求だけは得られる。
3. 型宣言と実装の同期ずれがない。

失うものはより大きい。

1. 型表記の量が定義数ではなく操作数に比例する。
2. 公開APIの契約が一箇所に存在しない。
3. 操作されないデータ、空の容器、フィールドには型を書く場所がなく、全体解析が必要になる。この限界は設計文書自身が認めている。[DESIGN.md:35](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/DESIGN.md#L35)
4. 閉じた世界と静的な呼出候補を守るため、反射、高階値、継承などを削る。

また「一行でどの関数が走るか分かる」は過剰な表現である。`String.upcase(x)`では正しいが、`Shape.area(s)`は第1引数の型で実装を選び、`(A|B).f(x)`も候補集合しか示さない。[spec.md:303](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/docs/spec.md#L303) `a + b`、`a[i]`、裸の関数呼び出しも暗黙解決である。[spec.md:490](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/docs/spec.md#L490) 正確には「多くの通常呼び出しで、探索名前空間または候補集合がその行に出る」だ。

Ruby+RBS/Steep/Sorbet、Go、OCaml/F#は境界の契約と別コンパイルに強く、Sakeは利用箇所の局所性に強い。CrystalやTypeProfは注釈を減らしつつ既存のメソッド記法を保つ。Elixirは最も近いが、モジュールを型と同一視せず、高階関数も動的な表現力も保つ。[Elixir公式](https://elixir.hexdocs.pm/gradual-set-theoretic-types.html) この比較では、Sakeが新たに買った局所性より、支払った一般性の方が大きい。

# 2. 誰に価値があるか

### 確認したこと

AI評価では、Sonnet級はRubyとほぼ同じ正しさに到達したが、Sakeの生成コストは概ね1.1～2.4倍だった。小さいHaikuではSake 26%、Ruby 77%と大差が出た。[README.md:233](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/README.md#L233) P3では存在しないAPIがほぼゼロである一方、出力トークンは試行あり1.62倍、一発2.37倍だった。[AI評価:316](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L316)

人間によるレビューは測られていない。[README.md:260](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/README.md#L260) 手書きコードでは、500本の比較でSakeはRubyより行数が5%少ないが、字句トークンは16%多く、ソースの9.6%が操作の型名だった。フィールドアクセスは特に長くなる。[review:67](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-review/README.md#L67)

ネイティブ版は3マイクロベンチでRuby YJITの2.7～21倍、手書きRustの0.9～1.6倍だったが、Hash、例外、Thread等は対象外で、Integerの意味もインタプリタと異なる。[rust-backend:19](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-10-rust-backend/README.md#L19) [rust-backend:108](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-10-rust-backend/README.md#L108)

### 判断

| 対象 | 評価 | 理由 |
|---|---|---|
| AIによるコード生成 | 現状は負 | 強いモデルでも同じ正しさに余分なトークンを払い、弱いモデルでは品質が崩れる。型付き操作が誤りを減らした証拠もない |
| AIコードを人がレビュー | 研究仮説として有望、製品価値は未証明 | 動的ディスパッチを追う必要は減るが、型名の反復が業務ロジックを埋める。しかも演算子・mixin・裸呼び出しでは具体的な実装が見えない |
| 人間が手で書く | 大半の用途で負 | Rubyに似ているのに重要な慣用句が使えず、タイプ量と認知的な例外が増える |
| Ruby風コードのネイティブ化 | 限定的に正 | 閉じた世界と単相化しやすい制約には価値がある。ただし操作に型を書く構文は性能の必要条件ではない |
| 教育 | 限定的 | 「データと操作を分け、要求型を利用箇所から読む」教材にはなる。だがRubyの学習用としては似て非なる規則が多すぎる |
| 研究 | 強く正 | 設計を実装し、否定的結果、コーパス、失敗、訂正まで公開した点が最大の成果 |

AI向けという主目的については、今の答えは「価値なし」に近い。モデルにとってAPI選択が明示的になる可能性はあるが、SonnetではAPI幻覚が既に床に張り付き、Haikuでは未知言語税が利益を圧倒した。型付きAPIスキーマ、コンパイラ診断、LSPを既存言語に与える方が、モデルの事前学習を捨てずに同じ利益を狙える。

人間レビュー向けは唯一、コア記法そのものに未検証の実用可能性がある。例えば、

```ruby
total = Array.sum(prices)
name  = User.name(user)
```

は、`prices.sum`、`user.name`より検索先が明示的である。ただしレビューでは呼出先だけでなく、`prices`の不変条件、`user`の生成経路、nil、認可、例外、制御フローを見る。Sakeが可視化するのはその一部である。型名反復のノイズが利益を上回る可能性も十分ある。

人手での一般開発には勧めない。`[]`がTuple、`{}`がRecord、値定数なし、第一級ブロックなし、継承は「写し」、値メソッド禁止という差は、Ruby経験を資産より罠にする。59例とライブラリ移植は「書ける」ことを示したが、「書きたい」「保守しやすい」は示していない。

性能用途では、価値があるのは「Rubyの動的意味論の一部を言語から除けば、小さいAOTコンパイラで高性能にできる」という結果である。Spinelと整数・配列ベンチがほぼ同速で、解析器の規模が大きく異なるという結果は興味深い。[rust-backend:54](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-10-rust-backend/README.md#L54) ただしこれは「`String.upcase(s)`と綴ったから速い」のではなく、静的呼出先、閉じた型集合、限定されたブロック、反射禁止が効いている。

# 3. 証拠は問いに答えているか

### 確認したこと

評価はかなり誠実である。隠しテスト、正負の対照、公開例と採点の分離、訂正履歴を持ち、都合の悪い結果も残している。当初は1セル5反復・API直接実行を計画していたが、実際の多くはClaude Code subagent、1～4反復で実施された。[AI評価:51](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L51) [AI評価:123](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L123)

SQL実験の集計は算術的に整合している。Rubyの平均出力192kに対しSake 328.5kで1.71倍、行数比は約1.25、隠しテストは全系列366～368/369である。[AI評価:918](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L918) Java、Haskell、Scheme、Steepを加えても正しさは天井で、型検査が防いだと特定できる最終バグはなかった。[AI評価:969](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L969)

したがって「型を置く場所の効果を未知言語税から切り分けられなかった」という結論は正しい。むしろ「支持されなかった」より厳密には、「介入が束になっているため、因果仮説を直接検定していない」である。

### 判断

この評価は次の記述的問いには答えている。

- 初見のSakeでも、強いモデルは資料と実行環境があれば大きなプログラムを作れる。
- そのコストは既知のRubyより大きい。
- 弱いモデルほど未知言語税が大きい。
- この課題群ではSakeの型検査による最終正答率の優位は観測されない。

しかし「操作に型を書く方が、変数に書くより良いか」には答えられない。理由は四つある。

1. Sake対他言語は、型の位置だけでなく、構文、生態系、意味論、資料量、モデルの事前学習量が同時に違う。
2. SQLの369テストは369独立標本ではない。実験単位は各言語2系列であり、統計的には極小である。
3. 366～368/369は強い天井効果である。「差を検出できなかった」は「同等」の証明ではない。
4. 1体が複数課題を解く実験では課題を独立標本として扱えない。モデルの一回の軌跡にクラスタ化されている。

「出力トークン−可視出力」を思考トークンと呼ぶ指標も、課金・生成負担の代理としては有用だが、認知過程の測定ではない。READMEも近似であると明記している。[AI評価:16](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L16)

説得力あるAI実験には、同じ処理系・標準ライブラリ・診断・IRを共有し、表面構文だけが異なる二つの人工方言が要る。

- A: `String.upcase(x)`型の利用箇所注釈。
- B: `def f(x: String) -> String; x.upcase; end`型の束縛・境界注釈。
- 可能ならC: 注釈なし＋IDE inlay。
- 課題40～60、少なくとも各セル20～30独立run、2～3モデル、順序と課題を無作為化。
- 主指標はpass@1、修復後正答率、生成トークン、実行回数、静的診断が実際に阻止した欠陥数。
- 誤りを「操作対象の型」「値の不変条件」「nil」「制御・仕様」に事前分類する。
- 40課題×2方言×30反復×3モデルなら7,200 task-runs、概算72～216M生成トークン級である。

人間レビュー仮説は別実験にする。Ruby経験者48～60名、両方の記法を学ぶ短い訓練、12～16パッチの被験者内crossover、Latin squareで順序を平衡化する。誤った操作対象、データ不変条件、nil、認可、制御フローの欠陥を同数仕込み、検出率、時間、誤検出、確信度、負荷を測る。参加者時間は144～180時間、準備を含め1～2人月程度が現実的な規模である。

過小評価されている証拠もある。500本では型が99%以上「決まる」一方、level 1でも正しい52/500本を拒否し、level 2では約半数以上を拒否した時期がある。[inference-500:247](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-01-inference-500/README.md#L247) また静的に証明できた検査の45%はフィールドと容器要素の全体解析に依存する。[local-analysis:104](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-02-local-analysis/README.md#L104) これは「操作に型があるから推論が局所的」という物語への強い反証である。

# 4. 本質的なものと付随的なもの

### 確認したこと

Sakeは次を一つに束ねている。

| 要素 | コア仮説との関係 |
|---|---|
| 通常操作を必ず`T.op(x)`で書く | 本質 |
| 値へのメソッド呼び出しを禁止 | 本質 |
| 変数・引数・返り値・フィールドの型注釈を禁止 | 本質 |
| 呼出候補を閉じ、実行前に決める | 「一行で分かる」主張には本質 |
| 全プログラム推論 | 型注釈を全面禁止した結果として必要 |
| strict 0～4、`mixed`、nil分類 | 付随的な検査UX |
| Ruby構文・Ruby API名 | 移行・AI事前知識のための表面設計 |
| 構築場所ごとの型 | 推論精度を上げる実装選択 |
| Tuple/Recordへのリテラル再割当て | 付随的 |
| 値定数なし | 付随的 |
| 継承なし | 静的候補集合には便利だが、型を操作に置くこと自体には不要 |
| 第一級ブロックなし | 厳密な局所呼出先には都合がよいが、技術的必然ではない |

第一級ブロックは実験上、解析時間がブロック数に線形で、実装可能だった。拒否理由は爆発ではなく、異なる引数型のblockを容器に入れたときの精度低下である。[proc-values:39](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-04-proc-values/README.md#L39) したがって「第一級ブロックがない」はコア原理の論理的帰結ではなく、「呼出先を閉じ、簡単な解析を保つ」という追加方針である。

### 判断

価値のかなりの部分は、新言語なしで提供できる。

第一候補はTypeProf/RBSを使うRuby用LSPである。ソースは、

```ruby
user.name.strip.upcase
```

のまま保ち、各呼出位置に、

```text
User#name → String#strip → String#upcase
```

というinlay、hover、go-to-definition、曖昧な候補数を表示する。「一行で呼出先が分かる」という人間向け価値を、型名反復と生態系断絶なしで得られる。TypeProfは現在も「Rubyコードを理解するためのtype-level interpreter」と位置づけられている。[TypeProf公式](https://github.com/ruby/typeprof)

第二候補は「静的に解決可能なRuby」プロファイルである。

- `send`、`eval`、`method_missing`、open class等をlintする。
- 動的になったcall siteだけ警告する。
- RBSがある境界ではそれを使い、内部はTypeProfで推論する。
- CIでは「新しい未解決call siteを増やさない」を検査する。
- AOT対象部分だけ閉世界として切り出す。

これならSakeが禁止しているものを、プロジェクト全体の絶対禁止ではなく、性能・検査が必要な部分の選択的制約にできる。

第三候補はAPIをSake風の関数として提供するRubyライブラリ／スタイルである。

```ruby
Strings.upcase(name)
Arrays.map(xs) { ... }
```

これは呼出先を明示できるが、Ruby標準の`String.upcase(s)`は一般にクラスメソッドではないため、wrapper群が必要になる。全面変換は冗長だが、AI生成境界、セキュリティ上重要な変換、複数型に同名メソッドがある場所だけで使うなら現実的である。

逆に、Sake固有でツールだけでは完全に再現できないのは「束縛型を一切持たず、すべての利用箇所を要求の根拠にする」という言語実験である。ただし現行実装は後ろ向きの要求推論を中心にしておらず、値の供給を全体に流している。500本で推論精度が高いことは成果だが、その精度が型付き操作そのものから何割来たかは分解されていない。TypeProfとの99%対91%も、制限された閉世界言語と完全なRuby、異なる測定単位、TypeProfの49 timeoutを含むため、純粋な記法比較にはならない。[inference-500:83](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-01-inference-500/README.md#L83)

従って、価値を三つに分けるべきである。

1. 利用箇所で呼出先を見せるUX――Rubyツールで提供できる。
2. 閉世界Ruby風部分集合の静的解析・AOT――別の言語でなくRubyプロファイルでも試せる。
3. 束縛注釈を禁止する設計思想――Sakeという研究言語でなければ検証できない。

現在はこの三つを一言で「型を操作に書く価値」とまとめすぎている。

# 5. コストとリスク

### 確認したこと

表面上の冗長性は実測されている。自然さを見直した500本で、SakeはRubyより行数5%減、字句16%増、AI tokenizerで約6.5～11.8%増だった。[review:67](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-review/README.md#L67) 生成過程では1.4～2.4倍になるため、約7～16%が記法の物理的コスト、それを越える部分は未知言語・探索・書換えのコストと読める。

ライブラリ移植は大きな実装証拠だが、互換性証拠ではない。現checkoutには`sakelib/*.sake`が98本、比較用Sakeテストが94本ある。一方、移植ノートはstored block、反射、クラスを値で渡すAPI、動的DSL、暗号、ストリーム等の欠落を明記している。[not-ported.md:41](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/sakelib/notes/not-ported.md#L41) これらはupstreamの全テストスイートではなく、Ruby版と並行して書いた選択的な比較プログラムである。[sakelib/README.md:8](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/sakelib/README.md#L8)

Web実験も同様である。Sinatraはstored route blockを保持できないため、要求ごとにroute関数を複数回走らせる別設計になった。Rails型は1,362行の小フレームワークで、CSRF、暗号化Cookie、JSON、一般的callback、association、migration等を欠く。[web:24](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-12-web/README.md#L24) [web:48](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-12-web/README.md#L48)

### 判断

各コストの性質は異なる。

- **操作ごとの型名反復**は本質的で修正不能。省略すればコア仮説を捨てることになる。chain構文で括弧は減らせても型名は減らせない。
- **値メソッド禁止**も本質的。許せば「すべての操作が型を名乗る」規則は崩れる。
- **全プログラム解析**は、「型を束縛・境界・フィールドに一切書かない」ことと可変状態を併存させる限り、ほぼ本質的。モジュール別署名やキャッシュを導入すれば改善できるが、実質的に境界型を復活させる。
- **第一級ブロックなし**は修正可能。ただし導入するとcall target集合、escaping closure、共有変数を扱う必要があり、局所性の主張が弱くなる。
- **継承なし**は修正可能。静的継承やsealed hierarchyは可能だが、open subtype dispatchは「実装がその行で分かる」と衝突する。
- **値定数なし**はほぼ不要な制約で、コア価値に寄与しない。関数との名前空間衝突を別構文で解けばよい。
- **`[]`がTuple、`{}`がRecord**も本質ではない。Ruby互換を名乗るなら摩擦の方が大きい。
- **反射・動的定義なし**はAOTには有効だが、Ruby生態系との互換性を決定的に失わせる。

「未知言語税」は、十分な学習データや専用モデルができれば縮むので理論上は修正可能である。しかし採用者がいないと言語データが増えず、モデルが不得意だから採用者が増えないというbootstrap問題がある。しかもP2では、1エージェントの課題数を5から20へ増やしても、文書を短くしても題ごとの生成費用は下がらなかった。[AI評価:216](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/experiments/2026-10-05-ai-writability/README.md#L216) 少なくとも短期の慣れで消える税ではない。

生態系リスクは最大である。「Rubyの名前が使える」は互換性ではない。Gemの価値は関数名だけでなく、object model、継承、Proc、Enumerator、reflection、DSL、C extension、データ形式、upstream test、保守コミュニティにある。Sake移植は驚くほど多くを書き直せることを示したが、それは移植費用の大きさも同時に示している。

ネイティブ性能も慎重に扱うべきである。現在の数値は優秀だが、3～5マイクロベンチ、部分集合、C backendはメモリ非解放、64-bit整数という条件付きである。実用価値を主張するには、JSON、Hash、文字列、例外、長寿命オブジェクト、サーバ、GCを含む現実的負荷でCrystal、Spinel、YJIT、手書きRust/Cと比較する必要がある。

# 6. 評決と勧告

### 評決

Sakeは、一般目的言語としては現時点で価値が薄い。AI向け言語としての主仮説は支持されず、人間向けには局所的な読みやすさの可能性より、反復、全体解析、生態系喪失、表現力制限の方が大きい。ここへさらにライブラリを移植しても、この評価は変わりにくい。

一方、研究成果としては明確な価値がある。二週間規模で一つの設計点を、処理系、500～1,000本のコーパス、59例、ライブラリ、Web、AOT、複数モデル・複数言語評価まで押し通し、仮説が支持されなかったこと、測定ミスと撤回まで残した。この成果は「新言語Sake」より、「利用箇所型修飾を強制したとき何が起きるか」「未知言語をLLMに使わせる税」「制限したRuby風言語の解析可能性」として強い。

### 推奨順位

1. **言語機能の拡張を止め、研究artifactとしてまとめる。**

   主張は「型を操作に書けばAIが書きやすい」ではなく、「mandatory use-site type qualificationを実装・評価したが、未知言語税から正の効果を分離できず、現データでは支持されなかった」とする。否定的結果、500本推論、局所解析、LLM費用、AOTの四本を一つの論文／技術報告にまとめる。これは最も費用対効果が高い。

2. **価値のある部分をRubyツールへ移す。**

   TypeProf/RBS/LSP上で、各call siteの推定receiver型、解決候補、具体的定義、動的に残った理由をinlay表示する。「Sake mode」として`send`等の動的機能、未解決call、型が広がったcontainerを警告する。AI向けには、診断を構造化JSONにし、自動書換え候補を返す。Sakeの最も説得力あるUXを、Rubyの学習データとGem生態系を捨てずに届けられる。

3. **人間レビュー実験を一度だけ行う。**

   ここで明確な効果が出れば、Sake記法の存在理由が初めて得られる。出なければコア仮説は実用面で閉じてよい。言語機能や移植を増やす前に行うべきである。

4. **AOTを続けるなら別の主張に切り分ける。**

   「型を操作に書く言語」ではなく、「静的呼出先を持つ閉世界Ruby風部分集合」として評価する。現実的ベンチ、GC、Hash、String、例外を実装し、Crystal・Spinelと比較する。成果が出ても、それは主に意味論の制限とコンパイラ単純化の成果だと明記する。

5. **Gem/Rails互換の拡張は優先しない。**

   現在の移植は十分に表現力を証明した。これ以上は、コア仮説の検証ではなく、維持不能な第二の生態系を作る作業になる。実利用者と固有用途が現れるまで止めるべきである。

「停止」は失敗ではない。このプロジェクトで最も価値がある行為は、仮説を守るために結果を言い換えず、適切に閉じることである。READMEの現在の結論はその方向にかなり近い。[README.md:221](https://github.com/ko1/sake-lang/blob/eb831ca157ab1d50135016b8cdd7efd48f0e208e/README.md#L221) ただし「開発を小さく続ける」より、「研究対象を凍結し、Rubyツールと人間実験へ資源を移す」を勧める。

# 最も強い賛成材料

- 利用箇所型修飾を徹底した、狭いが実在する未探索の設計点である。
- 500本で99%以上の型が決まり、制限された閉世界言語の解析容易性を実証した。
- 強いモデルは未知言語でも4,000行級を高い正しさで扱えた。
- 小さいAOTコンパイラで手書きRust/Cに近い性能を出せる可能性を示した。
- 否定的結果、誤測定、撤回を含む実験記録そのものが研究資産である。

# 最も強い反対材料

- AIにとっての正しさの優位はなく、生成費用は一貫して高い。
- 弱いモデルでは未知言語税が致命的だった。
- 型名反復は本質的で、API境界の契約や別コンパイルには不利である。
- 「一行で実装が分かる」は演算子、mixin、union dispatch、裸呼出しでは成立しない。
- 第一級ブロック、継承、反射、値定数、Ruby DSLを失い、Ruby生態系との互換性は名前の互換に留まる。
- 実用上有望な部分の多くは、Ruby向けLSP、linter、RBS/TypeProf拡張、AOTプロファイルとして提供できる。