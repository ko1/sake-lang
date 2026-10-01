# Tally of difficulties in corpus/*/NOTES.md

Source: the 20 `corpus/<domain>/NOTES.md` files (500 programs, 25 per domain), read 2026-10-01.
The NOTES files were not changed.

## How the counts were made

- **Programs** = distinct task slugs (`domain/slug`) whose NOTES entry mentions the issue. A program
  counts once per issue, however many times it hits it.
- Many notes say an issue is "recurring; not repeated below", "applies to most tasks" or "General". Those
  domains are listed, but no slugs are added for them, so the count is a lower bound and is written **≥N**.
  The real count for issues like unary minus, value constants and multiple assignment is higher.
- In 17-encodings the general note names tables and functions instead of slugs ("Morse table",
  "zigzag" ...). I mapped them to slugs (morse, base64_codec, caesar_cracker, crc_catalog;
  protobuf_wire, bitset) and checked the `.sake` files to confirm.
- Writers do not always mention the same thing. One writer notes every `0 - x`. Another notes it once.
  So the counts measure how often writers *noticed and reported* an issue, not how often it occurs in
  the code. To get exact frequencies, grep the `.sake`/`.rb` pairs.
- Domain codes: 01 text, 02 analytics, 03 numtheory, 04 numeric, 05 sorting, 06 linked, 07 trees,
  08 graphs, 09 dp, 10 grids, 11 simulation, 12 parsers, 13 polymorphism, 14 errors, 15 data, 16 dates,
  17 encodings, 18 collections, 19 statemachines, 20 business.

Category key: **(a)** missing language feature / language design, **(b)** missing built-in operation or
argument, **(c)** interpreter bug or misleading message, **(d)** documentation mismatch, **(e)**
performance, **(f)** environment/process.

The user's example "Tuples have no == / ordering" is split here into two issues because the counts
differ: #1 (ordering: sort/min_by/max_by keys) and #4 (`==` on Tuple/Array/Set).

## Summary table

| # | Issue | Programs | Domains | Cat. | Status |
|---|-------|---------:|--------:|:----:|--------|
| 1 | Tuples are not ordered (multi-key `sort_by`/`min_by`/`max_by`, `[a,b] <=> [c,d]`) | 50 | 19 | a | open |
| 2 | No value constants (`FOO = ...`; `{}` is a Record) | ≥37 | 14 | a | open |
| 3 | Multiple assignment from an Array (`a, b = s.split(...)`) | ≥34 | 14 | a | open |
| 4 | `==`/`!=` undefined on Tuple/Array/Set | ≥30 | 13 | a | open |
| 5 | No unary minus on expressions (`-x`) | ≥29 | 19 | a | open |
| 6 | No `break` inside blocks; no `loop do` | ≥27 | 16 | a | open |
| 7 | No Enumerator chains (`each_with_index.map`, `each_cons(2).count`, ...) | ≥25 | 14 | b | open |
| 8 | No `Array.new(n, v)` / `Array.new(n) { }` | ≥24 | 14 | b | open |
| 9 | Slow interpreter forced smaller workloads | 22 | 11 | e | open |
| 10 | No `Array + Array` (also `-`, `[x] * n`) | 21 | 11 | b | open |
| 11 | No `case/when` (only `case/in`) | ≥21 | 10 | a | open |
| 12 | No nested destructuring in block/method params (`\|(a, b), i\|`) | ≥21 | 11 | a | open |
| 13 | No splat (`a, *b =`, `f(*x)`, `[h, *rows]`, `Set[*x]`) | ≥17 | 10 | a | open |
| 14 | No unary `!` (and `~`) | ≥16 | 13 | a | open |
| 15 | `[]` takes one index (`s[i, len]`, `m[r, c]`) | 16 | 13 | a/b | open |
| 16 | Records have no `r[:k]` read; every read is a `=> {k:}` pattern | 14 | 9 | a | open |
| 17 | `each_cons`/`each_slice`/`combination` yield Arrays, which `\|a, b\|` does not destructure | ≥13 | 11 | a/b | open |
| 18 | Struct `==` is structural; no identity (`equal?`); Comparable does not define `==` | 12 | 6 | a | open |
| 19 | Multiple assignment to index targets (`a[i], a[j] = a[j], a[i]`) | ≥9 | 7 | a | open |
| 20 | No two-argument min/max (`[a, b].max` is a Tuple with no `max`) | 9 | 8 | b | open |
| 21 | Module dispatch needs the function defined in the module (abstract stub) | 9 | 7 | a/d | open |
| 22 | Misleading "cannot compare elements of types X" message for Tuple keys | ≥8 | 8 | c | **fixed** |
| 23 | No `initialize` / default parameters; every Struct field is positional | 8 | 6 | a | open |
| 24 | Blocks are not values: `&block` forwarding needs `{ \|x\| yield(x) }` | 7 | 5 | a | open |
| 25 | No `Hash.new { \|h, k\| h[k] = [] }` (default block) | 7 | 7 | a | open |
| 26 | No `%w[...]` | ≥7 | 7 | a | open |
| 27 | No safe navigation `&.` | ≥7 | 5 | a | open |
| 28 | `x in T ? a : b` / `x in T && ...` needs parentheses | 7 | 6 | a | open (Ruby grammar) |
| 29 | No block form of `to_h` (Array/Set) | 6 | 4 | b | open |
| 30 | No `dup` for Hash/Set/Struct | 6 | 4 | b | open |
| 31 | No built-in numeric constants (`Math::PI`, `Float::INFINITY`, `Float::EPSILON`, `Math::E`) | ≥6 | 4 | b | open |
| 32 | Assignment in a condition avoided by writers, though it works | 6 | 4 | d | open (docs) |
| 33 | `String.split` has no limit argument | 5 | 4 | b | open |
| 34 | Type-specific numeric ops on union values (`abs`, `Float.round`, `Rational.to_f` on Integer) | 5 | 4 | a | open |
| 35 | `Array.join` without a separator crashed the interpreter | ≥4 | 6 | c | **fixed** |
| 36 | No radix argument (`Integer.to_s(n, 16)`, `String.to_i(s, 2)`, `Kernel.Integer(s, 10)`) | ≥4 | 5 | b | open |
| 37 | `==` between different types raises TypeError (and is asymmetric) | ≥4 | 2 | a/c | open |
| 38 | No default value/block on `Hash.fetch` / `Array.fetch` | 4 | 4 | b | open |
| 39 | `[...]` literal is a Tuple, not an Array (where Ruby code expects an Array) | 4 | 4 | a | open |
| 40 | No `send`/`public_send`/lambdas (operator tables become `case`) | 4 | 1 | a | open |
| 41 | Tuple equality is inconsistent: `include?`/`index`/`uniq` compare Tuples, `==` raises | 4 | 4 | c/d | open |
| 42 | `Set.select`/`reject`/`filter` returned an Array; spec said Set | 3 | 3 | d | **fixed** |
| 43 | No `gsub` with a block, no `$1` | 3 | 2 | b/a | open |
| 44 | `String.index` has no start offset | 3 | 2 | b | open |
| 45 | `Range.sum` takes no block | 3 | 3 | b | open |
| 46 | String Ranges cannot be iterated (`"a".."z"`) | 3 | 2 | b | open |
| 47 | `\|\|=` on an ivar/attribute rejected (`@x \|\|= v`, `node.zero \|\|= ...`) | 3 | 3 | a | open |
| 48 | `@x` always means the first parameter (pitfall in factory functions) | 3 | 3 | a | open |
| 49 | No `String#<<` / Array `<<` | 3 | 2 | b | open |
| 50 | Built-in exception messages carry a Sake prefix; `puts(e)` prints inspect form | ≥3 | 3 | a | open |
| 51 | Interpreter broken by concurrent edits of `lib/` (shared tree) | 3 (+1 domain) | 4 | f | process |
| 52 | A user function named `call` could not be called (`S.call(x)` read as `S.(...)`) | 2 | 2 | c | **fixed** |
| 53 | spec §8.3 lists `<=>` as unsupported, but it works | 2 | 2 | d | open |
| 54 | `String.chomp` takes no argument | 2 | 2 | b | open |
| 55 | `Array.last` takes no count | 2 | 2 | b | open |
| 56 | `reduce` needs an initial value; no `reduce(:&)` | 2 | 2 | b | open |
| 57 | No keyword arguments (`exception: false`, `chomp: true`) | 2 | 2 | a | open |
| 58 | TypeError / program errors cannot be rescued | 2 | 2 | a | open |
| 59 | Array cannot be a Hash key; Struct cannot be a Set element | 2 | 2 | a | open |
| 60 | `Array.uniq` did not deduplicate equal Struct values | 1 | 1 | c | **fixed** |
| 61 | Singletons (see list below) | 1 each | — | mixed | open |
| — | Duplicated diagnostics | 0 | 0 | c | **fixed** (not mentioned in any NOTES) |

