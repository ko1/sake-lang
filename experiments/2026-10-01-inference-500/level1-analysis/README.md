# level 1 の誤報の解析（2026-10-02）

- `by_commit.sh COMMIT...`：各コミットで corpus-v2 に `sake -c --strict=1` / `=2` をかけ、診断を `<commit>.l1.txt.gz` / `.l2.txt.gz` に保存する。数は `by_commit.log`（コミット、level 1 の診断数、level 2 の診断数）。
- `class-0{0,1,2}.tsv`：b5156d3 時点の level 1 の診断 280 件（`head.l1.txt.gz`）を、3 つのサブエージェントが 1 件ずつコードを読んで分類したもの。列は path / line:col / op / category / nil_only / explanation / fix。分類の定義は ../README.md の 10 節。
- 推論器のバグとされたものは、修正前に小さな再現で確かめてから直した（../README.md の 10 節）。
