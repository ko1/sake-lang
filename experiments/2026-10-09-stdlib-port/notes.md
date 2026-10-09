# 気づいた点（移植と、Sake でテストを書いていて）

書式: 何が起きたか → なぜ → どうしたか / 提案。日付は JST。

## 10-09: コア API の穴埋めと minitest

1. **`[1, 2]` は Tuple で、Array の結果と `==` で等しくならない。** `assert_equal(t, [1, 2], Array.sort!(a))` が失敗する。
   Ruby では両方 Array。Sake では「中身が同じなら等しい」のは同じ種類の中だけ。テストは `Array[1, 2]` と書くことで通したが、
   Ruby の感覚で書くと最初に必ず踏む。Tuple と Array の `==` を中身で比べる（長さと各要素）案は、型の区別を弱める代わりに
   この落とし穴を消す。
2. **組み込みの例外メッセージに `Op: ` が付く**（`Rational.quo: divided by 0`）。Ruby と同じ文で比べる assert は書けず、
   `assert_match` にした。以前の移植（strscan, tsort）も同じ要求を出している。
3. **`module` の関数は既定で mixin。`Minitest.assert_equal(...)` と呼ぶには `module_function` が要る。** エラーの hint がそのまま答えなので
   詰まらないが、Ruby の `module Foo; def self.bar` に当たる書き方が無いことは毎回思い出す。
4. **`rescue StandardError => e` は書けない**（`StandardError` is not an exception type）。全部を受けるのは裸の `rescue => e`。Ruby の癖で
   書くと止まる。これも hint で済むが、`StandardError` を裸の rescue の別名として受けてもよさそう。
5. **要素の型を変える破壊的操作は、容器の型を「前後の合併」にする。** `Hash.transform_keys!(h) { |k| Symbol.to_s(k) }` の後、`h` の鍵は
   `Symbol | String` になり、ブロック引数 `k` も同じ型なので `Symbol.to_s(k)` が partial になる（型が変わらない変換なら問題ない）。
   検査器が時間を持たない（1 つのサイトに 1 つの型）ことの帰結で、`map!` 系は同じ型への写像にしか安全に使えない。
   テストは `Kernel.to_s(k)` で逃げた。Ruby の破壊的 API を移すとここが構造的に合わない。
6. **Ruby の変換プロトコルに乗らない Sake の値。** `Array#assoc` は要素が `to_ary` に応える Array であることを要求するので、Tuple の要素を
   飛ばして nil を返した。Sake 側で Tuple/Array を見て書き直した。Ruby の実装に委ねる組み込みは、Tuple・Record・Struct 値が
   Ruby の Array/Hash でないことで静かに違う結果になりうる（`flatten` が Tuple を開かないのは意図どおりだが、同じ理由）。
7. **コアとライブラリで同じ名前**: Ruby 3.4 で `Time#xmlschema` がコアに入ったが、`sakelib/time.sake` は `Time.xmlschema(x)` を
   「String なら parse、Time なら format」の 1 関数にしている（クラスメソッドとインスタンスメソッドが同名で、Sake には名前空間が 1 つ）。
   組み込みに足すと再定義エラーになるので、組み込み側を見送った。名前空間が型ごとに 1 つなのは、Ruby の「クラスメソッドとインスタンスメソッド」の
   対を潰す（digest の移植も同じ要求）。
8. **`did you mean` が破壊的な形も挙げる**（`upcace` → `upcase` と `upcase!`）。穴埋めで `!` 付きが増えた副作用。害は無いが、
   候補を 1 つに絞るなら「`!` を除いた名前が一致する方」を優先する。
9. **`String.encoding` 系は Encoding オブジェクトを返せない**ので名前の String にした（`Symbol.encoding(:a)` は `"US-ASCII"`）。
   Ruby の値のうち Sake に型が無いもの（Encoding, Proc, Method, Enumerator, Class）はこうして String か Tuple に落とすしかない。
10. **ブロック無しで Enumerator を返す操作は全部落とした**（`chain`, `lazy`, `chunk`, `each_slice` のブロック無し形は Array）。
    Sake のブロックは第二級で Enumerator が無いので、Ruby の「ブロックを省くと Enumerator」は表せない。
11. **`Hash#default=`** は `Hash.set_default(h, v)`。setter の名前規則（`set_x`）に揃えた。
12. **`Process::CLOCK_MONOTONIC`** のような定数は `Process.CLOCK_MONOTONIC` という操作（`Math.PI` と同じ）。値の定数が無いことの帰結。