## Details

Each entry gives: description; programs (slugs); workaround; category.

### 1. Tuples are not ordered — 50 programs, 19 domains (all except 04) — (a)
A Tuple sort key (`sort_by { [-n, w] }`), `Array.sort`/`max`/`min_by` on Tuples, and Ruby's
Array `<=>` all fail at run time with `ArgumentError: ... cannot compare elements`.
- 01 text_stats, spell_suggest · 02 kwic_concordance, language_guess (+General) · 03 sieve_primes,
  factor_functions, happy_cycles · 05 merge_sort_inversions, autocomplete_msd, hashtag_trends (+General) ·
  06 markup_tag_checker, josephus_circle, chained_hash_table · 07 trie_autocomplete, huffman ·
  08 dijkstra_routes, exam_slots · 09 longest_increasing (+General: `Array.max` on Tuples) · 10 flood_fill
  (+General) · 11 elevator_scan, life_torus, parking_garage, epidemic_network, cpu_scheduler, runway_ops,
  ring_road_traffic · 12 stack_vm · 13 sparse_vector · 14 registration_form, card_validation, job_queue ·
  15 sales_by_region, access_log_report (+General) · 16 iso_week, easter, fiscal_quarters · 17 huffman,
  transposition · 18 course_overlap, word_pipeline, tag_recommender, word_rack · 19 turnstile, elevator ·
  20 todo_list, room_reservations, gym_membership, parking_garage, ticket_helpdesk, warehouse_picking (+General)
- Workaround: pack the keys into one Integer (`(0 - n) * 10000 + k`) or a zero-padded String
  (`format("%06d %s", 999999 - n, w)`); otherwise a Struct with `include Comparable` + `<=>`, or a
  chained `<=>` in place of Ruby's Array `<=>`. Some writers dropped the tie-break and relied on
  `min_by` keeping the first minimum (11 elevator_scan). Several noted that a packed key "happens to
  give the same order on this data" (05 hashtag_trends). Packed keys are fragile.

