# Making the language chapters readable (brief for the rewriters)

ko1 read the published manual (https://ko1.github.io/sake-lang/manual/) and said of chapter 04: 「箇条書きがつまりすぎて大変よみづらい。全般的に読みやすくして」 (the bullets are far too dense; make the whole thing readable). Of chapter 06: it opens directly with "6.1 パターンマッチ", with nothing on `if`, `while`, `case` before it. Your job is the two files of each chapter you are given, in `docs/manual/ja/` and `docs/manual/en/` (the same chapter in both languages; keep them parallel: same sections, same order, same examples).

## What "readable" means here

- **Every section opens with a short paragraph** (one to three sentences) saying what it covers and the one idea behind it, before any list.
- **One idea per bullet, at most about three lines.** A bullet that today packs four rules with semicolons becomes a paragraph plus a short list, or several bullets, or a `###` sub-section. Bold lead-ins (`**順序。**`) are fine when each bullet has one.
- **`###` sub-sections** when a `##` section covers several topics (functions: parameters, optional parameters, keywords, return values, recursion ...). Do not change the `##` section titles unless a title is wrong; adding sections is fine. Do not rename files or touch `docs/manual/book*.yml`.
- **A small example where a rule is abstract.** Three to eight lines of Sake, in a ```ruby fence, with the printed values as `# => value` comments on the printing lines, as the other chapters do. Run every example you write or change: `bin/sake --strict=2 FILE.sake` from the repository root, and copy the real output. An example meant to be rejected goes in a ```ruby error fence (look at how `docs/manual/en/ref/Array.md` does it). Do not write an example you did not run.
- **Tables** for enumerations (levels, operators, kinds of error) stay tables. A table with a cell of five sentences is split: the table keeps one short cell, the sentences move below it.
- **Plain words.** Say who does what: 「検査器は ... を報告します」, "the checker reports ...". No nested parentheses. A parenthesis longer than a line becomes its own sentence.
- Japanese: です・ます調, as the chapters are now. Keep the Japanese and the English saying the same things; write whichever first, then make the other match.

## What must not change

- **Every rule and fact stays.** You reorganize and rephrase; you do not drop a rule because it is awkward, and you do not add a rule from memory of Ruby. The authority is `docs/spec.md` (the same content, section by section) and the interpreter: when a sentence seems wrong, test it with `bin/sake`. If it is wrong, fix it and say so in your report with the program you ran. If you are unsure, keep the sentence and flag it in the report.
- **Terminology (decided today, 2026-10-10):** a type a program defines is a **class** (クラス); `Struct.new(:x, :y)` is the shorthand for `class C` with `attr_accessor x, y`. Never "Struct 型 / Struct type". An operator `a + b` is the module's function `Arithmetic.+(a, b)`, resolved by the type of the left operand. `include M` **copies** (書き写す) M's functions into the includer; not "borrows". `class B < A` writes A's definitions into B, for any class; there is no inheritance.
- Links between chapters are `[text](NN-name.md)` to files that exist in the same directory: 01-overview, 02-program, 03-values, 04-functions, 05-operators, 06-control, 07-classes, 08-exceptions, 09-builtins, 10-library, a1-ruby, and `ref/NS.md` for the reference. No anchors.
- Chapter 02 is being rewritten by someone else (nested namespaces are being added to the language); do not touch it. If your chapter mentions namespaces not nesting, leave the sentence as it is.
- Do not run `sh docs/manual/build.sh` (several of you work at once and it writes one directory); the coordinator builds at the end. Do not commit.

## Chapter 06 in particular

The chapter must cover control flow before patterns: conditions (`if`/`unless`, the modifier forms, `&&`/`||`/`!`, truthiness: only `nil` and `false` are false), loops (`while`/`until`, `loop`, `break`/`next`, and that iteration is mostly `Array.each` and the other block-taking operations, see 04), `case`/`in` (there is no `case`/`when`), early `return`, and how a condition **narrows** a type (`if x` removes nil; `x in Integer` narrows). Mine `docs/spec.md` for the facts (its sections on control flow, patterns, nil narrowing) and verify with `bin/sake`. Then the existing pattern-matching section, made readable.

## Report

In your final message: the chapters you changed; the sentences you corrected (with the program that showed the old text wrong) or flagged as doubtful; and **usage notes**: anything about writing Sake examples that was awkward, surprising, or pleasant (ko1 collects these).
