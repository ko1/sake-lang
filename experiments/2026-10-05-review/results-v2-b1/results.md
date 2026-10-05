## Sake typer (500 programs; 0 failed to load)

"determined" = mono + nilable + union among reached units (no unknown anywhere in the type).

| unit | n | mono | nilable | union | partial | unknown | none | determined |
|---|---|---|---|---|---|---|---|---|
| expr.var | 57298 | 46268 (80.7%) | 7567 (13.2%) | 3060 (5.3%) | 88 (0.2%) | 277 (0.5%) | 38 (0.1%) | 99.4% |
| expr.call | 60921 | 49290 (80.9%) | 8130 (13.3%) | 2415 (4.0%) | 65 (0.1%) | 169 (0.3%) | 852 (1.4%) | 99.6% |
| sig.param | 5152 | 4118 (79.9%) | 617 (12.0%) | 393 (7.6%) | 9 (0.2%) | 15 (0.3%) | 0 (0.0%) | 99.5% |
| sig.ret | 4282 | 3305 (77.2%) | 634 (14.8%) | 298 (7.0%) | 8 (0.2%) | 35 (0.8%) | 2 (0.0%) | 99.0% |
| sig.field | 2849 | 2349 (82.4%) | 381 (13.4%) | 115 (4.0%) | 2 (0.1%) | 2 (0.1%) | 0 (0.0%) | 99.9% |

- not converged within the pass limit: 0
- dead (never called) functions: 78
- run-time check sites: proven=50333 partial=3639 error=9 unknown=81

## TypeProf on the Ruby versions (451 programs; 49 failed)

| unit | n | mono | nilable | union | partial | unknown | none | determined |
|---|---|---|---|---|---|---|---|---|
| sig.param | 4516 | 3261 (72.2%) | 294 (6.5%) | 533 (11.8%) | 168 (3.7%) | 260 (5.8%) | 0 (0.0%) | 90.5% |
| sig.ret | 3562 | 2559 (71.8%) | 362 (10.2%) | 328 (9.2%) | 151 (4.2%) | 150 (4.2%) | 12 (0.3%) | 91.5% |
| sig.field | 2299 | 1764 (76.7%) | 188 (8.2%) | 163 (7.1%) | 53 (2.3%) | 131 (5.7%) | 0 (0.0%) | 92.0% |

- reported errors (all false: every program runs): 3331 in 391 programs
  - 403: wrong type of arguments
  - 386: failed to resolve overloads
  - 181: undefined method: nil#[]
  - 118: undefined method: nil#-
  - 117: undefined method: nil#+
  - 77: undefined method: Numeric#*
  - 63: undefined method: nil#left
  - 61: undefined method: nil#right
  - 60: undefined method: nil#size
  - 57: undefined method: nil#*
