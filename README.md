# Sake

読み方は /seɪk/（英語の "for the sake of" の sake と同じ）。

Ruby の文法で書く、操作に型を書く言語の実験的な処理系。設計は [DESIGN.md](DESIGN.md)。
言語の説明は英語で [docs/tutorial.md](docs/tutorial.md)（動作例つき）と [docs/spec.md](docs/spec.md)。
両方を 1 ページにまとめたガイド: `docs/guide.html`（artifact: https://claude.ai/artifact/EdrbscXRGUtkKppprRKohP 。`ruby tools/gen_guide.rb` で再生成してから同じ artifact に publish する）。

```
bin/sake examples/first.sake      # 実行
bin/sake --check FILE.sake        # 静的検査だけ
bin/sake --strict FILE.sake       # nil かもしれない値を確かめずに使う箇所も、実行前に報告する
bin/sake --types FILE.sake        # 実験的な型推論（検査箇所ごとに proven / partial / error / unknown）
ruby test/test_samples.rb         # テスト（UPDATE=1 で期待値を更新）
ruby test/test_cli.rb             # bin/sake 経由のテストと、docs/tutorial.md が最新かの確認
ruby tools/gen_tutorial.rb        # docs/tutorial.src.md と docs/examples/ から docs/tutorial.md を生成
```

- `lib/sake/resolver.rb`: 実行前の名前解決・検査（修正案つきのエラー）
- `lib/sake/interpreter.rb`: AST を直接評価
- `lib/sake/stdlib.rb`: 組み込みの操作と `BinaryOp` の閉じた実装表
- `lib/sake/typer.rb`: プログラム全体の型推論（`--types` / `--strict` と、nil エラーの修正案に使う）
- `experiments/`: 実験（方法・結果・限界を各ディレクトリの README に記録）
