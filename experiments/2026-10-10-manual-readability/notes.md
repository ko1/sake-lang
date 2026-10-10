# 利用感（2026-10-10: 言語の章を書き直しながら例を書いたエージェント 7 体の報告の要約）

各章に規則ごとの小さな例（3〜8 行）を書き、`bin/sake --strict=2` で走らせて出力を写した。合計で約 250 の fence。

## 良かった

- **エラーの文がそのまま文書になる。** 「parameters after `*rest` are not supported: required, optional, `*rest`, keywords, `**opts`, in that order」「Shape.area dispatches to Rect.area, whose arguments or block differ」「Point does not include Arithmetic / hint: add `include Arithmetic` and `def +(a, b)`」。`# !>` の行に貼れる安定さがある。
- **hint が Sake の綴りを教える**ので、a1 の対応表（Ruby の書き方 → Sake の書き方）は行ごとに機械的に検証できた。`Point.new(1, 2) creates one Point; Point[...] is an Array of Point`、`keep the match: m = String.match(s, re), then m[1]`。
- Ruby と同じに動くもの: `f(k:)`、`return a, b` を `a, b = f()` で受ける、Tuple の変数を `*rest` に展開、`Hash.each(h) do |k, v|`、`attr_accessor value, :next`（裸と Symbol の混在）、`Time.at(0, in: "+00:00")`。
- 失敗する例は 1 行ずつ `ruby error` の fence にするだけでよく、`Exception.message(e)` は union のまま呼べる。
- 関数は呼び出しごとに検査されるので、「誤りを見せる例」は誤った呼び出しを 1 つ足せばよい（`greet()` を足すと `hint: reached by the call at line 5` が付く）。最初は驚き、すぐ便利になった。
- `Dir.mktmpdir` / `File.delete` / `Dir.rmdir` で自己完結のファイル例が 6 行。`Open3.capture2("echo", "hi")` の多重代入は Tuple に合う。

## つまずいた

- **1 つの fence には実行時エラーが 1 つ**（最初で止まる）。静的エラーが 1 つでもあると実行時の行は 1 つも走らない。`# !>` ごとに fence を分けることになる。「`--strict=2` で走らせる」と「実行時の形を見せる」が引っ張り合い、実行時の表のほとんど（Tuple の範囲外、型付き Array の書き込み、混在のソート…）は level 2 では静的に止まるので、文で `--strict=0` の文言を引用した。
- **nil のレベル。** `String.match` は level 2 で `MatchData | nil` なので、4 行の例でも `if m` が要る。`Array.first` の nil は level 3 なので level 2 の絞り込みの例には使えず、省略できる引数やフィールドの読みで nil を作る。「構築場所ごとの型」のせいで、フィールドの nil を見せるには `def mk(v) = Node.new(v, nil)` のような工場が要る。`@y ||= 0` はフィールドを絞らない。
- `xs[5] + 1` を `--strict=2` が通す（level 3 の項目）。`--strict` を「nil を捕まえる」と読む人は踏む。
- `STDOUT` は値でない（`IO.stdout`）。`return` はトップレベルで静的エラーなので、早期脱出の例は `def` の中に。`x in T` は引数・三項・`&&` の位置で必ず括弧（hint がそう言う）。`p(f() rescue -1)` は構文エラー（Ruby と同じ）。
- `Shape` の関数から、`Circle < Shape` と `Square < Shape` だけが定義する `area(s)` を型無しで呼べない（写しなので Shape にはない）。テンプレートメソッドの形は組めず、例を組み替えた。
- hint の外し: `def bump = count + 1` でトップレベルのローカル `count` を読むと `String.count()`… の 5 候補。`f = proc { }` は「undefined function `proc`」だけ。`JSON.parse` の結果（7 型の union）に添字すると全 Indexable の署名が並び、hint が「Tuple か Record に」と逆を指す。
- 複数行を印字する例（`Integer.times(3) { |i| p(i) }`）に 1 つの `# =>` は付けられない。Array に集めて 1 回印字した。
- minitest は `Minitest.test` の時点でブロックを走らせ、`Minitest.run` は報告だけ。Ruby の読者は run が走らせると思う。報告に時間の行があるので `# =>` にできない。
- 環境: 同じ scratchpad を複数体が共有すると他人の `g*.sake` が自分の glob に入る（1 体は個別ディレクトリに移った）。`lib/` を同時に直していた時間帯は `bin/sake` が一時的に壊れ、1 体は `git archive HEAD` の写しで検証して最後に本体で再確認した。sandbox はこの機械で起動せず、全員が外して走らせた。

## 入れ子の名前空間（同日に実装、agent の報告は sakelib の書き換え後に追記）

## 02 章（入れ子の名前空間を入れたあとに 1 体）

- `p(x in T)` は構文エラーで `p((x in T))` が要る（hint は明確だが 2 度踏んだ）。真偽を見せる例は必ず二重括弧になる。
- `# !>` にはエラーの文だけが載り hint が落ちるので、「`upcase` は `String.upcase`、`Symbol.upcase` にある」のような一番役に立つ部分は文で補った。
- `module_function :f` を def の後に書くのが、mixin 関数と module 関数を 1 つの module に並べる書き方。裸の `module_function` は以降を全部 module 関数にする（それで Shape の例が誤報告になった → TODO）。
- 良い: resolver の文がそのまま文書になる（`include Summary in Empty: Summary.total needs \`items\`, which Empty does not define (used at line 2)`）。「require は先に全部読む」規則は両ファイルの `puts` で簡単に示せた。
