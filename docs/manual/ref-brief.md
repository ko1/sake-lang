# Writing the built-in reference chapters (brief for the writers)

Goal: `docs/manual/ja/ref/NS.md` and `docs/manual/en/ref/NS.md`, one chapter per namespace, documenting
**every** operation of the namespace in detail, in Japanese and in English. `docs/manual/ja/ref/Tuple.md`
and `docs/manual/en/ref/Tuple.md` are the model: read both first and follow their structure and tone.

## Structure (enforced by `ruby tools/check_reference.rb NS`)

- Line 1 is `# NS`. Then an introduction: what the type/module is, the literal, how it differs from Ruby,
  which operators apply, pointers to the language chapters (`../03-values.md`, `../05-operators.md`, ...;
  only link files that exist in `docs/manual/ja/` resp. `docs/manual/en/`: 01-overview … 10-library, a1-ruby).
- One `## name` section per operation, in a sensible order (not alphabetical: group related operations).
  Aliases share one section: `## find, detect`, `## length, size`. Operators as functions: `## +, -, *`.
  The constructor `T[...]` is the section `## T[]` (it makes a typed **Array** of T, not a T).
- Right under the heading, each operation's exact signature on its own line in backticks, as
  `ruby tools/check_reference.rb --list NS` prints it (`Array.first(x, [Integer])`). The checker fails on a
  missing operation, a misspelled one, a missing signature, or an operation documented twice.
- Then the description. Say, in this order where applicable: what it does and what it returns (the type);
  what each argument means, optional ones and their defaults, what the block receives and what its result
  does; when the result is **nil** and whether `--strict` (level 2) flags using it unchecked or only level 3
  does (the nil of a miss: `x[k]`, `Array.first/last/pop/shift/min/max/at/sample/delete_at` is level 3);
  which **exceptions** it raises (by name: `ArgumentError`, `IndexError`, `KeyError`, `TypeError`,
  `IOError`, `ZeroDivisionError`, ...); what the **checker** rejects statically (`type` problems); whether it
  changes the subject in place or returns a new value; how it differs from Ruby's method of the same name.
- Then at least one example block, ```ruby, that **runs**. Annotate printed lines with `# => value`: the
  checker runs the block under `--strict=2` (cwd an empty temp dir, stdin `"3\n1 2\n"`) and requires the
  stdout lines to equal the annotations in order, and no stderr. For a failing case use a ```ruby error
  block: it must be rejected or fail, and each `# !> text` must occur in its output. Only when an example
  truly cannot run in the checker (outside network, a long sleep, a terminal: the checker's stdin is a pipe)
  use a plain ``` fence and say so; confirm a terminal example under a pty, e.g.
  `printf 'x\n' | script -qc "bin/sake x.sake" /dev/null`. The checker runs a chapter's examples in one temp
  dir, so file and directory names in examples must differ from section to section.

## Facts

- Get the behaviour from the implementation, not from memory of Ruby: `lib/sake/stdlib.rb`,
  `stdlib_core.rb`, `stdlib_ext.rb`, `stdlib_io.rb`, `stdlib_net.rb`, `stdlib_text.rb`, and the table
  `lib/sake/stdlib_table.rb` (rows `[namespace, name, params, result, options]`; `result` symbols such
  as `:int_nil` mean the result may be nil). Result types and nil-ness as the checker sees them are in
  `Typer#builtin_result` (`lib/sake/typer.rb`), `builtin_result_ext` (`typer_ext.rb`), and
  `Typer#table_result`. The spec (`docs/spec.md`) and the chapter `docs/manual/en/09-builtins.md` give
  the surrounding rules.
- **Run `bin/sake` to confirm every nontrivial claim** (nil or error? which exception? what the checker
  says?). Write examples whose output you have seen. Never invent an operation or an argument form:
  only what `--list` prints exists.
- Where Sake follows Ruby, say "as Ruby's" briefly; spell out every difference (nil vs error, required
  initial value, no block form, typed Arrays, Tuple vs Array, Record vs Hash).
- Do not change `lib/`, tests, or other chapters. If you find a bug or an inconsistency (the doc of a
  built-in cannot be written honestly because the behaviour is odd), still describe the real behaviour and
  list the finding in your final report.

## Language

- Japanese: です・ます体, terms as in `docs/manual/ja/` (操作, 主語, 型, 検査器, 静的に, 実行時, 添字,
  容器, 構築). English: plain, present tense, as in `docs/manual/en/`.
- Both chapters must document the same operations with the same sections and the same examples.
  Write the Japanese and the English of a section together.

## Done means

`ruby tools/check_reference.rb NS` prints `0 problems` for each of your namespaces, and
`ruby tools/check_reference.rb --coverage` shows ja and en equal to the operation count.
Do not commit. Report: the namespaces finished, operation counts, and any bugs or oddities found.
