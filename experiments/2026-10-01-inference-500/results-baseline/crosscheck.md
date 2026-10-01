corpus/09-dp/floyd_warshall.sake: [29, 7, "Kernel.==", "pair"]: observed [["Nil", "Nil"]] but no static check
corpus/09-dp/floyd_warshall.sake: [60, 16, "Kernel.==", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/09-dp/floyd_warshall.sake: L64 Array.push result: observed ["Array"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| coin_change.sake | 2 | 69 | 2 | 3 | 0 | 58 | 0 | 0 |
| company_party.sake | 3 | 70 | 2 | 5 | 0 | 52 | 0 | 0 |
| critical_path.sake | 2 | 83 | 17 | 2 | 0 | 64 | 0 | 0 |
| decode_ways.sake | 3 | 95 | 10 | 0 | 0 | 83 | 0 | 0 |
| dice_odds.sake | 2 | 71 | 9 | 0 | 0 | 69 | 0 | 0 |
| digit_counting.sake | 2 | 63 | 2 | 0 | 0 | 53 | 0 | 0 |
| edit_distance.sake | 2 | 100 | 17 | 0 | 0 | 96 | 0 | 0 |
| egg_drop.sake | 2 | 61 | 18 | 1 | 0 | 60 | 0 | 0 |
| floyd_warshall.sake | 2 | 74 | 12 | 7 | 0 | 64 | 2 | 3 |
| grid_paths.sake | 2 | 95 | 20 | 0 | 0 | 86 | 0 | 0 |
corpus/06-linked/deque_sliding_window.sake: [97, 43, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/deque_sliding_window.sake: L101 Array.push result: observed ["Array"], static (none)
corpus/06-linked/free_list_pool.sake: [37, 93, "Kernel.==", "pair"]: observed [["Boolean", "Boolean"]] but no static check
corpus/06-linked/free_list_pool.sake: [40, 7, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/free_list_pool.sake: [45, 25, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/free_list_pool.sake: [103, 40, "String.delete", 1]: observed [["String"]] but no static check
corpus/06-linked/free_list_pool.sake: [103, 30, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/free_list_pool.sake: L103 String.delete result: observed ["String"], static (none)
corpus/06-linked/markup_tag_checker.sake: [47, 18, "Kernel.!=", "pair"]: observed [["Frame", "Frame"]] but no static check
corpus/06-linked/markup_tag_checker.sake: [52, 18, "Frame.get_parent", 1]: observed [["Frame"]] but no static check
corpus/06-linked/markup_tag_checker.sake: L52 Frame.get_parent result: observed ["Frame", "Nil"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cycle_detection.sake | 2 | 60 | 19 | 0 | 0 | 66 | 0 | 0 |
| deque_sliding_window.sake | 3 | 89 | 7 | 2 | 0 | 87 | 1 | 2 |
| digit_list_bignum.sake | 2 | 96 | 0 | 1 | 0 | 85 | 0 | 0 |
| free_list_pool.sake | 3 | 91 | 6 | 8 | 0 | 82 | 5 | 6 |
| josephus_circle.sake | 2 | 45 | 11 | 2 | 0 | 49 | 0 | 0 |
| lfu_cache_buckets.sake | 4 | 77 | 11 | 0 | 0 | 85 | 0 | 0 |
| list_toolkit.sake | 3 | 56 | 12 | 7 | 0 | 73 | 0 | 0 |
| lru_cache.sake | 3 | 71 | 1 | 0 | 0 | 64 | 0 | 0 |
| markup_tag_checker.sake | 2 | 51 | 11 | 2 | 0 | 61 | 2 | 3 |
| merge_log_streams.sake | 3 | 76 | 7 | 1 | 0 | 69 | 0 | 0 |
corpus/08-graphs/euler_itinerary.sake: [10, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [11, 4, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [18, 46, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [19, 44, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [20, 41, "Integer.abs", 1]: observed [["Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [20, 41, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [34, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/08-graphs/euler_itinerary.sake: [36, 45, "Array.sort", 1]: observed [["Array"]] but no static check
corpus/08-graphs/euler_itinerary.sake: L20 Array.find result: observed ["Nil", "String"], static nil
corpus/08-graphs/euler_itinerary.sake: L43 Array.shift result: observed ["String"], static nil
corpus/08-graphs/euler_itinerary.sake: L21 NoItinerary.new result: observed ["NoItinerary"], static (none)
corpus/08-graphs/floyd_transit.sake: [49, 16, "Kernel.==", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/08-graphs/floyd_transit.sake: [53, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/08-graphs/floyd_transit.sake: [85, 52, "Array.join", 1]: observed [["Array"]] but no static check
corpus/08-graphs/floyd_transit.sake: L50 Array[] result: observed ["Array"], static (none)
corpus/08-graphs/floyd_transit.sake: L53 Array.push result: observed ["Array"], static (none)
corpus/08-graphs/floyd_transit.sake: L85 Array.join result: observed ["String"], static (none)
corpus/08-graphs/kruskal_network.sake: [35, 8, "Edge.get_cost", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [35, 18, "Edge.get_cost", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [35, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [36, 16, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [37, 7, "Edge.get_a", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [37, 13, "Edge.get_b", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [37, 25, "Edge.get_a", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [37, 46, "Edge.get_b", 1]: observed [["Edge"]] but no static check
corpus/08-graphs/kruskal_network.sake: [37, 4, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
corpus/08-graphs/kruskal_network.sake: [9, 31, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [10, 10, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [22, 7, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [26, 22, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/kruskal_network.sake: [26, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| critical_path.sake | 2 | 66 | 20 | 0 | 0 | 63 | 0 | 0 |
| currency_paths.sake | 2 | 60 | 12 | 0 | 0 | 48 | 0 | 0 |
| dijkstra_routes.sake | 3 | 85 | 6 | 0 | 0 | 68 | 0 | 0 |
| dot_stats.sake | 2 | 79 | 9 | 0 | 0 | 57 | 0 | 0 |
| euler_itinerary.sake | 2 | 40 | 1 | 0 | 2 | 49 | 8 | 11 |
| exam_slots.sake | 3 | 82 | 16 | 0 | 0 | 76 | 0 | 0 |
| floyd_transit.sake | 2 | 81 | 10 | 8 | 0 | 74 | 3 | 6 |
| friend_groups.sake | 2 | 80 | 9 | 0 | 0 | 69 | 0 | 0 |
| intern_matching.sake | 2 | 53 | 6 | 0 | 0 | 49 | 0 | 0 |
| kruskal_network.sake | 2 | 62 | 1 | 9 | 0 | 59 | 14 | 14 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expr_lexer.sake | 2 | 66 | 0 | 2 | 0 | 57 | 0 | 0 |
| http_parser.sake | 3 | 135 | 16 | 6 | 0 | 138 | 0 | 0 |
| job_pipeline.sake | 3 | 86 | 4 | 0 | 0 | 82 | 0 | 0 |
| keypad_lock.sake | 2 | 95 | 0 | 1 | 0 | 67 | 0 | 0 |
| machine_mixin.sake | 2 | 66 | 0 | 1 | 0 | 59 | 0 | 0 |
| markdown_blocks.sake | 3 | 112 | 4 | 1 | 0 | 105 | 0 | 0 |
| morse_decoder.sake | 2 | 79 | 5 | 0 | 0 | 70 | 0 | 0 |
| order_workflow.sake | 2 | 79 | 0 | 1 | 0 | 69 | 0 | 0 |
| regex_nfa.sake | 2 | 94 | 25 | 0 | 0 | 111 | 0 | 0 |
| shell_words.sake | 2 | 66 | 2 | 1 | 0 | 63 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| access_log_report.sake | 2 | 112 | 7 | 0 | 0 | 103 | 0 | 0 |
| bank_reconcile.sake | 2 | 118 | 3 | 0 | 0 | 115 | 0 | 0 |
| budget_variance.sake | 2 | 53 | 0 | 0 | 0 | 41 | 0 | 0 |
| clickstream_sessions.sake | 3 | 117 | 4 | 2 | 0 | 114 | 0 | 0 |
| cohort_retention.sake | 2 | 95 | 6 | 1 | 0 | 95 | 0 | 0 |
| csv_import_validation.sake | 2 | 96 | 8 | 0 | 0 | 95 | 0 | 0 |
| customer_dedupe.sake | 3 | 130 | 0 | 0 | 0 | 107 | 0 | 0 |
| employee_dept_join.sake | 2 | 87 | 9 | 0 | 0 | 89 | 0 | 0 |
| etl_star_schema.sake | 2 | 165 | 3 | 0 | 0 | 130 | 0 | 0 |
| expense_pivot.sake | 3 | 95 | 2 | 0 | 0 | 78 | 0 | 0 |
corpus/14-errors/expr_calculator.sake: [107, 17, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [99, 57, "Kernel.==", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/14-errors/expr_calculator.sake: [106, 17, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [109, 53, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 6, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 21, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [105, 17, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/expr_calculator.sake: [110, 29, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/log_triage.sake: L63 Kernel.!= pair: observed [["String", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/14-errors/log_triage.sake: [63, 17, "String.to_i", 1]: observed [["String"]] but no static check
corpus/14-errors/log_triage.sake: [63, 17, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/14-errors/log_triage.sake: L63 String.to_i result: observed ["Integer"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_import.sake | 2 | 64 | 12 | 0 | 0 | 59 | 0 | 0 |
| dependency_resolver.sake | 3 | 31 | 2 | 0 | 0 | 27 | 0 | 0 |
| error_wrapping.sake | 2 | 49 | 0 | 0 | 0 | 40 | 0 | 0 |
| expr_calculator.sake | 3 | 80 | 10 | 1 | 1 | 85 | 8 | 8 |
| http_error_mapping.sake | 2 | 62 | 1 | 0 | 0 | 46 | 0 | 0 |
| job_queue.sake | 2 | 86 | 0 | 1 | 0 | 79 | 0 | 0 |
| ledger_reconcile.sake | 2 | 72 | 3 | 0 | 0 | 63 | 0 | 0 |
| log_triage.sake | 2 | 61 | 8 | 0 | 0 | 60 | 2 | 4 |
| matrix_checks.sake | 3 | 102 | 5 | 2 | 0 | 77 | 0 | 0 |
| nested_schema.sake | 2 | 36 | 8 | 1 | 0 | 40 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| huffman.sake | 3 | 76 | 9 | 0 | 0 | 78 | 0 | 0 |
| interval_bookings.sake | 3 | 93 | 2 | 0 | 0 | 89 | 0 | 0 |
| ip_route_trie.sake | 2 | 92 | 20 | 2 | 0 | 104 | 0 | 0 |
| kd_tree.sake | 3 | 115 | 17 | 0 | 0 | 125 | 0 | 0 |
| lazy_seat_inventory.sake | 2 | 136 | 12 | 0 | 0 | 126 | 0 | 0 |
| merkle_sync.sake | 3 | 76 | 6 | 2 | 0 | 68 | 0 | 0 |
| org_chart.sake | 3 | 112 | 13 | 2 | 0 | 113 | 0 | 0 |
| quadtree.sake | 3 | 123 | 19 | 1 | 0 | 130 | 0 | 0 |
| rope_editor.sake | 3 | 50 | 18 | 1 | 0 | 58 | 0 | 0 |
| segment_tree_stats.sake | 2 | 127 | 8 | 1 | 0 | 97 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| base_conversion.sake | 2 | 69 | 1 | 3 | 0 | 67 | 0 | 0 |
| calendar_congruences.sake | 2 | 120 | 6 | 1 | 0 | 108 | 0 | 0 |
| check_digits.sake | 2 | 102 | 5 | 1 | 0 | 94 | 0 | 0 |
| collatz_stats.sake | 2 | 73 | 7 | 0 | 0 | 68 | 0 | 0 |
| continued_fractions.sake | 2 | 101 | 3 | 1 | 0 | 89 | 0 | 0 |
| digit_curiosities.sake | 2 | 85 | 0 | 0 | 0 | 77 | 0 | 0 |
| egyptian_fractions.sake | 2 | 140 | 1 | 1 | 0 | 124 | 0 | 0 |
| factor_functions.sake | 2 | 100 | 2 | 1 | 0 | 91 | 0 | 0 |
| farey_stern_brocot.sake | 2 | 124 | 10 | 1 | 0 | 120 | 0 | 0 |
| fibonacci_numbers.sake | 2 | 147 | 3 | 0 | 0 | 137 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| teller_queue_des.sake | 2 | 132 | 19 | 1 | 0 | 122 | 0 | 0 |
| thermostat_house.sake | 2 | 94 | 2 | 0 | 0 | 77 | 0 | 0 |
| traffic_intersection.sake | 2 | 109 | 4 | 0 | 0 | 92 | 0 | 0 |
| vending_machine.sake | 2 | 120 | 4 | 0 | 0 | 109 | 0 | 0 |
| water_tanks.sake | 2 | 100 | 28 | 0 | 0 | 112 | 0 | 0 |
| assembler.sake | 2 | 117 | 28 | 11 | 0 | 88 | 0 | 0 |
| brainfuck.sake | 2 | 68 | 4 | 0 | 0 | 50 | 0 | 0 |
| calc_rd.sake | 4 | 120 | 14 | 0 | 0 | 123 | 0 | 0 |
| chem_formula.sake | 3 | 76 | 11 | 4 | 0 | 71 | 0 | 0 |
| cmdline_parser.sake | 2 | 82 | 15 | 1 | 0 | 81 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| restaurant_orders.sake | 2 | 100 | 4 | 1 | 0 | 95 | 0 | 0 |
| room_reservations.sake | 3 | 102 | 5 | 3 | 0 | 101 | 0 | 0 |
| sales_report.sake | 2 | 118 | 12 | 0 | 0 | 115 | 0 | 0 |
| shopping_cart.sake | 3 | 136 | 3 | 1 | 0 | 125 | 0 | 0 |
| subscription_billing.sake | 2 | 105 | 2 | 1 | 0 | 91 | 0 | 0 |
| ticket_helpdesk.sake | 3 | 97 | 4 | 2 | 0 | 95 | 0 | 0 |
| timesheet.sake | 2 | 79 | 13 | 0 | 0 | 81 | 0 | 0 |
| todo_list.sake | 2 | 102 | 2 | 1 | 0 | 96 | 0 | 0 |
| vendor_quotes.sake | 2 | 82 | 4 | 0 | 0 | 79 | 0 | 0 |
| warehouse_picking.sake | 2 | 96 | 13 | 1 | 0 | 99 | 0 | 0 |
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
| rpn_calc.sake | 3 | 82 | 7 | 0 | 0 | 79 | 0 | 0 |
| shunting_yard.sake | 2 | 42 | 3 | 0 | 19 | 61 | 0 | 0 |
| stack_vm.sake | 2 | 90 | 18 | 3 | 0 | 86 | 0 | 0 |
| symbolic_diff.sake | 4 | 68 | 0 | 0 | 32 | 90 | 0 | 0 |
| template_engine.sake | 3 | 93 | 10 | 1 | 0 | 86 | 0 | 0 |
| tiny_basic.sake | 3 | 93 | 9 | 1 | 46 | 132 | 0 | 0 |
| tokenizer.sake | 2 | 106 | 1 | 0 | 0 | 84 | 0 | 0 |
| truth_table.sake | 3 | 85 | 0 | 5 | 0 | 77 | 0 | 0 |
| turing_machine.sake | 2 | 66 | 10 | 3 | 0 | 59 | 0 | 0 |
| type_checker.sake | 3 | 19 | 0 | 1 | 21 | 64 | 26 | 28 |
corpus/13-polymorphism/sparse_vector.sake: [65, 8, "Ranked.get_count", 1]: observed [["Ranked"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [65, 32, "Ranked.get_count", 1]: observed [["Ranked"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [65, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [66, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [66, 13, "Ranked.get_key", 1]: observed [["Ranked"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [66, 22, "Ranked.get_key", 1]: observed [["Ranked"]] but no static check
corpus/13-polymorphism/sparse_vector.sake: [66, 13, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| matrix_ops.sake | 3 | 151 | 21 | 3 | 0 | 110 | 0 | 0 |
| modint_combinatorics.sake | 2 | 143 | 5 | 2 | 0 | 124 | 0 | 0 |
| money_ledger.sake | 2 | 121 | 4 | 1 | 0 | 103 | 0 | 0 |
| notify_channels.sake | 2 | 68 | 1 | 0 | 0 | 54 | 0 | 0 |
| payroll.sake | 2 | 93 | 5 | 0 | 0 | 75 | 0 | 0 |
| physical_quantities.sake | 2 | 154 | 2 | 2 | 3 | 105 | 0 | 0 |
| polynomial.sake | 3 | 151 | 9 | 1 | 0 | 134 | 0 | 0 |
| quaternion_rotation.sake | 2 | 248 | 5 | 0 | 0 | 214 | 0 | 0 |
| shapes_area.sake | 2 | 130 | 1 | 0 | 0 | 110 | 0 | 0 |
| sparse_vector.sake | 2 | 91 | 2 | 0 | 10 | 92 | 7 | 7 |
corpus/08-graphs/metro_transfers.sake: L83 Kernel.== pair: observed [["String", "String"]], static [nil, nil]
corpus/08-graphs/metro_transfers.sake: L90 Array.first result: observed ["String"], static nil | nil | [nil | String, String]
corpus/08-graphs/metro_transfers.sake: L90 Array.last result: observed ["String"], static nil | nil | [nil | String, String]
corpus/08-graphs/org_chart_lca.sake: [23, 32, "Array.push", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [30, 6, "Array.each", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [31, 19, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [32, 8, "Array.push", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [66, 10, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [68, 6, "Array.push", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [96, 17, "Array.join", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [62, 38, "Array.map", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [62, 28, "Array.sum", 1]: observed [["Array"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [62, 24, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [53, 9, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/org_chart_lca.sake: [58, 18, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/org_chart_lca.sake: L23 Array.push result: observed ["Array"], static (none)
corpus/08-graphs/org_chart_lca.sake: L30 Array.each result: observed ["Array"], static (none)
corpus/08-graphs/org_chart_lca.sake: L65 Array[] result: observed ["Array"], static (none)
corpus/08-graphs/org_chart_lca.sake: L68 Array.push result: observed ["Array"], static (none)
corpus/08-graphs/org_chart_lca.sake: L96 Array.join result: observed ["String"], static (none)
corpus/08-graphs/org_chart_lca.sake: L62 Array.map result: observed ["Array"], static (none)
corpus/08-graphs/org_chart_lca.sake: L62 Array.sum result: observed ["Integer"], static (none)
corpus/08-graphs/org_chart_lca.sake: L98 Kernel.format result: observed ["String"], static (none)
corpus/08-graphs/org_chart_lca.sake: L98 Kernel.puts result: observed ["Nil"], static (none)
corpus/08-graphs/prim_cables.sake: [14, 30, "Site.get_pos", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: [14, 30, "Arithmetic.-", "pair"]: observed [["Point", "Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 26, "Point.get_x", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 31, "Point.get_x", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 26, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 47, "Point.get_y", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 52, "Point.get_y", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [6, 47, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [8, 29, "Point.get_x", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [8, 33, "Point.get_y", 1]: observed [["Point"]] but no static check
corpus/08-graphs/prim_cables.sake: [8, 18, "Math.hypot", 1]: observed [["Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [8, 18, "Math.hypot", 2]: observed [["Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [28, 27, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [35, 27, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [56, 4, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/08-graphs/prim_cables.sake: [57, 42, "Site.get_name", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: [57, 67, "Site.get_name", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: [63, 40, "Site.get_name", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: [63, 65, "Site.get_name", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: [67, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/08-graphs/prim_cables.sake: [71, 30, "Site.get_name", 1]: observed [["Site"]] but no static check
corpus/08-graphs/prim_cables.sake: L14 Site.get_pos result: observed ["Point"], static (none)
corpus/08-graphs/prim_cables.sake: L8 Math.hypot result: observed ["Float"], static (none)
corpus/08-graphs/prim_cables.sake: L57 Site.get_name result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L57 Site.get_name result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L57 Kernel.format result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L57 Kernel.puts result: observed ["Nil"], static (none)
corpus/08-graphs/prim_cables.sake: L63 Site.get_name result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L63 Site.get_name result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L63 Kernel.format result: observed ["String"], static (none)
corpus/08-graphs/prim_cables.sake: L63 Kernel.puts result: observed ["Nil"], static (none)
corpus/08-graphs/prim_cables.sake: L71 Site.get_name result: observed ["String"], static (none)
corpus/08-graphs/tarjan_scc.sake: [97, 12, "Array.join", 1]: observed [["Array"]] but no static check
corpus/08-graphs/tarjan_scc.sake: [97, 43, "Array.join", 1]: observed [["Array"]] but no static check
corpus/08-graphs/tarjan_scc.sake: L97 Array.join result: observed ["String"], static (none)
corpus/08-graphs/tarjan_scc.sake: L97 Array.join result: observed ["String"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| land_islands.sake | 2 | 102 | 6 | 0 | 0 | 87 | 0 | 0 |
| make_rebuild.sake | 2 | 62 | 6 | 0 | 0 | 55 | 0 | 0 |
| maze_bfs.sake | 2 | 48 | 6 | 0 | 0 | 45 | 0 | 0 |
| metro_transfers.sake | 2 | 74 | 9 | 0 | 0 | 65 | 0 | 3 |
| org_chart_lca.sake | 2 | 97 | 5 | 14 | 0 | 93 | 12 | 21 |
| pipeline_flow.sake | 2 | 73 | 5 | 0 | 0 | 62 | 0 | 0 |
| prim_cables.sake | 2 | 65 | 1 | 8 | 0 | 72 | 21 | 32 |
| rival_teams.sake | 2 | 57 | 3 | 0 | 0 | 41 | 0 | 0 |
| tarjan_scc.sake | 3 | 102 | 5 | 2 | 0 | 85 | 2 | 4 |
| word_ladder.sake | 2 | 44 | 6 | 0 | 0 | 40 | 0 | 0 |
corpus/11-simulation/elevator_scan.sake: L30 Array.empty? 1: observed [["Array"]], static Set@L29[Integer]
corpus/11-simulation/elevator_scan.sake: L29 Set.select result: observed ["Array"], static Set@L29[Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bakery_shift.sake | 2 | 87 | 15 | 0 | 0 | 89 | 0 | 0 |
| bank_ledger.sake | 2 | 100 | 0 | 1 | 0 | 80 | 0 | 0 |
| car_rental.sake | 2 | 122 | 3 | 0 | 0 | 115 | 0 | 0 |
| checkout_lanes.sake | 3 | 100 | 1 | 0 | 0 | 83 | 0 | 0 |
| cpu_scheduler.sake | 2 | 102 | 2 | 0 | 0 | 90 | 0 | 0 |
| ecosystem_patches.sake | 2 | 135 | 0 | 0 | 0 | 125 | 0 | 0 |
| elevator_scan.sake | 2 | 161 | 6 | 1 | 0 | 164 | 0 | 2 |
| epidemic_network.sake | 2 | 112 | 9 | 0 | 0 | 98 | 0 | 0 |
| forest_fire.sake | 2 | 87 | 8 | 2 | 0 | 78 | 0 | 0 |
| hotel_bookings.sake | 3 | 131 | 1 | 1 | 0 | 123 | 0 | 0 |
corpus/16-dates/timetable.sake: [48, 4, "Kernel.!=", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/16-dates/timetable.sake: [48, 18, "Kernel.!=", "pair"]: observed [["Integer", "Nil"], ["Nil", "Nil"]] but no static check
corpus/16-dates/timetable.sake: [48, 32, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [57, 34, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [83, 11, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [16, 37, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [16, 36, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [16, 51, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [85, 79, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [104, 42, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [112, 8, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: [113, 29, "Kernel.==", "pair"]: observed [["Nil", "Nil"], ["Tuple", "Nil"]] but no static check
corpus/16-dates/timetable.sake: [113, 46, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/timetable.sake: L16 Kernel.format result: observed ["String"], static (none)
corpus/16-dates/timetable.sake: L84 Kernel.format result: observed ["String"], static (none)
corpus/16-dates/timetable.sake: L84 Kernel.puts result: observed ["Nil"], static (none)
corpus/16-dates/timetable.sake: L97 Kernel.format result: observed ["String"], static (none)
corpus/16-dates/timetable.sake: L97 Kernel.puts result: observed ["Nil"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| moon_phases.sake | 2 | 151 | 1 | 0 | 0 | 143 | 0 | 0 |
| parking_fees.sake | 2 | 106 | 17 | 0 | 0 | 106 | 0 | 0 |
| project_gantt.sake | 2 | 160 | 8 | 2 | 0 | 154 | 0 | 0 |
| public_holidays.sake | 2 | 164 | 0 | 1 | 0 | 156 | 0 | 0 |
| recurring_events.sake | 2 | 132 | 14 | 0 | 0 | 134 | 0 | 0 |
| room_booking.sake | 2 | 109 | 0 | 4 | 0 | 94 | 0 | 0 |
| shift_rota.sake | 3 | 112 | 4 | 0 | 0 | 100 | 0 | 0 |
| time_zones.sake | 2 | 138 | 0 | 1 | 0 | 131 | 0 | 0 |
| timesheet.sake | 3 | 131 | 14 | 2 | 0 | 128 | 0 | 0 |
| timetable.sake | 2 | 52 | 0 | 2 | 0 | 64 | 13 | 18 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii85.sake | 2 | 103 | 1 | 5 | 0 | 96 | 0 | 0 |
| base32_ids.sake | 2 | 81 | 5 | 3 | 0 | 74 | 0 | 0 |
| base64_codec.sake | 2 | 63 | 7 | 2 | 0 | 61 | 0 | 0 |
| bitset.sake | 2 | 119 | 1 | 2 | 0 | 104 | 0 | 0 |
| bloom_filter.sake | 2 | 82 | 2 | 0 | 0 | 78 | 0 | 0 |
| caesar_cracker.sake | 2 | 52 | 3 | 0 | 0 | 46 | 0 | 0 |
| check_digits.sake | 2 | 79 | 0 | 1 | 0 | 72 | 0 | 0 |
| crc_catalog.sake | 2 | 82 | 13 | 0 | 0 | 89 | 0 | 0 |
| frame_parser.sake | 2 | 148 | 18 | 0 | 0 | 133 | 0 | 0 |
| hamming_secded.sake | 2 | 87 | 0 | 1 | 0 | 76 | 0 | 0 |
corpus/05-sorting/external_sort_sim.sake: L69 Array.push result: observed ["Array"], static (none)
corpus/05-sorting/hashtag_trends.sake: [10, 8, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [10, 31, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [10, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [11, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [11, 13, "Tally.get_tag", 1]: observed [["Tally"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [11, 22, "Tally.get_tag", 1]: observed [["Tally"]] but no static check
corpus/05-sorting/hashtag_trends.sake: [11, 13, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| autocomplete_msd.sake | 2 | 65 | 29 | 1 | 0 | 76 | 0 | 0 |
| bisect_on_answer.sake | 2 | 79 | 13 | 1 | 0 | 79 | 0 | 0 |
| bucket_sort_ratings.sake | 2 | 91 | 11 | 3 | 0 | 94 | 0 | 0 |
| external_sort_sim.sake | 2 | 96 | 20 | 6 | 0 | 100 | 0 | 1 |
| gift_two_pointers.sake | 2 | 96 | 20 | 1 | 0 | 94 | 0 | 0 |
| gradebook_insertion.sake | 2 | 62 | 7 | 0 | 0 | 57 | 0 | 0 |
| hashtag_trends.sake | 2 | 60 | 6 | 0 | 1 | 63 | 7 | 7 |
| heap_scheduler.sake | 3 | 92 | 6 | 0 | 0 | 74 | 0 | 0 |
| kway_log_merge.sake | 2 | 124 | 14 | 0 | 0 | 108 | 0 | 0 |
| leaderboard_insert.sake | 3 | 75 | 7 | 1 | 0 | 74 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| order_lifecycle.sake | 2 | 32 | 4 | 0 | 0 | 33 | 0 | 0 |
| param_coercion.sake | 2 | 52 | 1 | 1 | 0 | 45 | 0 | 0 |
| password_policy.sake | 2 | 93 | 0 | 0 | 0 | 88 | 0 | 0 |
| quote_fallback.sake | 2 | 48 | 2 | 0 | 0 | 45 | 0 | 0 |
| registration_form.sake | 2 | 78 | 2 | 0 | 0 | 74 | 0 | 0 |
| result_pipeline.sake | 2 | 62 | 1 | 0 | 0 | 36 | 0 | 0 |
| retry_backoff.sake | 2 | 44 | 3 | 1 | 0 | 40 | 0 | 0 |
| spreadsheet_errors.sake | 3 | 77 | 15 | 3 | 0 | 75 | 0 | 0 |
| unit_quantities.sake | 2 | 61 | 5 | 3 | 0 | 52 | 0 | 0 |
| warehouse_reservation.sake | 2 | 66 | 2 | 0 | 0 | 63 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| smtp_session.sake | 3 | 77 | 1 | 0 | 0 | 72 | 0 | 0 |
| tcp_states.sake | 2 | 52 | 0 | 0 | 0 | 41 | 0 | 0 |
| traffic_light.sake | 2 | 71 | 15 | 2 | 0 | 83 | 0 | 0 |
| turnstile.sake | 2 | 32 | 0 | 1 | 0 | 30 | 0 | 0 |
| vending_machine.sake | 2 | 84 | 1 | 1 | 0 | 71 | 0 | 0 |
| appointment_scheduler.sake | 2 | 63 | 11 | 1 | 0 | 65 | 0 | 0 |
| bank_ledger.sake | 3 | 122 | 4 | 1 | 0 | 114 | 0 | 0 |
| course_enrollment.sake | 2 | 105 | 0 | 0 | 0 | 101 | 0 | 0 |
| customer_loyalty.sake | 3 | 96 | 5 | 2 | 0 | 96 | 0 | 0 |
| event_registration.sake | 2 | 77 | 0 | 0 | 0 | 74 | 0 | 0 |
corpus/09-dp/held_karp.sake: [65, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/09-dp/held_karp.sake: [70, 3, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/09-dp/held_karp.sake: [91, 29, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/09-dp/held_karp.sake: [91, 20, "Arithmetic.*", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/09-dp/held_karp.sake: [91, 20, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
corpus/09-dp/held_karp.sake: [91, 8, "Float.round", 1]: observed [["Float"]] but no static check
corpus/09-dp/held_karp.sake: [101, 33, "City.get_name", 1]: observed [["City"]] but no static check
corpus/09-dp/held_karp.sake: [101, 59, "City.get_name", 1]: observed [["City"]] but no static check
corpus/09-dp/held_karp.sake: L91 Float.round result: observed ["Float"], static (none)
corpus/09-dp/held_karp.sake: L101 City.get_name result: observed ["String"], static (none)
corpus/09-dp/held_karp.sake: L101 City.get_name result: observed ["String"], static (none)
corpus/09-dp/held_karp.sake: L101 Kernel.format result: observed ["String"], static (none)
corpus/09-dp/held_karp.sake: L101 Kernel.puts result: observed ["Nil"], static (none)
corpus/09-dp/longest_increasing.sake: [33, 7, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/09-dp/optimal_bst.sake: L61 Kernel.== pair: observed [["Node", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/09-dp/optimal_bst.sake: [62, 7, "Node.get_right", 1]: observed [["Node"]] but no static check
corpus/09-dp/optimal_bst.sake: [63, 27, "Node.get_key", 1]: observed [["Node"]] but no static check
corpus/09-dp/optimal_bst.sake: [63, 18, "Arithmetic.+", "pair"]: observed [["String", "String"]] but no static check
corpus/09-dp/optimal_bst.sake: [64, 7, "Node.get_left", 1]: observed [["Node"]] but no static check
corpus/09-dp/optimal_bst.sake: L97 Node.get_key 1: observed [["Node"]], static nil
corpus/09-dp/optimal_bst.sake: L34 Node.new result: observed ["Node"], static (none)
corpus/09-dp/optimal_bst.sake: L62 Node.get_right result: observed ["Node", "Nil"], static (none)
corpus/09-dp/optimal_bst.sake: L63 Node.get_key result: observed ["String"], static (none)
corpus/09-dp/optimal_bst.sake: L63 Array.push result: observed ["Array"], static (none)
corpus/09-dp/optimal_bst.sake: L64 Node.get_left result: observed ["Nil", "Node"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| held_karp.sake | 2 | 74 | 14 | 8 | 0 | 79 | 8 | 13 |
| house_robber.sake | 2 | 70 | 4 | 0 | 0 | 63 | 0 | 0 |
| interval_scheduling.sake | 2 | 96 | 18 | 1 | 0 | 85 | 0 | 0 |
| knapsack_01.sake | 2 | 48 | 13 | 0 | 0 | 50 | 0 | 0 |
| lcs_diff.sake | 2 | 102 | 14 | 0 | 0 | 78 | 0 | 0 |
| line_breaking.sake | 2 | 74 | 4 | 3 | 0 | 69 | 0 | 0 |
| longest_increasing.sake | 2 | 80 | 6 | 1 | 0 | 72 | 1 | 1 |
| matrix_chain.sake | 3 | 78 | 23 | 4 | 0 | 83 | 0 | 0 |
| optimal_bst.sake | 4 | 85 | 19 | 4 | 0 | 81 | 4 | 11 |
| palindromes.sake | 2 | 101 | 16 | 1 | 0 | 88 | 0 | 0 |
corpus/03-numtheory/pythagorean_triples.sake: [15, 11, "Triple.get_c", 1]: observed [["Triple"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [15, 18, "Triple.get_c", 1]: observed [["Triple"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [15, 11, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [16, 4, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [16, 23, "Triple.get_a", 1]: observed [["Triple"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [16, 30, "Triple.get_a", 1]: observed [["Triple"]] but no static check
corpus/03-numtheory/pythagorean_triples.sake: [16, 23, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/04-numeric/bezier_curves.sake: L74 Array.min result: observed ["Float"], static nil | nil | [Float, Float]
corpus/04-numeric/bezier_curves.sake: L74 Array.max result: observed ["Float"], static nil | nil | [Float, Float]
corpus/04-numeric/bezier_curves.sake: L74 Array.min result: observed ["Float"], static nil
corpus/04-numeric/bezier_curves.sake: L74 Array.max result: observed ["Float"], static nil
corpus/04-numeric/correlation_matrix.sake: [42, 46, "Kernel.==", "pair"]: observed [["Float", "Float"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| pythagorean_triples.sake | 2 | 157 | 3 | 1 | 0 | 156 | 7 | 7 |
| quadratic_residues.sake | 2 | 153 | 0 | 2 | 0 | 139 | 0 | 0 |
| repeating_decimals.sake | 2 | 67 | 20 | 0 | 0 | 70 | 0 | 0 |
| rsa_toy.sake | 2 | 98 | 0 | 1 | 0 | 92 | 0 | 0 |
| sieve_primes.sake | 2 | 92 | 3 | 0 | 0 | 75 | 0 | 0 |
| bezier_curves.sake | 2 | 117 | 12 | 0 | 0 | 110 | 0 | 4 |
| correlation_matrix.sake | 2 | 134 | 9 | 3 | 0 | 121 | 1 | 1 |
| cubic_spline.sake | 2 | 228 | 44 | 1 | 0 | 200 | 0 | 0 |
| curve_fitting.sake | 2 | 120 | 30 | 1 | 0 | 113 | 0 | 0 |
| descriptive_stats.sake | 2 | 79 | 3 | 0 | 19 | 82 | 0 | 0 |
corpus/15-data/top_products.sake: [8, 8, "Score.get_rating", 1]: observed [["Score"]] but no static check
corpus/15-data/top_products.sake: [8, 32, "Score.get_rating", 1]: observed [["Score"]] but no static check
corpus/15-data/top_products.sake: [8, 8, "Comparable.<=>", "pair"]: observed [["Float", "Float"]] but no static check
corpus/15-data/top_products.sake: [9, 41, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/top_products.sake: [10, 41, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| size_histogram.sake | 2 | 50 | 3 | 0 | 0 | 47 | 0 | 0 |
| survey_crosstab.sake | 2 | 96 | 0 | 0 | 0 | 72 | 0 | 0 |
| table_renderer.sake | 2 | 98 | 15 | 2 | 0 | 100 | 0 | 0 |
| timesheet_payroll.sake | 2 | 102 | 2 | 0 | 0 | 98 | 0 | 0 |
| top_products.sake | 2 | 86 | 0 | 0 | 0 | 85 | 5 | 5 |
| activity_heatmap.sake | 2 | 153 | 5 | 0 | 0 | 134 | 0 | 0 |
| age_calculator.sake | 2 | 116 | 4 | 0 | 0 | 104 | 0 | 0 |
| billing_cycles.sake | 2 | 135 | 4 | 1 | 0 | 118 | 0 | 0 |
| business_days.sake | 2 | 103 | 3 | 2 | 0 | 102 | 0 | 0 |
| calendar_systems.sake | 2 | 189 | 2 | 0 | 0 | 173 | 0 | 0 |
corpus/02-analytics/ngram_counts.sake: [10, 8, "Gram.get_count", 1]: observed [["Gram"]] but no static check
corpus/02-analytics/ngram_counts.sake: [10, 30, "Gram.get_count", 1]: observed [["Gram"]] but no static check
corpus/02-analytics/ngram_counts.sake: [10, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/02-analytics/ngram_counts.sake: [11, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/02-analytics/ngram_counts.sake: [11, 13, "Gram.get_key", 1]: observed [["Gram"]] but no static check
corpus/02-analytics/ngram_counts.sake: [11, 22, "Gram.get_key", 1]: observed [["Gram"]] but no static check
corpus/02-analytics/ngram_counts.sake: [11, 13, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
corpus/02-analytics/rake_keywords.sake: [30, 8, "Keyword.get_score", 1]: observed [["Keyword"]] but no static check
corpus/02-analytics/rake_keywords.sake: [30, 33, "Keyword.get_score", 1]: observed [["Keyword"]] but no static check
corpus/02-analytics/rake_keywords.sake: [30, 8, "Comparable.<=>", "pair"]: observed [["Float", "Float"]] but no static check
corpus/02-analytics/rake_keywords.sake: [31, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/02-analytics/rake_keywords.sake: [31, 13, "Keyword.get_phrase", 1]: observed [["Keyword"]] but no static check
corpus/02-analytics/rake_keywords.sake: [31, 25, "Keyword.get_phrase", 1]: observed [["Keyword"]] but no static check
corpus/02-analytics/rake_keywords.sake: [31, 13, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
corpus/02-analytics/word_frequency.sake: [24, 8, "Rank.get_count", 1]: observed [["Rank"]] but no static check
corpus/02-analytics/word_frequency.sake: [24, 30, "Rank.get_count", 1]: observed [["Rank"]] but no static check
corpus/02-analytics/word_frequency.sake: [24, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/02-analytics/word_frequency.sake: [25, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/02-analytics/word_frequency.sake: [25, 13, "Rank.get_word", 1]: observed [["Rank"]] but no static check
corpus/02-analytics/word_frequency.sake: [25, 23, "Rank.get_word", 1]: observed [["Rank"]] but no static check
corpus/02-analytics/word_frequency.sake: [25, 13, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ngram_counts.sake | 2 | 54 | 2 | 0 | 0 | 48 | 7 | 7 |
| rake_keywords.sake | 2 | 166 | 3 | 2 | 0 | 141 | 7 | 7 |
| readability.sake | 2 | 100 | 0 | 0 | 1 | 94 | 0 | 0 |
| rhyme_scheme.sake | 2 | 42 | 3 | 0 | 1 | 39 | 0 | 0 |
| sentiment_lexicon.sake | 2 | 82 | 1 | 0 | 0 | 70 | 0 | 0 |
| soundex_index.sake | 2 | 61 | 3 | 0 | 0 | 52 | 0 | 0 |
| spell_suggest.sake | 2 | 56 | 14 | 0 | 0 | 50 | 0 | 0 |
| tf_idf.sake | 2 | 99 | 4 | 0 | 0 | 87 | 0 | 0 |
| vocabulary_growth.sake | 2 | 101 | 2 | 0 | 0 | 89 | 0 | 0 |
| word_frequency.sake | 2 | 58 | 0 | 0 | 0 | 58 | 7 | 7 |
corpus/09-dp/stock_trading.sake: [4, 16, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/09-dp/stock_trading.sake: L32 Trade.new result: observed ["Trade"], static (none)
corpus/09-dp/stock_trading.sake: L32 Array.unshift result: observed ["Array"], static (none)
corpus/09-dp/subset_partition.sake: [24, 4, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/connect_four.sake: [27, 58, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sequence_alignment.sake | 2 | 101 | 16 | 1 | 0 | 93 | 0 | 0 |
| stock_trading.sake | 2 | 61 | 27 | 7 | 0 | 72 | 1 | 3 |
| subset_partition.sake | 2 | 69 | 3 | 2 | 0 | 57 | 1 | 1 |
| viterbi.sake | 2 | 66 | 15 | 0 | 0 | 57 | 0 | 0 |
| word_break.sake | 3 | 82 | 3 | 1 | 0 | 69 | 0 | 0 |
| battleship.sake | 3 | 112 | 2 | 0 | 0 | 94 | 0 | 0 |
| chess_attacks.sake | 2 | 97 | 0 | 2 | 0 | 85 | 0 | 0 |
| connect_four.sake | 2 | 66 | 8 | 5 | 0 | 69 | 1 | 1 |
| crossword.sake | 2 | 111 | 1 | 0 | 0 | 101 | 0 | 0 |
| falling_sand.sake | 3 | 81 | 7 | 0 | 0 | 72 | 0 | 0 |
corpus/20-business/hotel_billing.sake: L73 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Float, Integer]
corpus/20-business/hotel_billing.sake: L57 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Float, Float]
corpus/20-business/hotel_billing.sake: L126 Arithmetic.+ pair: observed [["Float", "Float"], ["Integer", "Float"], ["Float", "Integer"]], static [Float, Float]
corpus/20-business/hotel_billing.sake: L33 Array.sum result: observed ["Float", "Integer"], static Float
corpus/20-business/hotel_billing.sake: L56 Array.sum result: observed ["Integer", "Float"], static Float
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expense_tracker.sake | 2 | 129 | 9 | 0 | 0 | 122 | 0 | 0 |
| grade_book.sake | 2 | 136 | 7 | 0 | 0 | 121 | 0 | 0 |
| gym_membership.sake | 2 | 47 | 1 | 2 | 0 | 45 | 0 | 0 |
| hotel_billing.sake | 2 | 137 | 0 | 2 | 0 | 124 | 0 | 5 |
| inventory_reorder.sake | 2 | 101 | 2 | 1 | 0 | 92 | 0 | 0 |
| invoice_generator.sake | 2 | 125 | 16 | 0 | 0 | 126 | 0 | 0 |
| library_loans.sake | 2 | 124 | 0 | 2 | 0 | 119 | 0 | 0 |
| parking_garage.sake | 2 | 100 | 7 | 2 | 0 | 100 | 0 | 0 |
| payroll.sake | 2 | 97 | 4 | 0 | 0 | 84 | 0 | 0 |
| rental_fleet.sake | 2 | 100 | 6 | 0 | 0 | 102 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| hex_dump.sake | 2 | 73 | 2 | 2 | 1 | 67 | 0 | 0 |
| huffman.sake | 2 | 80 | 8 | 0 | 0 | 81 | 0 | 0 |
| lzw.sake | 2 | 64 | 6 | 1 | 0 | 57 | 0 | 0 |
| morse.sake | 2 | 73 | 0 | 0 | 2 | 72 | 0 | 0 |
| murmur_ring.sake | 2 | 83 | 7 | 0 | 0 | 77 | 0 | 0 |
| percent_encoding.sake | 2 | 91 | 1 | 1 | 0 | 80 | 0 | 0 |
| playfair.sake | 2 | 68 | 1 | 1 | 14 | 76 | 0 | 0 |
| protobuf_wire.sake | 2 | 110 | 8 | 5 | 0 | 96 | 0 | 0 |
| raid5_parity.sake | 3 | 114 | 7 | 1 | 0 | 110 | 0 | 0 |
| rolling_sync.sake | 2 | 117 | 11 | 2 | 0 | 104 | 0 | 0 |
corpus/04-numeric/gaussian_elimination.sake: [12, 59, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/04-numeric/gaussian_elimination.sake: [12, 59, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/gaussian_elimination.sake: [49, 54, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/04-numeric/gaussian_elimination.sake: [49, 54, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/gaussian_elimination.sake: L12 Float.abs result: observed ["Float"], static (none)
corpus/04-numeric/gaussian_elimination.sake: L49 Float.abs result: observed ["Float"], static (none)
corpus/04-numeric/lu_decomposition.sake: [93, 112, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/lu_decomposition.sake: [93, 102, "Float.abs", 1]: observed [["Float"]] but no static check
corpus/04-numeric/lu_decomposition.sake: [93, 91, "Float[]", "elem"]: observed [["Float"]] but no static check
corpus/04-numeric/lu_decomposition.sake: [93, 81, "Array.max", 1]: observed [["Array"]] but no static check
corpus/04-numeric/lu_decomposition.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, nil]
corpus/04-numeric/lu_decomposition.sake: [38, 52, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/lu_decomposition.sake: L41 Arithmetic./ pair: observed [["Float", "Float"]], static [nil, Float | nil]
corpus/04-numeric/lu_decomposition.sake: L40 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, nil]
corpus/04-numeric/lu_decomposition.sake: [40, 36, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/lu_decomposition.sake: [100, 55, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/04-numeric/lu_decomposition.sake: L93 Float.abs result: observed ["Float"], static (none)
corpus/04-numeric/lu_decomposition.sake: L93 Float[] result: observed ["Array"], static (none)
corpus/04-numeric/lu_decomposition.sake: L93 Array.max result: observed ["Float"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| eigenvalues.sake | 2 | 141 | 55 | 1 | 0 | 149 | 0 | 0 |
| float_accuracy.sake | 2 | 126 | 1 | 0 | 0 | 122 | 0 | 0 |
| fourier_spectrum.sake | 2 | 147 | 11 | 1 | 0 | 144 | 0 | 0 |
| gaussian_elimination.sake | 2 | 120 | 40 | 6 | 0 | 121 | 4 | 6 |
| histogram_fit.sake | 2 | 160 | 12 | 0 | 0 | 159 | 0 | 0 |
| interval_arithmetic.sake | 2 | 101 | 49 | 1 | 0 | 126 | 0 | 0 |
| linear_regression.sake | 2 | 116 | 11 | 0 | 0 | 112 | 0 | 0 |
| loan_amortization.sake | 2 | 107 | 9 | 0 | 0 | 104 | 0 | 0 |
| lu_decomposition.sake | 2 | 113 | 29 | 8 | 0 | 116 | 7 | 13 |
| matrix_ops.sake | 3 | 162 | 13 | 3 | 0 | 143 | 0 | 0 |
corpus/16-dates/durations.sake: [37, 15, "String.to_i", 1]: observed [["String"]] but no static check
corpus/16-dates/durations.sake: [37, 34, "Hash.fetch", 1]: observed [["Hash"]] but no static check
corpus/16-dates/durations.sake: [37, 15, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/16-dates/durations.sake: [37, 6, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cron_schedule.sake | 2 | 147 | 8 | 4 | 0 | 139 | 0 | 0 |
| date_arith.sake | 2 | 114 | 5 | 2 | 0 | 104 | 0 | 0 |
| date_parser.sake | 2 | 98 | 48 | 0 | 1 | 114 | 0 | 0 |
| day_of_week.sake | 2 | 62 | 14 | 0 | 0 | 60 | 0 | 0 |
| durations.sake | 2 | 95 | 10 | 2 | 0 | 98 | 4 | 4 |
| easter.sake | 2 | 126 | 2 | 2 | 0 | 114 | 0 | 0 |
| fiscal_quarters.sake | 2 | 117 | 17 | 1 | 0 | 113 | 0 | 0 |
| iso_week.sake | 2 | 110 | 15 | 0 | 0 | 106 | 0 | 0 |
| meeting_scheduler.sake | 3 | 109 | 14 | 0 | 0 | 114 | 0 | 0 |
| month_calendar.sake | 2 | 75 | 2 | 0 | 0 | 71 | 0 | 0 |
corpus/15-data/fx_conversion.sake: L79 Arithmetic.+ pair: observed [["Rational", "Rational"], ["Rational", "Integer"], ["Integer", "Rational"]], static [Rational, Rational]
corpus/15-data/fx_conversion.sake: [49, 35, "Integer.to_f", 1]: observed [["Integer"]] but no static check
corpus/15-data/fx_conversion.sake: [49, 18, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/15-data/fx_conversion.sake: L77 Array.sum result: observed ["Rational", "Integer"], static Rational
corpus/15-data/fx_conversion.sake: L78 Array.sum result: observed ["Rational", "Integer"], static Rational
corpus/15-data/league_standings.sake: [10, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [11, 46, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [12, 48, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [13, 38, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [11, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [12, 8, "Team.get_goals_for", 1]: observed [["Team"]] but no static check
corpus/15-data/league_standings.sake: [12, 34, "Team.get_goals_for", 1]: observed [["Team"]] but no static check
corpus/15-data/league_standings.sake: [12, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/15-data/league_standings.sake: [13, 8, "Team.get_name", 1]: observed [["Team"]] but no static check
corpus/15-data/league_standings.sake: [13, 18, "Team.get_name", 1]: observed [["Team"]] but no static check
corpus/15-data/league_standings.sake: [13, 8, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| fulfillment_report.sake | 2 | 141 | 0 | 1 | 0 | 122 | 0 | 0 |
| fx_conversion.sake | 2 | 94 | 0 | 0 | 0 | 85 | 2 | 5 |
| grade_book.sake | 2 | 87 | 0 | 1 | 0 | 80 | 0 | 0 |
| groupby_query.sake | 2 | 85 | 7 | 2 | 0 | 76 | 0 | 0 |
| inventory_diff.sake | 2 | 135 | 4 | 0 | 0 | 130 | 0 | 0 |
| invoice_totals.sake | 2 | 104 | 0 | 0 | 0 | 84 | 0 | 0 |
| league_standings.sake | 3 | 114 | 3 | 0 | 0 | 106 | 11 | 11 |
| metric_anomalies.sake | 2 | 135 | 3 | 0 | 0 | 128 | 0 | 0 |
| quality_rules.sake | 2 | 89 | 0 | 0 | 0 | 79 | 0 | 0 |
| sales_by_region.sake | 2 | 97 | 4 | 0 | 0 | 77 | 0 | 0 |
corpus/03-numtheory/perfect_amicable.sake: [86, 28, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| goldbach.sake | 2 | 84 | 4 | 0 | 0 | 72 | 0 | 0 |
| happy_cycles.sake | 2 | 76 | 4 | 0 | 0 | 68 | 0 | 0 |
| integer_partitions.sake | 2 | 114 | 7 | 0 | 0 | 100 | 0 | 0 |
| linear_diophantine.sake | 2 | 94 | 0 | 2 | 0 | 70 | 0 | 0 |
| linear_sieve.sake | 2 | 125 | 20 | 0 | 0 | 96 | 0 | 0 |
| miller_rabin.sake | 2 | 85 | 0 | 0 | 0 | 82 | 0 | 0 |
| modular_crt.sake | 2 | 109 | 0 | 2 | 0 | 95 | 0 | 0 |
| perfect_amicable.sake | 2 | 71 | 9 | 2 | 0 | 63 | 1 | 1 |
| pollard_rho.sake | 3 | 116 | 0 | 1 | 0 | 108 | 0 | 0 |
| primitive_roots.sake | 2 | 138 | 2 | 1 | 0 | 132 | 0 | 0 |
corpus/18-collections/role_permissions.sake: [80, 53, "String.split", 1]: observed [["String"]] but no static check
corpus/18-collections/role_permissions.sake: [80, 53, "String.split", 2]: observed [["String"]] but no static check
corpus/18-collections/role_permissions.sake: [81, 80, "Array.size", 1]: observed [["Array"]] but no static check
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
corpus/18-collections/tag_recommender.sake: [9, 8, "Match.get_score", 1]: observed [["Match"]] but no static check
corpus/18-collections/tag_recommender.sake: [9, 31, "Match.get_score", 1]: observed [["Match"]] but no static check
corpus/18-collections/tag_recommender.sake: [9, 8, "Comparable.<=>", "pair"]: observed [["Float", "Float"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 28, "Match.get_article", 1]: observed [["Match"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 13, "Article.get_id", 1]: observed [["Article"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 57, "Match.get_article", 1]: observed [["Match"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 42, "Article.get_id", 1]: observed [["Article"]] but no static check
corpus/18-collections/tag_recommender.sake: [10, 13, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| range_set.sake | 2 | 106 | 16 | 0 | 0 | 114 | 0 | 0 |
| role_permissions.sake | 2 | 87 | 9 | 2 | 0 | 82 | 3 | 3 |
| room_bookings.sake | 2 | 100 | 26 | 0 | 0 | 110 | 0 | 0 |
| sales_pivot.sake | 2 | 134 | 15 | 0 | 0 | 106 | 0 | 0 |
| sensor_merge.sake | 2 | 79 | 2 | 1 | 0 | 110 | 39 | 46 |
| sparse_vectors.sake | 3 | 104 | 6 | 0 | 10 | 95 | 0 | 0 |
| survey_venn.sake | 2 | 104 | 3 | 0 | 0 | 101 | 0 | 0 |
| tag_recommender.sake | 2 | 110 | 8 | 0 | 0 | 111 | 9 | 9 |
| word_pipeline.sake | 2 | 101 | 2 | 0 | 5 | 96 | 0 | 0 |
| word_rack.sake | 2 | 126 | 3 | 0 | 0 | 122 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bank_queue_sim.sake | 2 | 118 | 16 | 1 | 0 | 114 | 0 | 0 |
| bracket_checker.sake | 2 | 53 | 0 | 2 | 0 | 51 | 0 | 0 |
| button_debounce.sake | 2 | 83 | 0 | 6 | 0 | 75 | 0 | 0 |
| circuit_breaker.sake | 2 | 70 | 4 | 2 | 0 | 66 | 0 | 0 |
| csv_parser.sake | 2 | 71 | 7 | 1 | 0 | 73 | 0 | 0 |
| dfa_minimize.sake | 3 | 93 | 1 | 0 | 0 | 79 | 0 | 0 |
| divisibility_dfa.sake | 5 | 77 | 1 | 1 | 4 | 75 | 0 | 0 |
| elevator.sake | 2 | 95 | 6 | 2 | 0 | 96 | 0 | 0 |
| enemy_ai.sake | 2 | 105 | 8 | 2 | 0 | 107 | 0 | 0 |
| event_sourcing.sake | 2 | 83 | 0 | 1 | 0 | 70 | 0 | 0 |
corpus/07-trees/spanning_tree.sake: [6, 31, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [7, 10, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [19, 23, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [21, 22, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [21, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [41, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [42, 4, "Array.push", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [56, 15, "Array.sort_by", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [56, 4, "Array.each", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [57, 14, "Set.include?", 1]: observed [["Set"]] but no static check
corpus/07-trees/spanning_tree.sake: [58, 6, "Set.add", 1]: observed [["Set"]] but no static check
corpus/07-trees/spanning_tree.sake: [61, 17, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [62, 6, "Array.push", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [90, 10, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [92, 22, "Array.map", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [92, 9, "Array.select", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [92, 67, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [93, 13, "Array.sort_by", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [93, 2, "Array.each", 1]: observed [["Array"]] but no static check
corpus/07-trees/spanning_tree.sake: [93, 96, "Arithmetic.+", "pair"]: observed [["String", "String"]] but no static check
corpus/07-trees/spanning_tree.sake: [74, 7, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [79, 26, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: [75, 26, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/spanning_tree.sake: L41 Array.push result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L42 Array.push result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L56 Array.sort_by result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L56 Array.each result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L92 Array.map result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L92 Array.select result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L93 Array.sort_by result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L93 Array.each result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L81 Array.push result: observed ["Array"], static (none)
corpus/07-trees/spanning_tree.sake: L77 Array.push result: observed ["Array"], static (none)
corpus/07-trees/taxonomy_lca.sake: [17, 57, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [19, 6, "Array.push", 1]: observed [["Array"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [45, 13, "Array.sort_by", 1]: observed [["Array"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [45, 47, "Taxonomy.get_names", 1]: observed [["Taxonomy"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [46, 17, "Array.reverse", 1]: observed [["Array"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [46, 6, "Array.each", 1]: observed [["Array"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [47, 8, "Taxonomy.get_depth", 1]: observed [["Taxonomy"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [47, 20, "Taxonomy.get_depth", 1]: observed [["Taxonomy"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [47, 20, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/07-trees/taxonomy_lca.sake: [48, 8, "Array.push", 1]: observed [["Array"]] but no static check
corpus/07-trees/taxonomy_lca.sake: L19 Array.push result: observed ["Array"], static (none)
corpus/07-trees/taxonomy_lca.sake: L45 Array.sort_by result: observed ["Array"], static (none)
corpus/07-trees/taxonomy_lca.sake: L46 Array.reverse result: observed ["Array"], static (none)
corpus/07-trees/taxonomy_lca.sake: L46 Array.each result: observed ["Array"], static (none)
corpus/07-trees/traversals.sake: L94 Kernel.== pair: observed [["BT", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/07-trees/traversals.sake: [95, 8, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: L117 Kernel.== pair: observed [["Nil", "Nil"], ["BT", "Nil"]], static [nil | nil, nil]
corpus/07-trees/traversals.sake: [117, 47, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: [118, 22, "BT.get_label", 1]: observed [["BT"]] but no static check
corpus/07-trees/traversals.sake: L95 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L117 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L117 Set.include? result: observed ["Boolean"], static (none)
corpus/07-trees/traversals.sake: L118 BT.get_label result: observed ["String"], static (none)
corpus/07-trees/traversals.sake: L118 Set.add result: observed ["Set"], static (none)
corpus/07-trees/traversals.sake: L119 Array.push result: observed ["Array"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| spanning_tree.sake | 2 | 100 | 1 | 28 | 0 | 100 | 23 | 33 |
| taxonomy_lca.sake | 2 | 102 | 8 | 12 | 0 | 98 | 10 | 14 |
| traversals.sake | 3 | 148 | 5 | 0 | 0 | 150 | 3 | 11 |
| tree_codec.sake | 3 | 97 | 4 | 0 | 0 | 98 | 0 | 0 |
| trie_autocomplete.sake | 2 | 78 | 12 | 0 | 0 | 84 | 0 | 0 |
| astar_terrain.sake | 2 | 69 | 12 | 0 | 0 | 59 | 0 | 0 |
| bellman_ford.sake | 2 | 66 | 2 | 0 | 0 | 54 | 0 | 0 |
| centrality.sake | 2 | 101 | 12 | 0 | 0 | 77 | 0 | 0 |
| course_schedule.sake | 2 | 74 | 7 | 0 | 0 | 62 | 0 | 0 |
| critical_links.sake | 2 | 75 | 8 | 0 | 0 | 61 | 0 | 0 |
corpus/04-numeric/numeric_integration.sake: L62 Kernel.== pair: observed [["Float", "Float"]], static [Tuple, Float]
corpus/04-numeric/numeric_integration.sake: L63 Arithmetic.* pair: observed [["Float", "Float"]], static [nil, Float]
corpus/04-numeric/numeric_integration.sake: [63, 6, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Tuple]
corpus/04-numeric/numeric_integration.sake: [65, 26, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Tuple]
corpus/04-numeric/numeric_integration.sake: [65, 50, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 15, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numeric_integration.sake: [65, 6, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/04-numeric/numerical_derivatives.sake: [61, 2, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/04-numeric/time_series.sake: L112 Kernel.format result: observed ["String"], static (none)
corpus/04-numeric/time_series.sake: L112 Kernel.puts result: observed ["Nil"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monte_carlo.sake | 2 | 137 | 0 | 0 | 0 | 120 | 0 | 0 |
| numeric_integration.sake | 2 | 108 | 4 | 6 | 2 | 115 | 6 | 10 |
| numerical_derivatives.sake | 2 | 131 | 17 | 4 | 0 | 132 | 1 | 1 |
| ode_solver.sake | 3 | 101 | 21 | 2 | 0 | 94 | 0 | 0 |
| optimization.sake | 2 | 143 | 22 | 1 | 0 | 139 | 0 | 0 |
| polynomial.sake | 2 | 165 | 14 | 0 | 0 | 144 | 0 | 0 |
| root_finding.sake | 2 | 103 | 2 | 6 | 0 | 103 | 0 | 0 |
| special_functions.sake | 2 | 153 | 4 | 1 | 0 | 152 | 0 | 0 |
| time_series.sake | 3 | 136 | 25 | 2 | 0 | 131 | 0 | 2 |
| vector_geometry.sake | 2 | 125 | 2 | 0 | 0 | 117 | 0 | 0 |
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
corpus/18-collections/prime_sets.sake: L62 Array.to_set 1: observed [["Array"]], static Set@L62[Integer]
corpus/18-collections/prime_sets.sake: L62 Set.select result: observed ["Array"], static Set@L62[Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| friend_graph.sake | 2 | 109 | 12 | 0 | 0 | 95 | 0 | 0 |
| grade_book.sake | 2 | 96 | 8 | 0 | 0 | 82 | 0 | 0 |
| inventory_diff.sake | 2 | 75 | 3 | 2 | 0 | 91 | 21 | 21 |
| ip_ranges.sake | 2 | 107 | 17 | 3 | 0 | 109 | 0 | 0 |
| latency_buckets.sake | 2 | 91 | 2 | 0 | 0 | 77 | 0 | 0 |
| leaderboard.sake | 2 | 64 | 8 | 0 | 0 | 85 | 19 | 19 |
| library_loans.sake | 3 | 167 | 18 | 1 | 0 | 160 | 0 | 0 |
| lottery.sake | 2 | 84 | 10 | 0 | 0 | 79 | 0 | 0 |
| paginate.sake | 2 | 106 | 10 | 0 | 0 | 101 | 0 | 0 |
| prime_sets.sake | 2 | 111 | 5 | 3 | 0 | 108 | 0 | 2 |
corpus/10-grids/flood_fill.sake: [9, 7, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [9, 17, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [9, 7, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/flood_fill.sake: [10, 6, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [10, 29, "Tally.get_count", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [10, 6, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/flood_fill.sake: [12, 6, "Tally.get_color", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [12, 17, "Tally.get_color", 1]: observed [["Tally"]] but no static check
corpus/10-grids/flood_fill.sake: [12, 6, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
corpus/10-grids/game_of_life.sake: [76, 7, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/maze_bfs.sake: [64, 26, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| flood_fill.sake | 2 | 92 | 9 | 0 | 0 | 92 | 9 | 9 |
| game_2048.sake | 3 | 97 | 6 | 1 | 0 | 87 | 0 | 0 |
| game_of_life.sake | 2 | 70 | 3 | 0 | 0 | 65 | 1 | 1 |
| hex_game.sake | 2 | 128 | 1 | 0 | 0 | 112 | 0 | 0 |
| knights_tour.sake | 2 | 91 | 6 | 0 | 0 | 86 | 0 | 0 |
| langtons_ant.sake | 2 | 83 | 0 | 1 | 0 | 72 | 0 | 0 |
| lights_out.sake | 2 | 76 | 0 | 1 | 0 | 76 | 0 | 0 |
| magic_square.sake | 2 | 95 | 8 | 0 | 0 | 85 | 0 | 0 |
| matrix_spiral.sake | 3 | 130 | 6 | 0 | 0 | 111 | 0 | 0 |
| maze_bfs.sake | 2 | 74 | 5 | 2 | 0 | 66 | 1 | 1 |
corpus/06-linked/adjacency_list_courses.sake: [43, 8, "Arithmetic.-", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/adjacency_list_courses.sake: [44, 11, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/adjacency_list_courses.sake: L41 Array.push result: observed ["Array"], static (none)
corpus/06-linked/adjacency_list_courses.sake: L45 Array.push result: observed ["Array"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sorted_matrix_search.sake | 2 | 71 | 13 | 0 | 0 | 69 | 0 | 0 |
| staff_multikey_sort.sake | 2 | 59 | 4 | 2 | 14 | 63 | 0 | 0 |
| trail_peak_search.sake | 2 | 77 | 7 | 0 | 0 | 70 | 0 | 0 |
| triage_partition.sake | 2 | 88 | 12 | 2 | 0 | 86 | 0 | 0 |
| version_resolver.sake | 3 | 74 | 17 | 2 | 0 | 73 | 0 | 0 |
| adjacency_list_courses.sake | 3 | 99 | 10 | 2 | 0 | 87 | 2 | 4 |
| bank_teller_sim.sake | 3 | 106 | 2 | 0 | 0 | 100 | 0 | 0 |
| browser_history.sake | 2 | 60 | 2 | 1 | 0 | 59 | 0 | 0 |
| chained_hash_table.sake | 3 | 114 | 0 | 0 | 0 | 98 | 0 | 0 |
| circular_playlist.sake | 2 | 90 | 17 | 0 | 0 | 99 | 0 | 0 |
corpus/05-sorting/library_catalog.sake: [11, 8, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
corpus/05-sorting/library_catalog.sake: [12, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/05-sorting/sensor_quickselect.sake: [10, 7, "Comparable.<", "pair"]: observed [["Float", "Float"], ["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| library_catalog.sake | 2 | 80 | 5 | 0 | 0 | 79 | 2 | 2 |
| log_time_bisect.sake | 2 | 63 | 12 | 1 | 0 | 64 | 0 | 0 |
| meeting_intervals.sake | 2 | 99 | 10 | 0 | 0 | 90 | 0 | 0 |
| merge_sort_inversions.sake | 2 | 83 | 5 | 0 | 0 | 69 | 0 | 0 |
| natural_runs_sort.sake | 2 | 149 | 20 | 1 | 0 | 132 | 0 | 0 |
| probe_count_search.sake | 2 | 91 | 13 | 2 | 0 | 82 | 0 | 0 |
| quicksort_median3.sake | 2 | 75 | 13 | 0 | 0 | 72 | 0 | 0 |
| radix_order_ids.sake | 2 | 78 | 7 | 0 | 0 | 68 | 0 | 0 |
| sensor_quickselect.sake | 3 | 75 | 27 | 2 | 0 | 84 | 1 | 1 |
| shell_sort_gaps.sake | 2 | 72 | 2 | 2 | 0 | 56 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| run_length.sake | 2 | 69 | 3 | 2 | 0 | 64 | 0 | 0 |
| transposition.sake | 2 | 70 | 2 | 0 | 0 | 62 | 0 | 0 |
| utf8_codec.sake | 2 | 91 | 15 | 8 | 0 | 100 | 0 | 0 |
| vigenere.sake | 2 | 87 | 2 | 0 | 0 | 76 | 0 | 0 |
| xor_breaker.sake | 2 | 82 | 7 | 0 | 0 | 81 | 0 | 0 |
| access_log.sake | 2 | 110 | 12 | 0 | 0 | 111 | 0 | 0 |
| build_order.sake | 3 | 85 | 7 | 2 | 0 | 78 | 0 | 0 |
| cart_discounts.sake | 2 | 73 | 5 | 0 | 0 | 61 | 0 | 0 |
| contact_dedupe.sake | 3 | 141 | 7 | 0 | 0 | 124 | 0 | 0 |
| course_overlap.sake | 2 | 118 | 11 | 0 | 0 | 121 | 0 | 0 |
corpus/12-parsers/query_engine.sake: [141, 43, "Query.get_where", 1]: observed [["Query"]] but no static check
corpus/12-parsers/query_engine.sake: [105, 19, "Cmp.get_column", 1]: observed [["Cmp"]] but no static check
corpus/12-parsers/query_engine.sake: L94 Hash.key? 1: observed [["Hash"]], static nil
corpus/12-parsers/query_engine.sake: [106, 8, "Cmp.get_value", 1]: observed [["Cmp"]] but no static check
corpus/12-parsers/query_engine.sake: [107, 76, "Kernel.==", "pair"]: observed [["Boolean", "Boolean"]] but no static check
corpus/12-parsers/query_engine.sake: [108, 9, "Cmp.get_op", 1]: observed [["Cmp"]] but no static check
corpus/12-parsers/query_engine.sake: [112, 16, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/query_engine.sake: [160, 6, "Array.each", 1]: observed [["Array"]] but no static check
corpus/12-parsers/query_engine.sake: [160, 52, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
corpus/12-parsers/query_engine.sake: [102, 17, "Logic.get_left", 1]: observed [["Logic"]] but no static check
corpus/12-parsers/query_engine.sake: [109, 16, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
corpus/12-parsers/query_engine.sake: [103, 4, "Logic.get_op", 1]: observed [["Logic"]] but no static check
corpus/12-parsers/query_engine.sake: [103, 4, "Kernel.==", "pair"]: observed [["String", "String"]] but no static check
corpus/12-parsers/query_engine.sake: [103, 48, "Logic.get_right", 1]: observed [["Logic"]] but no static check
corpus/12-parsers/query_engine.sake: [114, 17, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/query_engine.sake: [103, 92, "Logic.get_right", 1]: observed [["Logic"]] but no static check
corpus/12-parsers/query_engine.sake: [129, 42, "Agg.get_column", 1]: observed [["Agg"]] but no static check
corpus/12-parsers/query_engine.sake: [110, 17, "Kernel.!=", "pair"]: observed [["String", "String"]] but no static check
corpus/12-parsers/query_engine.sake: [111, 16, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/12-parsers/query_engine.sake: [170, 59, "Hash.map", 1]: observed [["Hash"]] but no static check
corpus/12-parsers/query_engine.sake: [170, 48, "Array.join", 1]: observed [["Array"]] but no static check
corpus/12-parsers/query_engine.sake: [107, 45, "Cmp.get_column", 1]: observed [["Cmp"]] but no static check
corpus/12-parsers/query_engine.sake: L149 Array.first result: observed ["Hash"], static nil
corpus/12-parsers/query_engine.sake: L133 Array.max result: observed ["Integer"], static nil
corpus/12-parsers/query_engine.sake: L170 Hash.map result: observed ["Array"], static (none)
corpus/12-parsers/query_engine.sake: L170 Array.join result: observed ["String"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_parser.sake | 2 | 79 | 5 | 3 | 0 | 69 | 0 | 0 |
| forth.sake | 3 | 105 | 19 | 1 | 0 | 103 | 0 | 0 |
| indent_lexer.sake | 3 | 68 | 5 | 1 | 0 | 66 | 0 | 0 |
| ini_parser.sake | 2 | 101 | 3 | 2 | 0 | 88 | 0 | 0 |
| json_parser.sake | 3 | 182 | 23 | 2 | 1 | 171 | 0 | 0 |
| lisp_interp.sake | 5 | 93 | 23 | 1 | 11 | 85 | 0 | 0 |
| markdown.sake | 2 | 100 | 20 | 6 | 0 | 106 | 0 | 0 |
| pratt_parser.sake | 3 | 79 | 24 | 2 | 33 | 102 | 0 | 0 |
| query_engine.sake | 2 | 72 | 0 | 2 | 17 | 108 | 21 | 26 |
| regex_matcher.sake | 2 | 140 | 11 | 3 | 0 | 123 | 0 | 0 |
corpus/13-polymorphism/interval_arith.sake: L27 Array.min result: observed ["Integer", "Float"], static Integer | nil
corpus/13-polymorphism/interval_arith.sake: L27 Array.max result: observed ["Integer", "Float"], static Integer | nil
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bitset_permissions.sake | 2 | 88 | 10 | 1 | 0 | 74 | 0 | 0 |
| calendar_dates.sake | 2 | 141 | 8 | 3 | 0 | 134 | 0 | 0 |
| collision_check.sake | 2 | 167 | 0 | 0 | 0 | 149 | 0 | 0 |
| color_palette.sake | 2 | 168 | 12 | 2 | 0 | 162 | 0 | 0 |
| doc_render.sake | 2 | 130 | 9 | 0 | 0 | 120 | 0 | 0 |
| duration_timesheet.sake | 2 | 158 | 3 | 3 | 0 | 135 | 0 | 0 |
| expr_tree.sake | 3 | 189 | 1 | 1 | 0 | 126 | 0 | 0 |
| fraction_math.sake | 2 | 162 | 1 | 1 | 0 | 126 | 0 | 0 |
| interval_arith.sake | 3 | 125 | 32 | 2 | 0 | 127 | 0 | 2 |
| life_grid.sake | 2 | 80 | 5 | 0 | 0 | 64 | 0 | 0 |
corpus/01-text/csv_report.sake: [68, 13, "String.to_i", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [68, 43, "String.to_f", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [80, 42, "Sale.get_region", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [84, 22, "Array.map", 1]: observed [["Array"]] but no static check
corpus/01-text/csv_report.sake: [5, 18, "Sale.get_units", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [5, 27, "Sale.get_price", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [5, 18, "Arithmetic.*", "pair"]: observed [["Integer", "Float"]] but no static check
corpus/01-text/csv_report.sake: [84, 12, "Array.sum", 1]: observed [["Array"]] but no static check
corpus/01-text/csv_report.sake: [85, 4, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus/01-text/csv_report.sake: [86, 23, "Array.size", 1]: observed [["Array"]] but no static check
corpus/01-text/csv_report.sake: [87, 15, "Array.sort_by", 1]: observed [["Array"]] but no static check
corpus/01-text/csv_report.sake: [87, 41, "Sale.get_rep", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [87, 4, "Array.each", 1]: observed [["Array"]] but no static check
corpus/01-text/csv_report.sake: [88, 13, "Sale.get_note", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [89, 18, "Kernel.==", "pair"]: observed [["String", "Nil"]] but no static check
corpus/01-text/csv_report.sake: [89, 33, "String.empty?", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [90, 53, "Sale.get_rep", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [90, 70, "Sale.get_product", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [91, 18, "Sale.get_units", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [91, 43, "Sale.get_price", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [90, 11, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [89, 69, "String.gsub", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [89, 69, "String.gsub", 2]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [89, 69, "String.gsub", 3]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: [89, 60, "Arithmetic.+", "pair"]: observed [["String", "String"]] but no static check
corpus/01-text/csv_report.sake: [93, 9, "Kernel.format", 1]: observed [["String"]] but no static check
corpus/01-text/csv_report.sake: L97 Kernel.!= pair: observed [["Sale", "Nil"]], static [nil, nil]
corpus/01-text/csv_report.sake: [97, 24, "Sale.get_rep", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: [97, 48, "Sale.get_product", 1]: observed [["Sale"]] but no static check
corpus/01-text/csv_report.sake: L68 String.to_i result: observed ["Integer"], static (none)
corpus/01-text/csv_report.sake: L68 String.to_f result: observed ["Float"], static (none)
corpus/01-text/csv_report.sake: L67 Sale.new result: observed ["Sale"], static (none)
corpus/01-text/csv_report.sake: L96 Array.max_by result: observed ["Sale"], static nil
corpus/01-text/csv_report.sake: L97 Sale.get_rep result: observed ["String"], static (none)
corpus/01-text/csv_report.sake: L97 Sale.get_product result: observed ["String"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii_table.sake | 2 | 82 | 12 | 1 | 0 | 81 | 0 | 0 |
| bwt_rle.sake | 2 | 81 | 10 | 2 | 0 | 78 | 0 | 0 |
| case_convert.sake | 2 | 93 | 8 | 1 | 0 | 94 | 0 | 0 |
| classic_ciphers.sake | 2 | 110 | 5 | 0 | 0 | 102 | 0 | 0 |
| columnize.sake | 2 | 66 | 2 | 0 | 0 | 63 | 0 | 0 |
| csv_report.sake | 2 | 62 | 8 | 6 | 0 | 87 | 28 | 35 |
| date_format.sake | 2 | 134 | 19 | 0 | 0 | 130 | 0 | 0 |
| doc_pretty.sake | 2 | 59 | 18 | 3 | 0 | 71 | 0 | 0 |
| human_format.sake | 2 | 122 | 3 | 0 | 0 | 120 | 0 | 0 |
| inflector.sake | 2 | 66 | 2 | 0 | 0 | 62 | 0 | 0 |
corpus/01-text/text_stats.sake: [6, 15, "WordCount.get_count", 1]: observed [["WordCount"]] but no static check
corpus/01-text/text_stats.sake: [6, 42, "WordCount.get_count", 1]: observed [["WordCount"]] but no static check
corpus/01-text/text_stats.sake: [6, 15, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/01-text/text_stats.sake: [7, 4, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/01-text/text_stats.sake: [7, 20, "WordCount.get_word", 1]: observed [["WordCount"]] but no static check
corpus/01-text/text_stats.sake: [7, 30, "WordCount.get_word", 1]: observed [["WordCount"]] but no static check
corpus/01-text/text_stats.sake: [7, 20, "Comparable.<=>", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| template_render.sake | 2 | 53 | 4 | 0 | 0 | 52 | 0 | 0 |
| text_box.sake | 2 | 97 | 6 | 2 | 0 | 95 | 0 | 0 |
| text_stats.sake | 2 | 71 | 2 | 0 | 5 | 79 | 7 | 7 |
| whitespace_tidy.sake | 2 | 106 | 7 | 0 | 0 | 100 | 0 | 0 |
| word_wrap.sake | 2 | 62 | 13 | 0 | 0 | 71 | 0 | 0 |
| access_log_urls.sake | 2 | 130 | 13 | 0 | 0 | 112 | 0 | 0 |
| anagram_groups.sake | 2 | 73 | 4 | 0 | 0 | 63 | 0 | 0 |
| autocomplete.sake | 2 | 57 | 12 | 0 | 0 | 58 | 0 | 0 |
| caesar_crack.sake | 2 | 59 | 2 | 0 | 0 | 54 | 0 | 0 |
| cooccurrence_pmi.sake | 2 | 76 | 0 | 0 | 0 | 62 | 0 | 0 |
corpus/06-linked/monotonic_stack_prices.sake: [33, 45, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/monotonic_stack_prices.sake: [48, 45, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/monotonic_stack_prices.sake: [64, 33, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/monotonic_stack_prices.sake: [71, 13, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/06-linked/monotonic_stack_prices.sake: [72, 9, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monotonic_stack_prices.sake | 3 | 51 | 3 | 5 | 0 | 55 | 5 | 5 |
| ring_buffer_metrics.sake | 2 | 82 | 10 | 1 | 0 | 78 | 0 | 0 |
| rpn_stack_calculator.sake | 3 | 60 | 0 | 1 | 0 | 59 | 0 | 0 |
| singly_linked_list.sake | 3 | 85 | 13 | 0 | 0 | 89 | 0 | 0 |
| skip_list_index.sake | 3 | 117 | 15 | 0 | 0 | 109 | 0 | 0 |
| sparse_matrix_rows.sake | 3 | 118 | 2 | 2 | 0 | 85 | 0 | 0 |
| sparse_polynomial.sake | 3 | 72 | 1 | 0 | 0 | 61 | 0 | 0 |
| triage_priority_list.sake | 3 | 81 | 8 | 1 | 0 | 73 | 0 | 0 |
| two_stack_print_queue.sake | 2 | 57 | 6 | 0 | 0 | 53 | 0 | 0 |
| undo_redo_editor.sake | 3 | 70 | 7 | 1 | 0 | 71 | 0 | 0 |
corpus/10-grids/terrain_dijkstra.sake: [79, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/10-grids/terrain_dijkstra.sake: [70, 28, "Kernel.!=", "pair"]: observed [["String", "String"]] but no static check
corpus/10-grids/terrain_dijkstra.sake: [70, 51, "Kernel.!=", "pair"]: observed [["String", "String"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| minesweeper.sake | 2 | 65 | 17 | 2 | 0 | 77 | 0 | 0 |
| n_queens.sake | 2 | 71 | 0 | 0 | 0 | 68 | 0 | 0 |
| nonogram.sake | 3 | 111 | 8 | 0 | 0 | 104 | 0 | 0 |
| othello.sake | 2 | 95 | 10 | 2 | 0 | 82 | 0 | 0 |
| sliding_puzzle.sake | 2 | 141 | 15 | 0 | 0 | 122 | 0 | 0 |
| sokoban.sake | 3 | 125 | 0 | 1 | 0 | 114 | 0 | 0 |
| sudoku_solver.sake | 2 | 94 | 3 | 1 | 0 | 86 | 0 | 0 |
| terrain_dijkstra.sake | 2 | 70 | 6 | 4 | 0 | 63 | 3 | 3 |
| tic_tac_toe.sake | 3 | 79 | 2 | 2 | 0 | 69 | 0 | 0 |
| word_search.sake | 2 | 89 | 3 | 0 | 0 | 78 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_pivot.sake | 2 | 95 | 6 | 0 | 0 | 83 | 0 | 0 |
| email_domains.sake | 2 | 89 | 4 | 0 | 1 | 81 | 0 | 0 |
| hashtag_trends.sake | 2 | 89 | 6 | 0 | 5 | 83 | 0 | 0 |
| inverted_index.sake | 2 | 76 | 12 | 0 | 0 | 73 | 0 | 0 |
| kwic_concordance.sake | 2 | 81 | 7 | 0 | 0 | 74 | 0 | 0 |
| language_guess.sake | 2 | 71 | 5 | 0 | 0 | 63 | 0 | 0 |
| log_summary.sake | 3 | 86 | 9 | 0 | 0 | 73 | 0 | 0 |
| markov_text.sake | 2 | 102 | 2 | 0 | 0 | 89 | 0 | 0 |
| naive_bayes.sake | 2 | 99 | 2 | 0 | 0 | 82 | 0 | 0 |
| near_duplicates.sake | 2 | 83 | 10 | 0 | 0 | 71 | 0 | 0 |
corpus/01-text/spell_suggest.sake: [6, 8, "Suggestion.get_distance", 1]: observed [["Suggestion"]] but no static check
corpus/01-text/spell_suggest.sake: [6, 22, "Suggestion.get_distance", 1]: observed [["Suggestion"]] but no static check
corpus/01-text/spell_suggest.sake: [6, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/01-text/spell_suggest.sake: [7, 16, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/01-text/spell_suggest.sake: [8, 8, "Suggestion.get_frequency", 1]: observed [["Suggestion"]] but no static check
corpus/01-text/spell_suggest.sake: [8, 40, "Suggestion.get_frequency", 1]: observed [["Suggestion"]] but no static check
corpus/01-text/spell_suggest.sake: [8, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/01-text/spell_suggest.sake: [9, 16, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ini_config.sake | 3 | 86 | 4 | 4 | 0 | 80 | 0 | 0 |
| json_pretty.sake | 3 | 148 | 7 | 0 | 0 | 134 | 0 | 0 |
| justify_text.sake | 2 | 69 | 1 | 1 | 0 | 67 | 0 | 0 |
| line_diff.sake | 2 | 106 | 17 | 1 | 0 | 98 | 0 | 0 |
| markdown_html.sake | 2 | 99 | 7 | 1 | 0 | 99 | 0 | 0 |
| markdown_table.sake | 2 | 103 | 9 | 2 | 0 | 103 | 0 | 0 |
| number_words.sake | 2 | 80 | 4 | 0 | 0 | 73 | 0 | 0 |
| outline_number.sake | 3 | 96 | 8 | 4 | 0 | 97 | 0 | 0 |
| slugify.sake | 2 | 69 | 3 | 0 | 0 | 66 | 0 | 0 |
| spell_suggest.sake | 2 | 89 | 12 | 1 | 0 | 90 | 8 | 8 |
corpus/13-polymorphism/temperature_units.sake: [59, 33, "Comparable.<=>", "pair"]: observed [["Temp", "Temp"]] but no static check
corpus/13-polymorphism/temperature_units.sake: [59, 32, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| stack_vm.sake | 3 | 117 | 7 | 3 | 0 | 98 | 0 | 0 |
| task_heap.sake | 3 | 119 | 21 | 0 | 0 | 116 | 0 | 0 |
| temperature_units.sake | 2 | 133 | 5 | 3 | 0 | 115 | 2 | 2 |
| vector_polygon.sake | 3 | 148 | 13 | 0 | 0 | 142 | 0 | 0 |
| version_constraints.sake | 3 | 114 | 8 | 4 | 0 | 107 | 0 | 0 |
| bank_transfers.sake | 2 | 65 | 1 | 0 | 0 | 56 | 0 | 0 |
| card_validation.sake | 2 | 69 | 2 | 0 | 0 | 58 | 0 | 0 |
| circuit_breaker.sake | 2 | 47 | 0 | 0 | 0 | 38 | 0 | 0 |
| config_loader.sake | 2 | 48 | 0 | 1 | 0 | 39 | 0 | 0 |
| contracts.sake | 2 | 61 | 0 | 0 | 0 | 58 | 0 | 0 |
corpus/07-trees/dom_tree.sake: [111, 85, "Element.get_attrs", 1]: observed [["Element"]] but no static check
corpus/07-trees/dom_tree.sake: L45 Kernel.== pair: observed [["String", "Nil"], ["Nil", "Nil"]], static [nil, nil]
corpus/07-trees/dom_tree.sake: [45, 23, "String.split", 1]: observed [["String"]] but no static check
corpus/07-trees/dom_tree.sake: L54 Kernel.!= pair: observed [["Nil", "String"], ["String", "String"]], static [nil, nil | String]
corpus/07-trees/dom_tree.sake: L161 String.start_with? 1: observed [["String"]], static nil
corpus/07-trees/dom_tree.sake: L45 String.split result: observed ["Array"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| avl_tree.sake | 2 | 94 | 27 | 0 | 0 | 119 | 0 | 0 |
| bill_of_materials.sake | 3 | 90 | 13 | 3 | 0 | 84 | 0 | 0 |
| bst_basic.sake | 2 | 84 | 2 | 0 | 0 | 85 | 0 | 0 |
| btree.sake | 2 | 89 | 21 | 0 | 0 | 96 | 0 | 0 |
| decision_tree.sake | 2 | 96 | 12 | 0 | 0 | 86 | 0 | 0 |
| dom_tree.sake | 2 | 117 | 13 | 4 | 0 | 113 | 2 | 6 |
| expression_tree.sake | 4 | 53 | 0 | 5 | 49 | 96 | 0 | 0 |
| fenwick_ranks.sake | 2 | 72 | 7 | 0 | 0 | 69 | 0 | 0 |
| filesystem_du.sake | 2 | 104 | 4 | 1 | 0 | 99 | 0 | 0 |
| heap_scheduler.sake | 3 | 104 | 17 | 0 | 0 | 96 | 0 | 0 |
corpus/11-simulation/runway_ops.sake: [7, 16, "Flight.get_emergency", 1]: observed [["Flight"]] but no static check
corpus/11-simulation/runway_ops.sake: [8, 4, "Flight.get_op", 1]: observed [["Flight"]] but no static check
corpus/11-simulation/runway_ops.sake: [8, 4, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus/11-simulation/runway_ops.sake: [12, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/runway_ops.sake: [13, 16, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/runway_ops.sake: [14, 8, "Flight.get_scheduled", 1]: observed [["Flight"]] but no static check
corpus/11-simulation/runway_ops.sake: [14, 23, "Flight.get_scheduled", 1]: observed [["Flight"]] but no static check
corpus/11-simulation/runway_ops.sake: [14, 8, "Comparable.<=>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus/11-simulation/runway_ops.sake: [15, 4, "Kernel.!=", "pair"]: observed [["Integer", "Integer"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| inventory_reorder.sake | 3 | 142 | 7 | 0 | 0 | 135 | 0 | 0 |
| langton_ants.sake | 2 | 107 | 7 | 1 | 0 | 88 | 0 | 0 |
| library_loans.sake | 2 | 110 | 37 | 1 | 0 | 125 | 0 | 0 |
| life_torus.sake | 2 | 104 | 1 | 0 | 0 | 93 | 0 | 0 |
| order_book.sake | 2 | 131 | 6 | 0 | 0 | 127 | 0 | 0 |
| packet_network.sake | 2 | 136 | 15 | 0 | 0 | 124 | 0 | 0 |
| parking_garage.sake | 2 | 106 | 2 | 2 | 0 | 101 | 0 | 0 |
| ring_road_traffic.sake | 2 | 114 | 15 | 0 | 0 | 115 | 0 | 0 |
| runway_ops.sake | 2 | 103 | 8 | 0 | 0 | 111 | 9 | 9 |
| sandpile.sake | 2 | 106 | 14 | 0 | 0 | 97 | 0 | 0 |