- failure: corpus/19-statemachines/tcp_states.rb: typeprof timeout (120 s)
- failure: corpus/02-analytics/caesar_crack.rb: typeprof timeout (120 s)
- failure: corpus/09-dp/dice_odds.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/sparse_vectors.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/survey_venn.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/tag_recommender.rb: typeprof timeout (120 s)
- failure: corpus/19-statemachines/machine_mixin.rb: typeprof timeout (120 s)
- failure: corpus/06-linked/adjacency_list_courses.rb: typeprof timeout (120 s)
- failure: corpus/01-text/classic_ciphers.rb: typeprof timeout (120 s)
- failure: corpus/05-sorting/staff_multikey_sort.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/05-sorting/triage_partition.rb: typeprof failed (exit 1): /home/ko1/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems/typeprof-0.31.1/lib/typeprof/core/ast/sig_type.rb:819:in 'TypeProf::Core::AST::SigTyVarNode#covariant_vertex0': unknown type variable: Return (RuntimeError)
- failure: corpus/18-collections/access_log.rb: typeprof failed (exit 1): /home/ko1/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems/typeprof-0.31.1/lib/typeprof/core/ast/sig_type.rb:819:in 'TypeProf::Core::AST::SigTyVarNode#covariant_vertex0': unknown type variable: Return (RuntimeError)
- failure: corpus/18-collections/build_order.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/course_overlap.rb: typeprof timeout (120 s)
- failure: corpus/13-polymorphism/bitset_permissions.rb: typeprof timeout (120 s)
- failure: corpus/13-polymorphism/collision_check.rb: typeprof timeout (120 s)
- failure: corpus/08-graphs/prim_cables.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/inventory_diff.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/epidemic_network.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/forest_fire.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/bakery_shift.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/cpu_scheduler.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/02-analytics/markov_text.rb: typeprof timeout (120 s)
- failure: corpus/02-analytics/naive_bayes.rb: typeprof timeout (120 s)
- failure: corpus/04-numeric/cubic_spline.rb: typeprof timeout (120 s)
- failure: corpus/04-numeric/descriptive_stats.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/14-errors/expr_calculator.rb: typeprof timeout (120 s)
- failure: corpus/20-business/payroll.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/08-graphs/dijkstra_routes.rb: typeprof timeout (120 s)
- failure: corpus/08-graphs/euler_itinerary.rb: typeprof timeout (120 s)
- failure: corpus/20-business/grade_book.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/langton_ants.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/room_bookings.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/14-errors/spreadsheet_errors.rb: typeprof timeout (120 s)
- failure: corpus/16-dates/public_holidays.rb: typeprof timeout (120 s)
- failure: corpus/16-dates/date_parser.rb: typeprof timeout (120 s)
- failure: corpus/09-dp/floyd_warshall.rb: typeprof timeout (120 s)
- failure: corpus/17-encodings/rolling_sync.rb: typeprof timeout (120 s)
- failure: corpus/01-text/doc_pretty.rb: typeprof timeout (120 s)
- failure: corpus/02-analytics/tf_idf.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/leaderboard.rb: typeprof timeout (120 s)
- failure: corpus/15-data/top_products.rb: typeprof timeout (120 s)
- failure: corpus/14-errors/password_policy.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/11-simulation/parking_garage.rb: typeprof timeout (120 s)
- failure: corpus/17-encodings/xor_breaker.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/12-parsers/chem_formula.rb: typeprof timeout (120 s)
- failure: corpus/14-errors/nested_schema.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/03-numtheory/goldbach.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/12-parsers/type_checker.rb: typeprof timeout (120 s)

## Sake checks before running on correct programs (false reports)

| level | programs rejected | diagnostics |
|---|---|---|
| 1 | 51 / 500 | 152 |
| 2 | 285 / 500 | 1217 |
| 3 | 447 / 500 | 3648 |
| 4 | 455 / 500 | 3863 |

## Per domain

| domain | programs | Sake expr determined | Sake sig determined | TypeProf sig determined |
|---|---|---|---|---|
| 01-text | 25 | 100.0% | 99.8% | 92.7% |
| 02-analytics | 25 | 100.0% | 100.0% | 91.2% |
| 03-numtheory | 25 | 100.0% | 99.8% | 96.2% |
| 04-numeric | 25 | 99.5% | 99.0% | 88.7% |
| 05-sorting | 25 | 98.8% | 98.5% | 91.0% |
| 06-linked | 25 | 100.0% | 100.0% | 93.2% |
| 07-trees | 25 | 99.7% | 99.1% | 89.5% |
| 08-graphs | 25 | 100.0% | 100.0% | 92.5% |
| 09-dp | 25 | 100.0% | 100.0% | 92.7% |
| 10-grids | 25 | 100.0% | 100.0% | 88.8% |
| 11-simulation | 25 | 100.0% | 100.0% | 94.1% |
| 12-parsers | 25 | 95.2% | 95.0% | 89.9% |
| 13-polymorphism | 25 | 100.0% | 100.0% | 94.7% |
| 14-errors | 25 | 98.3% | 98.4% | 90.3% |
| 15-data | 25 | 100.0% | 100.0% | 85.7% |
| 16-dates | 25 | 100.0% | 100.0% | 83.2% |
| 17-encodings | 25 | 100.0% | 100.0% | 96.4% |
| 18-collections | 25 | 100.0% | 100.0% | 90.5% |
| 19-statemachines | 25 | 98.4% | 99.3% | 97.8% |
| 20-business | 25 | 100.0% | 100.0% | 88.4% |

## Why Sake units are not mono (by callee / reason)

