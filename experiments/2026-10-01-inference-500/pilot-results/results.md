## Sake typer (8 programs; 0 failed to load)

"determined" = mono + nilable + union among reached units (no unknown anywhere in the type).

| unit | n | mono | nilable | union | partial | unknown | none | determined |
|---|---|---|---|---|---|---|---|---|
| expr.var | 1088 | 875 (80.4%) | 112 (10.3%) | 100 (9.2%) | 0 (0.0%) | 0 (0.0%) | 1 (0.1%) | 100.0% |
| expr.call | 1047 | 799 (76.3%) | 123 (11.7%) | 83 (7.9%) | 0 (0.0%) | 0 (0.0%) | 42 (4.0%) | 100.0% |
| sig.param | 77 | 65 (84.4%) | 5 (6.5%) | 7 (9.1%) | 0 (0.0%) | 0 (0.0%) | 0 (0.0%) | 100.0% |
| sig.ret | 99 | 64 (64.6%) | 12 (12.1%) | 21 (21.2%) | 0 (0.0%) | 0 (0.0%) | 2 (2.0%) | 100.0% |
| sig.field | 68 | 47 (69.1%) | 5 (7.4%) | 16 (23.5%) | 0 (0.0%) | 0 (0.0%) | 0 (0.0%) | 100.0% |

- not converged within the pass limit: 0
- dead (never called) functions: 1
- run-time check sites: proven=838 partial=43 error=6

## TypeProf on the Ruby versions (8 programs; 0 failed)

| unit | n | mono | nilable | union | partial | unknown | none | determined |
|---|---|---|---|---|---|---|---|---|
| sig.param | 76 | 54 (71.1%) | 7 (9.2%) | 10 (13.2%) | 3 (3.9%) | 2 (2.6%) | 0 (0.0%) | 93.4% |
| sig.ret | 99 | 57 (57.6%) | 9 (9.1%) | 23 (23.2%) | 6 (6.1%) | 1 (1.0%) | 3 (3.0%) | 92.7% |
| sig.field | 59 | 33 (55.9%) | 6 (10.2%) | 20 (33.9%) | 0 (0.0%) | 0 (0.0%) | 0 (0.0%) | 100.0% |

- reported errors (all false: every program runs): 72 in 8 programs
  - 16: undefined method: String#-
  - 5: undefined method: nil#match?
  - 5: undefined method: nil#-
  - 5: wrong type of arguments
  - 5: undefined method: Numeric#/
  - 4: undefined method: nil#+
  - 4: undefined method: nil#<
  - 4: undefined method: Numeric#*
  - 3: undefined method: nil#[]
  - 2: undefined method: Array[String?]#match?

## Sake checks before running on correct programs (false reports)

| level | programs rejected | diagnostics |
|---|---|---|
| 1 | 4 / 8 | 9 |
| 2 | 6 / 8 | 18 |
| 3 | 8 / 8 | 45 |
| 4 | 8 / 8 | 49 |

## Per domain

| domain | programs | Sake expr determined | Sake sig determined | TypeProf sig determined |
|---|---|---|---|---|
| 10-grids | 4 | 100.0% | 100.0% | 97.9% |
| 12-parsers | 4 | 100.0% | 100.0% | 92.6% |

## Why Sake units are not mono (by callee / reason)

**union** (227): `union: expr.var` 100, `union: sig.ret` 21, `union: sig.field` 16, `union: expr` 7, `union: sig.param` 7, `union: Array.push` 6, `union: run_all` 4, `union: Array[]` 4, `union: parse_unary` 4, `union: block` 3, `union: parse_value` 3, `union: numbers_in` 3, `union: binary` 3, `union: Hash[]` 3, `union: Array.each` 3

**nilable** (257): `nilable: expr.var` 112, `nilable: peek` 15, `nilable: sig.ret` 12, `nilable: Token.get_text` 7, `nilable: src` 5, `nilable: sig.field` 5, `nilable: sig.param` 5, `nilable: parts` 4, `nilable: m` 4, `nilable: @squares[i]` 4, `nilable: String.match` 3, `nilable: win` 3, `nilable: Array.pop` 3, `nilable: Move.get_square` 3, `nilable: @src[@pos..]` 2


## Corpus check

- programs: 8; run with exit 0 and output identical to Ruby and .out: 8

## Soundness (crosscheck)

| typer | programs checked | violations | programs with violations |
|---|---|---|---|
| as is | 8 | 0 | 0 |
| sabotaged (negative control) | 8 | 0 | 0 |

## Dispatch demand

Ruby versions, run with receiver tracing: call sites (line, method) whose receivers had 2+ classes (nil excluded).

| category | sites | programs |
|---|---|---|
| operator | 6 | 3 |
| show | 2 | 2 |
| exception | 0 | 0 |
| user | 7 | 1 |
| builtin | 1 | 1 |
| mixed | 0 | 0 |

(traced sites in total: 1617; programs: 8)

builtin/mixed sites: `builtin: (Array|Hash).map` 1

Sake versions: hand-written dispatch (case/in or if-in branches calling the same operation through different types): 2 operations in 1 programs; calls through a module of the program: 8 in 1 programs.

`(Hash|Array).empty?` 1, `(Hash|Array).map` 1