### 2. No value constants — ≥37 programs, 14 domains — (a)
`FOO = [...]`/`{...}.freeze` has no Sake form, and `{...}` is a Record, not a Hash.
- 01 markdown_html · 04 correlation_matrix (+General: Gauss nodes etc.) · 06 rpn_stack_calculator,
  ring_buffer_metrics · 07 segment_tree_stats, quadtree · 10 sudoku_solver, tic_tac_toe, connect_four,
  langtons_ant, chess_attacks (+General) · 11 traffic_intersection, vending_machine, parking_garage,
  thermostat_house, forest_fire, langton_ants, car_rental, bakery_shift, hotel_bookings · 12 forth,
  symbolic_diff · 13 money_ledger, sparse_vector, bitset_permissions · 15 access_log_report,
  metric_anomalies · 16 durations (+General: "every Sake version") · 17 morse, base64_codec,
  caesar_cracker, crc_catalog (from General) · 18 access_log · 19 tcp_states, machine_mixin ·
  20 expense_tracker, subscription_billing (+General)
- Workaround: a zero-argument function (`def day_names = Array[...]`), a `case/in` lookup function, a
  nested ternary, or a Struct field built once. Side effect: tables are rebuilt on every call (11
  thermostat_house: ~600 rebuilds; 13 bitset_permissions; 17 General).

### 3. Multiple assignment from an Array — ≥34 programs, 14 domains — (a)
`a, b = String.split(...)` (or any Array) fails at run time: `TypeError: multiple assignment needs a
Tuple, got Array`. Several writers called this the most frequent workaround (20 General).
- 01 template_render · 04 numerical_derivatives · 05 staff_multikey_sort, meeting_intervals, version_resolver ·
  06 undo_redo_editor · 07 heap_scheduler, dom_tree (`m.captures`), ip_route_trie ("recurring; not repeated") ·
  08 course_schedule, intern_matching · 09 interval_scheduling · 12 chem_formula · 13 duration_timesheet,
  physical_quantities, stack_vm · 15 sales_by_region, metric_anomalies, league_standings (+General) ·
  16 iso_week, meeting_scheduler, fiscal_quarters · 18 room_bookings, latency_buckets, ip_ranges ·
  19 http_parser · 20 grade_book, gym_membership, parking_garage, timesheet, warehouse_picking,
  vendor_quotes, bank_ledger, invoice_generator
- Workaround: index the Array (`parts[0]`, `Array.fetch(parts, 1)`). Where the shape fits, use
  `String.partition`, which returns a 3-Tuple (`a, _sep, b = String.partition(s, ":")`). Or
  `a, b = parts[0], parts[1]` (the right-hand list is a Tuple).

### 4. `==`/`!=` undefined on Tuple/Array/Set — ≥30 programs, 13 domains — (a)
`[1, 2] == [1, 2]` raises `TypeError: Kernel.==: no implementation for (Tuple, Tuple)`. The same holds for
`(Array, Array)` and `(Set, Set)`.
- 03 integer_partitions, quadratic_residues (+General) · 04 optimization · 05 heap_scheduler,
  radix_order_ids, autocomplete_msd, bucket_sort_ratings, shell_sort_gaps, triage_partition,
  natural_runs_sort · 07 btree · 08 maze_bfs, astar_terrain (+General) · 09 (General, probing only) ·
  10 maze_bfs, sokoban, terrain_dijkstra, n_queens, game_2048, matrix_spiral, battleship, nonogram ·
  12 regex_matcher, cmdline_parser · 13 physical_quantities · 14 matrix_checks · 16 easter, moon_phases ·
  17 run_length, percent_encoding · 18 lottery (Set)
- Workaround: compare `Array.join(a, ",")` strings, a `same_pos?` helper that destructures both
  Tuples, `Range.all?` over indices, or for Sets `Set.subset?(a, b) && Set.superset?(a, b)`.

### 5. No unary minus — ≥29 programs, 19 domains (all except 15) — (a)
`-x` on a non-literal is rejected. Negative literals (`-1`) are fine.
- 01 markdown_table, number_words, human_format (`10 ** -d`) · 02 (General) · 03 sieve_primes (+General) ·
  04 lu_decomposition, float_accuracy, numerical_derivatives, loan_amortization (+General "most tasks") ·
  05 trail_peak_search ("same in other tasks") · 06 rpn_stack_calculator, deque_sliding_window ·
  07 trie_autocomplete ("recurring; not repeated") · 08 exam_slots · 09 (General) · 10 n_queens,
  connect_four, hex_game (+General) · 11 life_torus · 12 calc_rd · 13 fraction_math, quaternion_rotation ·
  14 (General) · 16 easter (+General) · 17 bitset, protobuf_wire (General) · 18 course_overlap,
  word_pipeline · 19 turnstile · 20 payroll, sales_report, bank_ledger (+General)
- Workaround: `0 - x`, `0.0 - x`, `x * -1`, `** (0 - k)`.

### 6. No `break` inside blocks; no `loop do` — ≥27 programs, 16 domains — (a)
`break` inside `each` is a static error ("only supported directly inside `while`/`until`"). `loop do`
does not exist.
- 01 slugify, json_pretty · 03 farey_stern_brocot, linear_sieve (+General) · 04 eigenvalues ·
  06 skip_list_index · 07 dom_tree · 08 land_islands · 09 line_breaking, sequence_alignment (+General) ·
  10 minesweeper, battleship, game_2048, hex_game, sliding_puzzle (+General) · 11 teller_queue_des ·
  12 calc_rd, stack_vm · 13 version_constraints, payroll · 14 (General) · 16 billing_cycles ·
  18 room_bookings, prime_sets, paginate · 19 bank_queue_sim, job_pipeline · 20 customer_loyalty (+General)
- Workaround: `while` with an index and `break`; `while true ... break`; or `next if done` with a flag.
  The flag form keeps iterating, and changes run time: 03 linear_sieve took 88 s for N=3000 with
  `next`, and was rewritten as `while` with N reduced to 1500.

