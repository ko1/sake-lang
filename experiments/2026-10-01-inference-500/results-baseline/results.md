## Sake typer (500 programs; 0 failed to load)

"determined" = mono + nilable + union among reached units (no unknown anywhere in the type).

| unit | n | mono | nilable | union | partial | unknown | none | determined |
|---|---|---|---|---|---|---|---|---|
| expr.var | 57645 | 45579 (79.1%) | 7876 (13.7%) | 2695 (4.7%) | 229 (0.4%) | 615 (1.1%) | 651 (1.1%) | 98.5% |
| expr.call | 61718 | 49109 (79.6%) | 8028 (13.0%) | 1907 (3.1%) | 253 (0.4%) | 890 (1.4%) | 1531 (2.5%) | 98.1% |
| sig.param | 5164 | 4113 (79.6%) | 620 (12.0%) | 372 (7.2%) | 15 (0.3%) | 39 (0.8%) | 5 (0.1%) | 99.0% |
| sig.ret | 4294 | 3321 (77.3%) | 616 (14.3%) | 255 (5.9%) | 19 (0.4%) | 68 (1.6%) | 15 (0.3%) | 98.0% |
| sig.field | 2846 | 2325 (81.7%) | 369 (13.0%) | 105 (3.7%) | 15 (0.5%) | 32 (1.1%) | 0 (0.0%) | 98.3% |

- not converged within the pass limit: 0
- dead (never called) functions: 110
- run-time check sites: proven=47762 error=594 partial=3883 unknown=331

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
- failure: corpus/18-collections/room_bookings.rb: typeprof timeout (120 s)
- failure: corpus/13-polymorphism/bitset_permissions.rb: typeprof timeout (120 s)
- failure: corpus/13-polymorphism/collision_check.rb: typeprof timeout (120 s)
- failure: corpus/02-analytics/tf_idf.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/01-text/classic_ciphers.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/12-parsers/type_checker.rb: typeprof timeout (120 s)
- failure: corpus/05-sorting/staff_multikey_sort.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/05-sorting/triage_partition.rb: typeprof failed (exit 1): /home/ko1/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems/typeprof-0.31.1/lib/typeprof/core/ast/sig_type.rb:819:in 'TypeProf::Core::AST::SigTyVarNode#covariant_vertex0': unknown type variable: Return (RuntimeError)
- failure: corpus/14-errors/expr_calculator.rb: typeprof timeout (120 s)
- failure: corpus/17-encodings/xor_breaker.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/epidemic_network.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/11-simulation/forest_fire.rb: typeprof timeout (120 s)
- failure: corpus/08-graphs/dijkstra_routes.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/08-graphs/euler_itinerary.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/09-dp/floyd_warshall.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/11-simulation/langton_ants.rb: typeprof timeout (120 s)
- failure: corpus/12-parsers/chem_formula.rb: typeprof timeout (120 s)
- failure: corpus/08-graphs/prim_cables.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/03-numtheory/goldbach.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/20-business/grade_book.rb: typeprof timeout (120 s)
- failure: corpus/15-data/top_products.rb: typeprof timeout (120 s)
- failure: corpus/16-dates/public_holidays.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/sparse_vectors.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/survey_venn.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/tag_recommender.rb: typeprof timeout (120 s)
- failure: corpus/01-text/doc_pretty.rb: typeprof timeout (120 s)
- failure: corpus/16-dates/date_parser.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/access_log.rb: typeprof failed (exit 1): /home/ko1/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems/typeprof-0.31.1/lib/typeprof/core/ast/sig_type.rb:819:in 'TypeProf::Core::AST::SigTyVarNode#covariant_vertex0': unknown type variable: Return (RuntimeError)
- failure: corpus/18-collections/build_order.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/course_overlap.rb: typeprof timeout (120 s)
- failure: corpus/19-statemachines/machine_mixin.rb: typeprof timeout (120 s)
- failure: corpus/06-linked/adjacency_list_courses.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/11-simulation/parking_garage.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/bakery_shift.rb: typeprof timeout (120 s)
- failure: corpus/11-simulation/cpu_scheduler.rb: typeprof timeout (120 s)
- failure: corpus/04-numeric/cubic_spline.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/04-numeric/descriptive_stats.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/02-analytics/markov_text.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/02-analytics/naive_bayes.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/14-errors/nested_schema.rb: typeprof timeout (120 s)
- failure: corpus/17-encodings/rolling_sync.rb: typeprof timeout (120 s)
- failure: corpus/09-dp/dice_odds.rb: typeprof timeout (120 s)
- failure: corpus/20-business/payroll.rb: typeprof timeout (120 s)
- failure: corpus/14-errors/spreadsheet_errors.rb: typeprof timeout (120 s)
- failure: corpus/02-analytics/caesar_crack.rb: typeprof failed (exit 1): [FATAL] failed to allocate memory
- failure: corpus/14-errors/password_policy.rb: typeprof timeout (120 s)
- failure: corpus/19-statemachines/tcp_states.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/leaderboard.rb: typeprof timeout (120 s)
- failure: corpus/18-collections/inventory_diff.rb: typeprof timeout (120 s)

