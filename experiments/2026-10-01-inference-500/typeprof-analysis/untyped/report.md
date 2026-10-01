# Where TypeProf's untyped comes from

451 programs that TypeProf finished. A slot is a method parameter, a return value, or an attr reader.
"reached": the method ran when the program was executed (TracePoint :call); a field counts as reached when any method of its class ran.

| unit | slots | with untyped | of which in methods that never ran | in methods that ran |
|---|---|---|---|---|
| sig.param | 4516 | 428 (9.5%) | 22 | 406 |
| sig.ret | 3550 | 301 (8.5%) | 5 | 296 |
| sig.field | 2299 | 184 (8.0%) | 0 | 184 |

## Shape of the untyped type, in methods that ran

| shape | param | ret | field |
|---|---|---|---|
| untyped | 238 | 145 | 131 |
| Array[untyped] | 57 | 38 | 19 |
| Hash[K, untyped] or Hash[untyped, V] | 33 | 37 | 13 |
| Array[... untyped ...] | 39 | 17 | 10 |
| tuple with untyped | 11 | 35 | 2 |
| other ((:quote | Integer | Lambda | Prim | Symb) | 5 | 6 | 0 |
| other ((Float | Hash[String, (Float | Hash[Stri) | 5 | 5 | 0 |
| other (Set[untyped]) | 1 | 2 | 2 |
| other ((Array[(Array[String?] | Array[untyped] ) | 3 | 2 | 0 |
| other ((Array[untyped] | Integer)?) | 4 | 0 | 0 |
| other (Set[String] | Set[untyped]) | 0 | 1 | 2 |
| other ((Array[(Array[untyped] | Float | Integer) | 1 | 1 | 0 |
| other (([ Float, Float ] | [ untyped, untyped ]) | 2 | 0 | 0 |
| Hash[untyped, untyped] | 0 | 1 | 1 |
| other ((Array[untyped] | Integer | String | boo) | 0 | 1 | 0 |
| other ((Array[untyped] | Integer | String | [ ]) | 1 | 0 | 0 |
| other (Set[Integer] | Set[untyped]) | 0 | 1 | 0 |
| other (([ Integer, Integer ] | [ untyped, untyp) | 0 | 1 | 0 |
| other ((Array[untyped] | Cpx)?) | 1 | 0 | 0 |
| other ((Array[untyped] | Integer | Rational | S) | 0 | 1 | 0 |
| other (Set[:screen | :video | :whiteboard] | Se) | 0 | 0 | 1 |
| other (Set[:video] | Set[:whiteboard] | Set[unt) | 1 | 0 | 0 |
| other (Set[(Integer | Numeric | [ Integer | Num) | 0 | 0 | 1 |
| other (Integer | [ Integer | [ untyped, Integer) | 0 | 0 | 1 |
| other ((:quote | Integer | String | Symbol | [ ) | 1 | 0 | 0 |
| other (Integer | Symbol | [ :quote, Integer | S) | 0 | 1 | 0 |
| other ((Array[:quote | Integer | Symbol | [ :qu) | 0 | 0 | 1 |
| other ((Integer | Symbol | [ :quote, Integer | ) | 1 | 0 | 0 |
| other ((:"=" | :* | :+ | :- | :/ | :< | :car | ) | 1 | 0 | 0 |
| other ((:quote | Integer | Symbol | [ :quote, I) | 1 | 0 | 0 |
| other (([ String, Integer ] | [ String, untyped) | 0 | 1 | 0 |

## Programs with the most untyped slots in methods that ran

- corpus/12-parsers/lisp_interp.rb: 21
- corpus/06-linked/list_toolkit.rb: 20
- corpus/10-grids/magic_square.rb: 19
- corpus/16-dates/recurring_events.rb: 17
- corpus/16-dates/billing_cycles.rb: 15
- corpus/12-parsers/truth_table.rb: 15
- corpus/14-errors/result_pipeline.rb: 14
- corpus/16-dates/timesheet.rb: 13
- corpus/16-dates/parking_fees.rb: 13
- corpus/07-trees/spanning_tree.rb: 13
- corpus/20-business/sales_report.rb: 12
- corpus/07-trees/interval_bookings.rb: 12

## Sample (every 25th untyped slot in a method that ran)

- corpus/17-encodings/check_digits.rb `CheckDigit#digits_of 0` (sig.param): `untyped`
- corpus/05-sorting/meeting_intervals.rb `Meeting#minutes` (sig.ret): `Array[untyped]`
- corpus/20-business/appointment_scheduler.rb `Object#free_run 2` (sig.param): `untyped`
- corpus/15-data/etl_star_schema.rb `Object#to_cents` (sig.ret): `untyped`
- corpus/01-text/ini_config.rb `Object#coerce` (sig.ret): `(Array[(Array[untyped] | Float | Integer | String | bool)?] | Float | Integer | String | bool)?`
- corpus/05-sorting/hashtag_trends.rb `Object#ranking 0` (sig.param): `Array[untyped]`
- corpus/14-errors/bank_transfers.rb `Account#withdraw` (sig.ret): `untyped`
- corpus/07-trees/spanning_tree.rb `Edge#a` (sig.field): `untyped`
- corpus/12-parsers/lisp_interp.rb `Object#lisp_eval 0` (sig.param): `(:quote | Integer | String | Symbol | [ :quote, Integer | Symbol | [ :quote, untyped ] | [ ] | bool ] | [ ] | bool)?`
- corpus/06-linked/list_toolkit.rb `L#palindrome? 0` (sig.param): `untyped`
- corpus/11-simulation/bank_ledger.rb `Bank#total` (sig.ret): `untyped`
- corpus/04-numeric/correlation_matrix.rb `Object#pearson 1` (sig.param): `Array[Float] | Array[untyped] | [ Float, Float, Float, Float ]`
- corpus/07-trees/interval_bookings.rb `INode#max_end` (sig.field): `untyped`
- corpus/01-text/text_stats.rb `Object#flesch 2` (sig.param): `untyped`
- corpus/19-statemachines/dfa_minimize.rb `Dfa#accepts? 0` (sig.param): `Array[Array[untyped] | String] | String`
- corpus/07-trees/filesystem_du.rb `Dir#name` (sig.field): `untyped`
- corpus/08-graphs/intern_matching.rb `Intern#name` (sig.field): `Array[untyped]`
- corpus/13-polymorphism/stack_vm.rb `BinOp#op` (sig.field): `untyped`
- corpus/16-dates/timesheet.rb `Object#parse_time` (sig.ret): `untyped`
- corpus/15-data/metric_anomalies.rb `Object#median` (sig.ret): `untyped`
- corpus/14-errors/warehouse_reservation.rb `OutOfStock#available` (sig.field): `untyped`
- corpus/16-dates/fiscal_quarters.rb `Object#retail_period` (sig.ret): `[ untyped, Integer, Integer, Integer ]`
- corpus/16-dates/parking_fees.rb `Object#ts` (sig.ret): `untyped`
- corpus/10-grids/magic_square.rb `Build#blank 0` (sig.param): `untyped`
- corpus/06-linked/digit_list_bignum.rb `BigNat#<=> 0` (sig.param): `untyped`
- corpus/09-dp/digit_counting.rb `Object#repeat_walk 0` (sig.param): `Array[untyped]`
- corpus/07-trees/bill_of_materials.rb `Catalog#where_used` (sig.ret): `Array[untyped]`
- corpus/04-numeric/eigenvalues.rb `Object#mat_vec` (sig.ret): `Array[untyped]`
- corpus/15-data/timesheet_payroll.rb `Shift#minutes` (sig.field): `untyped`
- corpus/06-linked/undo_redo_editor.rb `Editor#replace_all 0` (sig.param): `untyped`
- corpus/11-simulation/packet_network.rb `Routing#table` (sig.ret): `untyped`
- corpus/20-business/todo_list.rb `Todo#title` (sig.field): `untyped`
- corpus/20-business/sales_report.rb `Sale#region` (sig.field): `untyped`
- corpus/08-graphs/course_schedule.rb `Course#code` (sig.field): `untyped`
- corpus/13-polymorphism/life_grid.rb `Grid#cells` (sig.field): `Array[Array[untyped]]`
- corpus/09-dp/sequence_alignment.rb `Object#pair_score 1` (sig.param): `untyped`