### 7. No Enumerator chains — ≥25 programs, 14 domains — (b)
Block-less iterators are missing (`each_with_index.map`, `each_cons(2).count`, `each_slice(2).map`,
`times.any?`, `each_index.min_by`, `each.with_index(1)`, `each_line.with_index`).
- 01 markdown_table, csv_report · 03 pollard_rho, fibonacci_numbers · 04 gaussian_elimination, time_series ·
  06 merge_log_streams, monotonic_stack_prices · 07 merkle_sync · 08 land_islands · 09 digit_counting ·
  10 sudoku_solver, n_queens, knights_tour, terrain_dijkstra, magic_square, lights_out (+General) ·
  12 indent_lexer · 13 polynomial · 15 timesheet_payroll, table_renderer · 16 timetable · 18 leaderboard ·
  20 timesheet, warehouse_picking
- Workaround: one block-taking call that pushes into an `Array[]` or updates a running counter/max;
  `Range.map(0...n)` over indices; a `with_index` helper built from `Array.zip` (15 table_renderer).

### 8. No `Array.new(n, v)` / `Array.new(n) { }` — ≥24 programs, 14 domains — (b)
- 01 line_diff · 03 sieve_primes, linear_sieve (+General) · 04 gaussian_elimination, polynomial ·
  05 radix_order_ids · 06 ring_buffer_metrics, skip_list_index, free_list_pool, monotonic_stack_prices ·
  07 segment_tree_stats · 08 kruskal_network · 09 grid_paths (+General) · 10 minesweeper, nonogram,
  othello · 11 forest_fire, sandpile, ring_road_traffic · 12 brainfuck · 13 polynomial, life_grid ·
  17 transposition · 20 appointment_scheduler
- Workaround: `Range.map(0...n) { v }`, `Integer.times` + `Array.push`, `Array.fill(Range.to_a(0..n), v)`.

### 9. Slow interpreter forced smaller workloads — 22 programs, 11 domains — (e)
The first versions took 5-88 s in Sake against ~0.1 s in Ruby. Inputs were cut to stay under about 3-5 s.
- 01 spell_suggest · 02 spell_suggest (slowest, ~3.5 s) · 03 linear_sieve, fibonacci_numbers,
  collatz_stats, miller_rabin, goldbach, happy_cycles, pollard_rho · 04 optimization (22 s), monte_carlo
  (10 s vs 0.1 s), float_accuracy (24 s), bezier_curves (15 s) · 09 digit_counting (16 s) ·
  10 sudoku_solver (5 s) · 11 langton_ants, ring_road_traffic (5.8 s) · 12 tiny_basic (14 s) ·
  16 cron_schedule (11 s vs 0.1 s) · 17 bloom_filter (4.9 s), xor_breaker · 19 bank_queue_sim
- Workaround: smaller N, fewer iterations, an easier puzzle; 16 cron_schedule also hoisted a sort.
- Caveat: the machine had load averages of 25-40 on 16 cores (03, 04, 10, 17, 19). The absolute times
  are noisy, but the 10-100x ratios to Ruby were measured at the same moment.

### 10. No `Array + Array` (also `-`, `* n`) — 21 programs, 11 domains — (b)
`Arithmetic.+: no implementation for (Array, Array)`.
- 01 ascii_table, outline_number, doc_pretty · 03 integer_partitions, pollard_rho · 06 sparse_matrix_rows
  (`[1] * n`) · 08 currency_paths · 09 held_karp · 10 battleship, nonogram, chess_attacks · 11 runway_ops
  (`-`) · 12 chem_formula · 15 table_renderer · 18 sales_pivot, role_permissions, contact_dedupe (`+`, `-`),
  word_rack (`[c] * n`) · 19 regex_nfa, csv_parser, job_pipeline
- Workaround: `Array.push(Array.dup(a), x)`, `Array.concat(Array.dup(a), b)`, `Array.unshift`,
  `Array.union`, `Array.difference`, `Array.delete_if` + `include?`.

### 11. No `case/when` — ≥21 programs, 10 domains — (a)
Only `case/in` exists. Regexp, Range and class `===` dispatch from `when` has no equivalent.
- 01 justify_text, json_pretty, ini_config, classic_ciphers, markdown_html · 06 rpn_stack_calculator,
  undo_redo_editor · 07 expression_tree · 09 sequence_alignment (+General) · 10 minesweeper,
  terrain_dijkstra · 11 teller_queue_des · 12 calc_rd, stack_vm, forth, turing_machine, symbolic_diff ·
  16 date_parser · 17 protobuf_wire · 18 access_log, library_loans
- Workaround: `case x in :a | :b` for literals and types (it needs an explicit `else`/`in String then nil`
  arm for exhaustiveness, 10 terrain_dijkstra). Regexp `when` becomes an `if/elsif` chain of
  `String.match?`. Range `when` becomes comparisons.

### 12. No nested destructuring in parameters — ≥21 programs, 11 domains — (a)
`|(a, b), i|`, `|acc, (p, e)|`, `def dist((px, py), ...)`, and nested multiple assignment
`(a, b), c = x` are rejected ("nested destructuring `(a, b)` is not supported").
- 02 ngram_counts, kwic_concordance, language_guess · 03 factor_functions · 04 histogram_fit,
  bezier_curves · 07 merkle_sync · 10 maze_bfs, chess_attacks (+General) · 11 cpu_scheduler,
  checkout_lanes · 15 expense_pivot, budget_variance (+General) · 16 durations, fiscal_quarters ·
  18 word_pipeline, sales_pivot, leaderboard, lottery · 19 tcp_states · 20 event_registration
- Workaround: take one parameter (`|pair, i|`), then `a, b = pair` inside the block, or index it.

### 13. No splat — ≥17 programs, 10 domains — (a)
- 01 template_render, csv_report · 04 interval_arithmetic · 07 dom_tree · 09 word_break (`Set[*x]`) ·
  10 battleship, nonogram, othello, falling_sand, crossword (+General) · 12 template_engine, forth
  (`when *LIST`) · 15 timesheet_payroll, fx_conversion · 16 date_parser · 18 sales_pivot ·
  20 invoice_generator