## Sake checks before running on correct programs (false reports)

| level | programs rejected | diagnostics |
|---|---|---|
| 1 | 192 / 500 | 580 |
| 2 | 355 / 500 | 1844 |
| 3 | 465 / 500 | 4241 |
| 4 | 473 / 500 | 4453 |

## Per domain

| domain | programs | Sake expr determined | Sake sig determined | TypeProf sig determined |
|---|---|---|---|---|
| 01-text | 25 | 99.1% | 98.5% | 92.7% |
| 02-analytics | 25 | 98.2% | 99.1% | 91.2% |
| 03-numtheory | 25 | 99.8% | 99.8% | 96.2% |
| 04-numeric | 25 | 99.3% | 99.0% | 88.7% |
| 05-sorting | 25 | 98.6% | 98.5% | 91.0% |
| 06-linked | 25 | 99.7% | 100.0% | 93.2% |
| 07-trees | 25 | 97.2% | 97.8% | 89.5% |
| 08-graphs | 25 | 98.9% | 98.5% | 92.5% |
| 09-dp | 25 | 99.8% | 100.0% | 92.7% |
| 10-grids | 25 | 99.7% | 100.0% | 88.8% |
| 11-simulation | 25 | 99.9% | 100.0% | 94.1% |
| 12-parsers | 25 | 87.4% | 85.4% | 89.9% |
| 13-polymorphism | 25 | 98.6% | 99.0% | 94.7% |
| 14-errors | 25 | 98.2% | 98.9% | 90.3% |
| 15-data | 25 | 99.9% | 100.0% | 85.7% |
| 16-dates | 25 | 99.6% | 100.0% | 83.2% |
| 17-encodings | 25 | 98.6% | 99.0% | 96.4% |
| 18-collections | 25 | 96.9% | 97.0% | 90.5% |
| 19-statemachines | 25 | 98.2% | 99.3% | 97.8% |
| 20-business | 25 | 99.6% | 100.0% | 88.4% |

## Why Sake units are not mono (by callee / reason)

**unknown** (1644): `unknown: scan groups` 495, `unknown: operand` 410, `unknown: no signature for ...` 291, `unknown: index` 249, `unknown: tuple depth` 43, `unknown: record depth` 40, `unknown: destructure` 36, `unknown: recursive yield` 35, `unknown: pattern` 26, `unknown: block destructure` 16, `unknown: record variants` 3

**partial** (531): `unknown: scan groups` 333, `unknown: index` 102, `unknown: block destructure` 28, `unknown: tuple depth` 28, `unknown: operand` 27, `unknown: no signature for ...` 13

**union** (5334): `union: expr.var` 2695, `union: sig.param` 372, `union: sig.ret` 255, `union: sig.field` 105, `union: Array.each` 102, `union: a` 90, `union: Array` 83, `union: Array.push` 60, `union: Hash` 44, `union: Array[]` 43, `union: yield` 42, `union: Array.map` 34, `union: Array.sum` 23, `union: m` 21, `union: Hash.fetch` 21

**nilable** (17509): `nilable: expr.var` 7876, `nilable: sig.param` 620, `nilable: sig.ret` 616, `nilable: sig.field` 369, `nilable: m` 363, `nilable: Array.push` 202, `nilable: Array.max` 185, `nilable: Array.each` 136, `nilable: Array[]` 130, `nilable: Array.map` 127, `nilable: String.match` 116, `nilable: Array.last` 109, `nilable: Array` 98, `nilable: a` 96, `nilable: Array.max_by` 86


## Corpus check

- programs: 500; run with exit 0 and output identical to Ruby and .out: 500

## Soundness (crosscheck)

| typer | programs checked | violations | programs with violations |
|---|---|---|---|
| as is | 500 | 585 | 67 |
| sabotaged (negative control) | 500 | 2306 | 222 |

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

Sake versions: hand-written dispatch (case/in or if-in branches calling the same operation through different types): 24 operations in 16 programs; calls through a module of the program: 223 in 30 programs.

`(Array|Hash).map` 3, `(Var|Fn).get_name` 3, `(Insert|Delete|Replace).get_pos` 2, `(Deposited|Withdrawn|Transferred).get_amount` 1, `(Opened|Deposited|Withdrawn|Closed).get_account` 1, `(Rational|Integer).to_f` 1, `(ProfileError|DecodeError).get_cause` 1, `(AccountNotFound|AccountFrozen).get_id` 1, `(Rational|Integer).to_s` 1, `(Circle|Box|Dot).moved` 1, `(Circle|Box|Dot).bounds` 1, `(Logic|Cmp).get_op` 1, `(Lambda|Prim).get_name` 1, `(Hash|Array).map` 1, `(Hash|Array).empty?` 1, `(MLeaf|MNode).get_hash` 1, `(Leaf|Internal).get_order` 1, `(Leaf|Internal).get_weight` 1, `(Array|String).size` 1
