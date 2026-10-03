# level 1 を「必ず失敗」だけにしたら（2026-10-03）

問い（ko1 との議論から）: 状態（フィールド・要素）の型がぼやけて出る誤報は、level 1（既定）が「失敗するかもしれない」（union のどれかが合わない、verdict `partial`）まで止めているから出る。level 1 を「必ず失敗」（verdict `error`）だけにし、`partial` を上の level に回すと、何を失い何を得るか。

- 処理系: commit 84aecec（v8 と同じ推論器）。
- `split.rb`: 各プログラムの level 1 の報告を verdict で分ける（`corpus.jsonl`）。

## コーパス 500 本（すべて正しいプログラム）

| level 1 の報告 | 件数 |
|---|---|
| 失敗するかもしれない（partial） | 154 |
| 必ず失敗（error） | 8 |

level 1 で止められる正しいプログラムは 52 本。「必ず失敗」だけなら 3 本（bucket_sort_ratings、list_toolkit、json_parser）。この 3 本の 8 件も誤報で、その推論の文脈では値が届けば必ず失敗するが、実際には届かない経路（別の変数との相関）か、受け手が Hash か Array か分からないときの添字の検査（json_parser）。

## ライブラリ試作（`experiments/2026-10-03-libraries/`）

つまずきの記録の引用から、言い回し（"but is" = 必ず失敗、"can be" / "may be" = かもしれない）で分けた。

- 誤報のうち level 1 の型の報告: 5 件、すべて「かもしれない」（collections の Integer[] への push、events の 2 件、graph の Heap の比較、json の常に raise する関数＝修正済み）。残りの誤報は nil の報告（level 2 以上）。
- 本物の誤りを捕まえた 10 件: nil 5 件（level 2、この変更とは無関係）。型 5 件のうち「必ず失敗」4 件（csvtable 2、validate 2）、「かもしれない」1 件（json: JSON の値の union に Struct の Point が混ざり `generate` の `case/in` に届いた）。

## 読み

- level 1 を「必ず失敗」だけにすると、既定で止められる正しいプログラムは 52 → 3 本。試作の level 1 の誤報は 5 件とも消える。
- 失うのは、union の一部が本当に誤っている場合（json の Point の 1 件）を、既定の level で止められなくなること。その報告は `partial` を回した先の level（推奨の level 2 に入れれば `--strict` で）で出る。実行時の各操作の検査は残る。
- 「かもしれない」は、ぼやけ（汎用の入れ物、相関）と、本物の混入（json の Point）を区別しない。区別するには推論の精度が要る（`experiments/2026-10-03-state-survey/`）。