- Workaround: `Array.shift`/`pop`/`first`/`drop`, `Array.unshift(rows, header)`, `Array.to_set`, or
  destructuring into locals before the call.

### 14. No unary `!` (and `~`) — ≥16 programs, 13 domains — (a)
- 01 word_wrap · 02 rake_keywords · 04 ode_solver · 06 deque_sliding_window · 08 rival_teams ·
  09 (General) · 10 n_queens (`~`), chess_attacks, falling_sand (+General) · 12 csv_parser, truth_table ·
  13 vector_polygon, polynomial · 15 clickstream_sessions · 17 (General) · 18 grade_book ·
  20 expense_tracker, course_enrollment (+General)
- Workaround: `x == false`, `!= nil`, swapped branches, `reject` for `select { !... }`, `full ^ mask` for `~`.

### 15. `[]` takes one index — 16 programs, 13 domains — (a) for user `[]`, (b) for String substrings
`s[i, len]` is a static error ("takes one index"). A user `def [](m, r, c)` cannot be reached either.
- String: 01 word_wrap, json_pretty · 02 spell_suggest · 03 check_digits · 05 autocomplete_msd ·
  06 undo_redo_editor · 09 palindromes · 10 sliding_puzzle · 15 expense_pivot · 16 iso_week ·
  19 expr_lexer · 20 expense_tracker
- User two-index `[]`: 04 matrix_ops · 10 matrix_spiral · 13 matrix_ops, life_grid
- Workaround: Range indexing `s[i...(i + n)]` (written the same in both versions), or a Tuple index
  `m[[r, c]]` destructured inside `[]`/`[]=`.

### 16. Records cannot be indexed — 14 programs, 9 domains — (a)
`r[:k]` has no Sake form. Every field read is a pattern `r => {k:}`, which turns one-line blocks into
two statements.
- 02 access_log_urls · 04 gaussian_elimination · 06 cycle_detection · 07 spanning_tree · 10 word_search ·
  11 thermostat_house, checkout_lanes · 12 shunting_yard, assembler · 15 customer_dedupe, survey_crosstab ·
  18 sales_pivot, cart_discounts, paginate
- Workaround: `{ |m| m => {ids:}; Array.size(ids) > 1 }`. Related: Records cannot be extended
  (14 result_pipeline rebuilds them) and have no field writes (07 quadtree uses a Hash counter).

### 17. Array-yielding iterators are not destructured by `|a, b|` — ≥13 programs, 11 domains — (a/b)
`each_cons`, `each_slice` and `combination` yield Arrays. Blocks destructure only Tuples, so the run
fails with `ArgumentError: block takes 2 parameter(s) but was given 1`.
- 02 ngram_counts, rake_keywords · 03 fibonacci_numbers · 05 radix_order_ids (+General) · 07 merkle_sync ·
  08 centrality · 09 held_karp · 10 knights_tour · 13 sparse_vector · 15 cohort_retention,
  timesheet_payroll · 16 meeting_scheduler · 20 timesheet
- Workaround: `|pair|` then `pair[0]`, `pair[1]` / `Array.fetch`; nested loops instead of `combination`.

### 18. Struct `==` is structural; no identity — 12 programs, 6 domains — (a)
Sake has no `equal?`. Struct `==` compares fields recursively. A user `<=>` from Comparable does not
define `==`. Results can differ from Ruby without any error.
- 06 singly_linked_list, markup_tag_checker, josephus_circle, digit_list_bignum, cycle_detection,
  circular_playlist (+General) · 07 dom_tree · 08 astar_terrain · 13 version_constraints,
  temperature_units (`20°C == 68°F` was false) · 15 fulfillment_report (output differed: 6 vs 7 parcels) ·
  20 vendor_quotes
- Workaround: an `id` field, comparing a unique field (title/name), an explicit
  `def ==(a, b) = (a <=> b) == 0`, or restructuring so that no identity check is needed.

### 19. Multiple assignment to index targets — ≥9 programs, 7 domains — (a)
`a[i], a[j] = a[j], a[i]` is rejected: "only `a, b = tuple` (local variables, no splat) is supported".
- 03 check_digits · 04 gaussian_elimination, lu_decomposition · 05 (General) · 07 heap_scheduler ·
  10 sliding_puzzle, falling_sand · 13 matrix_ops, task_heap · 19 bank_queue_sim
- Workaround: a temporary (three statements per swap).

### 20. No two-argument min/max — 9 programs, 8 domains — (b)
`[a, b].max` is a Tuple, which has no `max`. There is no `Integer.max(a, b)`.
- 03 integer_partitions · 05 version_resolver · 06 list_toolkit · 15 timesheet_payroll ·
  16 meeting_scheduler · 18 room_bookings · 19 csv_parser, enemy_ai · 20 inventory_reorder
- Workaround: `Array.max(Array[a, b])`, which a checker may see as possibly nil (15 timesheet_payroll),
  or a ternary.

### 21. Module dispatch needs the function in the module — 9 programs, 7 domains — (a/d)
`Shape.area(s)` is "undefined function" unless `Shape` itself defines `area`, even when every includer
does. Field accessors (`get_x`) are not module functions. A stub cannot stand in for a function that
yields ("does not take a block (it has no `yield`)").
- 04 curve_fitting · 08 make_rebuild · 13 shapes_area, payroll, life_grid · 15 quality_rules ·
  16 calendar_systems · 19 event_sourcing · 20 payroll
- Workaround: an abstract stub `def area(s) = raise("...")` or a forwarding wrapper
  `def label(m) = describe(m)` in the module.

