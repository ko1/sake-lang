corpus/16-dates/durations.sake: L17 Float.round 1: observed [["Float"]], static Integer
corpus/16-dates/fiscal_quarters.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer | nil]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cron_schedule.sake | 2 | 155 | 8 | 4 | 0 | 139 | 0 | 0 |
| date_arith.sake | 2 | 117 | 5 | 2 | 0 | 104 | 0 | 0 |
| date_parser.sake | 2 | 102 | 48 | 0 | 0 | 114 | 0 | 0 |
| day_of_week.sake | 2 | 70 | 14 | 0 | 0 | 60 | 0 | 0 |
| durations.sake | 2 | 98 | 10 | 3 | 0 | 98 | 0 | 1 |
| easter.sake | 2 | 131 | 2 | 2 | 0 | 114 | 0 | 0 |
| fiscal_quarters.sake | 2 | 125 | 17 | 1 | 0 | 113 | 0 | 1 |
| iso_week.sake | 2 | 115 | 14 | 0 | 0 | 106 | 0 | 0 |
| meeting_scheduler.sake | 3 | 111 | 14 | 0 | 0 | 114 | 0 | 0 |
| month_calendar.sake | 2 | 79 | 2 | 0 | 0 | 71 | 0 | 0 |
corpus/05-sorting/bisect_on_answer.sake: L74 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L75 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L65 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/bisect_on_answer.sake: L66 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/bisect_on_answer.sake: L67 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/05-sorting/bisect_on_answer.sake: L67 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L67 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bisect_on_answer.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bisect_on_answer.sake: L133 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bucket_sort_ratings.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L13 Math.sqrt 1: observed [["Float"]], static Integer
corpus/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L15 Float.clamp 1: observed [["Float"]], static Integer
corpus/05-sorting/bucket_sort_ratings.sake: L36 Float.floor 1: observed [["Float"]], static Integer
corpus/05-sorting/bucket_sort_ratings.sake: L60 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L90 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L91 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/bucket_sort_ratings.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L91 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/bucket_sort_ratings.sake: L91 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| autocomplete_msd.sake | 2 | 92 | 16 | 1 | 0 | 76 | 0 | 0 |
| bisect_on_answer.sake | 2 | 82 | 11 | 1 | 0 | 79 | 0 | 11 |
| bucket_sort_ratings.sake | 2 | 98 | 9 | 6 | 0 | 94 | 0 | 21 |
| external_sort_sim.sake | 2 | 115 | 18 | 4 | 0 | 100 | 0 | 0 |
| gift_two_pointers.sake | 2 | 114 | 19 | 1 | 0 | 94 | 0 | 0 |
| gradebook_insertion.sake | 2 | 67 | 6 | 0 | 0 | 57 | 0 | 0 |
| hashtag_trends.sake | 2 | 69 | 6 | 0 | 0 | 63 | 0 | 0 |
| heap_scheduler.sake | 3 | 107 | 5 | 0 | 0 | 74 | 0 | 0 |
| kway_log_merge.sake | 2 | 148 | 12 | 0 | 0 | 108 | 0 | 0 |
| leaderboard_insert.sake | 2 | 81 | 6 | 1 | 0 | 74 | 0 | 0 |
corpus/19-statemachines/morse_decoder.sake: L35 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/19-statemachines/morse_decoder.sake: L45 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/19-statemachines/morse_decoder.sake: L49 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/19-statemachines/morse_decoder.sake: L50 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/19-statemachines/morse_decoder.sake: L60 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/19-statemachines/morse_decoder.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expr_lexer.sake | 2 | 71 | 0 | 2 | 0 | 57 | 0 | 0 |
| http_parser.sake | 3 | 145 | 14 | 6 | 0 | 138 | 0 | 0 |
| job_pipeline.sake | 3 | 86 | 4 | 0 | 0 | 82 | 0 | 0 |
| keypad_lock.sake | 2 | 95 | 0 | 1 | 0 | 67 | 0 | 0 |
| machine_mixin.sake | 2 | 66 | 0 | 1 | 0 | 59 | 0 | 0 |
| markdown_blocks.sake | 3 | 114 | 4 | 1 | 0 | 105 | 0 | 0 |
| morse_decoder.sake | 2 | 83 | 5 | 0 | 0 | 70 | 0 | 6 |
| order_workflow.sake | 2 | 78 | 1 | 1 | 0 | 69 | 0 | 0 |
| regex_nfa.sake | 2 | 111 | 16 | 0 | 0 | 111 | 0 | 0 |
| shell_words.sake | 2 | 70 | 2 | 1 | 0 | 63 | 0 | 0 |
corpus/11-simulation/order_book.sake: L111 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
corpus/11-simulation/parking_garage.sake: L93 Time.strftime 1: observed [["Time"]], static Integer
corpus/11-simulation/parking_garage.sake: L36 Kernel.== pair: observed [["Ticket", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/11-simulation/parking_garage.sake: [37, 11, "Ticket.get_spot", 1]: observed [["Ticket"]] but no static check
corpus/11-simulation/parking_garage.sake: [38, 4, "Spot.set_plate", 1]: observed [["Spot"]] but no static check
corpus/11-simulation/parking_garage.sake: [39, 31, "Ticket.get_entered", 1]: observed [["Ticket"]] but no static check
corpus/11-simulation/parking_garage.sake: [39, 26, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
corpus/11-simulation/parking_garage.sake: [39, 25, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/11-simulation/parking_garage.sake: [39, 14, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus/11-simulation/parking_garage.sake: [40, 26, "Ticket.get_kind", 1]: observed [["Ticket"]] but no static check
corpus/11-simulation/parking_garage.sake: [56, 14, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [57, 10, "Integer.ceildiv", 1]: observed [["Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [58, 9, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/11-simulation/parking_garage.sake: [59, 15, "Integer.divmod", 1]: observed [["Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [61, 12, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [62, 23, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [63, 2, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [63, 2, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [58, 38, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/11-simulation/parking_garage.sake: [122, 33, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: [122, 49, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/parking_garage.sake: L30 Ticket.new result: observed ["Ticket"], static (none)
corpus/11-simulation/parking_garage.sake: L35 Hash.delete result: observed ["Ticket", "Nil"], static nil
corpus/11-simulation/parking_garage.sake: L37 Ticket.get_spot result: observed ["Spot"], static (none)
corpus/11-simulation/parking_garage.sake: L38 Spot.set_plate result: observed ["Nil"], static (none)
corpus/11-simulation/parking_garage.sake: L39 Ticket.get_entered result: observed ["Time"], static (none)
corpus/11-simulation/parking_garage.sake: L39 Float.to_i result: observed ["Integer"], static (none)
corpus/11-simulation/parking_garage.sake: L40 Ticket.get_kind result: observed ["Symbol"], static (none)
corpus/11-simulation/parking_garage.sake: L57 Integer.ceildiv result: observed ["Integer"], static (none)
corpus/11-simulation/parking_garage.sake: L59 Integer.divmod result: observed ["Tuple"], static (none)
corpus/11-simulation/ring_road_traffic.sake: L32 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/sandpile.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| inventory_reorder.sake | 3 | 146 | 3 | 0 | 0 | 135 | 0 | 0 |
| langton_ants.sake | 2 | 115 | 7 | 1 | 0 | 88 | 0 | 0 |
| library_loans.sake | 2 | 134 | 13 | 1 | 0 | 125 | 0 | 0 |
| life_torus.sake | 2 | 104 | 1 | 0 | 0 | 93 | 0 | 0 |
| order_book.sake | 2 | 131 | 6 | 0 | 0 | 127 | 0 | 1 |
| packet_network.sake | 2 | 137 | 14 | 0 | 0 | 124 | 0 | 0 |
| parking_garage.sake | 2 | 86 | 1 | 3 | 0 | 101 | 18 | 29 |
| ring_road_traffic.sake | 2 | 119 | 13 | 1 | 0 | 115 | 0 | 1 |
| runway_ops.sake | 2 | 117 | 6 | 0 | 0 | 111 | 0 | 0 |
| sandpile.sake | 2 | 113 | 14 | 0 | 0 | 97 | 0 | 1 |
corpus/14-errors/expr_calculator.sake: [107, 17, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [99, 57, "Kernel.==", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/14-errors/expr_calculator.sake: [106, 17, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [109, 53, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 6, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 21, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [105, 17, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 29, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/matrix_checks.sake: L35 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
corpus/14-errors/matrix_checks.sake: L60 Arithmetic.- pair: observed [["Integer", "Rational"]], static [Integer, Integer]
corpus/14-errors/matrix_checks.sake: L60 Arithmetic.- pair: observed [["Integer", "Rational"]], static [Integer, Integer]
corpus/14-errors/matrix_checks.sake: L12 Array.fetch result: observed ["Integer", "Rational"], static Integer
corpus/14-errors/matrix_checks.sake: L35 Array.sum result: observed ["Integer", "Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_import.sake | 2 | 71 | 12 | 0 | 0 | 59 | 0 | 0 |
| dependency_resolver.sake | 3 | 31 | 2 | 0 | 0 | 27 | 0 | 0 |
| error_wrapping.sake | 2 | 49 | 0 | 0 | 0 | 40 | 0 | 0 |
| expr_calculator.sake | 3 | 90 | 8 | 1 | 1 | 85 | 8 | 8 |
| http_error_mapping.sake | 2 | 62 | 1 | 0 | 0 | 46 | 0 | 0 |
| job_queue.sake | 2 | 86 | 0 | 1 | 0 | 79 | 0 | 0 |
| ledger_reconcile.sake | 2 | 76 | 3 | 0 | 0 | 63 | 0 | 0 |
| log_triage.sake | 2 | 67 | 6 | 0 | 0 | 60 | 0 | 0 |
| matrix_checks.sake | 3 | 110 | 5 | 2 | 0 | 77 | 0 | 5 |
| nested_schema.sake | 2 | 42 | 3 | 1 | 0 | 40 | 0 | 0 |
corpus/07-trees/bill_of_materials.sake: L42 Kernel.!= pair: observed [["Nil", "Nil"], ["Float", "Nil"]], static [nil | Integer, nil]
corpus/07-trees/bill_of_materials.sake: L106 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/07-trees/bill_of_materials.sake: L43 Array.sum result: observed ["Float"], static Integer
corpus/07-trees/decision_tree.sake: L7 Math.log2 1: observed [["Float"]], static Integer
corpus/07-trees/decision_tree.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/07-trees/decision_tree.sake: L7 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/07-trees/decision_tree.sake: L19 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/07-trees/decision_tree.sake: L19 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/decision_tree.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/decision_tree.sake: L29 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/07-trees/decision_tree.sake: L115 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/decision_tree.sake: L7 Array.sum result: observed ["Float"], static Integer
corpus/07-trees/decision_tree.sake: L19 Array.sum result: observed ["Float"], static Integer
corpus/07-trees/fenwick_ranks.sake: L85 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/filesystem_du.sake: L38 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| avl_tree.sake | 2 | 111 | 11 | 0 | 0 | 119 | 0 | 0 |
| bill_of_materials.sake | 3 | 94 | 13 | 3 | 0 | 84 | 0 | 3 |
| bst_basic.sake | 2 | 84 | 2 | 0 | 0 | 85 | 0 | 0 |
| btree.sake | 2 | 112 | 10 | 0 | 0 | 96 | 0 | 0 |
| decision_tree.sake | 2 | 106 | 3 | 0 | 0 | 86 | 0 | 10 |
| dom_tree.sake | 2 | 125 | 12 | 3 | 0 | 113 | 0 | 0 |
| expression_tree.sake | 3 | 105 | 0 | 5 | 0 | 96 | 0 | 0 |
| fenwick_ranks.sake | 2 | 77 | 7 | 0 | 0 | 69 | 0 | 1 |
| filesystem_du.sake | 2 | 108 | 3 | 1 | 0 | 99 | 0 | 1 |
| heap_scheduler.sake | 3 | 123 | 13 | 0 | 0 | 96 | 0 | 0 |
corpus/05-sorting/trail_peak_search.sake: L63 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/trail_peak_search.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/trail_peak_search.sake: L64 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/05-sorting/trail_peak_search.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/trail_peak_search.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/05-sorting/trail_peak_search.sake: L57 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/trail_peak_search.sake: L57 Math.exp 1: observed [["Float"]], static Integer
corpus/05-sorting/trail_peak_search.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/05-sorting/trail_peak_search.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/trail_peak_search.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/trail_peak_search.sake: L66 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/05-sorting/trail_peak_search.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sorted_matrix_search.sake | 2 | 83 | 13 | 0 | 0 | 69 | 0 | 0 |
| staff_multikey_sort.sake | 2 | 67 | 4 | 2 | 14 | 63 | 0 | 0 |
| trail_peak_search.sake | 2 | 87 | 7 | 0 | 0 | 70 | 0 | 12 |
| triage_partition.sake | 2 | 101 | 10 | 2 | 0 | 86 | 0 | 0 |
| version_resolver.sake | 2 | 86 | 12 | 2 | 0 | 73 | 0 | 0 |
| adjacency_list_courses.sake | 3 | 117 | 12 | 0 | 0 | 87 | 0 | 0 |
| bank_teller_sim.sake | 3 | 107 | 2 | 0 | 0 | 100 | 0 | 0 |
| browser_history.sake | 2 | 61 | 2 | 1 | 0 | 59 | 0 | 0 |
| chained_hash_table.sake | 3 | 119 | 0 | 0 | 0 | 98 | 0 | 0 |
| circular_playlist.sake | 2 | 94 | 13 | 0 | 0 | 99 | 0 | 0 |
corpus/17-encodings/vigenere.sake: L51 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/17-encodings/vigenere.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/17-encodings/vigenere.sake: L65 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/17-encodings/vigenere.sake: L66 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/17-encodings/vigenere.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/17-encodings/vigenere.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/17-encodings/vigenere.sake: L51 Array.find result: observed ["{ic: Float, period: Integer}"], static nil | {ic: Integer, period: Integer}
corpus/18-collections/access_log.sake: L80 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/access_log.sake: L81 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: L70 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: L71 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: L73 Arithmetic.- pair: observed [["Set", "Set"]], static [Set@L62[(none)], Integer]
corpus/18-collections/course_overlap.sake: [74, 30, "Set.sort", 1]: observed [["Set"]] but no static check
corpus/18-collections/course_overlap.sake: [74, 19, "Array.join", 1]: observed [["Array"]] but no static check
corpus/18-collections/course_overlap.sake: L84 Set.empty? 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: [85, 81, "Set.sort", 1]: observed [["Set"]] but no static check
corpus/18-collections/course_overlap.sake: [85, 70, "Array.join", 1]: observed [["Array"]] but no static check
corpus/18-collections/course_overlap.sake: L50 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: L52 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/course_overlap.sake: L74 Set.sort result: observed ["Array"], static (none)
corpus/18-collections/course_overlap.sake: L74 Array.join result: observed ["String"], static (none)
corpus/18-collections/course_overlap.sake: L85 Set.sort result: observed ["Array"], static (none)
corpus/18-collections/course_overlap.sake: L85 Array.join result: observed ["String"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| run_length.sake | 2 | 74 | 3 | 2 | 0 | 64 | 0 | 0 |
| transposition.sake | 2 | 76 | 2 | 0 | 0 | 62 | 0 | 0 |
| utf8_codec.sake | 2 | 94 | 15 | 8 | 0 | 100 | 0 | 0 |
| vigenere.sake | 2 | 93 | 2 | 0 | 0 | 76 | 0 | 7 |
| xor_breaker.sake | 2 | 88 | 7 | 0 | 0 | 81 | 0 | 0 |
| access_log.sake | 2 | 113 | 7 | 2 | 0 | 111 | 0 | 2 |
| build_order.sake | 3 | 87 | 7 | 2 | 0 | 78 | 0 | 0 |
| cart_discounts.sake | 2 | 75 | 5 | 0 | 0 | 61 | 0 | 0 |
| contact_dedupe.sake | 3 | 146 | 13 | 0 | 0 | 124 | 0 | 0 |
| course_overlap.sake | 2 | 114 | 9 | 6 | 0 | 121 | 4 | 14 |
corpus/09-dp/dice_odds.sake: L16 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus/09-dp/dice_odds.sake: L31 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/09-dp/dice_odds.sake: L31 Rational.round 1: observed [["Rational"]], static Integer
corpus/09-dp/dice_odds.sake: L54 Rational.to_s 1: observed [["Rational"]], static Integer
corpus/09-dp/dice_odds.sake: L68 Rational.to_s 1: observed [["Rational"]], static Integer
corpus/09-dp/dice_odds.sake: L43 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus/09-dp/dice_odds.sake: L43 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer, Integer]
corpus/09-dp/dice_odds.sake: L44 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer, Integer]
corpus/09-dp/dice_odds.sake: L23 Hash.sum result: observed ["Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| coin_change.sake | 2 | 77 | 2 | 3 | 0 | 58 | 0 | 0 |
| company_party.sake | 3 | 70 | 2 | 5 | 0 | 52 | 0 | 0 |
| critical_path.sake | 2 | 89 | 14 | 2 | 0 | 64 | 0 | 0 |
| decode_ways.sake | 3 | 107 | 10 | 0 | 0 | 83 | 0 | 0 |
| dice_odds.sake | 2 | 71 | 10 | 3 | 0 | 69 | 0 | 9 |
| digit_counting.sake | 2 | 68 | 2 | 0 | 0 | 53 | 0 | 0 |
| edit_distance.sake | 2 | 120 | 17 | 0 | 0 | 96 | 0 | 0 |
| egg_drop.sake | 2 | 74 | 18 | 1 | 0 | 60 | 0 | 0 |
| floyd_warshall.sake | 2 | 93 | 25 | 1 | 0 | 64 | 0 | 0 |
| grid_paths.sake | 2 | 114 | 20 | 0 | 0 | 86 | 0 | 0 |
corpus/10-grids/game_of_life.sake: [76, 7, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/maze_bfs.sake: [64, 26, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| flood_fill.sake | 2 | 107 | 9 | 0 | 0 | 92 | 0 | 0 |
| game_2048.sake | 3 | 103 | 6 | 1 | 0 | 87 | 0 | 0 |
| game_of_life.sake | 2 | 73 | 3 | 0 | 0 | 65 | 1 | 1 |
| hex_game.sake | 2 | 128 | 1 | 0 | 0 | 112 | 0 | 0 |
| knights_tour.sake | 2 | 94 | 5 | 0 | 0 | 86 | 0 | 0 |
| langtons_ant.sake | 2 | 85 | 0 | 1 | 0 | 72 | 0 | 0 |
| lights_out.sake | 2 | 76 | 0 | 1 | 0 | 76 | 0 | 0 |
| magic_square.sake | 2 | 101 | 8 | 0 | 0 | 85 | 0 | 0 |
| matrix_spiral.sake | 3 | 134 | 6 | 0 | 0 | 111 | 0 | 0 |
| maze_bfs.sake | 2 | 78 | 5 | 2 | 0 | 66 | 1 | 1 |
corpus/09-dp/held_karp.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer | nil]
corpus/09-dp/held_karp.sake: L91 Float.round 1: observed [["Float"]], static Integer
corpus/09-dp/interval_scheduling.sake: L89 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus/09-dp/interval_scheduling.sake: L88 Array.sum result: observed ["Float"], static Integer
corpus/09-dp/knapsack_01.sake: L83 Float.round 1: observed [["Float"]], static Integer
corpus/09-dp/matrix_chain.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/09-dp/optimal_bst.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus/09-dp/optimal_bst.sake: L20 Kernel.== pair: observed [["Nil", "Nil"], ["Float", "Nil"]], static [Integer | nil, nil]
corpus/09-dp/optimal_bst.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Float]
corpus/09-dp/optimal_bst.sake: L20 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/09-dp/optimal_bst.sake: L45 Arithmetic.* pair: observed [["Float", "Integer"]], static [nil | Integer, Integer]
corpus/09-dp/optimal_bst.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| held_karp.sake | 2 | 90 | 31 | 2 | 0 | 79 | 0 | 2 |
| house_robber.sake | 2 | 76 | 4 | 0 | 0 | 63 | 0 | 0 |
| interval_scheduling.sake | 2 | 113 | 19 | 1 | 0 | 85 | 0 | 2 |
| knapsack_01.sake | 2 | 56 | 12 | 1 | 0 | 50 | 0 | 1 |
| lcs_diff.sake | 2 | 123 | 14 | 0 | 0 | 78 | 0 | 0 |
| line_breaking.sake | 2 | 80 | 6 | 1 | 0 | 69 | 0 | 0 |
| longest_increasing.sake | 2 | 93 | 8 | 0 | 0 | 72 | 0 | 0 |
| matrix_chain.sake | 3 | 98 | 20 | 2 | 0 | 83 | 0 | 1 |
| optimal_bst.sake | 4 | 105 | 24 | 1 | 0 | 81 | 0 | 6 |
| palindromes.sake | 2 | 125 | 16 | 1 | 0 | 88 | 0 | 0 |
corpus/02-analytics/csv_pivot.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/csv_pivot.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/csv_pivot.sake: L63 Array.sum result: observed ["Float"], static Integer
corpus/02-analytics/csv_pivot.sake: L90 Array.sum result: observed ["Float"], static Integer
corpus/02-analytics/hashtag_trends.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/hashtag_trends.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/language_guess.sake: L62 Set.size 1: observed [["Set"]], static Integer
corpus/02-analytics/markov_text.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/naive_bayes.sake: L59 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/naive_bayes.sake: L59 Math.log 1: observed [["Float"]], static Integer
corpus/02-analytics/naive_bayes.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/naive_bayes.sake: L52 Math.log 1: observed [["Float"]], static Integer
corpus/02-analytics/naive_bayes.sake: L103 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/naive_bayes.sake: L82 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/near_duplicates.sake: L22 Set.size 1: observed [["Set"]], static Integer
corpus/02-analytics/near_duplicates.sake: L24 Set.size 1: observed [["Set"]], static Integer
corpus/02-analytics/near_duplicates.sake: L24 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/near_duplicates.sake: L42 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/near_duplicates.sake: L79 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_pivot.sake | 2 | 99 | 4 | 0 | 0 | 83 | 0 | 4 |
| email_domains.sake | 2 | 92 | 4 | 0 | 0 | 81 | 0 | 0 |
| hashtag_trends.sake | 2 | 102 | 6 | 0 | 0 | 83 | 0 | 2 |
| inverted_index.sake | 2 | 77 | 12 | 0 | 0 | 73 | 0 | 0 |
| kwic_concordance.sake | 2 | 88 | 6 | 0 | 0 | 74 | 0 | 0 |
| language_guess.sake | 2 | 74 | 5 | 1 | 0 | 63 | 0 | 1 |
| log_summary.sake | 3 | 86 | 9 | 0 | 0 | 73 | 0 | 0 |
| markov_text.sake | 2 | 105 | 2 | 0 | 0 | 89 | 0 | 1 |
| naive_bayes.sake | 2 | 101 | 2 | 0 | 0 | 82 | 0 | 6 |
| near_duplicates.sake | 2 | 84 | 9 | 2 | 0 | 71 | 0 | 5 |
corpus/20-business/expense_tracker.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/expense_tracker.sake: L120 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/expense_tracker.sake: L133 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/expense_tracker.sake: L133 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/expense_tracker.sake: L133 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/expense_tracker.sake: L98 Array.sum result: observed ["Float"], static Integer
corpus/20-business/expense_tracker.sake: L131 Array.sum result: observed ["Float"], static Integer
corpus/20-business/expense_tracker.sake: L132 Array.sum result: observed ["Float"], static Integer
corpus/20-business/grade_book.sake: L42 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L48 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L57 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/grade_book.sake: L57 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/20-business/grade_book.sake: L7 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L8 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L9 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L10 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/20-business/grade_book.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/grade_book.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L71 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L71 Math.sqrt 1: observed [["Float"]], static Integer
corpus/20-business/grade_book.sake: L116 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/20-business/grade_book.sake: L116 Float.clamp 1: observed [["Float"]], static Integer
corpus/20-business/grade_book.sake: L118 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/grade_book.sake: L119 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/grade_book.sake: L123 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/grade_book.sake: L45 Array.min result: observed ["Float"], static Integer | nil
corpus/20-business/grade_book.sake: L46 Array.delete_at result: observed ["Float"], static Integer | nil
corpus/20-business/grade_book.sake: L48 Array.sum result: observed ["Float"], static Integer
corpus/20-business/grade_book.sake: L107 Array.sum result: observed ["Float"], static Integer
corpus/20-business/grade_book.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus/20-business/grade_book.sake: L71 Array.sum result: observed ["Float"], static Integer
corpus/20-business/gym_membership.sake: L56 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/hotel_billing.sake: L17 Time.month 1: observed [["Time"]], static Integer
corpus/20-business/hotel_billing.sake: L46 Time.friday? 1: observed [["Time"]], static Integer
corpus/20-business/hotel_billing.sake: [46, 41, "Time.saturday?", 1]: observed [["Time"]] but no static check
corpus/20-business/hotel_billing.sake: [47, 36, "Time.strftime", 1]: observed [["Time"]] but no static check
corpus/20-business/hotel_billing.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/hotel_billing.sake: L66 Time.strftime 1: observed [["Time"]], static Integer
corpus/20-business/hotel_billing.sake: L73 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Float, Integer]
corpus/20-business/hotel_billing.sake: L57 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Float, Float]
corpus/20-business/hotel_billing.sake: L57 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/hotel_billing.sake: L126 Arithmetic.+ pair: observed [["Float", "Float"], ["Integer", "Float"], ["Float", "Integer"]], static [Float | Integer, Float]
corpus/20-business/hotel_billing.sake: L46 Time.saturday? result: observed ["Boolean"], static (none)
corpus/20-business/hotel_billing.sake: L47 Time.strftime result: observed ["String"], static (none)
corpus/20-business/hotel_billing.sake: L33 Array.sum result: observed ["Float", "Integer"], static Float
corpus/20-business/hotel_billing.sake: L56 Array.sum result: observed ["Integer", "Float"], static Float
corpus/20-business/hotel_billing.sake: L126 Array.sum result: observed ["Float"], static Integer
corpus/20-business/inventory_reorder.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L31 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L31 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L31 Math.sqrt 1: observed [["Float"]], static Integer
corpus/20-business/inventory_reorder.sake: L85 Float.ceil 1: observed [["Float"]], static Integer
corpus/20-business/inventory_reorder.sake: L86 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L86 Float.ceil 1: observed [["Float"]], static Integer
corpus/20-business/inventory_reorder.sake: L87 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L89 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/20-business/inventory_reorder.sake: L89 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/inventory_reorder.sake: L89 Math.sqrt 1: observed [["Float"]], static Integer
corpus/20-business/inventory_reorder.sake: L107 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/inventory_reorder.sake: L31 Array.sum result: observed ["Float"], static Integer
corpus/20-business/inventory_reorder.sake: L102 Array.sum result: observed ["Float"], static Integer
corpus/20-business/inventory_reorder.sake: L114 Hash.sum result: observed ["Float"], static Integer
corpus/20-business/invoice_generator.sake: L50 Time.strftime 1: observed [["Time"]], static Integer
corpus/20-business/invoice_generator.sake: L10 Rational.round 1: observed [["Rational"]], static Integer
corpus/20-business/invoice_generator.sake: L58 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/20-business/invoice_generator.sake: L59 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus/20-business/invoice_generator.sake: L60 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus/20-business/invoice_generator.sake: L61 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus/20-business/invoice_generator.sake: L64 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/20-business/invoice_generator.sake: L122 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/invoice_generator.sake: L123 Float.to_i 1: observed [["Float"]], static Integer
corpus/20-business/parking_garage.sake: L25 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/parking_garage.sake: L55 Ticket.set_charged_kwh result: observed ["Float"], static Integer
corpus/20-business/payroll.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L56 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/payroll.sake: L57 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/payroll.sake: L57 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/payroll.sake: L38 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L43 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L44 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Integer"]], static [Integer | nil, Integer]
corpus/20-business/payroll.sake: L44 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/20-business/payroll.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/20-business/payroll.sake: L48 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/payroll.sake: L59 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/payroll.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/payroll.sake: L102 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/20-business/payroll.sake: L108 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L109 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L109 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/payroll.sake: L44 Array.min result: observed ["Integer", "Float"], static Integer | nil
corpus/20-business/rental_fleet.sake: L95 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/20-business/rental_fleet.sake: L96 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expense_tracker.sake | 2 | 136 | 7 | 0 | 0 | 122 | 0 | 8 |
| grade_book.sake | 2 | 142 | 7 | 1 | 0 | 121 | 0 | 27 |
| gym_membership.sake | 2 | 47 | 1 | 2 | 0 | 45 | 0 | 1 |
| hotel_billing.sake | 2 | 130 | 0 | 7 | 0 | 124 | 2 | 15 |
| inventory_reorder.sake | 2 | 99 | 2 | 3 | 0 | 92 | 0 | 16 |
| invoice_generator.sake | 2 | 128 | 14 | 3 | 0 | 126 | 0 | 9 |
| library_loans.sake | 2 | 124 | 0 | 2 | 0 | 119 | 0 | 0 |
| parking_garage.sake | 2 | 100 | 6 | 3 | 0 | 100 | 0 | 2 |
| payroll.sake | 2 | 93 | 4 | 4 | 0 | 84 | 0 | 17 |
| rental_fleet.sake | 2 | 102 | 5 | 0 | 0 | 102 | 0 | 2 |
corpus/19-statemachines/bank_queue_sim.sake: L117 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bank_queue_sim.sake | 3 | 137 | 7 | 1 | 0 | 114 | 0 | 1 |
| bracket_checker.sake | 2 | 53 | 0 | 2 | 0 | 51 | 0 | 0 |
| button_debounce.sake | 2 | 83 | 0 | 6 | 0 | 75 | 0 | 0 |
| circuit_breaker.sake | 2 | 70 | 4 | 2 | 0 | 66 | 0 | 0 |
| csv_parser.sake | 2 | 76 | 4 | 1 | 0 | 73 | 0 | 0 |
| dfa_minimize.sake | 3 | 93 | 1 | 0 | 0 | 79 | 0 | 0 |
| divisibility_dfa.sake | 5 | 78 | 1 | 1 | 4 | 75 | 0 | 0 |
| elevator.sake | 2 | 98 | 4 | 2 | 0 | 96 | 0 | 0 |
| enemy_ai.sake | 2 | 106 | 8 | 2 | 0 | 107 | 0 | 0 |
| event_sourcing.sake | 2 | 83 | 0 | 1 | 0 | 70 | 0 | 0 |
corpus/06-linked/ring_buffer_metrics.sake: L77 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/06-linked/sparse_polynomial.sake: L13 Kernel.== pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus/06-linked/sparse_polynomial.sake: L88 Comparable.< pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus/06-linked/sparse_polynomial.sake: L89 Comparable.< pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus/06-linked/sparse_polynomial.sake: L68 Arithmetic.* pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus/06-linked/sparse_polynomial.sake: L68 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
corpus/06-linked/sparse_polynomial.sake: L37 Term.get_coef result: observed ["Integer", "Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monotonic_stack_prices.sake | 3 | 58 | 12 | 0 | 0 | 55 | 0 | 0 |
| ring_buffer_metrics.sake | 2 | 82 | 10 | 3 | 0 | 78 | 0 | 1 |
| rpn_stack_calculator.sake | 2 | 60 | 0 | 1 | 0 | 59 | 0 | 0 |
| singly_linked_list.sake | 3 | 88 | 10 | 0 | 0 | 89 | 0 | 0 |
| skip_list_index.sake | 3 | 134 | 14 | 0 | 0 | 109 | 0 | 0 |
| sparse_matrix_rows.sake | 3 | 123 | 2 | 2 | 0 | 85 | 0 | 0 |
| sparse_polynomial.sake | 3 | 72 | 1 | 0 | 0 | 61 | 0 | 6 |
| triage_priority_list.sake | 3 | 90 | 7 | 1 | 0 | 73 | 0 | 0 |
| two_stack_print_queue.sake | 2 | 58 | 5 | 0 | 0 | 53 | 0 | 0 |
| undo_redo_editor.sake | 3 | 76 | 7 | 1 | 0 | 71 | 0 | 0 |
corpus/18-collections/role_permissions.sake: L47 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/role_permissions.sake: L60 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/role_permissions.sake: L64 Set.include? 1: observed [["Set"]], static Integer
corpus/18-collections/role_permissions.sake: L71 Arithmetic.- pair: observed [["Set", "Set"]], static [nil | Integer, nil | Integer]
corpus/18-collections/role_permissions.sake: L71 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/role_permissions.sake: L72 Arithmetic.- pair: observed [["Set", "Set"]], static [nil | Integer, nil | Integer]
corpus/18-collections/role_permissions.sake: L72 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/role_permissions.sake: L73 Set.subset? 1: observed [["Set"]], static nil | Integer
corpus/18-collections/role_permissions.sake: L73 Set.subset? 2: observed [["Set"]], static nil | Integer
corpus/18-collections/role_permissions.sake: L74 Set.proper_superset? 1: observed [["Set"]], static nil | Integer
corpus/18-collections/role_permissions.sake: L74 Set.proper_superset? 2: observed [["Set"]], static nil | Integer
corpus/18-collections/role_permissions.sake: [75, 32, "Set.disjoint?", 1]: observed [["Set"]] but no static check
corpus/18-collections/role_permissions.sake: L75 Set.disjoint? 2: observed [["Set"]], static nil | Integer
corpus/18-collections/role_permissions.sake: L77 Bitwise.| pair: observed [["Set", "Set"]], static [Set@L77[(none)], Integer]
corpus/18-collections/role_permissions.sake: [80, 53, "String.split", 1]: observed [["String"]] but no static check
corpus/18-collections/role_permissions.sake: [80, 53, "String.split", 2]: observed [["String"]] but no static check
corpus/18-collections/role_permissions.sake: [81, 80, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/role_permissions.sake: L75 Set.disjoint? result: observed ["Boolean"], static (none)
corpus/18-collections/sales_pivot.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/18-collections/sales_pivot.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/sales_pivot.sake: L86 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/18-collections/sales_pivot.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | nil]
corpus/18-collections/sales_pivot.sake: L97 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/18-collections/sales_pivot.sake: L83 Array.sum result: observed ["Float"], static Integer
corpus/18-collections/sensor_merge.sake: L41 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/sensor_merge.sake: L43 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/sensor_merge.sake: L43 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/sensor_merge.sake: [44, 37, "Kernel.==", "pair"]: observed [["Float", "Nil"], ["Nil", "Nil"]] but no static check
corpus/18-collections/sensor_merge.sake: [44, 55, "Hash.key?", 1]: observed [["Hash"]] but no static check
corpus/18-collections/sensor_merge.sake: [48, 56, "Bitwise.|", "pair"]: observed [["Set", "Set"]] but no static check
corpus/18-collections/sensor_merge.sake: [48, 43, "Set.include?", 1]: observed [["Set"]] but no static check
corpus/18-collections/sensor_merge.sake: [17, 7, "Kernel.!=", "pair"]: observed [["Float", "Nil"], ["Nil", "Nil"]] but no static check
corpus/18-collections/sensor_merge.sake: [34, 13, "Kernel.==", "pair"]: observed [["Float", "Nil"]] but no static check
corpus/18-collections/sensor_merge.sake: [34, 33, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/sensor_merge.sake: [55, 79, "Kernel.==", "pair"]: observed [["Float", "Nil"], ["Nil", "Nil"]] but no static check
corpus/18-collections/sensor_merge.sake: [55, 28, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/sensor_merge.sake: [28, 11, "Array.compact", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [29, 21, "Array.empty?", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [29, 48, "Array.sum", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [29, 66, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [29, 48, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [29, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [60, 43, "String.strip", 1]: observed [["String"]] but no static check
corpus/18-collections/sensor_merge.sake: L64 Kernel.!= pair: observed [["Float", "Nil"]], static [nil, nil]
corpus/18-collections/sensor_merge.sake: L64 Kernel.!= pair: observed [["Float", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/18-collections/sensor_merge.sake: [64, 38, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/sensor_merge.sake: [64, 28, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/18-collections/sensor_merge.sake: [64, 28, "Comparable.>", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/sensor_merge.sake: [69, 37, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [69, 37, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [71, 21, "Array.map", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [71, 7, "Array.compact", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [72, 21, "Array.map", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [72, 7, "Array.compact", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [73, 10, "Array.empty?", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [73, 35, "Array.sum", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [73, 51, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [73, 35, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [74, 10, "Array.max", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 79, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 114, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 131, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 114, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 147, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 147, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/sensor_merge.sake: [75, 7, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/sensor_merge.sake: [77, 78, "Kernel.!=", "pair"]: observed [["Float", "Nil"]] but no static check
corpus/18-collections/sensor_merge.sake: L77 Kernel.!= pair: observed [["Float", "Nil"]], static [nil, nil]
corpus/18-collections/sensor_merge.sake: [78, 39, "Comparable.>", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/sensor_merge.sake: L78 Comparable.>= pair: observed [["Float", "Integer"]], static [nil, Integer]
corpus/18-collections/sensor_merge.sake: L47 Array.first result: observed ["Integer"], static nil
corpus/18-collections/sensor_merge.sake: L47 Array.last result: observed ["Integer"], static nil
corpus/18-collections/sensor_merge.sake: L64 Float.abs result: observed ["Float"], static (none)
corpus/18-collections/sparse_vectors.sake: L56 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/18-collections/survey_venn.sake: L30 Arithmetic.- pair: observed [["Set", "Set"]], static [Integer, Set@L13[String]]
corpus/18-collections/survey_venn.sake: L31 Arithmetic.- pair: observed [["Set", "Set"]], static [Integer, Set@L13[String]]
corpus/18-collections/survey_venn.sake: L32 Arithmetic.- pair: observed [["Set", "Set"]], static [Integer, Set@L13[String]]
corpus/18-collections/survey_venn.sake: [34, 12, "Arithmetic.-", "pair"]: observed [["Set", "Set"]] but no static check
corpus/18-collections/survey_venn.sake: [37, 72, "Set.size", 1]: observed [["Set"]] but no static check
corpus/18-collections/survey_venn.sake: [39, 46, "Set.size", 1]: observed [["Set"]] but no static check
corpus/18-collections/survey_venn.sake: [40, 24, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/survey_venn.sake: L41 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/survey_venn.sake: L41 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/survey_venn.sake: L41 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/survey_venn.sake: [41, 109, "Set.size", 1]: observed [["Set"]] but no static check
corpus/18-collections/survey_venn.sake: [42, 46, "Set.size", 1]: observed [["Set"]] but no static check
corpus/18-collections/survey_venn.sake: L44 Set.intersect? 1: observed [["Set"]], static nil
corpus/18-collections/survey_venn.sake: L44 Set.intersect? 2: observed [["Set"]], static nil
corpus/18-collections/survey_venn.sake: L60 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/survey_venn.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/survey_venn.sake: L37 Set.size result: observed ["Integer"], static (none)
corpus/18-collections/survey_venn.sake: L37 Kernel.format result: observed ["String"], static (none)
corpus/18-collections/survey_venn.sake: L37 Kernel.puts result: observed ["Nil"], static (none)
corpus/18-collections/survey_venn.sake: L39 Set.size result: observed ["Integer"], static (none)
corpus/18-collections/survey_venn.sake: L39 Hash.sum result: observed ["Integer"], static (none)
corpus/18-collections/survey_venn.sake: L41 Set.size result: observed ["Integer"], static (none)
corpus/18-collections/survey_venn.sake: L42 Set.size result: observed ["Integer"], static (none)
corpus/18-collections/tag_recommender.sake: L12 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/tag_recommender.sake: L78 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/tag_recommender.sake: L79 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/tag_recommender.sake: L48 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/word_pipeline.sake: L74 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/word_rack.sake: L62 Set.sort 1: observed [["Set"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| range_set.sake | 2 | 107 | 15 | 0 | 0 | 114 | 0 | 0 |
| role_permissions.sake | 2 | 80 | 5 | 13 | 0 | 82 | 4 | 18 |
| room_bookings.sake | 2 | 114 | 22 | 0 | 0 | 110 | 0 | 0 |
| sales_pivot.sake | 2 | 150 | 15 | 0 | 0 | 106 | 0 | 6 |
| sensor_merge.sake | 2 | 82 | 2 | 4 | 0 | 110 | 39 | 49 |
| sparse_vectors.sake | 3 | 121 | 8 | 0 | 0 | 95 | 0 | 1 |
| survey_venn.sake | 2 | 85 | 1 | 17 | 0 | 101 | 6 | 23 |
| tag_recommender.sake | 2 | 123 | 6 | 4 | 0 | 111 | 0 | 4 |
| word_pipeline.sake | 2 | 108 | 4 | 1 | 0 | 96 | 0 | 1 |
| word_rack.sake | 2 | 124 | 5 | 1 | 0 | 122 | 0 | 1 |
corpus/11-simulation/ecosystem_patches.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/11-simulation/ecosystem_patches.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L19 Float.clamp 1: observed [["Float"]], static Integer
corpus/11-simulation/ecosystem_patches.sake: L19 Float.clamp 3: observed [["Float"]], static Integer
corpus/11-simulation/ecosystem_patches.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/11-simulation/ecosystem_patches.sake: L24 Float.clamp 1: observed [["Float"]], static Integer
corpus/11-simulation/ecosystem_patches.sake: L24 Float.clamp 3: observed [["Float"]], static Integer
corpus/11-simulation/ecosystem_patches.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/11-simulation/ecosystem_patches.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L28 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L40 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L41 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/ecosystem_patches.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L49 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L50 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/ecosystem_patches.sake: L49 Patch.set_rabbits result: observed ["Float"], static Integer
corpus/11-simulation/ecosystem_patches.sake: L50 Patch.set_rabbits result: observed ["Float"], static Integer
corpus/11-simulation/epidemic_network.sake: L115 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/11-simulation/forest_fire.sake: L95 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/11-simulation/hotel_bookings.sake: L103 Time.strftime 1: observed [["Time"]], static Integer
corpus/11-simulation/hotel_bookings.sake: L27 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus/11-simulation/hotel_bookings.sake: L36 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus/11-simulation/hotel_bookings.sake: L16 Time.friday? 1: observed [["Time"]], static Integer
corpus/11-simulation/hotel_bookings.sake: [17, 9, "Time.month", 1]: observed [["Time"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [17, 9, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [17, 32, "Time.day", 1]: observed [["Time"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [17, 32, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [16, 31, "Time.saturday?", 1]: observed [["Time"]] but no static check
corpus/11-simulation/hotel_bookings.sake: L51 Time.strftime 1: observed [["Time"]], static Integer
corpus/11-simulation/hotel_bookings.sake: L22 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus/11-simulation/hotel_bookings.sake: L44 Time.strftime 1: observed [["Time"]], static Integer
corpus/11-simulation/hotel_bookings.sake: [68, 30, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [68, 29, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [68, 18, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [69, 14, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/hotel_bookings.sake: [69, 38, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/hotel_bookings.sake: L119 Time.strftime 1: observed [["Time"]], static Integer
corpus/11-simulation/hotel_bookings.sake: L17 Time.month result: observed ["Integer"], static (none)
corpus/11-simulation/hotel_bookings.sake: L17 Time.day result: observed ["Integer"], static (none)
corpus/11-simulation/hotel_bookings.sake: L16 Time.saturday? result: observed ["Boolean"], static (none)
corpus/11-simulation/hotel_bookings.sake: L68 Stay.get_first_night result: observed ["Time"], static Integer
corpus/11-simulation/hotel_bookings.sake: L68 Float.to_i result: observed ["Integer"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bakery_shift.sake | 2 | 95 | 7 | 0 | 0 | 89 | 0 | 0 |
| bank_ledger.sake | 2 | 100 | 0 | 1 | 0 | 80 | 0 | 0 |
| car_rental.sake | 2 | 122 | 3 | 0 | 0 | 115 | 0 | 0 |
| checkout_lanes.sake | 3 | 100 | 1 | 0 | 0 | 83 | 0 | 0 |
| cpu_scheduler.sake | 2 | 104 | 2 | 0 | 0 | 90 | 0 | 0 |
| ecosystem_patches.sake | 2 | 131 | 1 | 4 | 0 | 125 | 0 | 18 |
| elevator_scan.sake | 2 | 163 | 5 | 0 | 0 | 164 | 0 | 0 |
| epidemic_network.sake | 2 | 116 | 5 | 0 | 0 | 98 | 0 | 1 |
| forest_fire.sake | 2 | 95 | 8 | 2 | 0 | 78 | 0 | 1 |
| hotel_bookings.sake | 3 | 117 | 1 | 6 | 0 | 123 | 10 | 23 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| moon_phases.sake | 2 | 159 | 1 | 0 | 0 | 143 | 0 | 0 |
| parking_fees.sake | 2 | 108 | 17 | 0 | 0 | 106 | 0 | 0 |
| project_gantt.sake | 2 | 160 | 8 | 2 | 0 | 154 | 0 | 0 |
| public_holidays.sake | 2 | 170 | 0 | 1 | 0 | 156 | 0 | 0 |
| recurring_events.sake | 2 | 136 | 14 | 0 | 0 | 134 | 0 | 0 |
| room_booking.sake | 2 | 111 | 0 | 4 | 0 | 94 | 0 | 0 |
| shift_rota.sake | 3 | 117 | 4 | 0 | 0 | 100 | 0 | 0 |
| time_zones.sake | 2 | 138 | 0 | 1 | 0 | 131 | 0 | 0 |
| timesheet.sake | 3 | 136 | 14 | 2 | 0 | 128 | 0 | 0 |
| timetable.sake | 2 | 69 | 9 | 1 | 0 | 64 | 0 | 0 |
corpus/01-text/ascii_table.sake: L119 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/bwt_rle.sake: L76 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/01-text/classic_ciphers.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/01-text/classic_ciphers.sake: L60 Arithmetic.- pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus/01-text/classic_ciphers.sake: L61 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/01-text/classic_ciphers.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/01-text/classic_ciphers.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/01-text/csv_report.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/01-text/csv_report.sake: L73 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/csv_report.sake: L84 Array.sum result: observed ["Float"], static Integer
corpus/01-text/human_format.sake: L13 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L21 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/01-text/human_format.sake: L22 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/01-text/human_format.sake: L22 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L22 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/01-text/human_format.sake: L58 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L62 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L66 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L68 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/01-text/human_format.sake: L68 Float.round 1: observed [["Float"]], static Integer
corpus/01-text/human_format.sake: L81 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii_table.sake | 2 | 92 | 9 | 2 | 0 | 81 | 0 | 1 |
| bwt_rle.sake | 2 | 93 | 9 | 2 | 0 | 78 | 0 | 1 |
| case_convert.sake | 2 | 96 | 8 | 1 | 0 | 94 | 0 | 0 |
| classic_ciphers.sake | 2 | 119 | 5 | 0 | 0 | 102 | 0 | 5 |
| columnize.sake | 2 | 69 | 2 | 0 | 0 | 63 | 0 | 0 |
| csv_report.sake | 2 | 97 | 17 | 1 | 0 | 87 | 0 | 3 |
| date_format.sake | 2 | 145 | 19 | 0 | 0 | 130 | 0 | 0 |
| doc_pretty.sake | 2 | 77 | 4 | 3 | 0 | 71 | 0 | 0 |
| human_format.sake | 2 | 120 | 1 | 7 | 0 | 120 | 0 | 11 |
| inflector.sake | 2 | 71 | 1 | 0 | 0 | 62 | 0 | 0 |
corpus/13-polymorphism/collision_check.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L25 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/collision_check.sake: L33 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus/13-polymorphism/color_palette.sake: L48 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L49 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus/13-polymorphism/color_palette.sake: L50 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus/13-polymorphism/color_palette.sake: L51 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L51 Arithmetic.- pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer | nil]
corpus/13-polymorphism/color_palette.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L52 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus/13-polymorphism/color_palette.sake: L54 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus/13-polymorphism/color_palette.sake: L57 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L57 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L57 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L59 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L29 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L29 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/13-polymorphism/color_palette.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/13-polymorphism/color_palette.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/13-polymorphism/color_palette.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L53 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L53 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L53 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L51 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus/13-polymorphism/color_palette.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L55 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L8 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L8 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/color_palette.sake: L8 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L8 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/color_palette.sake: L8 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L8 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/color_palette.sake: L25 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L25 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L25 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L73 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L73 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L74 Float.floor 1: observed [["Float"]], static Integer
corpus/13-polymorphism/color_palette.sake: [75, 58, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/13-polymorphism/color_palette.sake: L37 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L38 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L39 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L39 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L39 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L121 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L122 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L123 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/color_palette.sake: L123 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/color_palette.sake: L46 Array.max result: observed ["Float"], static Integer | nil
corpus/13-polymorphism/color_palette.sake: L47 Array.min result: observed ["Float"], static Integer | nil
corpus/13-polymorphism/duration_timesheet.sake: L33 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/duration_timesheet.sake: L122 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/duration_timesheet.sake: L29 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/duration_timesheet.sake: L29 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/fraction_math.sake: L47 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/interval_arith.sake: L81 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Float"], ["Float", "Integer"], ["Interval", "Interval"], ["Interval", "Integer"]], static [Integer | Interval, Integer | Interval]
corpus/13-polymorphism/interval_arith.sake: L86 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/interval_arith.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/interval_arith.sake: L27 Array.min result: observed ["Integer", "Float"], static Integer | nil
corpus/13-polymorphism/interval_arith.sake: L27 Array.max result: observed ["Integer", "Float"], static Integer | nil
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bitset_permissions.sake | 2 | 90 | 10 | 1 | 0 | 74 | 0 | 0 |
| calendar_dates.sake | 2 | 143 | 8 | 3 | 0 | 134 | 0 | 0 |
| collision_check.sake | 3 | 173 | 0 | 0 | 0 | 149 | 0 | 9 |
| color_palette.sake | 2 | 162 | 16 | 5 | 0 | 162 | 1 | 55 |
| doc_render.sake | 2 | 138 | 7 | 0 | 0 | 120 | 0 | 0 |
| duration_timesheet.sake | 2 | 157 | 5 | 4 | 0 | 135 | 0 | 4 |
| expr_tree.sake | 3 | 191 | 1 | 1 | 0 | 126 | 0 | 0 |
| fraction_math.sake | 2 | 162 | 1 | 1 | 0 | 126 | 0 | 1 |
| interval_arith.sake | 3 | 128 | 32 | 2 | 0 | 127 | 0 | 5 |
| life_grid.sake | 2 | 82 | 5 | 0 | 0 | 64 | 0 | 0 |
corpus/05-sorting/merge_sort_inversions.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/merge_sort_inversions.sake: L52 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/05-sorting/radix_order_ids.sake: L43 Float.floor 1: observed [["Float"]], static Integer
corpus/05-sorting/radix_order_ids.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/sensor_quickselect.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/05-sorting/sensor_quickselect.sake: L68 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/05-sorting/sensor_quickselect.sake: L68 Float.ceil 1: observed [["Float"]], static Integer
corpus/05-sorting/sensor_quickselect.sake: L103 Float.abs 1: observed [["Float"]], static Integer
corpus/05-sorting/sensor_quickselect.sake: [103, 29, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/05-sorting/sensor_quickselect.sake: [103, 48, "Float.round", 1]: observed [["Float"]] but no static check
corpus/05-sorting/sensor_quickselect.sake: L103 Float.round result: observed ["Float"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| library_catalog.sake | 2 | 87 | 6 | 0 | 0 | 79 | 0 | 0 |
| log_time_bisect.sake | 2 | 73 | 10 | 1 | 0 | 64 | 0 | 0 |
| meeting_intervals.sake | 2 | 110 | 10 | 0 | 0 | 90 | 0 | 0 |
| merge_sort_inversions.sake | 2 | 90 | 5 | 0 | 0 | 69 | 0 | 2 |
| natural_runs_sort.sake | 2 | 181 | 15 | 1 | 0 | 132 | 0 | 0 |
| probe_count_search.sake | 2 | 96 | 13 | 2 | 0 | 82 | 0 | 0 |
| quicksort_median3.sake | 2 | 85 | 11 | 0 | 0 | 72 | 0 | 0 |
| radix_order_ids.sake | 2 | 85 | 5 | 1 | 0 | 68 | 0 | 2 |
| sensor_quickselect.sake | 3 | 103 | 12 | 3 | 0 | 84 | 2 | 7 |
| shell_sort_gaps.sake | 2 | 80 | 2 | 2 | 0 | 56 | 0 | 0 |
corpus/20-business/restaurant_orders.sake: L50 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/restaurant_orders.sake: L51 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/restaurant_orders.sake: L63 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/restaurant_orders.sake: L63 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/room_reservations.sake: L131 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/room_reservations.sake: L132 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/room_reservations.sake: L131 Array.sum result: observed ["Float"], static Integer
corpus/20-business/sales_report.sake: L57 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/20-business/sales_report.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | nil]
corpus/20-business/sales_report.sake: L63 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/sales_report.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/20-business/sales_report.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus/20-business/sales_report.sake: L31 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/sales_report.sake: L31 Float.round 1: observed [["Float"]], static Integer
corpus/20-business/sales_report.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/sales_report.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/20-business/sales_report.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/20-business/sales_report.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/sales_report.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/sales_report.sake: L92 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/20-business/sales_report.sake: L52 Array.sum result: observed ["Float"], static Integer
corpus/20-business/sales_report.sake: L69 Array.sum result: observed ["Float"], static Integer
corpus/20-business/sales_report.sake: L70 Array.max result: observed ["Float"], static Integer | nil
corpus/20-business/sales_report.sake: L79 Array.sum result: observed ["Float"], static Integer
corpus/20-business/sales_report.sake: L89 Array.sum result: observed ["Float"], static Integer
corpus/20-business/shopping_cart.sake: L78 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
corpus/20-business/shopping_cart.sake: [11, 28, "Float.round", 1]: observed [["Float"]] but no static check
corpus/20-business/shopping_cart.sake: L122 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/shopping_cart.sake: L125 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
corpus/20-business/subscription_billing.sake: L29 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus/20-business/subscription_billing.sake: L29 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Rational]
corpus/20-business/subscription_billing.sake: L44 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/20-business/subscription_billing.sake: L44 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/20-business/subscription_billing.sake: L44 Arithmetic.- pair: observed [["Integer", "Rational"]], static [Integer, Integer]
corpus/20-business/subscription_billing.sake: L95 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus/20-business/subscription_billing.sake: L16 Rational.round 1: observed [["Rational"]], static Integer
corpus/20-business/subscription_billing.sake: L16 Rational.to_f 1: observed [["Rational"]], static Integer
corpus/20-business/subscription_billing.sake: L114 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/20-business/subscription_billing.sake: L43 Array.sum result: observed ["Rational"], static Integer
corpus/20-business/subscription_billing.sake: L92 Array.sum result: observed ["Rational"], static Integer
corpus/20-business/subscription_billing.sake: L110 Array.sum result: observed ["Rational"], static Integer
corpus/20-business/timesheet.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/timesheet.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/timesheet.sake: L76 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/timesheet.sake: L84 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/timesheet.sake: L84 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/timesheet.sake: L82 Array.sum result: observed ["Float"], static Integer
corpus/20-business/todo_list.sake: L134 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/vendor_quotes.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/vendor_quotes.sake: L18 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/20-business/vendor_quotes.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/vendor_quotes.sake: L88 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/20-business/vendor_quotes.sake: L88 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/20-business/vendor_quotes.sake: L73 Hash.sum result: observed ["Float"], static Integer
corpus/20-business/vendor_quotes.sake: L87 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| restaurant_orders.sake | 2 | 100 | 1 | 4 | 0 | 95 | 0 | 4 |
| room_reservations.sake | 3 | 102 | 5 | 3 | 0 | 101 | 0 | 3 |
| sales_report.sake | 2 | 119 | 11 | 1 | 0 | 115 | 0 | 18 |
| shopping_cart.sake | 3 | 134 | 4 | 1 | 0 | 125 | 1 | 4 |
| subscription_billing.sake | 2 | 108 | 2 | 3 | 0 | 91 | 0 | 12 |
| ticket_helpdesk.sake | 3 | 97 | 4 | 2 | 0 | 95 | 0 | 0 |
| timesheet.sake | 2 | 83 | 13 | 0 | 0 | 81 | 0 | 6 |
| todo_list.sake | 2 | 102 | 2 | 1 | 0 | 96 | 0 | 1 |
| vendor_quotes.sake | 2 | 83 | 4 | 0 | 0 | 79 | 0 | 7 |
| warehouse_picking.sake | 2 | 102 | 12 | 1 | 0 | 99 | 0 | 0 |
corpus/04-numeric/eigenvalues.sake: L5 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/eigenvalues.sake: L6 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer | nil]
corpus/04-numeric/eigenvalues.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L107 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus/04-numeric/eigenvalues.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L67 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/eigenvalues.sake: L67 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [67, 62, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [67, 43, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [67, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [68, 18, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [68, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [69, 12, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [73, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [74, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [79, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [80, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/eigenvalues.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/eigenvalues.sake: L25 Float.abs 1: observed [["Float"]], static nil | Integer
corpus/04-numeric/eigenvalues.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/eigenvalues.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/eigenvalues.sake: L31 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/eigenvalues.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/eigenvalues.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L126 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/eigenvalues.sake: L126 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/eigenvalues.sake: L126 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/eigenvalues.sake: L3 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/eigenvalues.sake: L4 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/eigenvalues.sake: L67 Math.sqrt result: observed ["Float"], static (none)
corpus/04-numeric/eigenvalues.sake: L68 Math.sqrt result: observed ["Float"], static (none)
corpus/04-numeric/float_accuracy.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L38 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L67 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L67 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L54 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L55 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L10 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L10 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L10 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L43 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L44 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L44 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L48 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L49 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L92 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L92 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L92 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L93 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L93 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L93 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L99 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L99 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L100 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/float_accuracy.sake: L100 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L105 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L106 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/float_accuracy.sake: L107 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/float_accuracy.sake: L107 Float.nan? 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: L107 Float.finite? 1: observed [["Float"]], static Integer
corpus/04-numeric/float_accuracy.sake: [108, 21, "Float.infinite?", 1]: observed [["Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: [108, 61, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: [108, 45, "Float.infinite?", 1]: observed [["Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: [109, 18, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: [109, 41, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: [111, 2, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus/04-numeric/float_accuracy.sake: L108 Float.infinite? result: observed ["Integer"], static (none)
corpus/04-numeric/float_accuracy.sake: L108 Float.infinite? result: observed ["Integer"], static (none)
corpus/04-numeric/fourier_spectrum.sake: L61 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/fourier_spectrum.sake: L61 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/fourier_spectrum.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/fourier_spectrum.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/fourier_spectrum.sake: L61 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/fourier_spectrum.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L6 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/fourier_spectrum.sake: L6 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/fourier_spectrum.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L44 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L72 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/fourier_spectrum.sake: L74 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/fourier_spectrum.sake: L76 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/fourier_spectrum.sake: L82 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L54 Arithmetic.* pair: observed [["Cpx", "Float"]], static [Cpx, Integer]
corpus/04-numeric/fourier_spectrum.sake: [13, 26, "Cpx.get_re", 1]: observed [["Cpx"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [13, 26, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [13, 35, "Cpx.get_im", 1]: observed [["Cpx"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [13, 35, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [86, 68, "Arithmetic.-", "pair"]: observed [["Cpx", "Cpx"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: L92 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/fourier_spectrum.sake: L92 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/fourier_spectrum.sake: [97, 24, "Arithmetic.*", "pair"]: observed [["Float", "Float"], ["Float", "Integer"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [97, 24, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [97, 15, "Math.sin", 1]: observed [["Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [97, 9, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [97, 9, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [98, 43, "Cpx.get_re", 1]: observed [["Cpx"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [98, 43, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [98, 33, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [98, 20, "Float[]", "elem"]: observed [["Float"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: [98, 10, "Array.max", 1]: observed [["Array"]] but no static check
corpus/04-numeric/fourier_spectrum.sake: L81 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/fourier_spectrum.sake: L82 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/fourier_spectrum.sake: L86 Array.max result: observed ["Float"], static nil
corpus/04-numeric/gaussian_elimination.sake: L24 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/gaussian_elimination.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/gaussian_elimination.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/gaussian_elimination.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/gaussian_elimination.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/gaussian_elimination.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/gaussian_elimination.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/gaussian_elimination.sake: L68 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/gaussian_elimination.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/gaussian_elimination.sake: L97 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/gaussian_elimination.sake: L100 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/gaussian_elimination.sake: L115 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/gaussian_elimination.sake: L65 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L8 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L14 Math.log 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L14 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L14 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L71 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L71 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus/04-numeric/histogram_fit.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L35 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus/04-numeric/histogram_fit.sake: L35 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus/04-numeric/histogram_fit.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus/04-numeric/histogram_fit.sake: L37 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L37 Float.floor 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L23 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L24 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L26 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L81 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L82 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L82 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L82 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L89 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L47 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/histogram_fit.sake: L47 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L48 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L48 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/histogram_fit.sake: L48 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L105 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L105 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L111 Float.floor 1: observed [["Float"]], static Integer
corpus/04-numeric/histogram_fit.sake: L112 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L62 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/histogram_fit.sake: L112 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/histogram_fit.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L71 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L72 Array.min result: observed ["Float"], static Integer | nil
corpus/04-numeric/histogram_fit.sake: L72 Array.max result: observed ["Float"], static Integer | nil
corpus/04-numeric/histogram_fit.sake: L32 Array.min result: observed ["Float"], static Integer | nil
corpus/04-numeric/histogram_fit.sake: L33 Array.max result: observed ["Float"], static Integer | nil
corpus/04-numeric/histogram_fit.sake: L81 Bin.get_hi result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L81 Bin.get_lo result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L83 Bin.get_lo result: observed ["Float"], static Integer
corpus/04-numeric/histogram_fit.sake: L83 Bin.get_hi result: observed ["Float"], static Integer
corpus/04-numeric/interval_arithmetic.sake: L28 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/interval_arithmetic.sake: L43 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/interval_arithmetic.sake: L55 Arithmetic.* pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
corpus/04-numeric/interval_arithmetic.sake: L55 Arithmetic.* pair: observed [["Interval", "Float"], ["Float", "Float"]], static [Integer | Interval, Float]
corpus/04-numeric/interval_arithmetic.sake: L55 Arithmetic.- pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
corpus/04-numeric/interval_arithmetic.sake: L55 Arithmetic.+ pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval | nil]
corpus/04-numeric/interval_arithmetic.sake: L128 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/interval_arithmetic.sake: L57 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/interval_arithmetic.sake: L48 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/interval_arithmetic.sake: L70 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus/04-numeric/interval_arithmetic.sake: L76 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/interval_arithmetic.sake: L80 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/interval_arithmetic.sake: L94 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/interval_arithmetic.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/interval_arithmetic.sake: L129 Array.min result: observed ["Float"], static Integer | nil
corpus/04-numeric/interval_arithmetic.sake: L129 Array.max result: observed ["Float"], static Integer | nil
corpus/04-numeric/linear_regression.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L18 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L19 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L19 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/linear_regression.sake: L19 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L19 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/linear_regression.sake: L20 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus/04-numeric/linear_regression.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/linear_regression.sake: L25 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/linear_regression.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/linear_regression.sake: L27 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/linear_regression.sake: L5 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/linear_regression.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L64 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L64 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/linear_regression.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/linear_regression.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/linear_regression.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/linear_regression.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L39 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L39 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/linear_regression.sake: L39 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/linear_regression.sake: L42 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/linear_regression.sake: L85 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/linear_regression.sake: L25 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/linear_regression.sake: L33 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/linear_regression.sake: L34 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/linear_regression.sake: L89 Fit.get_r2 result: observed ["Float"], static Integer
corpus/04-numeric/loan_amortization.sake: L9 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/loan_amortization.sake: L9 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/loan_amortization.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/loan_amortization.sake: L5 Float.round 1: observed [["Float"]], static Integer
corpus/04-numeric/loan_amortization.sake: L20 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/loan_amortization.sake: L23 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/loan_amortization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/loan_amortization.sake: L100 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/loan_amortization.sake: L49 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/loan_amortization.sake: L50 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/loan_amortization.sake: L52 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/loan_amortization.sake: L53 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/loan_amortization.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/loan_amortization.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/lu_decomposition.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/lu_decomposition.sake: L71 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/lu_decomposition.sake: L93 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/lu_decomposition.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/lu_decomposition.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/lu_decomposition.sake: L40 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/lu_decomposition.sake: L46 Range.reduce result: observed ["Float"], static Integer
corpus/04-numeric/matrix_ops.sake: L59 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/matrix_ops.sake: L89 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/matrix_ops.sake: L93 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/matrix_ops.sake: L109 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/matrix_ops.sake: L109 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| eigenvalues.sake | 2 | 152 | 43 | 2 | 0 | 149 | 22 | 46 |
| float_accuracy.sake | 2 | 112 | 5 | 5 | 0 | 122 | 6 | 46 |
| fourier_spectrum.sake | 2 | 141 | 8 | 2 | 0 | 144 | 15 | 37 |
| gaussian_elimination.sake | 2 | 150 | 49 | 6 | 0 | 121 | 0 | 13 |
| histogram_fit.sake | 2 | 164 | 12 | 3 | 0 | 159 | 0 | 81 |
| interval_arithmetic.sake | 2 | 99 | 49 | 3 | 0 | 126 | 0 | 16 |
| linear_regression.sake | 2 | 120 | 9 | 1 | 0 | 112 | 0 | 41 |
| loan_amortization.sake | 2 | 111 | 5 | 1 | 0 | 104 | 0 | 14 |
| lu_decomposition.sake | 3 | 147 | 39 | 5 | 0 | 116 | 0 | 7 |
| matrix_ops.sake | 3 | 164 | 12 | 4 | 0 | 143 | 0 | 5 |
corpus/15-data/fulfillment_report.sake: L117 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/fulfillment_report.sake: L128 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/fx_conversion.sake: L77 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/15-data/fx_conversion.sake: L78 Comparable.< pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/15-data/fx_conversion.sake: L79 Arithmetic.+ pair: observed [["Rational", "Rational"], ["Rational", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
corpus/15-data/fx_conversion.sake: L83 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus/15-data/fx_conversion.sake: L89 Rational.abs 1: observed [["Rational"]], static Integer
corpus/15-data/fx_conversion.sake: L90 Rational.abs 1: observed [["Rational"]], static Integer
corpus/15-data/fx_conversion.sake: L91 Rational.abs 1: observed [["Rational"]], static Integer
corpus/15-data/fx_conversion.sake: L92 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/15-data/fx_conversion.sake: L92 Rational.to_f 1: observed [["Rational"]], static Integer
corpus/15-data/fx_conversion.sake: L77 Array.sum result: observed ["Rational", "Integer"], static Integer
corpus/15-data/fx_conversion.sake: L78 Array.sum result: observed ["Rational", "Integer"], static Integer
corpus/15-data/fx_conversion.sake: L81 Array.sum result: observed ["Rational"], static Integer
corpus/15-data/grade_book.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/15-data/grade_book.sake: L55 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L61 Kernel.== pair: observed [["Nil", "Nil"], ["Float", "Nil"]], static [Integer | nil, nil]
corpus/15-data/grade_book.sake: L61 Float.round 1: observed [["Float"]], static Integer
corpus/15-data/grade_book.sake: L61 Float.round 1: observed [["Float"]], static Integer | nil
corpus/15-data/grade_book.sake: L39 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L40 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L41 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L42 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L51 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L51 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L51 Math.sqrt 1: observed [["Float"]], static Integer
corpus/15-data/grade_book.sake: L104 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/grade_book.sake: L35 Hash.sum result: observed ["Float"], static Integer
corpus/15-data/grade_book.sake: L47 Array.sum result: observed ["Float", "Integer"], static Integer
corpus/15-data/grade_book.sake: L51 Array.sum result: observed ["Float"], static Integer
corpus/15-data/grade_book.sake: L85 Array.max result: observed ["Float"], static Integer | nil
corpus/15-data/grade_book.sake: L85 Array.min result: observed ["Float"], static Integer | nil
corpus/15-data/inventory_diff.sake: L92 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Float | Integer | String]
corpus/15-data/inventory_diff.sake: L93 Comparable.<= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/inventory_diff.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | String]
corpus/15-data/inventory_diff.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/inventory_diff.sake: L97 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/inventory_diff.sake: L101 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/inventory_diff.sake: L97 Array.sum result: observed ["Float"], static Integer
corpus/15-data/inventory_diff.sake: L59 Hash.sum result: observed ["Float"], static Integer
corpus/15-data/invoice_totals.sake: L10 Float.round 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/metric_anomalies.sake: L31 Float.round 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: L51 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/15-data/metric_anomalies.sake: L51 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/metric_anomalies.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/metric_anomalies.sake: L51 Math.sqrt 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: L57 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/15-data/metric_anomalies.sake: L62 Float.abs 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: L81 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/metric_anomalies.sake: L82 Float.abs 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: [83, 98, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/15-data/metric_anomalies.sake: L92 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer | nil]
corpus/15-data/metric_anomalies.sake: L92 Float.abs 1: observed [["Float"]], static Integer
corpus/15-data/metric_anomalies.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Float]
corpus/15-data/metric_anomalies.sake: L92 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/15-data/metric_anomalies.sake: L51 Array.sum result: observed ["Float"], static Integer
corpus/15-data/metric_anomalies.sake: L83 Kernel.format result: observed ["String"], static (none)
corpus/15-data/metric_anomalies.sake: L83 Kernel.puts result: observed ["Nil"], static (none)
corpus/15-data/quality_rules.sake: L103 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/sales_by_region.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| fulfillment_report.sake | 2 | 141 | 0 | 1 | 0 | 122 | 0 | 2 |
| fx_conversion.sake | 2 | 91 | 1 | 4 | 0 | 85 | 0 | 12 |
| grade_book.sake | 2 | 86 | 0 | 2 | 0 | 80 | 0 | 21 |
| groupby_query.sake | 2 | 85 | 7 | 2 | 0 | 76 | 0 | 0 |
| inventory_diff.sake | 2 | 135 | 4 | 0 | 0 | 130 | 0 | 8 |
| invoice_totals.sake | 2 | 102 | 1 | 1 | 0 | 84 | 0 | 1 |
| league_standings.sake | 3 | 124 | 4 | 0 | 0 | 106 | 0 | 0 |
| metric_anomalies.sake | 2 | 130 | 3 | 5 | 0 | 128 | 1 | 18 |
| quality_rules.sake | 2 | 89 | 0 | 0 | 0 | 79 | 0 | 1 |
| sales_by_region.sake | 2 | 101 | 4 | 0 | 0 | 77 | 0 | 1 |
corpus/11-simulation/teller_queue_des.sake: L121 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/11-simulation/thermostat_house.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L45 Comparable.<= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/11-simulation/thermostat_house.sake: L51 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/11-simulation/thermostat_house.sake: L51 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/11-simulation/thermostat_house.sake: L51 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/thermostat_house.sake: L52 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L43 Comparable.>= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L72 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L84 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/thermostat_house.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/thermostat_house.sake: L52 Room.set_temp result: observed ["Float"], static Integer
corpus/11-simulation/water_tanks.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/water_tanks.sake: L9 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/water_tanks.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/11-simulation/water_tanks.sake: L44 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/water_tanks.sake: L45 Math.sqrt 1: observed [["Float"]], static Integer
corpus/11-simulation/water_tanks.sake: L19 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/11-simulation/water_tanks.sake: L20 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/water_tanks.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/water_tanks.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/water_tanks.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/11-simulation/water_tanks.sake: L83 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/water_tanks.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/11-simulation/water_tanks.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/11-simulation/water_tanks.sake: L60 Tank.set_drawn result: observed ["Float"], static Integer
corpus/12-parsers/chem_formula.sake: L53 Hash.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| teller_queue_des.sake | 2 | 148 | 12 | 1 | 0 | 122 | 0 | 1 |
| thermostat_house.sake | 2 | 94 | 2 | 0 | 0 | 77 | 0 | 15 |
| traffic_intersection.sake | 2 | 109 | 4 | 0 | 0 | 92 | 0 | 0 |
| vending_machine.sake | 2 | 120 | 4 | 0 | 0 | 109 | 0 | 0 |
| water_tanks.sake | 2 | 100 | 28 | 0 | 0 | 112 | 0 | 14 |
| assembler.sake | 2 | 135 | 26 | 10 | 0 | 88 | 0 | 0 |
| brainfuck.sake | 2 | 75 | 4 | 0 | 0 | 50 | 0 | 0 |
| calc_rd.sake | 4 | 127 | 13 | 0 | 0 | 123 | 0 | 0 |
| chem_formula.sake | 3 | 81 | 11 | 4 | 0 | 71 | 0 | 1 |
| cmdline_parser.sake | 2 | 95 | 9 | 1 | 0 | 81 | 0 | 0 |
corpus/20-business/customer_loyalty.sake: L23 Float.floor 1: observed [["Float"]], static Integer
corpus/20-business/event_registration.sake: L68 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| smtp_session.sake | 3 | 79 | 1 | 0 | 0 | 72 | 0 | 0 |
| tcp_states.sake | 2 | 55 | 0 | 0 | 0 | 41 | 0 | 0 |
| traffic_light.sake | 2 | 82 | 4 | 2 | 0 | 83 | 0 | 0 |
| turnstile.sake | 2 | 32 | 0 | 1 | 0 | 30 | 0 | 0 |
| vending_machine.sake | 2 | 84 | 1 | 1 | 0 | 71 | 0 | 0 |
| appointment_scheduler.sake | 2 | 75 | 4 | 1 | 0 | 65 | 0 | 0 |
| bank_ledger.sake | 3 | 122 | 4 | 1 | 0 | 114 | 0 | 0 |
| course_enrollment.sake | 2 | 105 | 0 | 0 | 0 | 101 | 0 | 0 |
| customer_loyalty.sake | 3 | 95 | 5 | 3 | 0 | 96 | 0 | 1 |
| event_registration.sake | 2 | 78 | 0 | 0 | 0 | 74 | 0 | 1 |
corpus/15-data/access_log_report.sake: L66 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/access_log_report.sake: L88 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/access_log_report.sake: L46 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/access_log_report.sake: L46 Float.ceil 1: observed [["Float"]], static Integer
corpus/15-data/bank_reconcile.sake: L35 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/bank_reconcile.sake: L35 Float.round 1: observed [["Float"]], static Integer
corpus/15-data/bank_reconcile.sake: L41 Float.round 1: observed [["Float"]], static Integer
corpus/15-data/bank_reconcile.sake: L63 Time.strftime 1: observed [["Time"]], static Integer
corpus/15-data/budget_variance.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/budget_variance.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/budget_variance.sake: L21 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/15-data/budget_variance.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/15-data/budget_variance.sake: L54 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/clickstream_sessions.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/clickstream_sessions.sake: L107 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
corpus/15-data/csv_import_validation.sake: L105 Array.sum result: observed ["Float"], static Integer
corpus/15-data/customer_dedupe.sake: L117 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/employee_dept_join.sake: L46 Kernel.== pair: observed [["Integer", "Nil"], ["Float", "Nil"]], static [nil | Integer, nil]
corpus/15-data/employee_dept_join.sake: L47 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/15-data/etl_star_schema.sake: L125 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L44 Arithmetic.+ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/15-data/expense_pivot.sake: L54 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L39 Kernel.== pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L58 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L81 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L81 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L84 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus/15-data/expense_pivot.sake: L15 Array.sum result: observed ["Float"], static Integer
corpus/15-data/expense_pivot.sake: L17 Array.sum result: observed ["Float"], static Integer
corpus/15-data/expense_pivot.sake: L16 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| access_log_report.sake | 2 | 111 | 7 | 1 | 0 | 103 | 0 | 4 |
| bank_reconcile.sake | 2 | 115 | 3 | 3 | 0 | 115 | 0 | 4 |
| budget_variance.sake | 2 | 53 | 0 | 0 | 0 | 41 | 0 | 5 |
| clickstream_sessions.sake | 3 | 117 | 4 | 2 | 0 | 114 | 0 | 2 |
| cohort_retention.sake | 2 | 95 | 6 | 1 | 0 | 95 | 0 | 0 |
| csv_import_validation.sake | 2 | 99 | 6 | 0 | 0 | 95 | 0 | 1 |
| customer_dedupe.sake | 3 | 134 | 0 | 0 | 0 | 107 | 0 | 1 |
| employee_dept_join.sake | 2 | 90 | 7 | 0 | 0 | 89 | 0 | 2 |
| etl_star_schema.sake | 2 | 174 | 3 | 0 | 0 | 130 | 0 | 1 |
| expense_pivot.sake | 2 | 98 | 2 | 0 | 0 | 78 | 0 | 12 |
corpus/17-encodings/ascii85.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/17-encodings/ascii85.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/17-encodings/bloom_filter.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/17-encodings/bloom_filter.sake: L47 Math.exp 1: observed [["Float"]], static Integer
corpus/17-encodings/bloom_filter.sake: L47 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/17-encodings/caesar_cracker.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/17-encodings/caesar_cracker.sake: L45 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/17-encodings/caesar_cracker.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/17-encodings/caesar_cracker.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/17-encodings/caesar_cracker.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/17-encodings/frame_parser.sake: L108 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii85.sake | 2 | 104 | 1 | 5 | 0 | 96 | 0 | 2 |
| base32_ids.sake | 2 | 88 | 5 | 3 | 0 | 74 | 0 | 0 |
| base64_codec.sake | 2 | 70 | 7 | 2 | 0 | 61 | 0 | 0 |
| bitset.sake | 2 | 121 | 1 | 2 | 0 | 104 | 0 | 0 |
| bloom_filter.sake | 2 | 84 | 2 | 0 | 0 | 78 | 0 | 3 |
| caesar_cracker.sake | 2 | 54 | 3 | 0 | 0 | 46 | 0 | 5 |
| check_digits.sake | 2 | 81 | 0 | 1 | 0 | 72 | 0 | 0 |
| crc_catalog.sake | 2 | 86 | 13 | 0 | 0 | 89 | 0 | 0 |
| frame_parser.sake | 2 | 162 | 18 | 0 | 0 | 133 | 0 | 1 |
| hamming_secded.sake | 2 | 89 | 0 | 1 | 0 | 76 | 0 | 0 |
corpus/01-text/text_stats.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/01-text/text_stats.sake: L35 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/01-text/text_stats.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/01-text/text_stats.sake: L64 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/01-text/text_stats.sake: L64 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/caesar_crack.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/caesar_crack.sake: L35 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/02-analytics/caesar_crack.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/caesar_crack.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/caesar_crack.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/cooccurrence_pmi.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/cooccurrence_pmi.sake: L46 Math.log2 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| template_render.sake | 2 | 55 | 4 | 1 | 0 | 52 | 0 | 0 |
| text_box.sake | 2 | 99 | 6 | 2 | 0 | 95 | 0 | 0 |
| text_stats.sake | 2 | 85 | 2 | 0 | 0 | 79 | 0 | 5 |
| whitespace_tidy.sake | 2 | 110 | 5 | 0 | 0 | 100 | 0 | 0 |
| word_wrap.sake | 2 | 67 | 11 | 0 | 0 | 71 | 0 | 0 |
| access_log_urls.sake | 2 | 135 | 11 | 0 | 0 | 112 | 0 | 0 |
| anagram_groups.sake | 2 | 74 | 3 | 0 | 0 | 63 | 0 | 0 |
| autocomplete.sake | 2 | 63 | 7 | 0 | 0 | 58 | 0 | 0 |
| caesar_crack.sake | 2 | 60 | 2 | 0 | 0 | 54 | 0 | 5 |
| cooccurrence_pmi.sake | 2 | 76 | 0 | 0 | 0 | 62 | 0 | 2 |
corpus/12-parsers/json_parser.sake: L195 Float.round 1: observed [["Float"]], static Integer
corpus/12-parsers/json_parser.sake: L194 Array.sum result: observed ["Float"], static Integer
corpus/12-parsers/query_engine.sake: L134 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_parser.sake | 2 | 80 | 4 | 3 | 0 | 69 | 0 | 0 |
| forth.sake | 3 | 120 | 17 | 1 | 0 | 103 | 0 | 0 |
| indent_lexer.sake | 3 | 69 | 5 | 1 | 0 | 66 | 0 | 0 |
| ini_parser.sake | 2 | 101 | 3 | 2 | 0 | 88 | 0 | 0 |
| json_parser.sake | 3 | 202 | 21 | 8 | 0 | 171 | 0 | 2 |
| lisp_interp.sake | 5 | 138 | 20 | 1 | 0 | 85 | 0 | 0 |
| markdown.sake | 2 | 118 | 12 | 6 | 0 | 106 | 0 | 0 |
| pratt_parser.sake | 3 | 128 | 28 | 3 | 0 | 102 | 0 | 0 |
| query_engine.sake | 2 | 111 | 10 | 3 | 0 | 108 | 0 | 1 |
| regex_matcher.sake | 2 | 160 | 6 | 3 | 0 | 123 | 0 | 0 |
corpus/15-data/size_histogram.sake: L44 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/size_histogram.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L54 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L54 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L54 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/15-data/survey_crosstab.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/timesheet_payroll.sake: L78 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/15-data/timesheet_payroll.sake: L78 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/15-data/timesheet_payroll.sake: L78 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/15-data/timesheet_payroll.sake: L83 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/15-data/top_products.sake: L41 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/top_products.sake: L36 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/top_products.sake: L36 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/15-data/top_products.sake: L36 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/15-data/top_products.sake: L53 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| size_histogram.sake | 2 | 51 | 3 | 0 | 0 | 47 | 0 | 2 |
| survey_crosstab.sake | 2 | 96 | 0 | 0 | 0 | 72 | 0 | 10 |
| table_renderer.sake | 2 | 101 | 13 | 2 | 0 | 100 | 0 | 0 |
| timesheet_payroll.sake | 2 | 102 | 2 | 0 | 0 | 98 | 0 | 4 |
| top_products.sake | 2 | 95 | 1 | 1 | 0 | 85 | 0 | 5 |
| activity_heatmap.sake | 2 | 162 | 5 | 0 | 0 | 134 | 0 | 0 |
| age_calculator.sake | 2 | 119 | 4 | 0 | 0 | 104 | 0 | 0 |
| billing_cycles.sake | 2 | 138 | 4 | 1 | 0 | 118 | 0 | 0 |
| business_days.sake | 2 | 103 | 3 | 2 | 0 | 102 | 0 | 0 |
| calendar_systems.sake | 2 | 192 | 2 | 0 | 0 | 173 | 0 | 0 |
corpus/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L31 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L31 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L10 Math.hypot 1: observed [["Float"]], static Integer
corpus/04-numeric/bezier_curves.sake: L10 Math.hypot 2: observed [["Float"]], static Integer
corpus/04-numeric/bezier_curves.sake: L55 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L65 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/bezier_curves.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L67 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/bezier_curves.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus/04-numeric/bezier_curves.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus/04-numeric/bezier_curves.sake: L90 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/bezier_curves.sake: L74 Array.min result: observed ["Float"], static nil | [Float | Integer, Float | Integer]
corpus/04-numeric/bezier_curves.sake: L74 Array.max result: observed ["Float"], static nil | [Float | Integer, Float | Integer]
corpus/04-numeric/bezier_curves.sake: L74 Array.min result: observed ["Float"], static nil
corpus/04-numeric/bezier_curves.sake: L74 Array.max result: observed ["Float"], static nil
corpus/04-numeric/correlation_matrix.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus/04-numeric/correlation_matrix.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L32 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/correlation_matrix.sake: L52 Kernel.== pair: observed [["Float", "Nil"]], static [nil | Integer, nil]
corpus/04-numeric/correlation_matrix.sake: L81 Kernel.== pair: observed [["Float", "Nil"]], static [nil | Integer, nil]
corpus/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L95 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L95 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/correlation_matrix.sake: L102 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus/04-numeric/correlation_matrix.sake: L102 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus/04-numeric/correlation_matrix.sake: L102 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L102 Math.log 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L104 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L104 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L106 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/correlation_matrix.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/correlation_matrix.sake: L113 Kernel.!= pair: observed [["Float", "Nil"]], static [Integer | nil, nil]
corpus/04-numeric/correlation_matrix.sake: L113 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/cubic_spline.sake: L94 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L92 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L31 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/cubic_spline.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/cubic_spline.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/cubic_spline.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/cubic_spline.sake: L99 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L57 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
corpus/04-numeric/cubic_spline.sake: L57 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
corpus/04-numeric/cubic_spline.sake: L47 Comparable.<= pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus/04-numeric/cubic_spline.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus/04-numeric/cubic_spline.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L62 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/cubic_spline.sake: L85 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L88 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L89 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L89 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L89 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L78 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L78 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L78 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L78 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L79 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L106 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L108 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L108 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/cubic_spline.sake: L109 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus/04-numeric/cubic_spline.sake: L109 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/cubic_spline.sake: L110 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L110 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/cubic_spline.sake: L67 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float]
corpus/04-numeric/cubic_spline.sake: L68 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L69 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/cubic_spline.sake: L70 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L116 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/cubic_spline.sake: L116 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L116 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/cubic_spline.sake: L57 Array.first result: observed ["Float"], static Integer | nil
corpus/04-numeric/cubic_spline.sake: L57 Array.last result: observed ["Float"], static Integer | nil
corpus/04-numeric/cubic_spline.sake: L86 Array.last result: observed ["Float"], static Integer | nil
corpus/04-numeric/curve_fitting.sake: L66 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/curve_fitting.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/curve_fitting.sake: L53 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus/04-numeric/curve_fitting.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/curve_fitting.sake: L57 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus/04-numeric/curve_fitting.sake: L57 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L74 Math.exp 1: observed [["Float"]], static nil | Integer
corpus/04-numeric/curve_fitting.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L7 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L7 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/curve_fitting.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L12 Math.log 1: observed [["Float"]], static Integer
corpus/04-numeric/curve_fitting.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/curve_fitting.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus/04-numeric/curve_fitting.sake: L25 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/curve_fitting.sake: L103 Float.abs 1: observed [["Float"]], static Integer | nil
corpus/04-numeric/curve_fitting.sake: L65 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/curve_fitting.sake: L66 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/curve_fitting.sake: L7 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/curve_fitting.sake: L11 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/descriptive_stats.sake: L14 Float.floor 1: observed [["Float"]], static Integer
corpus/04-numeric/descriptive_stats.sake: [15, 7, "Float.ceil", 1]: observed [["Float"]] but no static check
corpus/04-numeric/descriptive_stats.sake: [16, 23, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/04-numeric/descriptive_stats.sake: L7 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/descriptive_stats.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/descriptive_stats.sake: L7 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/descriptive_stats.sake: L10 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/descriptive_stats.sake: [17, 9, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/04-numeric/descriptive_stats.sake: [18, 16, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/descriptive_stats.sake: [18, 2, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/descriptive_stats.sake: [18, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/descriptive_stats.sake: [18, 2, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/descriptive_stats.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/descriptive_stats.sake: L27 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/descriptive_stats.sake: L27 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/descriptive_stats.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/descriptive_stats.sake: L90 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/descriptive_stats.sake: L15 Float.ceil result: observed ["Integer"], static (none)
corpus/04-numeric/descriptive_stats.sake: L7 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/descriptive_stats.sake: L27 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| pythagorean_triples.sake | 2 | 164 | 3 | 1 | 0 | 156 | 0 | 0 |
| quadratic_residues.sake | 2 | 153 | 0 | 2 | 0 | 139 | 0 | 0 |
| repeating_decimals.sake | 2 | 76 | 18 | 0 | 0 | 70 | 0 | 0 |
| rsa_toy.sake | 2 | 98 | 0 | 1 | 0 | 92 | 0 | 0 |
| sieve_primes.sake | 2 | 99 | 3 | 0 | 0 | 75 | 0 | 0 |
| bezier_curves.sake | 2 | 122 | 12 | 2 | 0 | 110 | 0 | 26 |
| correlation_matrix.sake | 2 | 140 | 11 | 4 | 0 | 121 | 0 | 43 |
| cubic_spline.sake | 2 | 268 | 43 | 12 | 0 | 200 | 0 | 81 |
| curve_fitting.sake | 2 | 138 | 29 | 2 | 0 | 113 | 0 | 24 |
| descriptive_stats.sake | 2 | 73 | 1 | 2 | 19 | 82 | 7 | 20 |
corpus/10-grids/sokoban.sake: L106 Set.size 1: observed [["Set"]], static Integer
corpus/10-grids/sokoban.sake: L106 Set.& result: observed ["Set"], static Integer
corpus/10-grids/terrain_dijkstra.sake: L51 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/10-grids/terrain_dijkstra.sake: [79, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/terrain_dijkstra.sake: [70, 28, "Kernel.!=", "pair"]: observed [["String", "String"]] but no static check
corpus/10-grids/terrain_dijkstra.sake: [70, 51, "Kernel.!=", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| minesweeper.sake | 2 | 74 | 11 | 2 | 0 | 77 | 0 | 0 |
| n_queens.sake | 2 | 71 | 0 | 0 | 0 | 68 | 0 | 0 |
| nonogram.sake | 3 | 121 | 6 | 0 | 0 | 104 | 0 | 0 |
| othello.sake | 2 | 105 | 10 | 2 | 0 | 82 | 0 | 0 |
| sliding_puzzle.sake | 2 | 157 | 12 | 0 | 0 | 122 | 0 | 0 |
| sokoban.sake | 3 | 124 | 0 | 2 | 0 | 114 | 0 | 2 |
| sudoku_solver.sake | 2 | 98 | 3 | 1 | 0 | 86 | 0 | 0 |
| terrain_dijkstra.sake | 2 | 77 | 6 | 4 | 0 | 63 | 3 | 4 |
| tic_tac_toe.sake | 3 | 83 | 2 | 2 | 0 | 69 | 0 | 0 |
| word_search.sake | 2 | 95 | 3 | 0 | 0 | 78 | 0 | 0 |
corpus/18-collections/friend_graph.sake: L73 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/friend_graph.sake: L79 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/grade_book.sake: L27 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus/18-collections/grade_book.sake: L36 Kernel.!= pair: observed [["Float", "Nil"], ["Nil", "Nil"]], static [nil | Integer, nil]
corpus/18-collections/grade_book.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float]
corpus/18-collections/grade_book.sake: L53 Kernel.!= pair: observed [["Float", "Nil"], ["Nil", "Nil"]], static [Integer | nil, nil]
corpus/18-collections/grade_book.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer | nil]
corpus/18-collections/grade_book.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer | nil]
corpus/18-collections/grade_book.sake: L71 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/grade_book.sake: L73 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Float | Integer]
corpus/18-collections/grade_book.sake: L73 Float.clamp 1: observed [["Float"]], static Integer
corpus/18-collections/grade_book.sake: L86 Comparable.>= pair: observed [["Float", "Float"]], static [Integer | nil, Float]
corpus/18-collections/grade_book.sake: L27 Array.sum result: observed ["Integer", "Float"], static Integer
corpus/18-collections/grade_book.sake: L38 Hash.sum result: observed ["Float"], static Integer
corpus/18-collections/inventory_diff.sake: L29 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/inventory_diff.sake: L30 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/inventory_diff.sake: L31 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/inventory_diff.sake: [34, 47, "Item.get_qty", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [34, 79, "Item.get_price", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [36, 49, "Item.get_qty", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [41, 9, "Item.get_qty", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [41, 27, "Item.get_qty", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [41, 9, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/inventory_diff.sake: [42, 9, "Item.get_price", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [42, 29, "Item.get_price", 1]: observed [["Item"]] but no static check
corpus/18-collections/inventory_diff.sake: [42, 9, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/inventory_diff.sake: [43, 16, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/inventory_diff.sake: [43, 27, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/18-collections/inventory_diff.sake: [43, 27, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/inventory_diff.sake: [49, 48, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/inventory_diff.sake: [49, 22, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/inventory_diff.sake: [49, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/18-collections/inventory_diff.sake: [50, 52, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/18-collections/inventory_diff.sake: [50, 52, "Comparable.>=", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/inventory_diff.sake: [51, 21, "Array.join", 1]: observed [["Array"]] but no static check
corpus/18-collections/inventory_diff.sake: [51, 21, "Array.join", 2]: observed [["String"]] but no static check
corpus/18-collections/inventory_diff.sake: [50, 22, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/inventory_diff.sake: [50, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/18-collections/inventory_diff.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/18-collections/inventory_diff.sake: L56 Array.sum result: observed ["Float"], static Integer
corpus/18-collections/inventory_diff.sake: L57 Array.sum result: observed ["Float"], static Integer
corpus/18-collections/ip_ranges.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/latency_buckets.sake: L30 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/latency_buckets.sake: L30 Float.ceil 1: observed [["Float"]], static Integer
corpus/18-collections/latency_buckets.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/18-collections/leaderboard.sake: [68, 10, "Array.map", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [68, 34, "Hash.key?", 1]: observed [["Hash"]] but no static check
corpus/18-collections/leaderboard.sake: [69, 9, "Array.chunk_while", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [69, 43, "Kernel.==", "pair"]: observed [["Boolean", "Boolean"]] but no static check
corpus/18-collections/leaderboard.sake: [70, 32, "Array.select", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [70, 59, "Array.first", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [70, 22, "Array.map", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [70, 87, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [70, 12, "Array.max", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [71, 31, "Array.size", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [71, 11, "Range.filter_map", 1]: observed [["Range"]] but no static check
corpus/18-collections/leaderboard.sake: [71, 62, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 68, "Array.map", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 57, "Array.join", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 57, "Array.join", 2]: observed [["String"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 127, "Array.empty?", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 166, "Array.join", 1]: observed [["Array"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 166, "Array.join", 2]: observed [["String"]] but no static check
corpus/18-collections/leaderboard.sake: [72, 7, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/18-collections/library_loans.sake: L89 Float.clamp 1: observed [["Float"]], static Integer
corpus/18-collections/lottery.sake: L24 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/lottery.sake: L39 Set.sort 1: observed [["Set"]], static Integer
corpus/18-collections/lottery.sake: L57 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/lottery.sake: L59 Set.size 1: observed [["Set"]], static Integer
corpus/18-collections/prime_sets.sake: L63 Set.size 1: observed [["Set"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| friend_graph.sake | 2 | 113 | 12 | 2 | 0 | 95 | 0 | 2 |
| grade_book.sake | 2 | 110 | 8 | 1 | 0 | 82 | 0 | 12 |
| inventory_diff.sake | 2 | 73 | 3 | 5 | 0 | 91 | 21 | 27 |
| ip_ranges.sake | 2 | 119 | 16 | 3 | 0 | 109 | 0 | 1 |
| latency_buckets.sake | 2 | 95 | 2 | 1 | 0 | 77 | 0 | 3 |
| leaderboard.sake | 2 | 67 | 9 | 0 | 0 | 85 | 19 | 19 |
| library_loans.sake | 3 | 167 | 20 | 2 | 0 | 160 | 0 | 1 |
| lottery.sake | 2 | 90 | 7 | 4 | 0 | 79 | 0 | 4 |
| paginate.sake | 2 | 114 | 10 | 0 | 0 | 101 | 0 | 0 |
| prime_sets.sake | 2 | 117 | 5 | 3 | 0 | 108 | 0 | 1 |
corpus/04-numeric/monte_carlo.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L37 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L39 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L63 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L63 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/monte_carlo.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L68 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L68 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/monte_carlo.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L19 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L21 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L52 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L52 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L53 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L69 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L69 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/monte_carlo.sake: L54 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L26 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/monte_carlo.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L72 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L72 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/monte_carlo.sake: L75 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L85 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/monte_carlo.sake: L105 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/monte_carlo.sake: L105 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/monte_carlo.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L4 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L6 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/numeric_integration.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L16 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L18 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L18 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L62 Kernel.== pair: observed [["Float", "Float"]], static [Tuple, Float]
corpus/04-numeric/numeric_integration.sake: L63 Arithmetic.* pair: observed [["Float", "Float"]], static [nil, Float | Integer]
corpus/04-numeric/numeric_integration.sake: [63, 6, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Tuple]
corpus/04-numeric/numeric_integration.sake: [65, 26, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Tuple]
corpus/04-numeric/numeric_integration.sake: [65, 50, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 15, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 6, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: L68 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L75 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/numeric_integration.sake: L79 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L79 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L25 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L26 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/numeric_integration.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L33 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/numeric_integration.sake: L33 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numeric_integration.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L117 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/numeric_integration.sake: L101 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L101 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numeric_integration.sake: L125 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numeric_integration.sake: L125 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L1 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L3 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L4 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L4 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L12 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L53 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L36 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L27 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L70 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L70 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L5 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L85 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/numerical_derivatives.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/numerical_derivatives.sake: L85 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/numerical_derivatives.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/numerical_derivatives.sake: L106 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/ode_solver.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L53 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/ode_solver.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/ode_solver.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/ode_solver.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/ode_solver.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/ode_solver.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L23 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/ode_solver.sake: L23 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/ode_solver.sake: L59 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L59 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/ode_solver.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/ode_solver.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/ode_solver.sake: L61 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/ode_solver.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/ode_solver.sake: L72 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L78 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/ode_solver.sake: L75 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus/04-numeric/ode_solver.sake: L90 Float[] elem: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L91 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L92 Math.log2 1: observed [["Float"]], static Integer
corpus/04-numeric/ode_solver.sake: L38 State.set_t result: observed ["Float"], static Integer
corpus/04-numeric/ode_solver.sake: L74 State.set_t result: observed ["Float"], static Integer
corpus/04-numeric/optimization.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L97 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L97 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L97 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L18 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/optimization.sake: L23 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/optimization.sake: L23 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L23 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/optimization.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/optimization.sake: L98 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/optimization.sake: L99 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L99 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L37 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/optimization.sake: L37 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L42 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/optimization.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/optimization.sake: L42 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/optimization.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L54 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L70 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/optimization.sake: L74 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L76 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L81 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L123 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/optimization.sake: L123 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/optimization.sake: L123 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L123 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/optimization.sake: L123 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/optimization.sake: L123 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/optimization.sake: L123 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/polynomial.sake: L31 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/polynomial.sake: L53 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/polynomial.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/polynomial.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/polynomial.sake: L90 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/polynomial.sake: L91 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/polynomial.sake: L141 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/polynomial.sake: L141 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/polynomial.sake: L141 Math.cos 1: observed [["Float"]], static Integer
corpus/04-numeric/root_finding.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/root_finding.sake: L9 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L9 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L11 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L15 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/root_finding.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L31 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/root_finding.sake: [32, 11, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/root_finding.sake: [33, 4, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/root_finding.sake: [34, 45, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/04-numeric/root_finding.sake: [34, 45, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/root_finding.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L46 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L47 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/root_finding.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/root_finding.sake: L48 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/root_finding.sake: L74 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/root_finding.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L82 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L85 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/root_finding.sake: L87 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/root_finding.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L98 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/root_finding.sake: L98 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L98 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/root_finding.sake: L98 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L104 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/root_finding.sake: L34 Float.abs result: observed ["Float"], static (none)
corpus/04-numeric/special_functions.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/special_functions.sake: L22 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L22 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L22 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L22 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L90 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L90 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L93 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L15 Math.sin 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/special_functions.sake: L35 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/special_functions.sake: L35 Math.log 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L105 Math.log 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L107 Float.infinite? 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L42 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/special_functions.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/04-numeric/special_functions.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/special_functions.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L55 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/special_functions.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L113 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L70 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/special_functions.sake: L122 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L126 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/special_functions.sake: L126 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L127 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L133 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/special_functions.sake: L133 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/special_functions.sake: L139 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus/04-numeric/special_functions.sake: L75 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L75 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/special_functions.sake: L75 Math.exp 1: observed [["Float"]], static Integer
corpus/04-numeric/time_series.sake: L42 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/time_series.sake: L54 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/time_series.sake: L55 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/time_series.sake: L55 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/04-numeric/time_series.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus/04-numeric/time_series.sake: L24 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/time_series.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus/04-numeric/time_series.sake: L34 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/time_series.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/time_series.sake: L34 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/time_series.sake: L66 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/time_series.sake: L66 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/time_series.sake: L68 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/time_series.sake: L68 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus/04-numeric/time_series.sake: L109 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/time_series.sake: L110 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/time_series.sake: L110 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/04-numeric/time_series.sake: L111 Float.abs 1: observed [["Float"]], static nil | Integer
corpus/04-numeric/time_series.sake: L34 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/time_series.sake: L110 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/time_series.sake: L110 Array.sum result: observed ["Float"], static Integer
corpus/04-numeric/vector_geometry.sake: L11 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L20 Math.sqrt 1: observed [["Float"]], static Integer
corpus/04-numeric/vector_geometry.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L29 Math.atan2 2: observed [["Float"]], static Integer
corpus/04-numeric/vector_geometry.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/04-numeric/vector_geometry.sake: L32 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L32 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
corpus/04-numeric/vector_geometry.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/04-numeric/vector_geometry.sake: L78 Float.abs 1: observed [["Float"]], static Integer
corpus/04-numeric/vector_geometry.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monte_carlo.sake | 2 | 134 | 0 | 3 | 0 | 120 | 0 | 38 |
| numeric_integration.sake | 2 | 108 | 4 | 12 | 1 | 115 | 6 | 49 |
| numerical_derivatives.sake | 2 | 138 | 18 | 12 | 0 | 132 | 0 | 29 |
| ode_solver.sake | 3 | 125 | 20 | 8 | 0 | 94 | 0 | 29 |
| optimization.sake | 2 | 157 | 14 | 2 | 0 | 139 | 0 | 43 |
| polynomial.sake | 3 | 173 | 10 | 5 | 0 | 144 | 0 | 9 |
| root_finding.sake | 2 | 96 | 1 | 10 | 0 | 103 | 4 | 35 |
| special_functions.sake | 2 | 149 | 6 | 5 | 0 | 152 | 0 | 53 |
| time_series.sake | 3 | 153 | 25 | 4 | 0 | 131 | 0 | 21 |
| vector_geometry.sake | 2 | 120 | 6 | 1 | 0 | 117 | 0 | 14 |
corpus/08-graphs/currency_paths.sake: L58 Rational.to_f 1: observed [["Rational"]], static Integer
corpus/08-graphs/currency_paths.sake: L47 Kernel.!= pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/08-graphs/currency_paths.sake: L48 Rational.to_s 1: observed [["Rational"]], static Integer
corpus/08-graphs/dijkstra_routes.sake: L133 Float.round 1: observed [["Float"]], static Integer
corpus/08-graphs/exam_slots.sake: L38 Set.empty? 1: observed [["Set"]], static Integer
corpus/08-graphs/floyd_transit.sake: L39 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/08-graphs/friend_groups.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| critical_path.sake | 2 | 70 | 16 | 0 | 0 | 63 | 0 | 0 |
| currency_paths.sake | 2 | 58 | 12 | 2 | 0 | 48 | 0 | 3 |
| dijkstra_routes.sake | 3 | 88 | 6 | 1 | 0 | 68 | 0 | 1 |
| dot_stats.sake | 2 | 80 | 9 | 0 | 0 | 57 | 0 | 0 |
| euler_itinerary.sake | 2 | 61 | 2 | 0 | 0 | 49 | 0 | 0 |
| exam_slots.sake | 3 | 81 | 16 | 1 | 0 | 76 | 0 | 1 |
| floyd_transit.sake | 2 | 104 | 26 | 0 | 0 | 74 | 0 | 1 |
| friend_groups.sake | 2 | 81 | 9 | 0 | 0 | 69 | 0 | 1 |
| intern_matching.sake | 2 | 60 | 5 | 0 | 0 | 49 | 0 | 0 |
| kruskal_network.sake | 2 | 84 | 12 | 0 | 0 | 59 | 0 | 0 |
corpus/13-polymorphism/matrix_ops.sake: L55 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
corpus/13-polymorphism/matrix_ops.sake: [126, 18, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/13-polymorphism/matrix_ops.sake: L95 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, nil | Integer | Rational]
corpus/13-polymorphism/matrix_ops.sake: L95 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
corpus/13-polymorphism/matrix_ops.sake: L116 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
corpus/13-polymorphism/money_ledger.sake: L62 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/money_ledger.sake: L24 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"], ["Integer", "Integer"]], static [Integer, Float | Integer]
corpus/13-polymorphism/money_ledger.sake: L24 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/payroll.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/payroll.sake: L57 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/payroll.sake: L57 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/payroll.sake: L69 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/physical_quantities.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/polynomial.sake: L38 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [nil | Integer, Integer]
corpus/13-polymorphism/polynomial.sake: L65 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer | Rational]
corpus/13-polymorphism/polynomial.sake: L65 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Rational", "Integer"], ["Float", "Integer"]], static [Integer, Integer | Rational]
corpus/13-polymorphism/polynomial.sake: L65 Array.reduce result: observed ["Integer", "Rational", "Float"], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L18 Math.sqrt 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L29 Math.sin 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L30 Math.cos 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L30 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L30 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L30 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L53 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L54 Math.sqrt 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L44 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L45 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L55 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L86 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L86 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L16 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L120 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L67 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L71 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L4 Math.sqrt 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L4 Math.atan2 2: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L73 Math.sin 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L74 Math.sin 1: observed [["Float"]], static Integer
corpus/13-polymorphism/quaternion_rotation.sake: L75 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L75 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L128 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/quaternion_rotation.sake: L128 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/quaternion_rotation.sake: L133 Float.abs 1: observed [["Float"]], static Integer
corpus/13-polymorphism/shapes_area.sake: L19 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/shapes_area.sake: L27 Arithmetic.* pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Float, Integer]
corpus/13-polymorphism/shapes_area.sake: L35 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/shapes_area.sake: L36 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L36 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L36 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L36 Math.sqrt 1: observed [["Float"]], static Integer
corpus/13-polymorphism/shapes_area.sake: L46 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/shapes_area.sake: L46 Math.tan 1: observed [["Float"]], static Integer
corpus/13-polymorphism/shapes_area.sake: L46 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L47 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/shapes_area.sake: L84 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/shapes_area.sake: L84 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/sparse_vector.sake: L47 Kernel.== pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/sparse_vector.sake: L47 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| matrix_ops.sake | 3 | 157 | 21 | 3 | 0 | 110 | 1 | 5 |
| modint_combinatorics.sake | 2 | 149 | 5 | 2 | 0 | 124 | 0 | 0 |
| money_ledger.sake | 2 | 120 | 6 | 3 | 0 | 103 | 0 | 3 |
| notify_channels.sake | 2 | 69 | 1 | 0 | 0 | 54 | 0 | 0 |
| payroll.sake | 2 | 91 | 6 | 2 | 0 | 75 | 0 | 4 |
| physical_quantities.sake | 2 | 189 | 2 | 2 | 0 | 105 | 0 | 1 |
| polynomial.sake | 3 | 157 | 9 | 1 | 0 | 134 | 0 | 4 |
| quaternion_rotation.sake | 2 | 252 | 3 | 2 | 0 | 214 | 0 | 43 |
| shapes_area.sake | 2 | 131 | 1 | 0 | 0 | 110 | 0 | 17 |
| sparse_vector.sake | 2 | 112 | 3 | 0 | 0 | 92 | 0 | 2 |
corpus/17-encodings/lzw.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| hex_dump.sake | 2 | 76 | 2 | 2 | 0 | 67 | 0 | 0 |
| huffman.sake | 2 | 81 | 8 | 0 | 0 | 81 | 0 | 0 |
| lzw.sake | 2 | 66 | 6 | 1 | 0 | 57 | 0 | 1 |
| morse.sake | 2 | 75 | 0 | 0 | 0 | 72 | 0 | 0 |
| murmur_ring.sake | 2 | 90 | 7 | 0 | 0 | 77 | 0 | 0 |
| percent_encoding.sake | 2 | 92 | 1 | 1 | 0 | 80 | 0 | 0 |
| playfair.sake | 2 | 88 | 1 | 1 | 0 | 76 | 0 | 0 |
| protobuf_wire.sake | 2 | 113 | 8 | 5 | 0 | 96 | 0 | 0 |
| raid5_parity.sake | 3 | 118 | 7 | 1 | 0 | 110 | 0 | 0 |
| rolling_sync.sake | 2 | 128 | 9 | 2 | 0 | 104 | 0 | 0 |
corpus/06-linked/lru_cache.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/06-linked/markup_tag_checker.sake: [47, 18, "Kernel.!=", "pair"]: observed [["Frame", "Frame"]] but no static check
corpus/06-linked/markup_tag_checker.sake: [52, 18, "Frame.get_parent", 1]: observed [["Frame"]] but no static check
corpus/06-linked/markup_tag_checker.sake: L52 Frame.get_parent result: observed ["Frame", "Nil"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cycle_detection.sake | 2 | 69 | 13 | 0 | 0 | 66 | 0 | 0 |
| deque_sliding_window.sake | 3 | 91 | 10 | 0 | 0 | 87 | 0 | 0 |
| digit_list_bignum.sake | 2 | 94 | 2 | 1 | 0 | 85 | 0 | 0 |
| free_list_pool.sake | 3 | 107 | 16 | 1 | 0 | 82 | 0 | 0 |
| josephus_circle.sake | 2 | 53 | 5 | 2 | 0 | 49 | 0 | 0 |
| lfu_cache_buckets.sake | 4 | 85 | 3 | 0 | 0 | 85 | 0 | 0 |
| list_toolkit.sake | 3 | 60 | 9 | 6 | 0 | 73 | 0 | 0 |
| lru_cache.sake | 3 | 73 | 1 | 0 | 0 | 64 | 0 | 1 |
| markup_tag_checker.sake | 2 | 56 | 7 | 2 | 0 | 61 | 2 | 3 |
| merge_log_streams.sake | 3 | 81 | 6 | 1 | 0 | 69 | 0 | 0 |
corpus/08-graphs/metro_transfers.sake: L83 Kernel.== pair: observed [["String", "String"]], static [nil, nil]
corpus/08-graphs/metro_transfers.sake: L90 Array.first result: observed ["String"], static nil | [nil | String, String]
corpus/08-graphs/metro_transfers.sake: L90 Array.last result: observed ["String"], static nil | [nil | String, String]
corpus/08-graphs/prim_cables.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/08-graphs/prim_cables.sake: L82 Math.cos 1: observed [["Float"]], static Integer
corpus/08-graphs/prim_cables.sake: L82 Float.round 1: observed [["Float"]], static Integer
corpus/08-graphs/prim_cables.sake: L82 Math.sin 1: observed [["Float"]], static Integer
corpus/08-graphs/prim_cables.sake: L82 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| land_islands.sake | 2 | 104 | 6 | 0 | 0 | 87 | 0 | 0 |
| make_rebuild.sake | 2 | 62 | 6 | 0 | 0 | 55 | 0 | 0 |
| maze_bfs.sake | 2 | 51 | 6 | 0 | 0 | 45 | 0 | 0 |
| metro_transfers.sake | 2 | 78 | 8 | 0 | 0 | 65 | 0 | 3 |
| org_chart_lca.sake | 3 | 126 | 36 | 0 | 0 | 93 | 0 | 0 |
| pipeline_flow.sake | 2 | 73 | 5 | 0 | 0 | 62 | 0 | 0 |
| prim_cables.sake | 3 | 95 | 19 | 3 | 0 | 72 | 0 | 5 |
| rival_teams.sake | 2 | 57 | 3 | 0 | 0 | 41 | 0 | 0 |
| tarjan_scc.sake | 3 | 104 | 9 | 0 | 0 | 85 | 0 | 0 |
| word_ladder.sake | 2 | 50 | 4 | 0 | 0 | 40 | 0 | 0 |
corpus/03-numtheory/collatz_stats.sake: L80 Float.round 1: observed [["Float"]], static Integer
corpus/03-numtheory/continued_fractions.sake: L19 Arithmetic.+ pair: observed [["Integer", "Rational"]], static [Integer, Integer]
corpus/03-numtheory/continued_fractions.sake: L97 Float.abs 1: observed [["Float"]], static Integer
corpus/03-numtheory/egyptian_fractions.sake: L100 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/03-numtheory/egyptian_fractions.sake: L42 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus/03-numtheory/egyptian_fractions.sake: L43 Rational.denominator 1: observed [["Rational"]], static Integer
corpus/03-numtheory/egyptian_fractions.sake: [43, 55, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [43, 13, "Integer.ceildiv", 2]: observed [["Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [44, 18, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [45, 17, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [45, 13, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [45, 44, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [45, 13, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [47, 12, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [48, 13, "Arithmetic.-", "pair"]: observed [["Rational", "Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [49, 11, "Comparable.>", "pair"]: observed [["Rational", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [49, 21, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [49, 21, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [49, 52, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [49, 52, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: [50, 24, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus/03-numtheory/egyptian_fractions.sake: L43 Rational.numerator result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L43 Integer.ceildiv result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L45 Rational.denominator result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L45 Rational.numerator result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L49 Rational.numerator result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L49 Rational.denominator result: observed ["Integer"], static (none)
corpus/03-numtheory/egyptian_fractions.sake: L50 Rational.denominator result: observed ["Integer"], static (none)
corpus/03-numtheory/farey_stern_brocot.sake: L78 Float.abs 1: observed [["Float"]], static Integer
corpus/03-numtheory/farey_stern_brocot.sake: L78 Float.abs 1: observed [["Float"]], static Integer
corpus/03-numtheory/farey_stern_brocot.sake: L113 Float.abs 1: observed [["Float"]], static Integer
corpus/03-numtheory/fibonacci_numbers.sake: L110 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| base_conversion.sake | 2 | 70 | 1 | 3 | 0 | 67 | 0 | 0 |
| calendar_congruences.sake | 2 | 125 | 6 | 1 | 0 | 108 | 0 | 0 |
| check_digits.sake | 2 | 111 | 4 | 1 | 0 | 94 | 0 | 0 |
| collatz_stats.sake | 2 | 74 | 7 | 1 | 0 | 68 | 0 | 1 |
| continued_fractions.sake | 2 | 100 | 4 | 2 | 0 | 89 | 0 | 2 |
| digit_curiosities.sake | 2 | 85 | 0 | 0 | 0 | 77 | 0 | 0 |
| egyptian_fractions.sake | 2 | 121 | 4 | 2 | 0 | 124 | 15 | 25 |
| factor_functions.sake | 2 | 105 | 2 | 1 | 0 | 91 | 0 | 0 |
| farey_stern_brocot.sake | 2 | 129 | 6 | 4 | 0 | 120 | 0 | 3 |
| fibonacci_numbers.sake | 2 | 152 | 3 | 0 | 0 | 137 | 0 | 1 |
corpus/02-analytics/ngram_counts.sake: L57 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/ngram_counts.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/ngram_counts.sake: L74 Float.round 1: observed [["Float"]], static Integer
corpus/02-analytics/rake_keywords.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/rake_keywords.sake: L30 Comparable.<=> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/rake_keywords.sake: L133 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/rake_keywords.sake: L159 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/rake_keywords.sake: L102 Array.sum result: observed ["Float"], static Integer
corpus/02-analytics/rake_keywords.sake: L30 Keyword.get_score result: observed ["Float"], static Integer
corpus/02-analytics/rake_keywords.sake: L137 Keyword.get_score result: observed ["Float"], static Integer
corpus/02-analytics/rake_keywords.sake: L133 Keyword.get_score result: observed ["Float"], static Integer
corpus/02-analytics/rake_keywords.sake: L133 Keyword.get_score result: observed ["Float"], static Integer
corpus/02-analytics/rake_keywords.sake: L133 Keyword.set_score result: observed ["Float"], static Integer
corpus/02-analytics/readability.sake: L39 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/readability.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/readability.sake: L41 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/readability.sake: L41 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/readability.sake: L41 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/readability.sake: L57 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/readability.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/readability.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/readability.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/readability.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/readability.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/readability.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/readability.sake: L59 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/readability.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/sentiment_lexicon.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/sentiment_lexicon.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/sentiment_lexicon.sake: L97 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/sentiment_lexicon.sake: L48 Score.set_total result: observed ["Float"], static Integer
corpus/02-analytics/tf_idf.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/tf_idf.sake: L34 Math.log 1: observed [["Float"]], static Integer
corpus/02-analytics/tf_idf.sake: L22 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/tf_idf.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus/02-analytics/tf_idf.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/tf_idf.sake: L61 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/02-analytics/tf_idf.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/tf_idf.sake: L50 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/tf_idf.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/tf_idf.sake: L44 Math.sqrt 1: observed [["Float"]], static Integer
corpus/02-analytics/tf_idf.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/tf_idf.sake: L44 Hash.sum result: observed ["Float"], static Integer
corpus/02-analytics/vocabulary_growth.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L58 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus/02-analytics/vocabulary_growth.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/vocabulary_growth.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L40 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L40 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/02-analytics/vocabulary_growth.sake: L40 Math.exp 1: observed [["Float"]], static Integer
corpus/02-analytics/vocabulary_growth.sake: L62 Arithmetic.** pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/vocabulary_growth.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/02-analytics/vocabulary_growth.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/word_frequency.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/02-analytics/word_frequency.sake: L73 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ngram_counts.sake | 2 | 62 | 2 | 1 | 0 | 48 | 0 | 3 |
| rake_keywords.sake | 2 | 177 | 2 | 2 | 0 | 141 | 0 | 10 |
| readability.sake | 2 | 101 | 0 | 0 | 0 | 94 | 0 | 14 |
| rhyme_scheme.sake | 2 | 43 | 3 | 0 | 0 | 39 | 0 | 0 |
| sentiment_lexicon.sake | 2 | 81 | 2 | 0 | 0 | 70 | 0 | 4 |
| soundex_index.sake | 2 | 64 | 3 | 0 | 0 | 52 | 0 | 0 |
| spell_suggest.sake | 2 | 70 | 7 | 0 | 0 | 50 | 0 | 0 |
| tf_idf.sake | 2 | 99 | 4 | 0 | 0 | 87 | 0 | 12 |
| vocabulary_growth.sake | 2 | 102 | 2 | 0 | 0 | 89 | 0 | 16 |
| word_frequency.sake | 2 | 64 | 0 | 1 | 0 | 58 | 0 | 2 |
corpus/13-polymorphism/temperature_units.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L34 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/temperature_units.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L57 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/temperature_units.sake: L57 Float.round 1: observed [["Float"]], static Integer
corpus/13-polymorphism/temperature_units.sake: L50 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/temperature_units.sake: L99 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/temperature_units.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L43 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/temperature_units.sake: L106 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/temperature_units.sake: L51 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/temperature_units.sake: L55 Arithmetic.+ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus/13-polymorphism/temperature_units.sake: L11 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/temperature_units.sake: L99 Array.sum result: observed ["Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L6 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L6 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L40 Arithmetic./ pair: observed [["Vec", "Float"]], static [Vec, Integer]
corpus/13-polymorphism/vector_polygon.sake: L8 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L8 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L14 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L14 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L14 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L16 Math.sqrt 1: observed [["Integer"], ["Float"]], static Integer
corpus/13-polymorphism/vector_polygon.sake: L77 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L77 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L78 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L123 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/13-polymorphism/vector_polygon.sake: L124 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/13-polymorphism/vector_polygon.sake: L6 Vec.get_x result: observed ["Integer", "Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L6 Vec.get_y result: observed ["Integer", "Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L27 Vec.get_x result: observed ["Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L27 Vec.get_y result: observed ["Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L14 Vec.get_x result: observed ["Integer", "Float"], static Integer
corpus/13-polymorphism/vector_polygon.sake: L14 Vec.get_y result: observed ["Integer", "Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| stack_vm.sake | 3 | 120 | 7 | 3 | 0 | 98 | 0 | 0 |
| task_heap.sake | 3 | 139 | 10 | 0 | 0 | 116 | 0 | 0 |
| temperature_units.sake | 3 | 129 | 10 | 5 | 0 | 115 | 0 | 19 |
| vector_polygon.sake | 3 | 162 | 8 | 0 | 0 | 142 | 0 | 20 |
| version_constraints.sake | 3 | 118 | 6 | 4 | 0 | 107 | 0 | 0 |
| bank_transfers.sake | 2 | 66 | 1 | 0 | 0 | 56 | 0 | 0 |
| card_validation.sake | 2 | 70 | 2 | 0 | 0 | 58 | 0 | 0 |
| circuit_breaker.sake | 2 | 47 | 0 | 0 | 0 | 38 | 0 | 0 |
| config_loader.sake | 2 | 48 | 0 | 1 | 0 | 39 | 0 | 0 |
| contracts.sake | 2 | 61 | 0 | 0 | 0 | 58 | 0 | 0 |
corpus/09-dp/sequence_alignment.sake: L8 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/09-dp/viterbi.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus/09-dp/viterbi.sake: L22 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus/09-dp/viterbi.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus/09-dp/viterbi.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/09-dp/viterbi.sake: L73 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/09-dp/viterbi.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus/09-dp/viterbi.sake: L73 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/09-dp/viterbi.sake: L46 Array.sum result: observed ["Float"], static Integer
corpus/09-dp/viterbi.sake: L51 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sequence_alignment.sake | 2 | 121 | 16 | 1 | 0 | 93 | 0 | 1 |
| stock_trading.sake | 2 | 83 | 31 | 2 | 0 | 72 | 0 | 0 |
| subset_partition.sake | 2 | 76 | 7 | 0 | 0 | 57 | 0 | 0 |
| viterbi.sake | 2 | 69 | 15 | 0 | 0 | 57 | 0 | 9 |
| word_break.sake | 3 | 92 | 4 | 0 | 0 | 69 | 0 | 0 |
| battleship.sake | 3 | 112 | 2 | 0 | 0 | 94 | 0 | 0 |
| chess_attacks.sake | 2 | 99 | 0 | 2 | 0 | 85 | 0 | 0 |
| connect_four.sake | 2 | 71 | 13 | 2 | 0 | 69 | 0 | 0 |
| crossword.sake | 2 | 114 | 1 | 0 | 0 | 101 | 0 | 0 |
| falling_sand.sake | 3 | 88 | 7 | 0 | 0 | 72 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ini_config.sake | 3 | 87 | 4 | 4 | 0 | 80 | 0 | 0 |
| json_pretty.sake | 3 | 153 | 7 | 0 | 0 | 134 | 0 | 0 |
| justify_text.sake | 2 | 69 | 1 | 1 | 0 | 67 | 0 | 0 |
| line_diff.sake | 2 | 127 | 15 | 1 | 0 | 98 | 0 | 0 |
| markdown_html.sake | 2 | 102 | 6 | 1 | 0 | 99 | 0 | 0 |
| markdown_table.sake | 2 | 112 | 8 | 2 | 0 | 103 | 0 | 0 |
| number_words.sake | 2 | 88 | 1 | 0 | 0 | 73 | 0 | 0 |
| outline_number.sake | 3 | 96 | 8 | 4 | 0 | 97 | 0 | 0 |
| slugify.sake | 2 | 71 | 3 | 0 | 0 | 66 | 0 | 0 |
| spell_suggest.sake | 2 | 112 | 12 | 1 | 0 | 90 | 0 | 0 |
corpus/07-trees/traversals.sake: L94 Kernel.== pair: observed [["BT", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/07-trees/traversals.sake: [95, 8, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: L117 Kernel.== pair: observed [["Nil", "Nil"], ["BT", "Nil"]], static [nil, nil]
corpus/07-trees/traversals.sake: [117, 47, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: [118, 22, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: L95 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L117 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L117 Set.include? result: observed ["Boolean"], static (none)
corpus/07-trees/traversals.sake: L118 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L118 Set.add result: observed ["Set"], static (none)
corpus/07-trees/traversals.sake: L119 Array.push result: observed ["Array"], static (none)
corpus/08-graphs/centrality.sake: L64 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/08-graphs/centrality.sake: L64 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus/08-graphs/centrality.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus/08-graphs/centrality.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/08-graphs/centrality.sake: L78 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| spanning_tree.sake | 2 | 151 | 42 | 0 | 0 | 100 | 0 | 0 |
| taxonomy_lca.sake | 2 | 128 | 28 | 3 | 0 | 98 | 0 | 0 |
| traversals.sake | 3 | 150 | 4 | 0 | 0 | 150 | 3 | 11 |
| tree_codec.sake | 3 | 98 | 3 | 0 | 0 | 98 | 0 | 0 |
| trie_autocomplete.sake | 2 | 85 | 5 | 0 | 0 | 84 | 0 | 0 |
| astar_terrain.sake | 2 | 77 | 9 | 0 | 0 | 59 | 0 | 0 |
| bellman_ford.sake | 2 | 66 | 2 | 0 | 0 | 54 | 0 | 0 |
| centrality.sake | 2 | 104 | 11 | 0 | 0 | 77 | 0 | 5 |
| course_schedule.sake | 2 | 79 | 6 | 0 | 0 | 62 | 0 | 0 |
| critical_links.sake | 2 | 91 | 8 | 0 | 0 | 61 | 0 | 0 |
corpus/12-parsers/symbolic_diff.sake: L217 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/12-parsers/symbolic_diff.sake: L217 Float.round 1: observed [["Float"]], static Integer
corpus/12-parsers/symbolic_diff.sake: L220 Float.abs 1: observed [["Float"]], static Integer
corpus/12-parsers/type_checker.sake: [145, 80, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [145, 93, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [180, 16, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/type_checker.sake: [178, 16, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/type_checker.sake: [124, 27, "Hash.merge", 1]: observed [["Hash"]] but no static check
corpus/12-parsers/type_checker.sake: [124, 27, "Hash.merge", 2]: observed [["Hash"]] but no static check
corpus/12-parsers/type_checker.sake: [122, 53, "Kernel.==", "pair"]: observed [["Symbol", "Nil"], ["Nil", "Nil"]] but no static check
corpus/12-parsers/type_checker.sake: [164, 30, "Hash.merge", 1]: observed [["Hash"]] but no static check
corpus/12-parsers/type_checker.sake: [164, 30, "Hash.merge", 2]: observed [["Hash"]] but no static check
corpus/12-parsers/type_checker.sake: [179, 16, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/type_checker.sake: [134, 53, "Kernel.==", "pair"]: observed [["Tuple", "Nil"], ["Nil", "Nil"]] but no static check
corpus/12-parsers/type_checker.sake: [137, 69, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [148, 77, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [148, 90, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [169, 18, "String.size", 1]: observed [["String"]] but no static check
corpus/12-parsers/type_checker.sake: [170, 19, "Integer.to_s", 1]: observed [["Integer"]] but no static check
corpus/12-parsers/type_checker.sake: [181, 17, "Arithmetic.+", "pair"]: observed [["String", "String"]] but no static check
corpus/12-parsers/type_checker.sake: [151, 76, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [151, 89, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [127, 65, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [130, 62, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [182, 16, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/type_checker.sake: [172, 21, "String.upcase", 1]: observed [["String"]] but no static check
corpus/12-parsers/type_checker.sake: [154, 63, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/12-parsers/type_checker.sake: [183, 17, "Kernel.==", "pair"]: observed [["Integer", "Integer"], ["String", "String"]] but no static check
corpus/12-parsers/type_checker.sake: [171, 18, "Kernel.==", "pair"]: observed [["Boolean", "Boolean"]] but no static check
corpus/12-parsers/type_checker.sake: L188 Kernel.to_s result: observed ["String"], static (none)
corpus/12-parsers/type_checker.sake: L188 Kernel.inspect result: observed ["String"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| rpn_calc.sake | 3 | 83 | 7 | 0 | 0 | 79 | 0 | 0 |
| shunting_yard.sake | 3 | 60 | 6 | 0 | 0 | 61 | 0 | 0 |
| stack_vm.sake | 2 | 98 | 19 | 1 | 0 | 86 | 0 | 0 |
| symbolic_diff.sake | 4 | 90 | 11 | 7 | 0 | 90 | 0 | 3 |
| template_engine.sake | 3 | 103 | 10 | 2 | 0 | 86 | 0 | 0 |
| tiny_basic.sake | 3 | 130 | 25 | 1 | 0 | 132 | 0 | 0 |
| tokenizer.sake | 2 | 121 | 1 | 0 | 0 | 84 | 0 | 0 |
| truth_table.sake | 3 | 89 | 0 | 5 | 0 | 77 | 0 | 0 |
| turing_machine.sake | 2 | 66 | 10 | 3 | 0 | 59 | 0 | 0 |
| type_checker.sake | 3 | 44 | 0 | 1 | 0 | 64 | 26 | 28 |
corpus/14-errors/quote_fallback.sake: L74 Float.round 1: observed [["Float"]], static Integer
corpus/14-errors/unit_quantities.sake: L37 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| order_lifecycle.sake | 2 | 32 | 4 | 0 | 0 | 33 | 0 | 0 |
| param_coercion.sake | 2 | 53 | 1 | 1 | 0 | 45 | 0 | 0 |
| password_policy.sake | 2 | 94 | 0 | 0 | 0 | 88 | 0 | 0 |
| quote_fallback.sake | 2 | 48 | 2 | 1 | 0 | 45 | 0 | 1 |
| registration_form.sake | 2 | 80 | 2 | 0 | 0 | 74 | 0 | 0 |
| result_pipeline.sake | 2 | 68 | 1 | 0 | 0 | 36 | 0 | 0 |
| retry_backoff.sake | 2 | 44 | 3 | 1 | 0 | 40 | 0 | 0 |
| spreadsheet_errors.sake | 3 | 80 | 12 | 3 | 0 | 75 | 0 | 0 |
| unit_quantities.sake | 2 | 60 | 7 | 3 | 0 | 52 | 0 | 1 |
| warehouse_reservation.sake | 2 | 68 | 2 | 0 | 0 | 63 | 0 | 0 |
corpus/07-trees/huffman.sake: L96 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L7 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L31 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L25 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/07-trees/kd_tree.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L33 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus/07-trees/kd_tree.sake: L49 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L40 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L52 Kernel.== pair: observed [["Float", "Nil"]], static [Integer | nil, nil]
corpus/07-trees/kd_tree.sake: L52 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L52 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus/07-trees/kd_tree.sake: L114 Math.sqrt 1: observed [["Float"]], static Integer
corpus/07-trees/kd_tree.sake: L27 Search.set_best_d2 result: observed ["Float"], static Integer
corpus/07-trees/lazy_seat_inventory.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| huffman.sake | 3 | 77 | 9 | 0 | 0 | 78 | 0 | 1 |
| interval_bookings.sake | 3 | 95 | 2 | 0 | 0 | 89 | 0 | 0 |
| ip_route_trie.sake | 2 | 103 | 16 | 2 | 0 | 104 | 0 | 0 |
| kd_tree.sake | 3 | 123 | 14 | 0 | 0 | 125 | 0 | 14 |
| lazy_seat_inventory.sake | 2 | 150 | 12 | 0 | 0 | 126 | 0 | 1 |
| merkle_sync.sake | 3 | 85 | 6 | 2 | 0 | 68 | 0 | 0 |
| org_chart.sake | 3 | 119 | 12 | 2 | 0 | 113 | 0 | 0 |
| quadtree.sake | 3 | 126 | 19 | 1 | 0 | 130 | 0 | 0 |
| rope_editor.sake | 3 | 60 | 13 | 1 | 0 | 58 | 0 | 0 |
| segment_tree_stats.sake | 2 | 145 | 8 | 1 | 0 | 97 | 0 | 0 |
corpus/03-numtheory/integer_partitions.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus/03-numtheory/integer_partitions.sake: L89 Math.sqrt 1: observed [["Float"]], static Integer
corpus/03-numtheory/integer_partitions.sake: L89 Math.exp 1: observed [["Float"]], static Integer
corpus/03-numtheory/integer_partitions.sake: L89 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus/03-numtheory/integer_partitions.sake: L90 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus/03-numtheory/linear_sieve.sake: L71 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/03-numtheory/linear_sieve.sake: L80 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus/03-numtheory/linear_sieve.sake: L80 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| goldbach.sake | 2 | 90 | 4 | 0 | 0 | 72 | 0 | 0 |
| happy_cycles.sake | 2 | 76 | 4 | 0 | 0 | 68 | 0 | 0 |
| integer_partitions.sake | 2 | 130 | 7 | 0 | 0 | 100 | 0 | 5 |
| linear_diophantine.sake | 2 | 94 | 0 | 2 | 0 | 70 | 0 | 0 |
| linear_sieve.sake | 2 | 141 | 20 | 1 | 0 | 96 | 0 | 3 |
| miller_rabin.sake | 2 | 85 | 0 | 0 | 0 | 82 | 0 | 0 |
| modular_crt.sake | 2 | 109 | 0 | 2 | 0 | 95 | 0 | 0 |
| perfect_amicable.sake | 2 | 77 | 10 | 1 | 0 | 63 | 0 | 0 |
| pollard_rho.sake | 3 | 116 | 0 | 1 | 0 | 108 | 0 | 0 |
| primitive_roots.sake | 2 | 138 | 2 | 1 | 0 | 132 | 0 | 0 |
