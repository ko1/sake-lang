# Sake

Ruby の文法で書く、操作に型を書く言語の実験的な処理系。設計は [DESIGN.md](DESIGN.md)。

```
bin/sake examples/first.sake      # 実行
bin/sake --check FILE.sake        # 静的検査だけ
ruby test/test_samples.rb         # テスト（UPDATE=1 で期待値を更新）
```

- `lib/sake/resolver.rb`: 実行前の名前解決・検査（修正案つきのエラー）
- `lib/sake/interpreter.rb`: AST を直接評価
- `lib/sake/stdlib.rb`: 組み込みの操作と `BinaryOp` の閉じた実装表