### 22. Misleading "cannot compare elements of types X" — ≥8 programs, 8 domains — (c) **fixed**
The Tuple-key failure named the element type or the first Tuple component (Integer, String, Car,
Issue ...), not the Tuple.
- 03 sieve_primes · 06 markup_tag_checker · 08 dijkstra_routes · 10 flood_fill · 11 elevator_scan ·
  14 registration_form, job_queue · 19 turnstile (+elevator) · 20 (General)

### 23. No `initialize` / default parameters — 8 programs, 6 domains — (a)
- Constructor logic: 07 heap_scheduler, taxonomy_lca · 11 forest_fire · 12 tiny_basic ·
  16 project_gantt · 18 library_loans
- Default parameter: 10 hex_game · 12 truth_table
- Workaround: a factory function (`Library.open(today)`, `MinHeap.create`) or `default:` settings
  (04 monte_carlo used these successfully). Callers pass the argument explicitly.

### 24. `&block` forwarding — 7 programs, 5 domains — (a)
- 01 outline_number · 03 integer_partitions · 04 numeric_integration, ode_solver · 05 quicksort_median3,
  staff_multikey_sort · 07 btree
- Workaround: re-wrap at each level, `walk(x) { |n| yield(n) }`. Each recursion level adds a block frame.

### 25. No default-block `Hash.new` — 7 programs, 7 domains — (a)
- 07 traversals · 08 rival_teams, currency_paths · 11 epidemic_network · 16 iso_week · 17 rolling_sync ·
  18 friend_graph
- Workaround: `h[k] ||= Array[]` or `h[k] = Set[] unless Hash.key?(h, k)` before each insert.

### 26. No `%w[...]` — ≥7 programs, 7 domains — (a)
- 01 number_words · 06 rpn_stack_calculator · 10 word_search (+General) · 15 expense_pivot ·
  16 recurring_events · 19 expr_lexer · 20 room_reservations
- Workaround: `Array["a", ...]`, `String[...]`, `String.split("a b c", " ")`.

### 27. No `&.` — ≥7 programs, 5 domains — (a)
- 01 columnize · 06 deque_sliding_window, list_toolkit · 07 ip_route_trie · 10 word_search,
  chess_attacks (+General) · 12 markdown
- Workaround: an explicit nil check or a ternary.

### 28. `in` precedence needs parentheses — 7 programs, 6 domains — (a, inherited from Ruby's grammar)
`x in T ? a : b` is a syntax error ("unexpected '?'"). `l in T && ...` is too. Ruby has the same
rule, but Sake code hits it more often because `in` replaces `is_a?`.
- 01 ascii_table · 07 expression_tree · 12 lisp_interp · 13 expr_tree · 14 unit_quantities,
  spreadsheet_errors · 17 protobuf_wire
- Workaround: `(x in T) ? a : b`.

### 29. No block form of `to_h` — 6 programs, 4 domains — (b)
- 01 csv_report, ini_config · 09 viterbi · 18 survey_venn, sensor_merge · 20 ticket_helpdesk
- Workaround: fill a `Hash[]` in an `each` loop.

### 30. No `dup` for Hash/Set/Struct — 6 programs, 4 domains — (b)
- 08 make_rebuild · 13 sparse_vector · 18 role_permissions, sparse_vectors, build_order · 19 event_sourcing
- Workaround: `Hash.merge(h, Hash[])`, `Set.union(s, Set[])`, a hand-written `copy`.

### 31. No built-in numeric constants — ≥6 programs, 4 domains — (b)
- 03 farey_stern_brocot · 04 float_accuracy, numerical_derivatives (+General) · 08 prim_cables ·
  13 shapes_area, quaternion_rotation
- Workaround: literals (`def pi = 3.141592653589793`, `2.220446049250313e-16`), `1.0 / 0.0`, `Math.exp(1.0)`.

### 32. Assignment in a condition: avoided, though it works — 6 programs, 4 domains — (d)
Writers rewrote `if (m = ...)` / `while (x = ...)` as separate statements. 12 markdown (`elsif (m = ...)`)
and 20 restaurant_orders (`while (l = f(...))`) report that it works. The writers seem not to have
known this.
- 01 number_words, markdown_html, date_format · 10 falling_sand · 11 teller_queue_des · 12 pratt_parser

### 33. `String.split` has no limit — 5 programs, 4 domains — (b)
- 05 kway_log_merge · 12 assembler · 16 cron_schedule · 20 todo_list, timesheet
- Workaround: `String.partition`, a regexp `match`, split + `drop` + `join`.

### 34. Type-specific numeric ops on union values — 5 programs, 4 domains — (a)
Operations name their type, so `Float.round(int)` and `Rational.to_f(0)` raise. There is no dispatching `abs`.
- 06 sparse_polynomial · 12 calc_rd · 15 invoice_totals, fx_conversion (empty `Array.sum` gives Integer 0) ·
  20 shopping_cart
- Workaround: `case v in Integer ... in Float ...` branches; `a < 0 ? 0 - a : a`.

### 35. `Array.join` without a separator crashed — ≥4 programs, 6 domains — (c) **fixed**
- 07 huffman · 10 game_of_life ("workaround in every task") · 12 brainfuck · 15 expense_pivot ·
  General in 02, 08, 10, 15
- Workaround: always pass `""`. (15 noticed it was fixed during the run.)

### 36. No radix argument — ≥4 programs, 5 domains — (b)
- 07 merkle_sync · 13 bitset_permissions · 17 (General) · 19 divisibility_dfa · 20 timesheet (`Kernel.Integer("08")`)
- Workaround: `format("%x"/"%b")`, `String.hex`, a hand-written loop.

