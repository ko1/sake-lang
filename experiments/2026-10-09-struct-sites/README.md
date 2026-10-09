# 構築場所ごとの Struct 型（D13）の費用（2026-10-09）

ko1 の決定: gem 移植で最も繰り返された代償「フィールドの型はプログラム全体で 1 つ」（rspec の `Expectation.actual` が
`expect(42)` と `expect("abc")` で `Integer | String` になる）を、Struct 値の型を **構築場所ごと**（`Expectation@L4#1`）に分けて解く。
設計の経緯は `DESIGN.md` の末尾、仕様は `docs/spec.md` §10.1「One type per construction」。

## 方法

- 対象: `experiments/2026-10-05-ai-writability/runs/p10-sake-{1,2}/stage-6/code/main.sake`（SQL エンジン 2 本、`--strict=2 -c`）。
- `count.rb FILE` が typer を 1 回走らせ、時間・具体化（instantiation）の数・配列の場所・Struct の場所・pass 数を出す。
- 比較は同じマシン（ローカル、load < 1.5 を `uptime` で確認）、各 1〜2 回。前（commit 1b4ec46e）は `git stash` で測った。

## 結果

| | sake-1 前 | sake-1 後 | sake-2 前 | sake-2 後 |
|---|---|---|---|---|
| 時間 | 3.25 s | 4.4 s | 2.84 s | 7.1 s |
| 具体化 | 1837 | 2369 | 1470 | 2952 |
| 配列の場所 | 1716 | 1311 | 1143 | 1266 |
| Struct の場所 | – | 333 | – | 163 |
| pass | 7 | 7 | 7 | 6 |
| 検査 | proven 2076 / partial 15 | 同一 | | |

途中の案と、その数字（sake-1）:

| 案 | 時間 | 具体化 | 備考 |
|---|---|---|---|
| 場所の鍵 = 具体化の引数そのまま（配列と同じ） | > 600 s, 2 GB | – | 値から値を作る関数で場所が増え続ける（打ち切り） |
| 鍵 = 引数の平らな形（Struct は型名、容器は種類） | 9.5 s | 2377 | 有限。時間の 49% が `collect_makers`（Struct のフィールド表を通る走査） |
| 上 + Struct のフィールドに降りない | 44 s | 2987 | 自分が作った容器の検出が落ちて場所と具体化が増える |
| 上 + 走査の結果を GEN ごとにメモ | 21 s | 2369 | GEN（書き込みごと）が頻繁に進み、メモが効かない |
| 上 + 作り手の閉包を書き込み時に増分で保つ（採用） | 4.4 s | 2369 | `note_contents` / `grow` |
| 採用案 + Struct の atom を形（型名＋フィールドの型の id）で鍵に | 110 s | 19447 | フィールド型が pass ごとに変わり振動（30 pass）。却下 |

## 結論

- 検査結果は同一のまま、rspec 型のケース（`test/samples/mixed_warning.sake` の注釈、`sakelib/rspec.sake` の Tuple 回避が不要に）が解ける。
- 費用は 1.4〜2.6 倍。具体化が 1.3〜2 倍に増える（引数の Struct atom が場所ごとに違う）のが主因で、これ以上は
  Struct atom の形による鍵（振動を止める工夫が要る）か、場所の数の上限が要る。