**unknown** (498): `unknown: destructure` 117, `unknown: index` 114, `unknown: tuple depth` 63, `unknown: operand` 57, `unknown: pattern` 49, `unknown: recursive yield` 35, `unknown: record depth` 34, `unknown: expr.var` 10, `unknown: factor` 4, `unknown: term` 3, `unknown: sig.ret` 3, `unknown: record variants` 3, `unknown: block destructure` 3, `unknown: Parser.expr` 1, `unknown: expr` 1

**partial** (172): `unknown: pattern` 61, `unknown: destructure` 37, `unknown: index` 32, `unknown: tuple depth` 28, `unknown: block destructure` 8, `unknown: operand` 6

**union** (6281): `union: expr.var` 3060, `union: sig.param` 393, `union: sig.ret` 298, `union: Array.sum` 177, `union: sig.field` 115, `union: Array.each` 111, `union: a` 106, `union: Array` 92, `union: Array.push` 61, `union: Array.map` 50, `union: Hash` 46, `union: Array[]` 45, `union: yield` 43, `union: evaluate` 29, `union: Hash[]` 25

**nilable** (17329): `nilable: expr.var` 7567, `nilable: sig.ret` 634, `nilable: sig.param` 617, `nilable: sig.field` 381, `nilable: m` 356, `nilable: Array.push` 209, `nilable: Array.max` 184, `nilable: Array.map` 132, `nilable: Array.each` 132, `nilable: Array[]` 125, `nilable: String.match` 115, `nilable: Array.last` 114, `nilable: Array` 104, `nilable: a` 96, `nilable: Hash[]` 89


## Corpus check

- programs: 500; run with exit 0 and output identical to Ruby and .out: 500

## Soundness (crosscheck)

| typer | programs checked | violations | programs with violations |
|---|---|---|---|
| as is | 500 | 0 | 0 |
| sabotaged (negative control) | 500 | 1869 | 180 |

## Dispatch demand

Ruby versions, run with receiver tracing: call sites (line, method) whose receivers had 2+ classes (nil excluded).

| category | sites | programs |
|---|---|---|
| operator | 398 | 212 |
| show | 112 | 46 |
| exception | 6 | 4 |
| user | 119 | 23 |
| builtin | 74 | 66 |
| mixed | 9 | 8 |

(traced sites in total: 66308; programs: 500)

builtin/mixed sites: `builtin: (Array|String).size` 19, `builtin: (Array|Hash).size` 16, `builtin: (Array|Range).map` 14, `builtin: (Array|Set).size` 6, `builtin: (Array|String).empty?` 3, `builtin: (Array|Enumerator).map` 3, `builtin: (Float|Integer).round` 2, `mixed: (Array|Query).group_by` 2, `mixed: (Array|Table).size` 2, `builtin: (Array|Hash).each` 2, `builtin: (Array|Set).empty?` 1, `builtin: (Array|Set).each` 1, `mixed: (Array|RangeSet).size` 1, `builtin: (Integer|String).public_send` 1, `builtin: (Hash|Set).size` 1, `builtin: (Array|Set).include?` 1, `builtin: (Integer|Rational).to_f` 1, `builtin: (Array|Hash).sum` 1, `mixed: (Module|Ship).name` 1, `mixed: (Array|Grid).size` 1, `mixed: (Class|Replace).new` 1, `builtin: (Integer|Rational).abs` 1, `builtin: (Array|Set).sort` 1, `mixed: (Array|Hash|Node).size` 1

Sake versions: hand-written dispatch (case/in or if-in branches calling the same operation through different types): 17 operations in 11 programs; calls through a module of the program: 209 in 28 programs.

`(Array|Hash).map` 3, `(Var|Fn).name` 3, `(Insert|Delete|Replace).pos` 2, `(Hash|Array).empty?` 1, `(Hash|Array).map` 1, `(Lambda|Prim).name` 1, `(Logic|Cmp).op` 1, `(Rational|Integer).to_s` 1, `(AccountNotFound|AccountFrozen).id` 1, `(ProfileError|DecodeError).cause` 1, `(Opened|Deposited|Withdrawn|Closed).account` 1, `(Deposited|Withdrawn|Transferred).amount` 1