### 37. Mixed-type `==` raises — ≥4 programs, 2 domains — (a; asymmetry is c)
`1 == :a` is `TypeError: Kernel.==: no implementation for (Integer, Symbol)`; Ruby returns false. It is
also asymmetric: `Agg.new(..) == "*"` is false, but `"*" == Agg.new(..)` raises (12 query_engine).
- 12 lisp_interp, pratt_parser, query_engine · 15 table_renderer (+General)
- Workaround: narrow with `in` first, or use literal patterns (`case head in :quote`), which do not raise.

### 38. No default for `fetch` — 4 programs, 4 domains — (b)
- 04 polynomial (`Array.fetch(a, i, default)`) · 07 taxonomy_lca · 12 type_checker · 14 expr_calculator
  (`Hash.fetch(k) { raise }`)
- Workaround: `[]` + nil check + raise, or `Array.fetch(a, i) rescue 0.0`.

### 39. `[...]` is a Tuple — 4 programs, 4 domains — (a)
Ruby-style literals become Tuples, which then fail where an Array is required (`Array.each`,
`Array.fetch`, a typed-Array push, or an index write of a different type).
- 01 ascii_table · 07 taxonomy_lca · 11 packet_network · 15 etl_star_schema
- Workaround: write `Array[...]`, or read Tuples with `t[0]`.

### 40. No `send`/lambdas — 4 programs, 1 domain (12) — (a)
- 12 rpn_calc, lisp_interp, query_engine, type_checker
- Workaround: an explicit `case op in "<" then a < b ...`.

### 41. Inconsistent Tuple equality — 4 programs, 4 domains — (c/d)
`Array.include?`, `Array.index` and `Array.uniq` compare Tuples by content, yet `==` on Tuples raises.
Struct `==` with an Array field works, although Array `==` is "undecided".
- 04 optimization · 11 langton_ants · 13 polynomial · 16 moon_phases
- No workaround needed. Programs used `include?`/`index`.

### 42. `Set.select` returned an Array — 3 programs, 3 domains — (d) **fixed**
- 02 spell_suggest · 11 elevator_scan · 18 prime_sets
- Workaround: `Set.each` + `Set.add`, or `Array.to_set`.

### 43–49. Smaller built-in and language gaps
- **43. No `gsub` with a block, no `$1`** (3; 01 template_render, ini_config; 12 turing_machine): a
  `String.match` + `post_match` loop; `m[1]`.
- **44. `String.index` has no offset** (3; 06 undo_redo_editor; 12 template_engine, markdown): search
  `s[from..]` and add `from`.
- **45. `Range.sum` takes no block** (3; 01 number_words; 04 matrix_ops; 06 sparse_matrix_rows):
  `Range.reduce` or `Array.sum(Range.map(...))`.
- **46. String Ranges cannot be iterated** (3; 14 spreadsheet_errors; 18 word_pipeline, word_rack):
  `String.upto`, or ord/chr arithmetic.
- **47. `||=` on an ivar/attribute** (3; 07 ip_route_trie; 11 cpu_scheduler; 20 ticket_helpdesk; the
  last notes that `@x += v` is accepted but `@x ||= v` is not): an explicit nil check + setter.
- **48. `@x` is always the first parameter** (3; 08 tarjan_scc; 11 forest_fire; 12 json_parser): in
  a factory, call the accessors explicitly.
- **49. No `String#<<` / `Array#<<`** (3; 01 word_wrap, csv_report; 04 eigenvalues): `+=` / `Array.push`.

### 50. Built-in exception messages differ from Ruby — ≥3 programs, 3 domains — (a)
`Hash.fetch: key not found: "zed"` versus Ruby's `key not found: "zed"`; `Float.to_i: NaN`; `puts(e)`
prints `#<ValidationError: ...>`.
- 04 float_accuracy · 05 merge_sort_inversions · 14 (General)
- Workaround: print the program's own text.

### 51. Shared `lib/` edited concurrently — 3 programs + 1 domain — (f)
`bin/sake` failed with a SyntaxError in `lib/sake/resolver.rb` while someone else was editing it. A rerun
passed.
- 04 (General) · 11 sandpile · 16 calendar_systems · 15 (`Array.join` behaviour changed mid-run)
- Other environment notes: heavy machine load (03, 04, 09, 10, 17, 19) and TZ dependence
  (15 bank_reconcile fixed it; 20 invoice_generator and hotel_billing rely on TZ=UTC).

### 52–60. Two or fewer programs
- **52. Function named `call` not callable** (2; 14 retry_backoff, 19 circuit_breaker) — (c) **fixed**.
- **53. `<=>` works though spec §8.3 lists it unsupported** (2; 08 kruskal_network, 12 assembler) — (d).
- **54. `String.chomp(s, x)`** (2; 12 forth, 13 stack_vm) → `String.delete_suffix` — (b).
- **55. `Array.last(a, n)`** (2; 14 password_policy, 15 league_standings) → `take(reverse)`/`drop` — (b).
- **56. `reduce` without init / `reduce(:&)`** (2; 01 doc_pretty, 18 sparse_vectors) → fold from nil — (b).
- **57. No keyword arguments** (2; 14 csv_import, 12 indent_lexer) → `rescue nil`, explicit chomp — (a).
- **58. TypeError / program errors not rescuable** (2; 05 General, 13 physical_quantities) — (a).
- **59. Array as Hash key / Struct as Set element** (2; 03 happy_cycles, 06 cycle_detection) → a joined
  String key, or an id — (a).
- **60. `Array.uniq` on equal Structs** (1; 13 vector_polygon) — (c) **fixed**.

