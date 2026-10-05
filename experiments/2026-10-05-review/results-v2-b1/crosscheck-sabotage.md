corpus-v2/08-graphs/currency_paths.sake: L58 Rational.to_f 1: observed [["Rational"]], static Integer
corpus-v2/08-graphs/currency_paths.sake: L47 Kernel.!= pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/08-graphs/currency_paths.sake: L48 Rational.to_s 1: observed [["Rational"]], static Integer
corpus-v2/08-graphs/dijkstra_routes.sake: L133 Float.round 1: observed [["Float"]], static Integer
corpus-v2/08-graphs/floyd_transit.sake: L39 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/08-graphs/friend_groups.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| critical_path.sake | 2 | 70 | 16 | 0 | 0 | 63 | 0 | 0 |
| currency_paths.sake | 2 | 58 | 12 | 2 | 0 | 47 | 0 | 3 |
| dijkstra_routes.sake | 3 | 87 | 6 | 1 | 0 | 64 | 0 | 1 |
| dot_stats.sake | 2 | 87 | 2 | 0 | 0 | 57 | 0 | 0 |
| euler_itinerary.sake | 2 | 60 | 2 | 0 | 0 | 48 | 0 | 0 |
| exam_slots.sake | 3 | 80 | 16 | 0 | 0 | 73 | 0 | 0 |
| floyd_transit.sake | 2 | 102 | 26 | 0 | 0 | 67 | 0 | 1 |
| friend_groups.sake | 2 | 81 | 9 | 0 | 0 | 69 | 0 | 1 |
| intern_matching.sake | 2 | 55 | 5 | 0 | 0 | 47 | 0 | 0 |
| kruskal_network.sake | 2 | 84 | 12 | 0 | 0 | 59 | 0 | 0 |
corpus-v2/05-sorting/bisect_on_answer.sake: L74 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L75 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L65 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/bisect_on_answer.sake: L66 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/bisect_on_answer.sake: L67 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/05-sorting/bisect_on_answer.sake: L67 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L67 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bisect_on_answer.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bisect_on_answer.sake: L133 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L13 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L15 Float.clamp 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/bucket_sort_ratings.sake: L36 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/bucket_sort_ratings.sake: L60 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L90 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L91 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L91 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/bucket_sort_ratings.sake: L91 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| autocomplete_msd.sake | 2 | 77 | 16 | 0 | 0 | 66 | 0 | 0 |
| bisect_on_answer.sake | 2 | 82 | 11 | 0 | 0 | 79 | 0 | 11 |
| bucket_sort_ratings.sake | 2 | 94 | 9 | 6 | 0 | 90 | 0 | 21 |
| external_sort_sim.sake | 3 | 116 | 19 | 0 | 0 | 98 | 0 | 0 |
| gift_two_pointers.sake | 2 | 115 | 19 | 0 | 0 | 93 | 0 | 0 |
| gradebook_insertion.sake | 2 | 67 | 6 | 0 | 0 | 56 | 0 | 0 |
| hashtag_trends.sake | 2 | 65 | 5 | 0 | 0 | 57 | 0 | 0 |
| heap_scheduler.sake | 3 | 103 | 5 | 0 | 0 | 70 | 0 | 0 |
| kway_log_merge.sake | 2 | 144 | 11 | 0 | 0 | 104 | 0 | 0 |
| leaderboard_insert.sake | 2 | 77 | 6 | 0 | 0 | 72 | 0 | 0 |
corpus-v2/08-graphs/prim_cables.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/08-graphs/prim_cables.sake: L82 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/08-graphs/prim_cables.sake: L82 Float.round 1: observed [["Float"]], static Integer
corpus-v2/08-graphs/prim_cables.sake: L82 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/08-graphs/prim_cables.sake: L82 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| land_islands.sake | 2 | 97 | 6 | 0 | 0 | 84 | 0 | 0 |
| make_rebuild.sake | 2 | 63 | 5 | 0 | 0 | 54 | 0 | 0 |
| maze_bfs.sake | 2 | 48 | 5 | 0 | 0 | 41 | 0 | 0 |
| metro_transfers.sake | 2 | 78 | 8 | 0 | 0 | 64 | 0 | 0 |
| org_chart_lca.sake | 3 | 126 | 36 | 0 | 0 | 89 | 0 | 0 |
| pipeline_flow.sake | 2 | 74 | 3 | 0 | 0 | 60 | 0 | 0 |
| prim_cables.sake | 3 | 96 | 19 | 2 | 0 | 69 | 0 | 5 |
| rival_teams.sake | 2 | 57 | 3 | 0 | 0 | 41 | 0 | 0 |
| tarjan_scc.sake | 3 | 103 | 9 | 0 | 0 | 84 | 0 | 0 |
| word_ladder.sake | 2 | 50 | 4 | 0 | 0 | 40 | 0 | 0 |
corpus-v2/09-dp/sequence_alignment.sake: L8 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/09-dp/viterbi.sake: L20 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus-v2/09-dp/viterbi.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus-v2/09-dp/viterbi.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
corpus-v2/09-dp/viterbi.sake: L45 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/09-dp/viterbi.sake: L70 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/09-dp/viterbi.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/09-dp/viterbi.sake: L70 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/09-dp/viterbi.sake: L44 Array.sum result: observed ["Float"], static Integer
corpus-v2/09-dp/viterbi.sake: L48 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sequence_alignment.sake | 2 | 120 | 17 | 0 | 0 | 91 | 0 | 1 |
| stock_trading.sake | 2 | 85 | 31 | 0 | 0 | 69 | 0 | 0 |
| subset_partition.sake | 2 | 76 | 5 | 0 | 0 | 55 | 0 | 0 |
| viterbi.sake | 2 | 68 | 15 | 0 | 0 | 59 | 0 | 9 |
| word_break.sake | 3 | 92 | 4 | 0 | 0 | 66 | 0 | 0 |
| battleship.sake | 3 | 106 | 2 | 0 | 0 | 90 | 0 | 0 |
| chess_attacks.sake | 2 | 96 | 0 | 0 | 0 | 82 | 0 | 0 |
| connect_four.sake | 2 | 69 | 13 | 0 | 0 | 64 | 0 | 0 |
| crossword.sake | 2 | 109 | 1 | 0 | 0 | 96 | 0 | 0 |
| falling_sand.sake | 3 | 85 | 7 | 0 | 0 | 69 | 0 | 0 |
corpus-v2/17-encodings/ascii85.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/17-encodings/ascii85.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/17-encodings/bloom_filter.sake: L47 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/17-encodings/bloom_filter.sake: L47 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/17-encodings/caesar_cracker.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/17-encodings/caesar_cracker.sake: L45 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/caesar_cracker.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/caesar_cracker.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/caesar_cracker.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/17-encodings/frame_parser.sake: L108 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii85.sake | 2 | 102 | 1 | 0 | 0 | 94 | 0 | 2 |
| base32_ids.sake | 2 | 89 | 5 | 0 | 0 | 72 | 0 | 0 |
| base64_codec.sake | 2 | 70 | 7 | 0 | 0 | 60 | 0 | 0 |
| bitset.sake | 2 | 121 | 1 | 0 | 0 | 103 | 0 | 0 |
| bloom_filter.sake | 2 | 83 | 2 | 0 | 0 | 76 | 0 | 2 |
| caesar_cracker.sake | 2 | 54 | 3 | 0 | 0 | 46 | 0 | 5 |
| check_digits.sake | 2 | 81 | 0 | 0 | 0 | 72 | 0 | 0 |
| crc_catalog.sake | 2 | 98 | 1 | 0 | 0 | 89 | 0 | 0 |
| frame_parser.sake | 2 | 162 | 18 | 0 | 0 | 133 | 0 | 1 |
| hamming_secded.sake | 2 | 85 | 0 | 0 | 0 | 74 | 0 | 0 |
corpus-v2/11-simulation/ecosystem_patches.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L19 Float.clamp 1: observed [["Float"]], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L19 Float.clamp 3: observed [["Float"]], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L24 Float.clamp 1: observed [["Float"]], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L24 Float.clamp 3: observed [["Float"]], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L28 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L40 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L41 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/ecosystem_patches.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L49 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L50 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/ecosystem_patches.sake: L72 Array.sum result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L73 Array.sum result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L74 Array.sum result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L49 Patch.set_rabbits result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L50 Patch.set_rabbits result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L78 Census.grass result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L78 Census.rabbits result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L78 Census.foxes result: observed ["Float"], static Integer
corpus-v2/11-simulation/ecosystem_patches.sake: L82 Census.rabbits result: observed ["Float"], static Integer
corpus-v2/11-simulation/epidemic_network.sake: L115 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/forest_fire.sake: L95 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/hotel_bookings.sake: L104 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: L27 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/hotel_bookings.sake: L38 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/hotel_bookings.sake: L16 Time.friday? 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: [17, 9, "Time.month", 1]: observed [["Time"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [17, 9, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [17, 32, "Time.day", 1]: observed [["Time"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [17, 32, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [16, 31, "Time.saturday?", 1]: observed [["Time"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: L53 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: L22 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/hotel_bookings.sake: L46 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: [70, 30, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [70, 29, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [70, 18, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [71, 14, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: [71, 38, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/hotel_bookings.sake: L120 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: L17 Time.month result: observed ["Integer"], static (none)
corpus-v2/11-simulation/hotel_bookings.sake: L17 Time.day result: observed ["Integer"], static (none)
corpus-v2/11-simulation/hotel_bookings.sake: L16 Time.saturday? result: observed ["Boolean"], static (none)
corpus-v2/11-simulation/hotel_bookings.sake: L70 Stay.first_night result: observed ["Time"], static Integer
corpus-v2/11-simulation/hotel_bookings.sake: L70 Float.to_i result: observed ["Integer"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bakery_shift.sake | 2 | 93 | 7 | 0 | 0 | 85 | 0 | 0 |
| bank_ledger.sake | 2 | 93 | 0 | 0 | 0 | 79 | 0 | 0 |
| car_rental.sake | 2 | 121 | 3 | 0 | 0 | 114 | 0 | 0 |
| checkout_lanes.sake | 3 | 100 | 1 | 0 | 0 | 82 | 0 | 0 |
| cpu_scheduler.sake | 2 | 95 | 2 | 0 | 0 | 83 | 0 | 0 |
| ecosystem_patches.sake | 2 | 131 | 1 | 4 | 0 | 125 | 0 | 25 |
| elevator_scan.sake | 2 | 161 | 5 | 0 | 0 | 158 | 0 | 0 |
| epidemic_network.sake | 2 | 115 | 5 | 0 | 0 | 92 | 0 | 1 |
| forest_fire.sake | 3 | 95 | 9 | 0 | 0 | 78 | 0 | 1 |
| hotel_bookings.sake | 3 | 116 | 1 | 5 | 0 | 121 | 10 | 23 |
corpus-v2/05-sorting/trail_peak_search.sake: L63 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/trail_peak_search.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/trail_peak_search.sake: L64 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/trail_peak_search.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L57 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/trail_peak_search.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L66 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/05-sorting/trail_peak_search.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sorted_matrix_search.sake | 2 | 80 | 13 | 0 | 0 | 67 | 0 | 0 |
| staff_multikey_sort.sake | 2 | 59 | 6 | 0 | 14 | 60 | 0 | 0 |
| trail_peak_search.sake | 2 | 87 | 7 | 0 | 0 | 69 | 0 | 11 |
| triage_partition.sake | 2 | 89 | 11 | 0 | 0 | 74 | 0 | 0 |
| version_resolver.sake | 2 | 83 | 14 | 0 | 0 | 68 | 0 | 0 |
| adjacency_list_courses.sake | 3 | 117 | 12 | 0 | 0 | 87 | 0 | 0 |
| bank_teller_sim.sake | 3 | 108 | 1 | 0 | 0 | 100 | 0 | 0 |
| browser_history.sake | 2 | 62 | 1 | 0 | 0 | 59 | 0 | 0 |
| chained_hash_table.sake | 3 | 118 | 0 | 0 | 0 | 96 | 0 | 0 |
| circular_playlist.sake | 2 | 92 | 13 | 0 | 0 | 95 | 0 | 0 |
corpus-v2/13-polymorphism/temperature_units.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L44 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L36 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L59 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/temperature_units.sake: L59 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/temperature_units.sake: L52 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L101 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L45 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L45 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L45 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L53 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L57 Arithmetic.+ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/temperature_units.sake: L12 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/temperature_units.sake: L101 Array.sum result: observed ["Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L7 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L7 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L31 Arithmetic./ pair: observed [["Vec", "Float"]], static [Vec, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L9 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L9 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L12 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L12 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L12 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L14 Math.sqrt 1: observed [["Integer"], ["Float"]], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L68 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L68 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L69 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L114 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/vector_polygon.sake: L115 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/vector_polygon.sake: L7 Vec.x result: observed ["Integer", "Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L7 Vec.y result: observed ["Integer", "Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L18 Vec.x result: observed ["Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L18 Vec.y result: observed ["Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L12 Vec.x result: observed ["Integer", "Float"], static Integer
corpus-v2/13-polymorphism/vector_polygon.sake: L12 Vec.y result: observed ["Integer", "Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| stack_vm.sake | 4 | 119 | 8 | 0 | 0 | 95 | 0 | 0 |
| task_heap.sake | 3 | 134 | 10 | 0 | 0 | 109 | 0 | 0 |
| temperature_units.sake | 3 | 134 | 7 | 2 | 0 | 114 | 0 | 18 |
| vector_polygon.sake | 3 | 159 | 8 | 0 | 0 | 138 | 0 | 20 |
| version_constraints.sake | 3 | 112 | 4 | 0 | 0 | 95 | 0 | 0 |
| bank_transfers.sake | 2 | 66 | 1 | 0 | 0 | 56 | 0 | 0 |
| card_validation.sake | 2 | 68 | 2 | 0 | 0 | 54 | 0 | 0 |
| circuit_breaker.sake | 2 | 47 | 0 | 0 | 0 | 38 | 0 | 0 |
| config_loader.sake | 2 | 48 | 0 | 0 | 0 | 37 | 0 | 0 |
| contracts.sake | 2 | 60 | 0 | 0 | 0 | 57 | 0 | 0 |
corpus-v2/11-simulation/teller_queue_des.sake: L121 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L45 Comparable.<= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L51 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L51 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/11-simulation/thermostat_house.sake: L51 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/thermostat_house.sake: L52 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L43 Comparable.>= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L72 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L84 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/thermostat_house.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/thermostat_house.sake: L52 Room.set_temp result: observed ["Float"], static Integer
corpus-v2/11-simulation/water_tanks.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/water_tanks.sake: L9 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L44 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/water_tanks.sake: L45 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/11-simulation/water_tanks.sake: L19 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L20 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/water_tanks.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L83 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/water_tanks.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/11-simulation/water_tanks.sake: L60 Tank.set_drawn result: observed ["Float"], static Integer
corpus-v2/12-parsers/chem_formula.sake: L53 Hash.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| teller_queue_des.sake | 2 | 146 | 12 | 0 | 0 | 120 | 0 | 1 |
| thermostat_house.sake | 2 | 93 | 2 | 0 | 0 | 74 | 0 | 15 |
| traffic_intersection.sake | 2 | 108 | 4 | 0 | 0 | 91 | 0 | 0 |
| vending_machine.sake | 2 | 120 | 4 | 0 | 0 | 109 | 0 | 0 |
| water_tanks.sake | 2 | 99 | 28 | 0 | 0 | 111 | 0 | 14 |
| assembler.sake | 2 | 137 | 24 | 0 | 0 | 87 | 0 | 0 |
| brainfuck.sake | 2 | 74 | 4 | 0 | 0 | 48 | 0 | 0 |
| calc_rd.sake | 4 | 129 | 12 | 0 | 0 | 118 | 0 | 0 |
| chem_formula.sake | 3 | 78 | 11 | 0 | 0 | 71 | 0 | 1 |
| cmdline_parser.sake | 2 | 92 | 8 | 0 | 0 | 77 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ini_config.sake | 3 | 90 | 3 | 0 | 0 | 75 | 0 | 0 |
| json_pretty.sake | 4 | 152 | 6 | 0 | 0 | 128 | 0 | 0 |
| justify_text.sake | 2 | 68 | 1 | 0 | 0 | 66 | 0 | 0 |
| line_diff.sake | 2 | 123 | 15 | 0 | 0 | 96 | 0 | 0 |
| markdown_html.sake | 2 | 100 | 6 | 0 | 0 | 97 | 0 | 0 |
| markdown_table.sake | 2 | 112 | 10 | 0 | 0 | 101 | 0 | 0 |
| number_words.sake | 2 | 86 | 1 | 0 | 0 | 69 | 0 | 0 |
| outline_number.sake | 2 | 95 | 9 | 0 | 0 | 94 | 0 | 0 |
| slugify.sake | 2 | 70 | 3 | 0 | 0 | 63 | 0 | 0 |
| spell_suggest.sake | 2 | 112 | 12 | 0 | 0 | 86 | 0 | 0 |
corpus-v2/17-encodings/lzw.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| hex_dump.sake | 2 | 73 | 2 | 0 | 0 | 62 | 0 | 0 |
| huffman.sake | 2 | 78 | 8 | 0 | 0 | 76 | 0 | 0 |
| lzw.sake | 2 | 65 | 6 | 0 | 0 | 55 | 0 | 1 |
| morse.sake | 2 | 74 | 0 | 0 | 0 | 70 | 0 | 0 |
| murmur_ring.sake | 2 | 90 | 7 | 0 | 0 | 77 | 0 | 0 |
| percent_encoding.sake | 2 | 83 | 1 | 0 | 0 | 69 | 0 | 0 |
| playfair.sake | 2 | 88 | 1 | 0 | 0 | 74 | 0 | 0 |
| protobuf_wire.sake | 2 | 110 | 9 | 0 | 0 | 90 | 0 | 0 |
| raid5_parity.sake | 3 | 118 | 7 | 0 | 0 | 110 | 0 | 0 |
| rolling_sync.sake | 2 | 129 | 6 | 0 | 0 | 101 | 0 | 0 |
corpus-v2/11-simulation/order_book.sake: L113 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
corpus-v2/11-simulation/parking_garage.sake: L94 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/11-simulation/parking_garage.sake: L37 Kernel.== pair: observed [["Ticket", "Nil"]], static [nil, nil]
corpus-v2/11-simulation/parking_garage.sake: [38, 11, "Ticket.spot", 1]: observed [["Ticket"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [39, 4, "Spot.set_plate", 1]: observed [["Spot"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [40, 31, "Ticket.entered", 1]: observed [["Ticket"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [40, 26, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [40, 25, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [40, 14, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [41, 26, "Ticket.kind", 1]: observed [["Ticket"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [57, 14, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [58, 10, "Integer.ceildiv", 1]: observed [["Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [59, 9, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [60, 15, "Integer.divmod", 1]: observed [["Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [62, 12, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [63, 23, "Comparable.>", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [64, 2, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [64, 2, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [59, 38, "Kernel.==", "pair"]: observed [["Symbol", "Symbol"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [123, 33, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: [123, 49, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/11-simulation/parking_garage.sake: L31 Ticket.new result: observed ["Ticket"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L36 Hash.delete result: observed ["Ticket", "Nil"], static nil
corpus-v2/11-simulation/parking_garage.sake: L38 Ticket.spot result: observed ["Spot"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L39 Spot.set_plate result: observed ["Nil"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L40 Ticket.entered result: observed ["Time"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L40 Float.to_i result: observed ["Integer"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L41 Ticket.kind result: observed ["Symbol"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L58 Integer.ceildiv result: observed ["Integer"], static (none)
corpus-v2/11-simulation/parking_garage.sake: L60 Integer.divmod result: observed ["Tuple"], static (none)
corpus-v2/11-simulation/ring_road_traffic.sake: L32 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/11-simulation/ring_road_traffic.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/11-simulation/ring_road_traffic.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus-v2/11-simulation/sandpile.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| inventory_reorder.sake | 3 | 146 | 3 | 0 | 0 | 135 | 0 | 0 |
| langton_ants.sake | 2 | 115 | 9 | 0 | 0 | 87 | 0 | 0 |
| library_loans.sake | 2 | 136 | 10 | 0 | 0 | 122 | 0 | 0 |
| life_torus.sake | 2 | 103 | 1 | 0 | 0 | 90 | 0 | 0 |
| order_book.sake | 2 | 130 | 6 | 0 | 0 | 121 | 0 | 1 |
| packet_network.sake | 2 | 134 | 14 | 0 | 0 | 117 | 0 | 0 |
| parking_garage.sake | 2 | 83 | 1 | 1 | 0 | 96 | 18 | 29 |
| ring_road_traffic.sake | 2 | 115 | 13 | 1 | 0 | 111 | 0 | 3 |
| runway_ops.sake | 2 | 111 | 6 | 0 | 0 | 107 | 0 | 0 |
| sandpile.sake | 2 | 113 | 14 | 0 | 0 | 97 | 0 | 1 |
corpus-v2/19-statemachines/morse_decoder.sake: L35 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/19-statemachines/morse_decoder.sake: L45 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/19-statemachines/morse_decoder.sake: L49 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/19-statemachines/morse_decoder.sake: L50 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/19-statemachines/morse_decoder.sake: L60 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/19-statemachines/morse_decoder.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expr_lexer.sake | 2 | 71 | 0 | 0 | 0 | 55 | 0 | 0 |
| http_parser.sake | 5 | 138 | 15 | 0 | 0 | 127 | 0 | 0 |
| job_pipeline.sake | 3 | 86 | 3 | 0 | 0 | 82 | 0 | 0 |
| keypad_lock.sake | 2 | 69 | 1 | 0 | 0 | 67 | 0 | 0 |
| machine_mixin.sake | 2 | 66 | 0 | 0 | 0 | 58 | 0 | 0 |
| markdown_blocks.sake | 3 | 114 | 4 | 0 | 0 | 105 | 0 | 0 |
| morse_decoder.sake | 2 | 81 | 5 | 0 | 0 | 67 | 0 | 6 |
| order_workflow.sake | 3 | 78 | 0 | 0 | 0 | 67 | 0 | 0 |
| regex_nfa.sake | 3 | 108 | 16 | 0 | 0 | 106 | 0 | 0 |
| shell_words.sake | 2 | 70 | 2 | 0 | 0 | 56 | 0 | 0 |
corpus-v2/07-trees/huffman.sake: L82 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L7 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L31 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L25 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/07-trees/kd_tree.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L33 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/07-trees/kd_tree.sake: L49 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L40 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L52 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L52 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/kd_tree.sake: L113 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/07-trees/kd_tree.sake: L27 Search.set_best_d2 result: observed ["Float"], static Integer
corpus-v2/07-trees/lazy_seat_inventory.sake: L109 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| huffman.sake | 3 | 90 | 10 | 0 | 0 | 85 | 0 | 1 |
| interval_bookings.sake | 3 | 92 | 2 | 0 | 0 | 89 | 0 | 0 |
| ip_route_trie.sake | 3 | 96 | 12 | 0 | 0 | 103 | 0 | 0 |
| kd_tree.sake | 3 | 118 | 14 | 0 | 0 | 122 | 0 | 13 |
| lazy_seat_inventory.sake | 3 | 149 | 12 | 0 | 0 | 122 | 0 | 1 |
| merkle_sync.sake | 3 | 81 | 6 | 0 | 0 | 67 | 0 | 0 |
| org_chart.sake | 3 | 107 | 12 | 0 | 0 | 108 | 0 | 0 |
| quadtree.sake | 3 | 121 | 19 | 0 | 0 | 130 | 0 | 0 |
| rope_editor.sake | 3 | 64 | 6 | 0 | 0 | 54 | 0 | 0 |
| segment_tree_stats.sake | 3 | 145 | 8 | 0 | 0 | 97 | 0 | 0 |
corpus-v2/10-grids/terrain_dijkstra.sake: L50 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| minesweeper.sake | 3 | 73 | 11 | 0 | 0 | 76 | 0 | 0 |
| n_queens.sake | 2 | 67 | 0 | 0 | 0 | 62 | 0 | 0 |
| nonogram.sake | 4 | 116 | 5 | 0 | 0 | 95 | 0 | 0 |
| othello.sake | 2 | 105 | 10 | 0 | 0 | 81 | 0 | 0 |
| sliding_puzzle.sake | 2 | 153 | 12 | 0 | 0 | 117 | 0 | 0 |
| sokoban.sake | 3 | 121 | 1 | 0 | 0 | 112 | 0 | 0 |
| sudoku_solver.sake | 2 | 99 | 3 | 0 | 0 | 84 | 0 | 0 |
| terrain_dijkstra.sake | 3 | 81 | 10 | 0 | 0 | 60 | 0 | 1 |
| tic_tac_toe.sake | 3 | 82 | 4 | 0 | 0 | 66 | 0 | 0 |
| word_search.sake | 2 | 94 | 3 | 0 | 0 | 77 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| flood_fill.sake | 2 | 94 | 9 | 0 | 0 | 79 | 0 | 0 |
| game_2048.sake | 4 | 95 | 7 | 0 | 0 | 79 | 0 | 0 |
| game_of_life.sake | 2 | 73 | 3 | 0 | 0 | 63 | 0 | 0 |
| hex_game.sake | 2 | 129 | 0 | 0 | 0 | 112 | 0 | 0 |
| knights_tour.sake | 2 | 88 | 7 | 0 | 0 | 82 | 0 | 0 |
| langtons_ant.sake | 2 | 84 | 1 | 0 | 0 | 71 | 0 | 0 |
| lights_out.sake | 2 | 76 | 0 | 0 | 0 | 74 | 0 | 0 |
| magic_square.sake | 2 | 101 | 8 | 0 | 0 | 85 | 0 | 0 |
| matrix_spiral.sake | 3 | 130 | 6 | 0 | 0 | 107 | 0 | 0 |
| maze_bfs.sake | 2 | 70 | 6 | 0 | 0 | 57 | 0 | 0 |
corpus-v2/03-numtheory/integer_partitions.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/03-numtheory/integer_partitions.sake: L89 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/integer_partitions.sake: L89 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/integer_partitions.sake: L89 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/03-numtheory/integer_partitions.sake: L90 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus-v2/03-numtheory/linear_sieve.sake: L71 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/03-numtheory/linear_sieve.sake: L80 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/03-numtheory/linear_sieve.sake: L80 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| goldbach.sake | 2 | 88 | 4 | 0 | 0 | 69 | 0 | 0 |
| happy_cycles.sake | 2 | 73 | 4 | 0 | 0 | 63 | 0 | 0 |
| integer_partitions.sake | 2 | 120 | 7 | 0 | 0 | 98 | 0 | 5 |
| linear_diophantine.sake | 2 | 94 | 0 | 0 | 0 | 69 | 0 | 0 |
| linear_sieve.sake | 2 | 141 | 20 | 1 | 0 | 95 | 0 | 3 |
| miller_rabin.sake | 2 | 82 | 0 | 0 | 0 | 79 | 0 | 0 |
| modular_crt.sake | 2 | 109 | 0 | 0 | 0 | 95 | 0 | 0 |
| perfect_amicable.sake | 2 | 77 | 10 | 0 | 0 | 63 | 0 | 0 |
| pollard_rho.sake | 3 | 114 | 0 | 0 | 0 | 106 | 0 | 0 |
| primitive_roots.sake | 2 | 138 | 2 | 0 | 0 | 132 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| moon_phases.sake | 2 | 159 | 1 | 0 | 0 | 143 | 0 | 0 |
| parking_fees.sake | 2 | 94 | 21 | 0 | 0 | 102 | 0 | 0 |
| project_gantt.sake | 3 | 160 | 8 | 0 | 0 | 154 | 0 | 0 |
| public_holidays.sake | 2 | 170 | 0 | 0 | 0 | 156 | 0 | 0 |
| recurring_events.sake | 2 | 135 | 8 | 0 | 0 | 132 | 0 | 0 |
| room_booking.sake | 2 | 109 | 2 | 0 | 0 | 93 | 0 | 0 |
| shift_rota.sake | 3 | 112 | 3 | 0 | 0 | 96 | 0 | 0 |
| time_zones.sake | 2 | 138 | 0 | 0 | 0 | 130 | 0 | 0 |
| timesheet.sake | 3 | 119 | 19 | 0 | 0 | 124 | 0 | 0 |
| timetable.sake | 2 | 62 | 11 | 0 | 0 | 60 | 0 | 0 |
corpus-v2/05-sorting/merge_sort_inversions.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/merge_sort_inversions.sake: L52 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/05-sorting/radix_order_ids.sake: L43 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/radix_order_ids.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/radix_order_ids.sake: L98 Float.round 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/radix_order_ids.sake: L98 Array.sum result: observed ["Float"], static Integer
corpus-v2/05-sorting/sensor_quickselect.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/05-sorting/sensor_quickselect.sake: L68 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/05-sorting/sensor_quickselect.sake: L68 Float.ceil 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/sensor_quickselect.sake: L100 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/05-sorting/sensor_quickselect.sake: [100, 29, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/05-sorting/sensor_quickselect.sake: [100, 48, "Float.round", 1]: observed [["Float"]] but no static check
corpus-v2/05-sorting/sensor_quickselect.sake: L100 Float.round result: observed ["Float"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| library_catalog.sake | 2 | 87 | 6 | 0 | 0 | 79 | 0 | 0 |
| log_time_bisect.sake | 2 | 73 | 10 | 0 | 0 | 64 | 0 | 0 |
| meeting_intervals.sake | 2 | 101 | 8 | 0 | 0 | 90 | 0 | 0 |
| merge_sort_inversions.sake | 4 | 84 | 5 | 0 | 0 | 66 | 0 | 2 |
| natural_runs_sort.sake | 2 | 177 | 15 | 0 | 0 | 128 | 0 | 0 |
| probe_count_search.sake | 2 | 96 | 13 | 0 | 0 | 82 | 0 | 0 |
| quicksort_median3.sake | 2 | 81 | 11 | 0 | 0 | 70 | 0 | 0 |
| radix_order_ids.sake | 2 | 74 | 5 | 2 | 0 | 63 | 0 | 4 |
| sensor_quickselect.sake | 3 | 103 | 11 | 2 | 0 | 83 | 2 | 7 |
| shell_sort_gaps.sake | 2 | 76 | 2 | 0 | 0 | 52 | 0 | 0 |
corpus-v2/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L31 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L31 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/bezier_curves.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/bezier_curves.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L10 Math.hypot 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/bezier_curves.sake: L10 Math.hypot 2: observed [["Float"]], static Integer
corpus-v2/04-numeric/bezier_curves.sake: L55 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L65 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/bezier_curves.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/bezier_curves.sake: L67 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/bezier_curves.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/bezier_curves.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus-v2/04-numeric/bezier_curves.sake: L90 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/correlation_matrix.sake: L19 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L32 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L95 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L95 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/correlation_matrix.sake: L102 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L102 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L102 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L102 Math.log 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L104 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L104 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L106 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/correlation_matrix.sake: L113 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L19 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/correlation_matrix.sake: L20 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/cubic_spline.sake: L94 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L92 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L31 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L99 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L57 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
corpus-v2/04-numeric/cubic_spline.sake: L57 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
corpus-v2/04-numeric/cubic_spline.sake: L47 Comparable.<= pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L62 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L85 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L88 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L89 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L89 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L89 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L78 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L78 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L78 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L78 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L79 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L106 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L108 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L108 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/cubic_spline.sake: L109 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L109 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/cubic_spline.sake: L110 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L110 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/cubic_spline.sake: L67 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L68 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L69 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/cubic_spline.sake: L70 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L116 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L116 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L116 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/cubic_spline.sake: L57 Array.first result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/cubic_spline.sake: L57 Array.last result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/cubic_spline.sake: L86 Array.last result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/curve_fitting.sake: L66 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus-v2/04-numeric/curve_fitting.sake: L53 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus-v2/04-numeric/curve_fitting.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus-v2/04-numeric/curve_fitting.sake: L57 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus-v2/04-numeric/curve_fitting.sake: L57 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L74 Math.exp 1: observed [["Float"]], static nil | Integer
corpus-v2/04-numeric/curve_fitting.sake: L17 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L5 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L5 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L5 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L9 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L10 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L10 Math.log 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L10 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/curve_fitting.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
corpus-v2/04-numeric/curve_fitting.sake: L25 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L103 Float.abs 1: observed [["Float"]], static Integer | nil
corpus-v2/04-numeric/curve_fitting.sake: L65 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L66 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L5 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/curve_fitting.sake: L9 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: L3 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L14 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: [15, 7, "Float.ceil", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: [16, 23, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: L7 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L7 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L7 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L10 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: [17, 9, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: [18, 16, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: [18, 2, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: [18, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: [18, 2, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/descriptive_stats.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L27 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/descriptive_stats.sake: L27 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/descriptive_stats.sake: L90 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: L3 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: L15 Float.ceil result: observed ["Integer"], static (none)
corpus-v2/04-numeric/descriptive_stats.sake: L7 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/descriptive_stats.sake: L27 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| pythagorean_triples.sake | 2 | 163 | 3 | 0 | 0 | 152 | 0 | 0 |
| quadratic_residues.sake | 2 | 148 | 0 | 0 | 0 | 132 | 0 | 0 |
| repeating_decimals.sake | 2 | 79 | 14 | 0 | 0 | 69 | 0 | 0 |
| rsa_toy.sake | 2 | 98 | 0 | 0 | 0 | 92 | 0 | 0 |
| sieve_primes.sake | 2 | 86 | 2 | 0 | 0 | 72 | 0 | 0 |
| bezier_curves.sake | 2 | 118 | 14 | 0 | 4 | 110 | 0 | 22 |
| correlation_matrix.sake | 2 | 141 | 11 | 3 | 0 | 114 | 0 | 44 |
| cubic_spline.sake | 2 | 268 | 43 | 11 | 0 | 199 | 0 | 81 |
| curve_fitting.sake | 2 | 138 | 29 | 1 | 0 | 113 | 0 | 24 |
| descriptive_stats.sake | 2 | 73 | 1 | 2 | 19 | 82 | 7 | 22 |
corpus-v2/01-text/text_stats.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/01-text/text_stats.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/01-text/text_stats.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/01-text/text_stats.sake: L53 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/01-text/text_stats.sake: L53 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/caesar_crack.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/caesar_crack.sake: L35 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/caesar_crack.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/caesar_crack.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/caesar_crack.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/cooccurrence_pmi.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/cooccurrence_pmi.sake: L46 Math.log2 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| template_render.sake | 2 | 57 | 3 | 0 | 0 | 48 | 0 | 0 |
| text_box.sake | 3 | 99 | 6 | 0 | 0 | 91 | 0 | 0 |
| text_stats.sake | 2 | 73 | 2 | 0 | 0 | 66 | 0 | 5 |
| whitespace_tidy.sake | 2 | 106 | 5 | 0 | 0 | 95 | 0 | 0 |
| word_wrap.sake | 2 | 71 | 6 | 0 | 0 | 70 | 0 | 0 |
| access_log_urls.sake | 2 | 133 | 11 | 0 | 0 | 109 | 0 | 0 |
| anagram_groups.sake | 2 | 73 | 3 | 0 | 0 | 62 | 0 | 0 |
| autocomplete.sake | 2 | 61 | 7 | 0 | 0 | 54 | 0 | 0 |
| caesar_crack.sake | 2 | 56 | 2 | 0 | 0 | 48 | 0 | 5 |
| cooccurrence_pmi.sake | 2 | 74 | 0 | 0 | 0 | 58 | 0 | 2 |
corpus-v2/18-collections/sales_pivot.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/18-collections/sales_pivot.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/sales_pivot.sake: L97 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/18-collections/sales_pivot.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/18-collections/sales_pivot.sake: L97 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/18-collections/sales_pivot.sake: L71 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sales_pivot.sake: L74 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sales_pivot.sake: L75 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sales_pivot.sake: L83 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sensor_merge.sake: L29 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/sensor_merge.sake: L63 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/18-collections/sensor_merge.sake: L63 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/18-collections/sensor_merge.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/sensor_merge.sake: L29 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sensor_merge.sake: L72 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/sparse_vectors.sake: L57 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/18-collections/survey_venn.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| range_set.sake | 2 | 107 | 15 | 0 | 0 | 113 | 0 | 0 |
| role_permissions.sake | 2 | 93 | 8 | 0 | 0 | 83 | 0 | 0 |
| room_bookings.sake | 2 | 100 | 22 | 0 | 0 | 110 | 0 | 0 |
| sales_pivot.sake | 2 | 134 | 14 | 0 | 0 | 103 | 0 | 9 |
| sensor_merge.sake | 2 | 118 | 4 | 1 | 0 | 99 | 0 | 6 |
| sparse_vectors.sake | 3 | 111 | 7 | 0 | 0 | 90 | 0 | 1 |
| survey_venn.sake | 2 | 100 | 3 | 0 | 0 | 98 | 0 | 1 |
| tag_recommender.sake | 2 | 114 | 4 | 0 | 0 | 106 | 0 | 0 |
| word_pipeline.sake | 2 | 102 | 2 | 0 | 0 | 93 | 0 | 0 |
| word_rack.sake | 2 | 123 | 3 | 0 | 0 | 116 | 0 | 0 |
corpus-v2/04-numeric/monte_carlo.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L39 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L39 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L41 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L65 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/monte_carlo.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L70 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/monte_carlo.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L21 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/monte_carlo.sake: L22 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L23 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/monte_carlo.sake: L23 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L23 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L54 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L55 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L71 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L71 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/monte_carlo.sake: L56 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L56 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L28 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/monte_carlo.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L74 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L74 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L77 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L87 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/monte_carlo.sake: L107 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/monte_carlo.sake: L107 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/monte_carlo.sake: L109 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L4 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L6 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/numeric_integration.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L16 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L18 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L18 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L63 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L68 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L75 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/numeric_integration.sake: L79 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L79 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L25 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L26 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/numeric_integration.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L33 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numeric_integration.sake: L33 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L117 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numeric_integration.sake: L101 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L101 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numeric_integration.sake: L125 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numeric_integration.sake: L125 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L1 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L3 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L4 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L4 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L12 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L53 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L36 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L27 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L70 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L70 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L5 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L84 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/numerical_derivatives.sake: L84 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L84 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/numerical_derivatives.sake: L96 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/numerical_derivatives.sake: L104 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L53 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/ode_solver.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/ode_solver.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/ode_solver.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/ode_solver.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L23 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L23 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L59 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L59 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/ode_solver.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/ode_solver.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/ode_solver.sake: L61 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/ode_solver.sake: L72 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L78 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus-v2/04-numeric/ode_solver.sake: L75 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus-v2/04-numeric/ode_solver.sake: L90 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L91 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L92 Math.log2 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/ode_solver.sake: L38 State.set_t result: observed ["Float"], static Integer
corpus-v2/04-numeric/ode_solver.sake: L74 State.set_t result: observed ["Float"], static Integer
corpus-v2/04-numeric/optimization.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L15 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L98 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L98 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L98 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L19 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/optimization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/optimization.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L30 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L30 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L30 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L35 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/optimization.sake: L99 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/optimization.sake: L100 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L100 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L38 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L38 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/optimization.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L55 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L71 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/optimization.sake: L75 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L78 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L82 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/polynomial.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/polynomial.sake: L54 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/polynomial.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/polynomial.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/polynomial.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/polynomial.sake: L92 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/polynomial.sake: L142 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/polynomial.sake: L142 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/polynomial.sake: L142 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/root_finding.sake: L61 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/root_finding.sake: L9 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/root_finding.sake: L9 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L11 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/root_finding.sake: L15 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/root_finding.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/root_finding.sake: L31 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/root_finding.sake: [32, 11, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [33, 4, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [34, 45, "Float.abs", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [34, 45, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [43, 8, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [44, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [45, 12, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [46, 59, "Kernel.==", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [47, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [47, 14, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [47, 14, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [47, 9, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [48, 52, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [48, 42, "Float.abs", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [48, 42, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [68, 49, "Math.cos", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [68, 49, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [69, 46, "Math.cos", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [69, 46, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [69, 64, "Math.sin", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [69, 63, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [73, 11, "Float[]", "elem"]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [73, 0, "Array.each", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 44, "Math.sin", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 38, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 34, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 73, "Math.cos", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 67, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [74, 61, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [75, 53, "Result.root", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [75, 69, "Result.iterations", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [75, 7, "Kernel.format", 1]: observed [["String"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [79, 11, "Float[]", "elem"]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [79, 0, "Array.each", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [81, 19, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [81, 41, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [81, 41, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [82, 32, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [82, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [82, 43, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [83, 16, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [83, 42, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [83, 42, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [85, 10, "Array.max_by", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [85, 43, "Result.root", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [85, 60, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [85, 43, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [85, 33, "Float.abs", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [86, 20, "Array.map", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [86, 40, "Result.iterations", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [86, 10, "Array.sum", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 65, "Result.method", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 97, "Result.root", 1]: observed [["Result"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 118, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 97, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 87, "Float.abs", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [87, 7, "Kernel.format", 1]: observed [["String"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [92, 34, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [92, 34, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [94, 46, "BadBracket.a", 1]: observed [["BadBracket"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [94, 63, "BadBracket.b", 1]: observed [["BadBracket"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [94, 7, "Kernel.format", 1]: observed [["String"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 32, "Arithmetic.**", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 41, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 32, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 62, "Arithmetic.**", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 56, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [98, 56, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [100, 10, "NoConvergence.method", 1]: observed [["NoConvergence"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [100, 50, "NoConvergence.iterations", 1]: observed [["NoConvergence"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [104, 32, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [104, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [104, 45, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [106, 10, "NoConvergence.method", 1]: observed [["NoConvergence"]] but no static check
corpus-v2/04-numeric/root_finding.sake: [106, 50, "NoConvergence.iterations", 1]: observed [["NoConvergence"]] but no static check
corpus-v2/04-numeric/root_finding.sake: L58 Result.root result: observed ["Float"], static Integer
corpus-v2/04-numeric/root_finding.sake: L34 Float.abs result: observed ["Float"], static (none)
corpus-v2/04-numeric/root_finding.sake: L34 Result.new result: observed ["Result"], static (none)
corpus-v2/04-numeric/special_functions.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L22 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L22 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L22 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L90 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L90 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L93 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L15 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L35 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/special_functions.sake: L35 Math.log 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L105 Math.log 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L107 Float.infinite? 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L42 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/special_functions.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/special_functions.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L55 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/special_functions.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L113 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L70 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/special_functions.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L122 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L126 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L126 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L127 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L133 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L133 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/special_functions.sake: L139 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/04-numeric/special_functions.sake: L75 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L75 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/special_functions.sake: L75 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/time_series.sake: L77 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L42 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/time_series.sake: L54 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/time_series.sake: L55 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/time_series.sake: L55 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/time_series.sake: L16 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/time_series.sake: L24 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L33 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L34 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L34 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/time_series.sake: L66 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/time_series.sake: L66 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/time_series.sake: L68 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/time_series.sake: L68 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/time_series.sake: L105 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L109 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/time_series.sake: L110 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L110 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/time_series.sake: L111 Float.abs 1: observed [["Float"]], static nil | Integer
corpus-v2/04-numeric/time_series.sake: L77 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L16 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L33 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L34 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L105 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L110 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/time_series.sake: L110 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/vector_geometry.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L21 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L30 Math.atan2 2: observed [["Float"]], static Integer
corpus-v2/04-numeric/vector_geometry.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/vector_geometry.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L33 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/vector_geometry.sake: L79 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/vector_geometry.sake: L93 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monte_carlo.sake | 2 | 124 | 0 | 1 | 0 | 118 | 0 | 36 |
| numeric_integration.sake | 2 | 119 | 5 | 5 | 2 | 115 | 0 | 46 |
| numerical_derivatives.sake | 2 | 133 | 19 | 8 | 0 | 130 | 0 | 29 |
| ode_solver.sake | 3 | 125 | 20 | 6 | 0 | 92 | 0 | 29 |
| optimization.sake | 2 | 157 | 15 | 1 | 0 | 139 | 0 | 43 |
| polynomial.sake | 3 | 174 | 11 | 3 | 0 | 141 | 0 | 9 |
| root_finding.sake | 2 | 27 | 0 | 1 | 0 | 103 | 76 | 90 |
| special_functions.sake | 2 | 149 | 7 | 3 | 0 | 146 | 0 | 48 |
| time_series.sake | 3 | 154 | 25 | 3 | 0 | 130 | 0 | 29 |
| vector_geometry.sake | 2 | 124 | 2 | 1 | 0 | 117 | 0 | 14 |
corpus-v2/15-data/fulfillment_report.sake: L117 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/fulfillment_report.sake: L128 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: [46, 30, "Rational.to_f", 1]: observed [["Rational"]] but no static check
corpus-v2/15-data/fx_conversion.sake: L72 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: L73 Comparable.< pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: L74 Arithmetic.+ pair: observed [["Rational", "Rational"], ["Rational", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: L78 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus-v2/15-data/fx_conversion.sake: L84 Rational.abs 1: observed [["Rational"]], static Integer
corpus-v2/15-data/fx_conversion.sake: L85 Rational.abs 1: observed [["Rational"]], static Integer
corpus-v2/15-data/fx_conversion.sake: L86 Rational.abs 1: observed [["Rational"]], static Integer
corpus-v2/15-data/fx_conversion.sake: L87 Arithmetic./ pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: L87 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/fx_conversion.sake: L87 Rational.to_f 1: observed [["Rational"]], static Integer
corpus-v2/15-data/fx_conversion.sake: L72 Array.sum result: observed ["Rational", "Integer"], static Integer
corpus-v2/15-data/fx_conversion.sake: L73 Array.sum result: observed ["Rational", "Integer"], static Integer
corpus-v2/15-data/fx_conversion.sake: L76 Array.sum result: observed ["Rational"], static Integer
corpus-v2/15-data/fx_conversion.sake: L84 Array.sum result: observed ["Rational"], static Integer
corpus-v2/15-data/fx_conversion.sake: L85 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/fx_conversion.sake: L86 Array.sum result: observed ["Rational"], static Integer
corpus-v2/15-data/grade_book.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/grade_book.sake: L61 Float.round 1: observed [["Float"]], static Integer
corpus-v2/15-data/grade_book.sake: L61 Float.round 1: observed [["Float"]], static Integer
corpus-v2/15-data/grade_book.sake: L39 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L40 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L41 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L42 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L51 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L51 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L51 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/15-data/grade_book.sake: L104 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/grade_book.sake: L35 Hash.sum result: observed ["Float"], static Integer
corpus-v2/15-data/grade_book.sake: L47 Array.sum result: observed ["Float", "Integer"], static Integer
corpus-v2/15-data/grade_book.sake: L51 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/grade_book.sake: L85 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/15-data/grade_book.sake: L85 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/15-data/groupby_query.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/groupby_query.sake: L45 Array.sum result: observed ["Float", "Integer"], static Integer
corpus-v2/15-data/groupby_query.sake: L46 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/inventory_diff.sake: L92 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Float | Integer | String]
corpus-v2/15-data/inventory_diff.sake: L93 Comparable.<= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/inventory_diff.sake: L97 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | String]
corpus-v2/15-data/inventory_diff.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/inventory_diff.sake: L97 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/inventory_diff.sake: L101 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/inventory_diff.sake: L97 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/inventory_diff.sake: L59 Hash.sum result: observed ["Float"], static Integer
corpus-v2/15-data/invoice_totals.sake: [8, 26, "Float.round", 1]: observed [["Float"]] but no static check
corpus-v2/15-data/metric_anomalies.sake: L29 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/metric_anomalies.sake: L29 Float.round 1: observed [["Float"]], static Integer
corpus-v2/15-data/metric_anomalies.sake: L49 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/15-data/metric_anomalies.sake: L49 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/metric_anomalies.sake: L49 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/metric_anomalies.sake: L49 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/15-data/metric_anomalies.sake: L55 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/metric_anomalies.sake: L60 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/15-data/metric_anomalies.sake: L79 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/metric_anomalies.sake: L80 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/15-data/metric_anomalies.sake: [81, 90, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/15-data/metric_anomalies.sake: L90 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer | nil]
corpus-v2/15-data/metric_anomalies.sake: L90 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/15-data/metric_anomalies.sake: L90 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Float]
corpus-v2/15-data/metric_anomalies.sake: L90 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/15-data/metric_anomalies.sake: L49 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/metric_anomalies.sake: L81 Kernel.format result: observed ["String"], static (none)
corpus-v2/15-data/metric_anomalies.sake: L81 Kernel.puts result: observed ["Nil"], static (none)
corpus-v2/15-data/quality_rules.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/sales_by_region.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| fulfillment_report.sake | 2 | 141 | 0 | 0 | 0 | 120 | 0 | 2 |
| fx_conversion.sake | 2 | 85 | 2 | 4 | 0 | 78 | 1 | 17 |
| grade_book.sake | 2 | 86 | 0 | 2 | 0 | 78 | 0 | 19 |
| groupby_query.sake | 2 | 87 | 5 | 0 | 0 | 76 | 0 | 3 |
| inventory_diff.sake | 2 | 135 | 4 | 0 | 0 | 130 | 0 | 8 |
| invoice_totals.sake | 2 | 103 | 0 | 0 | 0 | 82 | 1 | 1 |
| league_standings.sake | 3 | 123 | 4 | 0 | 0 | 103 | 0 | 0 |
| metric_anomalies.sake | 2 | 116 | 7 | 6 | 0 | 118 | 1 | 18 |
| quality_rules.sake | 2 | 89 | 0 | 0 | 0 | 74 | 0 | 1 |
| sales_by_region.sake | 2 | 87 | 2 | 0 | 0 | 62 | 0 | 1 |
corpus-v2/18-collections/grade_book.sake: L27 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/18-collections/grade_book.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float]
corpus-v2/18-collections/grade_book.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer | nil]
corpus-v2/18-collections/grade_book.sake: L71 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/grade_book.sake: L73 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Float | Integer]
corpus-v2/18-collections/grade_book.sake: L73 Float.clamp 1: observed [["Float"]], static Integer
corpus-v2/18-collections/grade_book.sake: L86 Comparable.>= pair: observed [["Float", "Float"]], static [Integer | nil, Float]
corpus-v2/18-collections/grade_book.sake: L27 Array.sum result: observed ["Integer", "Float"], static Integer
corpus-v2/18-collections/grade_book.sake: L38 Hash.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/inventory_diff.sake: L43 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/18-collections/inventory_diff.sake: L50 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/18-collections/inventory_diff.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/18-collections/inventory_diff.sake: L50 Kernel.format result: observed ["String"], static (none)
corpus-v2/18-collections/inventory_diff.sake: L50 Array.push result: observed ["Array"], static (none)
corpus-v2/18-collections/inventory_diff.sake: L56 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/inventory_diff.sake: L57 Array.sum result: observed ["Float"], static Integer
corpus-v2/18-collections/ip_ranges.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/latency_buckets.sake: L30 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/latency_buckets.sake: L30 Float.ceil 1: observed [["Float"]], static Integer
corpus-v2/18-collections/latency_buckets.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/18-collections/library_loans.sake: L90 Float.clamp 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| friend_graph.sake | 2 | 103 | 12 | 0 | 0 | 91 | 0 | 0 |
| grade_book.sake | 2 | 109 | 8 | 1 | 0 | 78 | 0 | 9 |
| inventory_diff.sake | 2 | 95 | 8 | 2 | 0 | 91 | 0 | 7 |
| ip_ranges.sake | 2 | 98 | 14 | 0 | 0 | 105 | 0 | 1 |
| latency_buckets.sake | 2 | 90 | 2 | 1 | 0 | 75 | 0 | 3 |
| leaderboard.sake | 2 | 89 | 6 | 0 | 0 | 79 | 0 | 0 |
| library_loans.sake | 3 | 171 | 17 | 1 | 0 | 158 | 0 | 1 |
| lottery.sake | 2 | 79 | 3 | 0 | 0 | 74 | 0 | 0 |
| paginate.sake | 2 | 105 | 10 | 0 | 0 | 98 | 0 | 0 |
| prime_sets.sake | 2 | 116 | 5 | 0 | 0 | 106 | 0 | 0 |
corpus-v2/12-parsers/json_parser.sake: L195 Float.round 1: observed [["Float"]], static Integer
corpus-v2/12-parsers/json_parser.sake: L194 Array.sum result: observed ["Float"], static Integer
corpus-v2/12-parsers/query_engine.sake: L134 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_parser.sake | 2 | 80 | 2 | 0 | 0 | 67 | 0 | 0 |
| forth.sake | 3 | 119 | 18 | 0 | 0 | 98 | 0 | 0 |
| indent_lexer.sake | 3 | 69 | 5 | 0 | 0 | 66 | 0 | 0 |
| ini_parser.sake | 2 | 103 | 3 | 0 | 0 | 87 | 0 | 0 |
| json_parser.sake | 3 | 205 | 16 | 5 | 0 | 167 | 0 | 2 |
| lisp_interp.sake | 8 | 136 | 18 | 0 | 0 | 82 | 0 | 0 |
| markdown.sake | 2 | 131 | 5 | 0 | 0 | 106 | 0 | 0 |
| pratt_parser.sake | 4 | 132 | 23 | 0 | 0 | 95 | 0 | 0 |
| query_engine.sake | 2 | 113 | 10 | 1 | 0 | 99 | 0 | 1 |
| regex_matcher.sake | 2 | 154 | 7 | 0 | 0 | 113 | 0 | 0 |
corpus-v2/08-graphs/centrality.sake: L64 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/08-graphs/centrality.sake: L64 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/08-graphs/centrality.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/08-graphs/centrality.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/08-graphs/centrality.sake: L78 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/08-graphs/centrality.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/08-graphs/centrality.sake: L97 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| spanning_tree.sake | 2 | 146 | 42 | 0 | 0 | 100 | 0 | 0 |
| taxonomy_lca.sake | 3 | 128 | 28 | 0 | 0 | 96 | 0 | 0 |
| traversals.sake | 3 | 141 | 4 | 0 | 0 | 137 | 0 | 0 |
| tree_codec.sake | 4 | 98 | 3 | 0 | 0 | 96 | 0 | 0 |
| trie_autocomplete.sake | 2 | 82 | 5 | 0 | 0 | 80 | 0 | 0 |
| astar_terrain.sake | 3 | 74 | 8 | 0 | 0 | 56 | 0 | 0 |
| bellman_ford.sake | 2 | 66 | 2 | 0 | 0 | 50 | 0 | 0 |
| centrality.sake | 2 | 100 | 11 | 0 | 0 | 77 | 0 | 7 |
| course_schedule.sake | 2 | 76 | 6 | 0 | 0 | 62 | 0 | 0 |
| critical_links.sake | 2 | 91 | 8 | 0 | 0 | 58 | 0 | 0 |
corpus-v2/13-polymorphism/matrix_ops.sake: L56 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/13-polymorphism/matrix_ops.sake: [127, 18, "Kernel.format", 1]: observed [["String"]] but no static check
corpus-v2/13-polymorphism/matrix_ops.sake: L96 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, nil | Integer | Rational]
corpus-v2/13-polymorphism/matrix_ops.sake: L96 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
corpus-v2/13-polymorphism/matrix_ops.sake: L117 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
corpus-v2/13-polymorphism/money_ledger.sake: L63 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/money_ledger.sake: L25 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"], ["Integer", "Integer"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/money_ledger.sake: L25 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/payroll.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/payroll.sake: L56 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/payroll.sake: L56 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/payroll.sake: L69 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/physical_quantities.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/polynomial.sake: L39 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [nil | Integer, Integer]
corpus-v2/13-polymorphism/polynomial.sake: L66 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer | Rational]
corpus-v2/13-polymorphism/polynomial.sake: L66 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Rational", "Integer"], ["Float", "Integer"]], static [Integer, Integer | Rational]
corpus-v2/13-polymorphism/polynomial.sake: L66 Array.reduce result: observed ["Integer", "Rational", "Float"], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L19 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L31 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L32 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L55 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L56 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L57 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L88 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L88 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L16 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L122 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L69 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L73 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L4 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L4 Math.atan2 2: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L75 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L75 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L76 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/quaternion_rotation.sake: L77 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L77 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L130 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L130 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/quaternion_rotation.sake: L135 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/shapes_area.sake: L20 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L29 Arithmetic.* pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Float, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L39 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/shapes_area.sake: L50 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L50 Math.tan 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/shapes_area.sake: L50 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L51 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/shapes_area.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/shapes_area.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/shapes_area.sake: L75 Array.sum result: observed ["Float"], static Integer
corpus-v2/13-polymorphism/sparse_vector.sake: L48 Kernel.== pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/sparse_vector.sake: L48 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| matrix_ops.sake | 3 | 157 | 21 | 0 | 0 | 108 | 1 | 5 |
| modint_combinatorics.sake | 2 | 153 | 5 | 0 | 0 | 124 | 0 | 0 |
| money_ledger.sake | 2 | 123 | 3 | 2 | 0 | 102 | 0 | 3 |
| notify_channels.sake | 2 | 69 | 1 | 0 | 0 | 53 | 0 | 0 |
| payroll.sake | 2 | 85 | 6 | 2 | 0 | 68 | 0 | 4 |
| physical_quantities.sake | 2 | 172 | 4 | 0 | 0 | 103 | 0 | 1 |
| polynomial.sake | 3 | 156 | 9 | 0 | 0 | 132 | 0 | 4 |
| quaternion_rotation.sake | 2 | 252 | 3 | 2 | 0 | 211 | 0 | 43 |
| shapes_area.sake | 2 | 131 | 1 | 0 | 0 | 110 | 0 | 18 |
| sparse_vector.sake | 2 | 99 | 3 | 0 | 0 | 77 | 0 | 2 |
corpus-v2/14-errors/quote_fallback.sake: L74 Float.round 1: observed [["Float"]], static Integer
corpus-v2/14-errors/spreadsheet_errors.sake: L66 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/14-errors/spreadsheet_errors.sake: L61 Array.sum result: observed ["Float"], static Integer
corpus-v2/14-errors/spreadsheet_errors.sake: L66 Array.sum result: observed ["Float"], static Integer
corpus-v2/14-errors/unit_quantities.sake: L37 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/14-errors/unit_quantities.sake: L71 Float.round 1: observed [["Float"]], static Integer
corpus-v2/14-errors/unit_quantities.sake: L70 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| order_lifecycle.sake | 3 | 33 | 3 | 0 | 0 | 32 | 0 | 0 |
| param_coercion.sake | 2 | 54 | 1 | 0 | 0 | 42 | 0 | 0 |
| password_policy.sake | 2 | 94 | 0 | 0 | 0 | 88 | 0 | 0 |
| quote_fallback.sake | 2 | 48 | 2 | 1 | 0 | 44 | 0 | 1 |
| registration_form.sake | 2 | 74 | 2 | 0 | 0 | 70 | 0 | 0 |
| result_pipeline.sake | 2 | 59 | 1 | 0 | 0 | 32 | 0 | 0 |
| retry_backoff.sake | 2 | 44 | 4 | 0 | 0 | 39 | 0 | 0 |
| spreadsheet_errors.sake | 3 | 80 | 14 | 0 | 0 | 72 | 0 | 3 |
| unit_quantities.sake | 2 | 60 | 6 | 1 | 0 | 51 | 0 | 3 |
| warehouse_reservation.sake | 2 | 68 | 2 | 0 | 0 | 62 | 0 | 0 |
corpus-v2/06-linked/lru_cache.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cycle_detection.sake | 2 | 65 | 13 | 0 | 0 | 66 | 0 | 0 |
| deque_sliding_window.sake | 3 | 91 | 9 | 0 | 0 | 84 | 0 | 0 |
| digit_list_bignum.sake | 2 | 97 | 0 | 0 | 0 | 85 | 0 | 0 |
| free_list_pool.sake | 3 | 106 | 16 | 0 | 0 | 81 | 0 | 0 |
| josephus_circle.sake | 2 | 52 | 5 | 0 | 0 | 46 | 0 | 0 |
| lfu_cache_buckets.sake | 4 | 85 | 3 | 0 | 0 | 85 | 0 | 0 |
| list_toolkit.sake | 3 | 62 | 12 | 1 | 0 | 73 | 0 | 0 |
| lru_cache.sake | 3 | 73 | 1 | 0 | 0 | 64 | 0 | 1 |
| markup_tag_checker.sake | 2 | 62 | 2 | 0 | 0 | 58 | 0 | 0 |
| merge_log_streams.sake | 3 | 82 | 6 | 0 | 0 | 69 | 0 | 0 |
corpus-v2/20-business/customer_loyalty.sake: L23 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/20-business/event_registration.sake: L68 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| smtp_session.sake | 3 | 79 | 1 | 0 | 0 | 69 | 0 | 0 |
| tcp_states.sake | 3 | 54 | 0 | 0 | 0 | 40 | 0 | 0 |
| traffic_light.sake | 3 | 80 | 4 | 0 | 0 | 80 | 0 | 0 |
| turnstile.sake | 2 | 31 | 0 | 0 | 0 | 28 | 0 | 0 |
| vending_machine.sake | 2 | 84 | 1 | 0 | 0 | 71 | 0 | 0 |
| appointment_scheduler.sake | 2 | 78 | 1 | 0 | 0 | 63 | 0 | 0 |
| bank_ledger.sake | 3 | 122 | 4 | 0 | 0 | 113 | 0 | 0 |
| course_enrollment.sake | 2 | 104 | 0 | 0 | 0 | 99 | 0 | 0 |
| customer_loyalty.sake | 3 | 97 | 3 | 1 | 0 | 96 | 0 | 1 |
| event_registration.sake | 2 | 78 | 0 | 0 | 0 | 73 | 0 | 1 |
corpus-v2/15-data/size_histogram.sake: L44 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/size_histogram.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L54 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L54 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L54 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/table_renderer.sake: L99 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/15-data/table_renderer.sake: L98 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/timesheet_payroll.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/timesheet_payroll.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/timesheet_payroll.sake: L76 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/timesheet_payroll.sake: L81 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/15-data/top_products.sake: L42 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/top_products.sake: L37 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/top_products.sake: L37 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/15-data/top_products.sake: L37 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/top_products.sake: L54 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| size_histogram.sake | 2 | 51 | 3 | 0 | 0 | 47 | 0 | 2 |
| survey_crosstab.sake | 2 | 96 | 0 | 0 | 0 | 71 | 0 | 10 |
| table_renderer.sake | 2 | 101 | 13 | 0 | 0 | 98 | 0 | 2 |
| timesheet_payroll.sake | 2 | 87 | 6 | 0 | 0 | 84 | 0 | 4 |
| top_products.sake | 2 | 96 | 0 | 1 | 0 | 85 | 0 | 5 |
| activity_heatmap.sake | 2 | 162 | 5 | 0 | 0 | 132 | 0 | 0 |
| age_calculator.sake | 2 | 118 | 4 | 0 | 0 | 101 | 0 | 0 |
| billing_cycles.sake | 2 | 125 | 14 | 0 | 0 | 114 | 0 | 0 |
| business_days.sake | 2 | 101 | 3 | 0 | 0 | 99 | 0 | 0 |
| calendar_systems.sake | 2 | 192 | 2 | 0 | 0 | 172 | 0 | 0 |
corpus-v2/12-parsers/rpn_calc.sake: L74 Array.sum result: observed ["Float"], static Integer
corpus-v2/12-parsers/symbolic_diff.sake: L217 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/12-parsers/symbolic_diff.sake: L217 Float.round 1: observed [["Float"]], static Integer
corpus-v2/12-parsers/symbolic_diff.sake: L220 Float.abs 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| rpn_calc.sake | 3 | 83 | 7 | 0 | 0 | 77 | 0 | 1 |
| shunting_yard.sake | 3 | 59 | 6 | 0 | 0 | 56 | 0 | 0 |
| stack_vm.sake | 2 | 100 | 18 | 0 | 0 | 82 | 0 | 0 |
| symbolic_diff.sake | 5 | 90 | 19 | 2 | 0 | 88 | 0 | 3 |
| template_engine.sake | 3 | 102 | 10 | 0 | 0 | 81 | 0 | 0 |
| tiny_basic.sake | 3 | 131 | 25 | 0 | 0 | 127 | 0 | 0 |
| tokenizer.sake | 2 | 121 | 1 | 0 | 0 | 81 | 0 | 0 |
| truth_table.sake | 3 | 78 | 0 | 0 | 2 | 72 | 0 | 0 |
| turing_machine.sake | 2 | 73 | 1 | 0 | 0 | 56 | 0 | 0 |
| type_checker.sake | 4 | 47 | 0 | 0 | 31 | 58 | 0 | 0 |
corpus-v2/06-linked/ring_buffer_metrics.sake: L79 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/06-linked/sparse_polynomial.sake: L14 Kernel.== pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/06-linked/sparse_polynomial.sake: L89 Comparable.< pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/06-linked/sparse_polynomial.sake: L69 Arithmetic.* pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/06-linked/sparse_polynomial.sake: L69 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/06-linked/sparse_polynomial.sake: [90, 24, "Rational.abs", 1]: observed [["Rational"]] but no static check
corpus-v2/06-linked/sparse_polynomial.sake: L38 Term.coef result: observed ["Integer", "Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monotonic_stack_prices.sake | 3 | 56 | 12 | 0 | 0 | 53 | 0 | 0 |
| ring_buffer_metrics.sake | 2 | 83 | 8 | 2 | 0 | 77 | 0 | 1 |
| rpn_stack_calculator.sake | 3 | 60 | 1 | 0 | 0 | 58 | 0 | 0 |
| singly_linked_list.sake | 3 | 90 | 8 | 0 | 0 | 89 | 0 | 0 |
| skip_list_index.sake | 3 | 139 | 9 | 0 | 0 | 109 | 0 | 0 |
| sparse_matrix_rows.sake | 3 | 123 | 2 | 0 | 0 | 85 | 0 | 0 |
| sparse_polynomial.sake | 3 | 72 | 1 | 0 | 0 | 60 | 1 | 6 |
| triage_priority_list.sake | 3 | 93 | 6 | 0 | 0 | 73 | 0 | 0 |
| two_stack_print_queue.sake | 2 | 63 | 0 | 0 | 0 | 53 | 0 | 0 |
| undo_redo_editor.sake | 3 | 74 | 6 | 0 | 0 | 71 | 0 | 0 |
corpus-v2/16-dates/durations.sake: L17 Float.round 1: observed [["Float"]], static Integer
corpus-v2/16-dates/fiscal_quarters.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cron_schedule.sake | 2 | 147 | 3 | 0 | 0 | 139 | 0 | 0 |
| date_arith.sake | 2 | 118 | 4 | 0 | 0 | 102 | 0 | 0 |
| date_parser.sake | 2 | 126 | 24 | 0 | 0 | 112 | 0 | 0 |
| day_of_week.sake | 2 | 64 | 14 | 0 | 0 | 60 | 0 | 0 |
| durations.sake | 2 | 103 | 5 | 1 | 0 | 96 | 0 | 1 |
| easter.sake | 2 | 129 | 2 | 0 | 0 | 108 | 0 | 0 |
| fiscal_quarters.sake | 2 | 115 | 15 | 0 | 0 | 110 | 0 | 1 |
| iso_week.sake | 2 | 106 | 13 | 0 | 0 | 101 | 0 | 0 |
| meeting_scheduler.sake | 3 | 104 | 17 | 0 | 0 | 113 | 0 | 0 |
| month_calendar.sake | 2 | 79 | 2 | 0 | 0 | 69 | 0 | 0 |
corpus-v2/04-numeric/eigenvalues.sake: L5 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/eigenvalues.sake: L6 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/04-numeric/eigenvalues.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L107 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/04-numeric/eigenvalues.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L67 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/eigenvalues.sake: L67 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [67, 62, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [67, 43, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [67, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [68, 18, "Math.sqrt", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [68, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [69, 12, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [73, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [74, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [79, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [80, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/eigenvalues.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L25 Float.abs 1: observed [["Float"]], static nil | Integer
corpus-v2/04-numeric/eigenvalues.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/eigenvalues.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
corpus-v2/04-numeric/eigenvalues.sake: L31 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/04-numeric/eigenvalues.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
corpus-v2/04-numeric/eigenvalues.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L126 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L126 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/eigenvalues.sake: L126 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/eigenvalues.sake: L3 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/eigenvalues.sake: L4 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/eigenvalues.sake: L67 Math.sqrt result: observed ["Float"], static (none)
corpus-v2/04-numeric/eigenvalues.sake: L68 Math.sqrt result: observed ["Float"], static (none)
corpus-v2/04-numeric/eigenvalues.sake: L122 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L38 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L67 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L67 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L54 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L55 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L10 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L10 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L10 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L43 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L44 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L44 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L48 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L49 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L92 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L92 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L92 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L93 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L93 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L93 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L99 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L99 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L100 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/float_accuracy.sake: L100 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L105 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L107 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/float_accuracy.sake: L107 Float.nan? 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: L107 Float.finite? 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/float_accuracy.sake: [108, 21, "Float.infinite?", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/float_accuracy.sake: [108, 45, "Float.infinite?", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/float_accuracy.sake: [109, 18, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/float_accuracy.sake: [109, 41, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/float_accuracy.sake: [111, 2, "Float.to_i", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/float_accuracy.sake: L108 Float.infinite? result: observed ["Integer"], static (none)
corpus-v2/04-numeric/float_accuracy.sake: L108 Float.infinite? result: observed ["Integer"], static (none)
corpus-v2/04-numeric/fourier_spectrum.sake: L62 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L62 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/fourier_spectrum.sake: L62 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L28 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L7 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L7 Math.sin 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L75 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/fourier_spectrum.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L55 Arithmetic.* pair: observed [["Cpx", "Float"]], static [Cpx, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: [14, 26, "Cpx.re", 1]: observed [["Cpx"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [14, 26, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [14, 35, "Cpx.im", 1]: observed [["Cpx"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [14, 35, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [87, 68, "Arithmetic.-", "pair"]: observed [["Cpx", "Cpx"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: L93 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/fourier_spectrum.sake: L93 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/fourier_spectrum.sake: [98, 24, "Arithmetic.*", "pair"]: observed [["Float", "Float"], ["Float", "Integer"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [98, 24, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [98, 15, "Math.sin", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [98, 9, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [98, 9, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [99, 43, "Cpx.re", 1]: observed [["Cpx"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [99, 43, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [99, 33, "Float.abs", 1]: observed [["Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [99, 20, "Float[]", "elem"]: observed [["Float"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: [99, 10, "Array.max", 1]: observed [["Array"]] but no static check
corpus-v2/04-numeric/fourier_spectrum.sake: L82 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L83 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/fourier_spectrum.sake: L87 Array.max result: observed ["Float"], static nil
corpus-v2/04-numeric/gaussian_elimination.sake: L24 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/gaussian_elimination.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L68 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/gaussian_elimination.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L97 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/gaussian_elimination.sake: L100 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/gaussian_elimination.sake: L115 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/gaussian_elimination.sake: L65 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L8 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L14 Math.log 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L14 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L14 Math.cos 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L71 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L71 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/04-numeric/histogram_fit.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L35 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L35 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/04-numeric/histogram_fit.sake: L37 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L37 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L23 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L24 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L26 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L81 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L82 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L82 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L82 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L89 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L47 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/histogram_fit.sake: L47 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L48 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L48 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L48 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L105 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L105 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L111 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L112 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L62 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/histogram_fit.sake: L112 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/histogram_fit.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L71 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L72 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/histogram_fit.sake: L72 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/histogram_fit.sake: L32 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/histogram_fit.sake: L33 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/histogram_fit.sake: L81 Bin.hi result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L81 Bin.lo result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L83 Bin.lo result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L83 Bin.hi result: observed ["Float"], static Integer
corpus-v2/04-numeric/histogram_fit.sake: L48 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/interval_arithmetic.sake: L29 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/interval_arithmetic.sake: L44 Float[] elem: observed [["Float"]], static Integer
corpus-v2/04-numeric/interval_arithmetic.sake: L56 Arithmetic.* pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
corpus-v2/04-numeric/interval_arithmetic.sake: L56 Arithmetic.* pair: observed [["Interval", "Float"], ["Float", "Float"]], static [Integer | Interval, Float]
corpus-v2/04-numeric/interval_arithmetic.sake: L56 Arithmetic.- pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
corpus-v2/04-numeric/interval_arithmetic.sake: L56 Arithmetic.+ pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval | nil]
corpus-v2/04-numeric/interval_arithmetic.sake: L129 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/interval_arithmetic.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/interval_arithmetic.sake: L49 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/interval_arithmetic.sake: L71 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus-v2/04-numeric/interval_arithmetic.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/interval_arithmetic.sake: L81 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/interval_arithmetic.sake: L95 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/interval_arithmetic.sake: L97 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/interval_arithmetic.sake: L130 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/interval_arithmetic.sake: L130 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/linear_regression.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L13 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L18 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L19 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L19 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/linear_regression.sake: L19 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L19 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/linear_regression.sake: L20 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
corpus-v2/04-numeric/linear_regression.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/linear_regression.sake: L25 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/linear_regression.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/04-numeric/linear_regression.sake: L27 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/linear_regression.sake: L5 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/linear_regression.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L64 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L64 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/linear_regression.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/linear_regression.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L39 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/linear_regression.sake: L39 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/04-numeric/linear_regression.sake: L39 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L42 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/linear_regression.sake: L12 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L13 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L25 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L32 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L33 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L34 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/linear_regression.sake: L89 Fit.r2 result: observed ["Float"], static Integer
corpus-v2/04-numeric/loan_amortization.sake: L9 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L9 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L5 Float.round 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/loan_amortization.sake: L20 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L23 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L96 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L98 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L47 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/04-numeric/loan_amortization.sake: L48 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L51 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L57 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/04-numeric/loan_amortization.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/loan_amortization.sake: L96 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/loan_amortization.sake: L96 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/lu_decomposition.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/lu_decomposition.sake: L71 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/lu_decomposition.sake: L93 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/lu_decomposition.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
corpus-v2/04-numeric/lu_decomposition.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/lu_decomposition.sake: L40 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
corpus-v2/04-numeric/lu_decomposition.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/04-numeric/lu_decomposition.sake: L111 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/04-numeric/lu_decomposition.sake: L46 Range.reduce result: observed ["Float"], static Integer
corpus-v2/04-numeric/lu_decomposition.sake: L67 Array.sum result: observed ["Float"], static Integer
corpus-v2/04-numeric/lu_decomposition.sake: L67 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/04-numeric/matrix_ops.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/matrix_ops.sake: L90 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/04-numeric/matrix_ops.sake: L94 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/04-numeric/matrix_ops.sake: L110 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/04-numeric/matrix_ops.sake: L110 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| eigenvalues.sake | 2 | 152 | 43 | 2 | 0 | 149 | 22 | 47 |
| float_accuracy.sake | 2 | 113 | 5 | 5 | 0 | 119 | 5 | 43 |
| fourier_spectrum.sake | 3 | 141 | 8 | 1 | 0 | 142 | 15 | 36 |
| gaussian_elimination.sake | 2 | 150 | 47 | 7 | 0 | 120 | 0 | 13 |
| histogram_fit.sake | 2 | 160 | 12 | 3 | 0 | 158 | 0 | 81 |
| interval_arithmetic.sake | 2 | 100 | 47 | 2 | 0 | 125 | 0 | 16 |
| linear_regression.sake | 2 | 120 | 9 | 1 | 0 | 111 | 0 | 45 |
| loan_amortization.sake | 2 | 110 | 5 | 1 | 0 | 102 | 0 | 18 |
| lu_decomposition.sake | 3 | 147 | 36 | 7 | 0 | 115 | 0 | 11 |
| matrix_ops.sake | 3 | 164 | 13 | 0 | 0 | 143 | 0 | 5 |
corpus-v2/02-analytics/csv_pivot.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/csv_pivot.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/csv_pivot.sake: L63 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/csv_pivot.sake: L90 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/hashtag_trends.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/markov_text.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/naive_bayes.sake: L59 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/naive_bayes.sake: L59 Math.log 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/naive_bayes.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/naive_bayes.sake: L52 Math.log 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/naive_bayes.sake: L103 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/near_duplicates.sake: L24 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/near_duplicates.sake: L42 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/near_duplicates.sake: L79 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_pivot.sake | 2 | 97 | 4 | 0 | 0 | 81 | 0 | 4 |
| email_domains.sake | 2 | 92 | 4 | 0 | 0 | 81 | 0 | 0 |
| hashtag_trends.sake | 2 | 99 | 6 | 0 | 0 | 79 | 0 | 1 |
| inverted_index.sake | 2 | 81 | 8 | 0 | 0 | 70 | 0 | 0 |
| kwic_concordance.sake | 2 | 86 | 6 | 0 | 0 | 69 | 0 | 0 |
| language_guess.sake | 2 | 71 | 4 | 0 | 0 | 58 | 0 | 0 |
| log_summary.sake | 3 | 84 | 9 | 0 | 0 | 71 | 0 | 0 |
| markov_text.sake | 2 | 105 | 2 | 0 | 0 | 89 | 0 | 1 |
| naive_bayes.sake | 2 | 97 | 2 | 0 | 0 | 80 | 0 | 5 |
| near_duplicates.sake | 2 | 85 | 9 | 0 | 0 | 72 | 0 | 3 |
corpus-v2/17-encodings/vigenere.sake: L49 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/17-encodings/vigenere.sake: L51 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/17-encodings/vigenere.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/17-encodings/vigenere.sake: L65 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/vigenere.sake: L66 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/vigenere.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/17-encodings/vigenere.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/17-encodings/vigenere.sake: L49 Array.sum result: observed ["Float"], static Integer
corpus-v2/17-encodings/vigenere.sake: L51 Array.find result: observed ["{ic: Float, period: Integer}"], static nil | {ic: Integer, period: Integer}
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| run_length.sake | 2 | 63 | 1 | 0 | 0 | 58 | 0 | 0 |
| transposition.sake | 2 | 74 | 1 | 0 | 0 | 59 | 0 | 0 |
| utf8_codec.sake | 2 | 94 | 15 | 0 | 0 | 100 | 0 | 0 |
| vigenere.sake | 2 | 93 | 2 | 0 | 0 | 76 | 0 | 9 |
| xor_breaker.sake | 2 | 88 | 7 | 0 | 0 | 81 | 0 | 0 |
| access_log.sake | 2 | 113 | 7 | 0 | 0 | 106 | 0 | 0 |
| build_order.sake | 3 | 85 | 7 | 0 | 0 | 76 | 0 | 0 |
| cart_discounts.sake | 2 | 76 | 4 | 0 | 0 | 60 | 0 | 0 |
| contact_dedupe.sake | 3 | 158 | 7 | 0 | 0 | 123 | 0 | 0 |
| course_overlap.sake | 2 | 117 | 7 | 0 | 0 | 118 | 0 | 0 |
corpus-v2/02-analytics/ngram_counts.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/ngram_counts.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/ngram_counts.sake: L64 Float.round 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/rake_keywords.sake: L30 Comparable.<=> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/rake_keywords.sake: L130 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/rake_keywords.sake: L99 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L30 Keyword.score result: observed ["Float"], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L134 Keyword.score result: observed ["Float"], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L130 Keyword.score result: observed ["Float"], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L130 Keyword.score result: observed ["Float"], static Integer
corpus-v2/02-analytics/rake_keywords.sake: L130 Keyword.set_score result: observed ["Float"], static Integer
corpus-v2/02-analytics/readability.sake: L39 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/readability.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/readability.sake: L41 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/readability.sake: L41 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/readability.sake: L41 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/readability.sake: L57 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/readability.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/readability.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/readability.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/readability.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/readability.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/readability.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/readability.sake: L59 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/readability.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/sentiment_lexicon.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/sentiment_lexicon.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/sentiment_lexicon.sake: L99 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/sentiment_lexicon.sake: L48 Score.set_total result: observed ["Float"], static Integer
corpus-v2/02-analytics/sentiment_lexicon.sake: L97 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/sentiment_lexicon.sake: L99 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/tf_idf.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L34 Math.log 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/tf_idf.sake: L22 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
corpus-v2/02-analytics/tf_idf.sake: L60 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/02-analytics/tf_idf.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L50 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L44 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/tf_idf.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/tf_idf.sake: L44 Hash.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/tf_idf.sake: L100 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/vocabulary_growth.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L58 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L32 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L40 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L40 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L40 Math.exp 1: observed [["Float"]], static Integer
corpus-v2/02-analytics/vocabulary_growth.sake: L62 Arithmetic.** pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/vocabulary_growth.sake: L31 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/vocabulary_growth.sake: L32 Array.sum result: observed ["Float"], static Integer
corpus-v2/02-analytics/word_frequency.sake: L64 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/02-analytics/word_frequency.sake: L64 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ngram_counts.sake | 2 | 49 | 2 | 1 | 0 | 37 | 0 | 3 |
| rake_keywords.sake | 2 | 168 | 2 | 0 | 0 | 137 | 0 | 9 |
| readability.sake | 2 | 99 | 0 | 0 | 0 | 92 | 0 | 14 |
| rhyme_scheme.sake | 2 | 43 | 3 | 0 | 0 | 39 | 0 | 0 |
| sentiment_lexicon.sake | 2 | 80 | 2 | 0 | 0 | 67 | 0 | 6 |
| soundex_index.sake | 2 | 64 | 3 | 0 | 0 | 52 | 0 | 0 |
| spell_suggest.sake | 2 | 70 | 7 | 0 | 0 | 48 | 0 | 0 |
| tf_idf.sake | 2 | 95 | 4 | 0 | 0 | 81 | 0 | 12 |
| vocabulary_growth.sake | 2 | 101 | 2 | 0 | 0 | 87 | 0 | 20 |
| word_frequency.sake | 2 | 55 | 0 | 1 | 0 | 48 | 0 | 2 |
corpus-v2/20-business/restaurant_orders.sake: L51 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/restaurant_orders.sake: L52 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/restaurant_orders.sake: L64 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/restaurant_orders.sake: L64 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/room_reservations.sake: L133 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/room_reservations.sake: L134 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/room_reservations.sake: L133 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/sales_report.sake: L57 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/20-business/sales_report.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | nil]
corpus-v2/20-business/sales_report.sake: L63 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/sales_report.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/20-business/sales_report.sake: L31 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/sales_report.sake: L31 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/sales_report.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/sales_report.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/20-business/sales_report.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/sales_report.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/sales_report.sake: L92 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/20-business/sales_report.sake: L52 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/sales_report.sake: L69 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/sales_report.sake: L70 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/20-business/sales_report.sake: L79 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/sales_report.sake: L89 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/shopping_cart.sake: L75 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
corpus-v2/20-business/shopping_cart.sake: [8, 26, "Float.round", 1]: observed [["Float"]] but no static check
corpus-v2/20-business/shopping_cart.sake: L119 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/shopping_cart.sake: L122 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
corpus-v2/20-business/subscription_billing.sake: L29 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/20-business/subscription_billing.sake: L29 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Rational]
corpus-v2/20-business/subscription_billing.sake: L44 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/subscription_billing.sake: L44 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/subscription_billing.sake: L95 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus-v2/20-business/subscription_billing.sake: L16 Rational.round 1: observed [["Rational"]], static Integer
corpus-v2/20-business/subscription_billing.sake: L16 Rational.to_f 1: observed [["Rational"]], static Integer
corpus-v2/20-business/subscription_billing.sake: L114 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/subscription_billing.sake: L43 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/subscription_billing.sake: L92 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/subscription_billing.sake: L110 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/timesheet.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/timesheet.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/timesheet.sake: L76 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/timesheet.sake: L84 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/timesheet.sake: L84 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/timesheet.sake: L82 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/todo_list.sake: L131 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/vendor_quotes.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/vendor_quotes.sake: L18 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/vendor_quotes.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/vendor_quotes.sake: L88 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/vendor_quotes.sake: L88 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/vendor_quotes.sake: L73 Hash.sum result: observed ["Float"], static Integer
corpus-v2/20-business/vendor_quotes.sake: L87 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| restaurant_orders.sake | 2 | 101 | 0 | 3 | 0 | 95 | 0 | 4 |
| room_reservations.sake | 3 | 101 | 4 | 0 | 0 | 99 | 0 | 3 |
| sales_report.sake | 2 | 119 | 11 | 1 | 0 | 113 | 0 | 16 |
| shopping_cart.sake | 3 | 137 | 3 | 0 | 0 | 126 | 1 | 4 |
| subscription_billing.sake | 2 | 109 | 1 | 2 | 0 | 90 | 0 | 11 |
| ticket_helpdesk.sake | 3 | 97 | 2 | 0 | 0 | 90 | 0 | 0 |
| timesheet.sake | 2 | 74 | 14 | 0 | 0 | 81 | 0 | 6 |
| todo_list.sake | 2 | 96 | 1 | 0 | 0 | 89 | 0 | 1 |
| vendor_quotes.sake | 2 | 81 | 6 | 0 | 0 | 78 | 0 | 7 |
| warehouse_picking.sake | 2 | 93 | 11 | 0 | 0 | 97 | 0 | 0 |
corpus-v2/15-data/access_log_report.sake: L66 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/access_log_report.sake: L88 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/access_log_report.sake: L46 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/access_log_report.sake: L46 Float.ceil 1: observed [["Float"]], static Integer
corpus-v2/15-data/bank_reconcile.sake: L35 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/bank_reconcile.sake: L35 Float.round 1: observed [["Float"]], static Integer
corpus-v2/15-data/bank_reconcile.sake: L41 Float.round 1: observed [["Float"]], static Integer
corpus-v2/15-data/bank_reconcile.sake: L63 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/15-data/budget_variance.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/budget_variance.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/budget_variance.sake: L21 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/budget_variance.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/budget_variance.sake: L54 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/clickstream_sessions.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/clickstream_sessions.sake: L107 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
corpus-v2/15-data/csv_import_validation.sake: L105 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/customer_dedupe.sake: L118 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/employee_dept_join.sake: L47 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/etl_star_schema.sake: L125 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L45 Arithmetic.+ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/15-data/expense_pivot.sake: L40 Kernel.== pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L59 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L80 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L80 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L80 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L83 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus-v2/15-data/expense_pivot.sake: L16 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/expense_pivot.sake: L18 Array.sum result: observed ["Float"], static Integer
corpus-v2/15-data/expense_pivot.sake: L17 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| access_log_report.sake | 2 | 110 | 7 | 1 | 0 | 100 | 0 | 4 |
| bank_reconcile.sake | 2 | 108 | 5 | 3 | 0 | 108 | 0 | 4 |
| budget_variance.sake | 2 | 52 | 0 | 0 | 0 | 41 | 0 | 5 |
| clickstream_sessions.sake | 2 | 111 | 5 | 0 | 0 | 105 | 0 | 2 |
| cohort_retention.sake | 2 | 90 | 7 | 0 | 0 | 89 | 0 | 0 |
| csv_import_validation.sake | 2 | 99 | 6 | 0 | 0 | 94 | 0 | 1 |
| customer_dedupe.sake | 3 | 134 | 0 | 0 | 0 | 106 | 0 | 1 |
| employee_dept_join.sake | 2 | 97 | 0 | 0 | 0 | 87 | 0 | 1 |
| etl_star_schema.sake | 2 | 160 | 8 | 0 | 0 | 115 | 0 | 1 |
| expense_pivot.sake | 2 | 91 | 4 | 0 | 0 | 72 | 0 | 11 |
corpus-v2/14-errors/matrix_checks.sake: L36 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
corpus-v2/14-errors/matrix_checks.sake: L13 Array.fetch result: observed ["Integer", "Rational"], static Integer
corpus-v2/14-errors/matrix_checks.sake: L36 Array.sum result: observed ["Integer", "Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_import.sake | 2 | 71 | 12 | 0 | 0 | 57 | 0 | 0 |
| dependency_resolver.sake | 3 | 31 | 1 | 0 | 0 | 27 | 0 | 0 |
| error_wrapping.sake | 2 | 49 | 0 | 0 | 0 | 38 | 0 | 0 |
| expr_calculator.sake | 3 | 92 | 8 | 0 | 9 | 84 | 0 | 0 |
| http_error_mapping.sake | 2 | 61 | 1 | 0 | 0 | 39 | 0 | 0 |
| job_queue.sake | 2 | 84 | 0 | 0 | 0 | 77 | 0 | 0 |
| ledger_reconcile.sake | 2 | 68 | 3 | 0 | 0 | 60 | 0 | 0 |
| log_triage.sake | 2 | 67 | 6 | 0 | 0 | 58 | 0 | 0 |
| matrix_checks.sake | 3 | 101 | 5 | 0 | 0 | 74 | 0 | 3 |
| nested_schema.sake | 2 | 42 | 3 | 0 | 0 | 39 | 0 | 0 |
corpus-v2/19-statemachines/bank_queue_sim.sake: L118 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/19-statemachines/csv_parser.sake: L106 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bank_queue_sim.sake | 2 | 135 | 7 | 0 | 0 | 112 | 0 | 1 |
| bracket_checker.sake | 2 | 53 | 1 | 0 | 0 | 51 | 0 | 0 |
| button_debounce.sake | 2 | 72 | 5 | 0 | 0 | 75 | 0 | 0 |
| circuit_breaker.sake | 2 | 70 | 4 | 0 | 0 | 66 | 0 | 0 |
| csv_parser.sake | 2 | 75 | 4 | 0 | 0 | 72 | 0 | 1 |
| dfa_minimize.sake | 3 | 92 | 1 | 0 | 0 | 78 | 0 | 0 |
| divisibility_dfa.sake | 4 | 77 | 1 | 0 | 4 | 71 | 0 | 0 |
| elevator.sake | 3 | 95 | 4 | 0 | 0 | 93 | 0 | 0 |
| enemy_ai.sake | 4 | 106 | 8 | 0 | 0 | 107 | 0 | 0 |
| event_sourcing.sake | 2 | 81 | 0 | 0 | 0 | 70 | 0 | 0 |
corpus-v2/09-dp/dice_odds.sake: L16 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus-v2/09-dp/dice_odds.sake: L31 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/09-dp/dice_odds.sake: L31 Rational.round 1: observed [["Rational"]], static Integer
corpus-v2/09-dp/dice_odds.sake: L54 Rational.to_s 1: observed [["Rational"]], static Integer
corpus-v2/09-dp/dice_odds.sake: L68 Rational.to_s 1: observed [["Rational"]], static Integer
corpus-v2/09-dp/dice_odds.sake: L71 Rational.to_s 1: observed [["Rational"]], static Integer
corpus-v2/09-dp/dice_odds.sake: [71, 75, "Rational.to_f", 1]: observed [["Rational"]] but no static check
corpus-v2/09-dp/dice_odds.sake: L43 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
corpus-v2/09-dp/dice_odds.sake: L43 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer, Integer]
corpus-v2/09-dp/dice_odds.sake: L44 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer, Integer]
corpus-v2/09-dp/dice_odds.sake: L77 Rational.to_f 1: observed [["Rational"]], static Integer
corpus-v2/09-dp/dice_odds.sake: L23 Hash.sum result: observed ["Rational"], static Integer
corpus-v2/09-dp/dice_odds.sake: L25 Hash.sum result: observed ["Rational"], static Integer
corpus-v2/09-dp/dice_odds.sake: L71 Rational.to_f result: observed ["Float"], static (none)
corpus-v2/09-dp/dice_odds.sake: L71 Kernel.format result: observed ["String"], static (none)
corpus-v2/09-dp/dice_odds.sake: L71 Kernel.puts result: observed ["Nil"], static (none)
corpus-v2/09-dp/dice_odds.sake: L48 Array.sum result: observed ["Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| coin_change.sake | 2 | 77 | 2 | 0 | 0 | 53 | 0 | 0 |
| company_party.sake | 3 | 69 | 2 | 0 | 0 | 49 | 0 | 0 |
| critical_path.sake | 2 | 89 | 14 | 0 | 0 | 64 | 0 | 0 |
| decode_ways.sake | 3 | 107 | 10 | 0 | 0 | 83 | 0 | 0 |
| dice_odds.sake | 2 | 70 | 8 | 5 | 0 | 69 | 1 | 17 |
| digit_counting.sake | 2 | 62 | 2 | 0 | 0 | 48 | 0 | 0 |
| edit_distance.sake | 2 | 119 | 17 | 0 | 0 | 95 | 0 | 0 |
| egg_drop.sake | 2 | 75 | 18 | 0 | 0 | 59 | 0 | 0 |
| floyd_warshall.sake | 2 | 93 | 25 | 0 | 0 | 58 | 0 | 0 |
| grid_paths.sake | 2 | 114 | 20 | 0 | 0 | 81 | 0 | 0 |
corpus-v2/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L28 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/collision_check.sake: L36 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L49 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/13-polymorphism/color_palette.sake: L49 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L50 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/13-polymorphism/color_palette.sake: L51 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/13-polymorphism/color_palette.sake: L52 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L52 Arithmetic.- pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer | nil]
corpus-v2/13-polymorphism/color_palette.sake: L52 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L53 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L55 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L58 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L60 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L30 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L30 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L30 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L54 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L54 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L52 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
corpus-v2/13-polymorphism/color_palette.sake: L52 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L56 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L56 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L56 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L9 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L9 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/color_palette.sake: L9 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L9 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/color_palette.sake: L9 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L9 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/color_palette.sake: L26 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L26 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L26 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L74 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L74 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L75 Float.floor 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/color_palette.sake: [76, 58, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
corpus-v2/13-polymorphism/color_palette.sake: L38 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L39 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L40 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L40 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L40 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L122 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L123 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L124 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/color_palette.sake: L124 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/color_palette.sake: L47 Array.max result: observed ["Float"], static Integer | nil
corpus-v2/13-polymorphism/color_palette.sake: L48 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/13-polymorphism/duration_timesheet.sake: L34 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/duration_timesheet.sake: L122 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/13-polymorphism/duration_timesheet.sake: L30 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/13-polymorphism/duration_timesheet.sake: L30 Float.round 1: observed [["Float"]], static Integer
corpus-v2/13-polymorphism/fraction_math.sake: L48 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/13-polymorphism/interval_arith.sake: L82 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Float"], ["Float", "Integer"], ["Interval", "Interval"], ["Interval", "Integer"]], static [Integer | Interval, Integer | Interval]
corpus-v2/13-polymorphism/interval_arith.sake: L87 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/interval_arith.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/13-polymorphism/interval_arith.sake: L28 Array.min result: observed ["Integer", "Float"], static Integer | nil
corpus-v2/13-polymorphism/interval_arith.sake: L28 Array.max result: observed ["Integer", "Float"], static Integer | nil
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bitset_permissions.sake | 2 | 90 | 10 | 0 | 0 | 73 | 0 | 0 |
| calendar_dates.sake | 3 | 141 | 8 | 0 | 0 | 132 | 0 | 0 |
| collision_check.sake | 3 | 175 | 0 | 0 | 0 | 149 | 0 | 9 |
| color_palette.sake | 2 | 162 | 16 | 4 | 0 | 162 | 1 | 55 |
| doc_render.sake | 2 | 137 | 7 | 0 | 0 | 119 | 0 | 0 |
| duration_timesheet.sake | 2 | 154 | 5 | 1 | 0 | 132 | 0 | 4 |
| expr_tree.sake | 3 | 191 | 1 | 0 | 0 | 125 | 0 | 0 |
| fraction_math.sake | 2 | 162 | 1 | 0 | 0 | 125 | 0 | 1 |
| interval_arith.sake | 3 | 123 | 32 | 0 | 0 | 125 | 0 | 5 |
| life_grid.sake | 2 | 82 | 5 | 0 | 0 | 64 | 0 | 0 |
corpus-v2/03-numtheory/collatz_stats.sake: L80 Float.round 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/continued_fractions.sake: L19 Arithmetic.+ pair: observed [["Integer", "Rational"]], static [Integer, Integer]
corpus-v2/03-numtheory/continued_fractions.sake: L97 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/egyptian_fractions.sake: L94 Rational.to_s 1: observed [["Rational"]], static Integer
corpus-v2/03-numtheory/egyptian_fractions.sake: [94, 64, "Rational.to_f", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: L100 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/03-numtheory/egyptian_fractions.sake: L42 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/03-numtheory/egyptian_fractions.sake: L43 Rational.denominator 1: observed [["Rational"]], static Integer
corpus-v2/03-numtheory/egyptian_fractions.sake: [43, 55, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [43, 13, "Integer.ceildiv", 2]: observed [["Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [44, 18, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [45, 17, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [45, 13, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [45, 44, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [45, 13, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [47, 12, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [48, 13, "Arithmetic.-", "pair"]: observed [["Rational", "Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [49, 11, "Comparable.>", "pair"]: observed [["Rational", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [49, 21, "Rational.numerator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [49, 21, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [49, 52, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [49, 52, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: [50, 24, "Rational.denominator", 1]: observed [["Rational"]] but no static check
corpus-v2/03-numtheory/egyptian_fractions.sake: L94 Rational.to_f result: observed ["Float"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L94 Kernel.format result: observed ["String"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L94 Kernel.puts result: observed ["Nil"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L43 Rational.numerator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L43 Integer.ceildiv result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L45 Rational.denominator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L45 Rational.numerator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L49 Rational.numerator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L49 Rational.denominator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/egyptian_fractions.sake: L50 Rational.denominator result: observed ["Integer"], static (none)
corpus-v2/03-numtheory/farey_stern_brocot.sake: L76 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/farey_stern_brocot.sake: L76 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/farey_stern_brocot.sake: L111 Float.abs 1: observed [["Float"]], static Integer
corpus-v2/03-numtheory/fibonacci_numbers.sake: L111 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| base_conversion.sake | 2 | 70 | 1 | 0 | 0 | 65 | 0 | 0 |
| calendar_congruences.sake | 2 | 124 | 6 | 0 | 0 | 106 | 0 | 0 |
| check_digits.sake | 2 | 111 | 4 | 0 | 0 | 93 | 0 | 0 |
| collatz_stats.sake | 2 | 70 | 7 | 1 | 0 | 67 | 0 | 1 |
| continued_fractions.sake | 2 | 101 | 4 | 1 | 0 | 88 | 0 | 2 |
| digit_curiosities.sake | 2 | 85 | 0 | 0 | 0 | 77 | 0 | 0 |
| egyptian_fractions.sake | 2 | 121 | 2 | 2 | 0 | 124 | 16 | 30 |
| factor_functions.sake | 2 | 97 | 1 | 0 | 0 | 88 | 0 | 0 |
| farey_stern_brocot.sake | 2 | 125 | 6 | 3 | 0 | 120 | 0 | 3 |
| fibonacci_numbers.sake | 2 | 148 | 3 | 0 | 0 | 137 | 0 | 1 |
corpus-v2/20-business/expense_tracker.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/expense_tracker.sake: L120 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/expense_tracker.sake: L133 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/expense_tracker.sake: L133 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/expense_tracker.sake: L133 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/expense_tracker.sake: L98 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/expense_tracker.sake: L131 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/expense_tracker.sake: L132 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/grade_book.sake: L42 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L48 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L57 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/grade_book.sake: L57 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/20-business/grade_book.sake: L7 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L8 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L9 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L10 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
corpus-v2/20-business/grade_book.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/grade_book.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L71 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L71 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/20-business/grade_book.sake: L116 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/20-business/grade_book.sake: L116 Float.clamp 1: observed [["Float"]], static Integer
corpus-v2/20-business/grade_book.sake: L118 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/grade_book.sake: L119 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/grade_book.sake: L123 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L123 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/grade_book.sake: L45 Array.min result: observed ["Float"], static Integer | nil
corpus-v2/20-business/grade_book.sake: L46 Array.delete_at result: observed ["Float"], static Integer | nil
corpus-v2/20-business/grade_book.sake: L48 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/grade_book.sake: L107 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/grade_book.sake: L70 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/grade_book.sake: L71 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/grade_book.sake: L123 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/gym_membership.sake: L56 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/hotel_billing.sake: L17 Time.month 1: observed [["Time"]], static Integer
corpus-v2/20-business/hotel_billing.sake: L47 Time.friday? 1: observed [["Time"]], static Integer
corpus-v2/20-business/hotel_billing.sake: [47, 41, "Time.saturday?", 1]: observed [["Time"]] but no static check
corpus-v2/20-business/hotel_billing.sake: [48, 36, "Time.strftime", 1]: observed [["Time"]] but no static check
corpus-v2/20-business/hotel_billing.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/hotel_billing.sake: L67 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/20-business/hotel_billing.sake: L74 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/hotel_billing.sake: L58 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/hotel_billing.sake: L58 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/hotel_billing.sake: L126 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/hotel_billing.sake: L127 Arithmetic.+ pair: observed [["Float", "Float"], ["Integer", "Float"], ["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/hotel_billing.sake: L47 Time.saturday? result: observed ["Boolean"], static (none)
corpus-v2/20-business/hotel_billing.sake: L48 Time.strftime result: observed ["String"], static (none)
corpus-v2/20-business/hotel_billing.sake: L34 Array.sum result: observed ["Float", "Integer"], static Integer
corpus-v2/20-business/hotel_billing.sake: L56 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/hotel_billing.sake: L57 Array.sum result: observed ["Integer", "Float"], static Integer
corpus-v2/20-business/hotel_billing.sake: L124 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/hotel_billing.sake: L127 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/inventory_reorder.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L31 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L31 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L31 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/20-business/inventory_reorder.sake: L85 Float.ceil 1: observed [["Float"]], static Integer
corpus-v2/20-business/inventory_reorder.sake: L86 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L86 Float.ceil 1: observed [["Float"]], static Integer
corpus-v2/20-business/inventory_reorder.sake: L87 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L89 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
corpus-v2/20-business/inventory_reorder.sake: L89 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/inventory_reorder.sake: L89 Math.sqrt 1: observed [["Float"]], static Integer
corpus-v2/20-business/inventory_reorder.sake: L107 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/inventory_reorder.sake: L31 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/inventory_reorder.sake: L102 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/inventory_reorder.sake: L114 Hash.sum result: observed ["Float"], static Integer
corpus-v2/20-business/invoice_generator.sake: L38 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Rational]
corpus-v2/20-business/invoice_generator.sake: L50 Time.strftime 1: observed [["Time"]], static Integer
corpus-v2/20-business/invoice_generator.sake: L10 Rational.round 1: observed [["Rational"]], static Integer
corpus-v2/20-business/invoice_generator.sake: L58 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L58 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L59 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L60 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L61 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L64 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L117 Rational.to_f 1: observed [["Rational"]], static Integer
corpus-v2/20-business/invoice_generator.sake: L122 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/invoice_generator.sake: L123 Float.to_i 1: observed [["Float"]], static Integer
corpus-v2/20-business/invoice_generator.sake: L35 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/invoice_generator.sake: L57 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/invoice_generator.sake: L116 Array.sum result: observed ["Rational"], static Integer
corpus-v2/20-business/parking_garage.sake: L25 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/parking_garage.sake: L57 Ticket.set_charged_kwh result: observed ["Float"], static Integer
corpus-v2/20-business/payroll.sake: L17 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L45 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/payroll.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/payroll.sake: L46 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/payroll.sake: L27 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L32 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L33 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Integer"]], static [Integer | nil, Integer]
corpus-v2/20-business/payroll.sake: L33 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
corpus-v2/20-business/payroll.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/20-business/payroll.sake: L37 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/payroll.sake: L48 Float.round 1: observed [["Float"]], static Integer
corpus-v2/20-business/payroll.sake: L87 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L87 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L98 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L99 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L99 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/20-business/payroll.sake: L33 Array.min result: observed ["Integer", "Float"], static Integer | nil
corpus-v2/20-business/payroll.sake: L83 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/payroll.sake: L84 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/payroll.sake: L86 Array.sum result: observed ["Float"], static Integer
corpus-v2/20-business/rental_fleet.sake: L97 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/20-business/rental_fleet.sake: L98 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expense_tracker.sake | 2 | 135 | 7 | 0 | 0 | 120 | 0 | 8 |
| grade_book.sake | 2 | 137 | 7 | 1 | 0 | 119 | 0 | 29 |
| gym_membership.sake | 2 | 45 | 2 | 0 | 0 | 43 | 0 | 1 |
| hotel_billing.sake | 2 | 130 | 0 | 5 | 0 | 123 | 2 | 18 |
| inventory_reorder.sake | 2 | 99 | 2 | 2 | 0 | 92 | 0 | 16 |
| invoice_generator.sake | 2 | 121 | 15 | 4 | 0 | 126 | 0 | 15 |
| library_loans.sake | 2 | 124 | 0 | 0 | 0 | 116 | 0 | 0 |
| parking_garage.sake | 2 | 98 | 5 | 1 | 0 | 94 | 0 | 2 |
| payroll.sake | 2 | 93 | 4 | 4 | 0 | 82 | 0 | 20 |
| rental_fleet.sake | 2 | 102 | 5 | 0 | 0 | 102 | 0 | 2 |
corpus-v2/07-trees/bill_of_materials.sake: L43 Array.sum result: observed ["Float"], static Integer
corpus-v2/07-trees/decision_tree.sake: L7 Math.log2 1: observed [["Float"]], static Integer
corpus-v2/07-trees/decision_tree.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/07-trees/decision_tree.sake: L7 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
corpus-v2/07-trees/decision_tree.sake: L19 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/decision_tree.sake: L19 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/decision_tree.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/07-trees/decision_tree.sake: L29 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/07-trees/decision_tree.sake: L115 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/decision_tree.sake: L7 Array.sum result: observed ["Float"], static Integer
corpus-v2/07-trees/decision_tree.sake: L19 Array.sum result: observed ["Float"], static Integer
corpus-v2/07-trees/fenwick_ranks.sake: L86 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/07-trees/filesystem_du.sake: L38 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| avl_tree.sake | 3 | 111 | 11 | 0 | 0 | 117 | 0 | 0 |
| bill_of_materials.sake | 3 | 87 | 13 | 0 | 0 | 79 | 0 | 1 |
| bst_basic.sake | 3 | 84 | 2 | 0 | 0 | 84 | 0 | 0 |
| btree.sake | 2 | 107 | 9 | 0 | 0 | 94 | 0 | 0 |
| decision_tree.sake | 2 | 106 | 3 | 0 | 0 | 86 | 0 | 10 |
| dom_tree.sake | 3 | 115 | 13 | 0 | 0 | 104 | 0 | 0 |
| expression_tree.sake | 3 | 93 | 0 | 0 | 0 | 81 | 0 | 0 |
| fenwick_ranks.sake | 2 | 77 | 7 | 0 | 0 | 65 | 0 | 1 |
| filesystem_du.sake | 3 | 105 | 3 | 0 | 0 | 95 | 0 | 1 |
| heap_scheduler.sake | 3 | 113 | 13 | 0 | 0 | 93 | 0 | 0 |
corpus-v2/01-text/ascii_table.sake: L119 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/ascii_table.sake: L87 Array.sum result: observed ["Integer", "Float"], static Integer
corpus-v2/01-text/bwt_rle.sake: L76 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/01-text/classic_ciphers.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/01-text/classic_ciphers.sake: L60 Arithmetic.- pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus-v2/01-text/classic_ciphers.sake: L61 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/01-text/classic_ciphers.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/01-text/classic_ciphers.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/01-text/csv_report.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
corpus-v2/01-text/csv_report.sake: L73 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/csv_report.sake: L84 Array.sum result: observed ["Float"], static Integer
corpus-v2/01-text/human_format.sake: L13 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L21 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/01-text/human_format.sake: L22 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/01-text/human_format.sake: L22 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L22 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/01-text/human_format.sake: L58 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L62 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L66 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L68 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
corpus-v2/01-text/human_format.sake: L68 Float.round 1: observed [["Float"]], static Integer
corpus-v2/01-text/human_format.sake: L81 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii_table.sake | 2 | 92 | 8 | 1 | 0 | 77 | 0 | 2 |
| bwt_rle.sake | 2 | 93 | 9 | 0 | 0 | 76 | 0 | 1 |
| case_convert.sake | 2 | 93 | 8 | 0 | 0 | 92 | 0 | 0 |
| classic_ciphers.sake | 2 | 109 | 5 | 0 | 0 | 99 | 0 | 5 |
| columnize.sake | 2 | 69 | 2 | 0 | 0 | 61 | 0 | 0 |
| csv_report.sake | 2 | 97 | 14 | 1 | 0 | 83 | 0 | 3 |
| date_format.sake | 2 | 142 | 19 | 0 | 0 | 126 | 0 | 0 |
| doc_pretty.sake | 2 | 76 | 3 | 0 | 0 | 68 | 0 | 0 |
| human_format.sake | 2 | 119 | 1 | 7 | 0 | 118 | 0 | 11 |
| inflector.sake | 2 | 71 | 1 | 0 | 0 | 60 | 0 | 0 |
corpus-v2/09-dp/held_karp.sake: L91 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer | nil]
corpus-v2/09-dp/held_karp.sake: L91 Float.round 1: observed [["Float"]], static Integer
corpus-v2/09-dp/interval_scheduling.sake: L89 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
corpus-v2/09-dp/interval_scheduling.sake: L88 Array.sum result: observed ["Float"], static Integer
corpus-v2/09-dp/knapsack_01.sake: L83 Float.round 1: observed [["Float"]], static Integer
corpus-v2/09-dp/matrix_chain.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
corpus-v2/09-dp/optimal_bst.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
corpus-v2/09-dp/optimal_bst.sake: L20 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
corpus-v2/09-dp/optimal_bst.sake: L20 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
corpus-v2/09-dp/optimal_bst.sake: L45 Arithmetic.* pair: observed [["Float", "Integer"]], static [nil | Integer, Integer]
corpus-v2/09-dp/optimal_bst.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| held_karp.sake | 2 | 87 | 31 | 1 | 0 | 74 | 0 | 2 |
| house_robber.sake | 3 | 74 | 4 | 0 | 0 | 61 | 0 | 0 |
| interval_scheduling.sake | 2 | 106 | 18 | 0 | 0 | 81 | 0 | 2 |
| knapsack_01.sake | 2 | 56 | 12 | 1 | 0 | 50 | 0 | 1 |
| lcs_diff.sake | 2 | 123 | 14 | 0 | 0 | 78 | 0 | 0 |
| line_breaking.sake | 2 | 80 | 6 | 0 | 0 | 67 | 0 | 0 |
| longest_increasing.sake | 3 | 92 | 8 | 0 | 0 | 68 | 0 | 0 |
| matrix_chain.sake | 3 | 99 | 20 | 0 | 0 | 82 | 0 | 1 |
| optimal_bst.sake | 4 | 106 | 24 | 0 | 0 | 79 | 0 | 5 |
| palindromes.sake | 3 | 125 | 17 | 0 | 0 | 87 | 0 | 0 |
