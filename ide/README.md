# Sake Playground (browser IDE)

Sake on ruby.wasm (Ruby 4.0): an editor on the left, the result on the right.

- **Editor** (CodeMirror 6): completion of operations after `T.` (built-in and your own: `new`, `get_x`, functions), of type names after `x.` (a chain `x.T.op`), and of variables, functions and keywords; diagnostics as you type (errors at the chosen strict level, warnings for the items above it, with hints); hover for the inferred type of a variable or call, and a function's signature on its `def`. Ctrl/Cmd-Enter runs.
- **Result**: Output (what `sake --strict=LEVEL` prints, with stdin), Types (problems, functions' inferred signatures, Struct fields, Arrays), SakeAST.
- Two Web Workers run Ruby: one analyzes as you type, the other runs the program. A run longer than 10 s, or Stop, restarts the running one only.
- Ruby side: `lib/sake/ide.rb` (`Sake::IDE.dispatch`, JSON in and out; tests in `test/test_ide.rb`). `src/sake_loader.rb` loads lib/ from bundled strings in place of files.

Build: `npm install && npm run build` (in this directory) makes `dist/`: `index.html`, `app.js`, `worker.js`, and `ruby.gz.wasm` (ruby+stdlib.wasm of @ruby/4.0-wasm-wasi, gzip-compressed; the page decompresses it). Rebuild after changing lib/.

Published (private artifact): <https://claude.ai/artifact/WUnGQBBr4qfGiZ8VbCBtaK>

Limits: the wasm stack is shallower than bin/sake's, so deep recursion (about 9,000 Sake calls) stops with SystemStackError earlier than on the command line.