### 61. Singletons (one program each)
- (b) `start_with?` with several prefixes (01 ini_config); `String.squeeze(s, " ")` (18 contact_dedupe;
  with no argument it also squeezed letters, as Ruby's does); `Hash.dig` with two keys (15 budget_variance);
  `Hash.merge` with a block (18 leaderboard); `Math.acos` (13 quaternion_rotation); `Set.min_by`
  (11 elevator_scan); `Array.inspect` (11 checkout_lanes); `String#[]=` (03 check_digits);
  `pack`/`force_encoding` (02 access_log_urls, which needed no workaround); `Array.sort` with a block
  (05 General); a typed-Array name for booleans (06 free_list_pool); `NotImplementedError` (13 shapes_area);
  `Exception#cause` (14 error_wrapping).
- (a) Array patterns `in [a, b]` (6: 05 sorted_matrix_search, 12 type_checker, 13 collision_check,
  14 expr_calculator, 19 turnstile, 20 subscription_billing). Record patterns with a value, nested Record
  patterns, or guards (6: 06 two_stack_print_queue, 08 rival_teams, 14 result_pipeline,
  expr_calculator (guard), 19 turnstile, 20 shopping_cart). Both are workarounds via `case e[0]`
  or nested `case`. *(These have 6 programs each and belong between #29 and #33 by count; they are
  listed here to keep the table short. They should still be treated as top-30 issues.)*
- (a) modifier `while` (10 crossword); a compound index assignment as an expression (12 tiny_basic);
  `private def` (06 two_stack_print_queue).
- (c, minor) a confusing hint `Employee.retirement(get_Employee, e)` after a typo (20 payroll).

### Not Sake problems (Ruby side or the writer's own slips)
- A `# ... coding: ...` first-line comment is read as a magic encoding comment (17 huffman, percent_encoding).
- Name clashes on the Ruby side: `Queue` (06 bank_teller_sim), `redo` (06 undo_redo_editor),
  `SyntaxError` (12 shunting_yard), `LoadError` (15 etl_star_schema), and Sake's own `Range`
  (15 quality_rules).
- `"#$."` interpolates in Ruby too (10 sokoban, where Sake caught it and Ruby silently printed wrong output).
- Ruby-habit slips caught by the checker: `x.to_s`/`x.inspect` method calls (06, 12 indent_lexer, 13
  fraction_math), `Array.each` on a Hash (15 budget_variance, inventory_diff), `String.chr` (10 knights_tour),
  `String[src, i, 2]` (19 expr_lexer).

## Interpreter bugs reported, with the minimal repro as given

| # | Bug | Repro (verbatim from NOTES) | Reported in | Status |
|---|-----|-----------------------------|-------------|--------|
| B1 | `Array.join` with no separator crashes with an internal Ruby `NoMethodError` (`stdlib.rb:176: undefined method 'map' for an instance of String`) | `p(Array.join(Array["a", "b"]))` (also `puts(Array.join(Array[1, 2]))`) | 02, 07 huffman, 08, 10, 12 brainfuck, 15 expense_pivot | **fixed** |
| B2 | `Set.select`/`reject`/`filter` return an Array, but spec §15 says Set | `p(Set.select(Set[1,2,3]) { it > 1 })` prints `[2, 3]` | 02 spell_suggest, 11 elevator_scan, 18 prime_sets | **fixed** |
| B3 | A Tuple-key comparison failure names the wrong type | `p(Array.sort_by(Array[[2, 1], [1, 5]]) { \|t\| t })`; `p(Array.sort_by(Array[3, 1, 2]) { \|x\| [x, 0] })` → "types Integer"; `p(Array.sort_by(Array[1, 2]) { \|x\| [0 - x, "a"] })`; `p(Array.sort_by(Array["x", "yy", "z"]) { \|a\| [String.size(a), a] })` | 03, 06, 08, 10, 11, 14, 19, 20 | **fixed** |
| B4 | A user function named `call` cannot be called (read as `S.(...)`) | `S = Struct.new(:a)` / `class S; def call(s) = @a; end` / `p(S.call(S.new(1)))` → "type scope `S.(...)` is not supported yet" | 14 retry_backoff, 19 circuit_breaker | **fixed** |
| B5 | `Array.uniq` does not deduplicate equal Struct values | `P = Struct.new(:x, :y); p(Array.uniq(Array[P.new(1, 2), P.new(1, 2)]))` prints both | 13 vector_polygon | **fixed** |
| B6 | Tuple equality inconsistent: `include?`/`index` match Tuples, `==` raises | `f = Array[[1.0, 2.0]]; p(Array.include?(f, [1.0, 2.0])); p([1.0, 2.0] == [1.0, 2.0])`; `a = Array[[1, 2], [3, 4]]; p(Array.index(a, [3, 4])); p([3, 4] == [3, 4])` (prints 1, then fails) | 04 optimization, 16 moon_phases (also 11 langton_ants: `uniq` works) | open |
| B7 | `==` asymmetric across types: `Agg.new(..) == "*"` is false, `"*" == Agg.new(..)` raises `Kernel.==: no implementation for (String, A)` | (no standalone repro given) | 12 query_engine | open |
| B8 | `@x \|\|= v` rejected ("unsupported syntax: instance variable or write") while `@x += v` is accepted | `@first_reply_at \|\|= at` | 20 ticket_helpdesk | open (inconsistency) |
| B9 | Doc: spec §8.3 says `<=>` is unsupported, but it runs | `3 <=> 4` gives -1 | 08 kruskal_network, 12 assembler | open (doc) |
| B10 | Confusing checker hint after a typo: suggested `Employee.retirement(get_Employee, e)` | (writer's typo `get_Employee.retirement(e)`) | 20 payroll | open (minor) |
| — | Duplicated diagnostics | not mentioned in any NOTES file | — | **fixed** |

Domains reporting "no interpreter bugs found": 03 (apart from B3), 05, 17.
