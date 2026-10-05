../2026-10-05-review/corpus-v3/12-parsers/rpn_calc.sake: [13, 4, "Calc.set_stack", 1]: observed [["Calc"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/rpn_calc.sake: [14, 4, "Calc.set_regs", 1]: observed [["Calc"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/rpn_calc.sake: [15, 4, "Calc.set_stack", 1]: observed [["Calc"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/rpn_calc.sake: [16, 4, "Calc.set_regs", 1]: observed [["Calc"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/rpn_calc.sake: L85 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/12-parsers/symbolic_diff.sake: [23, 22, "Parser.set_pos", 1]: observed [["Parser"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/symbolic_diff.sake: L218 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/12-parsers/symbolic_diff.sake: L218 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/12-parsers/symbolic_diff.sake: L221 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/12-parsers/template_engine.sake: [4, 4, "Tag.set_children", 1]: observed [["Tag"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/template_engine.sake: [5, 4, "Tag.set_children", 1]: observed [["Tag"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [36, 4, "Basic.set_numbers", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [37, 4, "Basic.set_vars", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [38, 4, "Basic.set_pc", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [39, 4, "Basic.set_gosubs", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [40, 4, "Basic.set_fors", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [41, 4, "Basic.set_out", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [42, 4, "Basic.set_partial", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [43, 4, "Basic.set_line", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [45, 4, "Basic.set_code", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [51, 4, "Basic.set_numbers", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [52, 4, "Basic.set_vars", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [53, 4, "Basic.set_gosubs", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [54, 4, "Basic.set_fors", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [55, 4, "Basic.set_out", 1]: observed [["Basic"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/tiny_basic.sake: [11, 22, "Toks.set_pos", 1]: observed [["Toks"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/truth_table.sake: [7, 22, "Reader.set_pos", 1]: observed [["Reader"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/type_checker.sake: [12, 22, "Stream.set_pos", 1]: observed [["Stream"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| rpn_calc.sake | 3 | 75 | 7 | 0 | 0 | 73 | 4 | 5 |
| shunting_yard.sake | 3 | 54 | 6 | 0 | 0 | 52 | 0 | 0 |
| stack_vm.sake | 2 | 95 | 18 | 0 | 0 | 79 | 0 | 0 |
| symbolic_diff.sake | 5 | 87 | 21 | 2 | 0 | 90 | 1 | 4 |
| template_engine.sake | 3 | 87 | 8 | 0 | 0 | 73 | 2 | 2 |
| tiny_basic.sake | 3 | 126 | 25 | 0 | 0 | 137 | 15 | 15 |
| tokenizer.sake | 2 | 120 | 1 | 0 | 0 | 80 | 0 | 0 |
| truth_table.sake | 3 | 78 | 0 | 0 | 2 | 72 | 1 | 1 |
| turing_machine.sake | 2 | 74 | 1 | 0 | 0 | 56 | 0 | 0 |
| type_checker.sake | 4 | 44 | 0 | 0 | 31 | 57 | 1 | 1 |
../2026-10-05-review/corpus-v3/17-encodings/lzw.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| hex_dump.sake | 2 | 73 | 2 | 0 | 0 | 62 | 0 | 0 |
| huffman.sake | 2 | 78 | 8 | 0 | 0 | 76 | 0 | 0 |
| lzw.sake | 2 | 65 | 6 | 0 | 0 | 55 | 0 | 1 |
| morse.sake | 2 | 74 | 0 | 0 | 0 | 70 | 0 | 0 |
| murmur_ring.sake | 2 | 91 | 7 | 0 | 0 | 77 | 0 | 0 |
| percent_encoding.sake | 2 | 82 | 1 | 0 | 0 | 69 | 0 | 0 |
| playfair.sake | 2 | 89 | 1 | 0 | 0 | 74 | 0 | 0 |
| protobuf_wire.sake | 2 | 110 | 9 | 0 | 0 | 90 | 0 | 0 |
| raid5_parity.sake | 3 | 113 | 7 | 0 | 0 | 105 | 0 | 0 |
| rolling_sync.sake | 2 | 129 | 6 | 0 | 0 | 101 | 0 | 0 |
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [20, 4, "HttpParser.set_state", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [21, 4, "HttpParser.set_buffer", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [22, 4, "HttpParser.set_request", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [23, 4, "HttpParser.set_remaining", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [24, 4, "HttpParser.set_done", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [4, 4, "Request.set_method", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [5, 4, "Request.set_path", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [6, 4, "Request.set_version", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [7, 4, "Request.set_headers", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [8, 4, "Request.set_body", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [9, 4, "Request.set_headers", 1]: observed [["Request"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [25, 4, "HttpParser.set_request", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/http_parser.sake: [26, 4, "HttpParser.set_done", 1]: observed [["HttpParser"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/job_pipeline.sake: [4, 4, "Job.set_state", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/job_pipeline.sake: [5, 4, "Job.set_attempts", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/job_pipeline.sake: [6, 4, "Job.set_started", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/job_pipeline.sake: [7, 4, "Job.set_finished", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/keypad_lock.sake: [4, 4, "Keypad.set_state", 1]: observed [["Keypad"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/keypad_lock.sake: [5, 4, "Keypad.set_buffer", 1]: observed [["Keypad"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/keypad_lock.sake: [6, 4, "Keypad.set_failures", 1]: observed [["Keypad"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/keypad_lock.sake: [7, 4, "Keypad.set_lockout_until", 1]: observed [["Keypad"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [27, 4, "Door.set_state", 1]: observed [["Door"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [28, 4, "Door.set_log", 1]: observed [["Door"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [29, 4, "Door.set_opened", 1]: observed [["Door"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [30, 4, "Door.set_log", 1]: observed [["Door"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [43, 4, "Light.set_state", 1]: observed [["Light"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [44, 4, "Light.set_log", 1]: observed [["Light"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [45, 4, "Light.set_brightness", 1]: observed [["Light"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [46, 4, "Light.set_log", 1]: observed [["Light"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [63, 4, "Ticket.set_state", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [64, 4, "Ticket.set_log", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [65, 4, "Ticket.set_reopen_count", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/machine_mixin.sake: [66, 4, "Ticket.set_log", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [13, 4, "Renderer.set_state", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [14, 4, "Renderer.set_out", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [15, 4, "Renderer.set_para", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [16, 4, "Renderer.set_counts", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [17, 4, "Renderer.set_out", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [18, 4, "Renderer.set_para", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/markdown_blocks.sake: [19, 4, "Renderer.set_counts", 1]: observed [["Renderer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L35 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L45 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L49 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L50 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L60 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/19-statemachines/morse_decoder.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/19-statemachines/order_workflow.sake: [34, 4, "Order.set_state", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/order_workflow.sake: [35, 4, "Order.set_paid", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/order_workflow.sake: [36, 4, "Order.set_audit", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/order_workflow.sake: [37, 4, "Order.set_paid", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/order_workflow.sake: [38, 4, "Order.set_audit", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/regex_nfa.sake: [4, 4, "NState.set_out1", 1]: observed [["NState"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/regex_nfa.sake: [5, 4, "NState.set_out2", 1]: observed [["NState"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expr_lexer.sake | 2 | 71 | 0 | 0 | 0 | 55 | 0 | 0 |
| http_parser.sake | 5 | 138 | 15 | 0 | 0 | 140 | 13 | 13 |
| job_pipeline.sake | 3 | 85 | 3 | 0 | 0 | 85 | 4 | 4 |
| keypad_lock.sake | 3 | 69 | 1 | 0 | 0 | 71 | 4 | 4 |
| machine_mixin.sake | 2 | 66 | 0 | 0 | 0 | 70 | 12 | 12 |
| markdown_blocks.sake | 3 | 114 | 4 | 0 | 0 | 112 | 7 | 7 |
| morse_decoder.sake | 2 | 81 | 5 | 0 | 0 | 67 | 0 | 6 |
| order_workflow.sake | 3 | 78 | 0 | 0 | 0 | 72 | 5 | 5 |
| regex_nfa.sake | 3 | 107 | 16 | 0 | 0 | 107 | 2 | 2 |
| shell_words.sake | 2 | 70 | 2 | 0 | 0 | 56 | 0 | 0 |
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L44 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L44 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L70 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: [20, 4, "Welford.set_n", 1]: observed [["Welford"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: [21, 4, "Welford.set_mean", 1]: observed [["Welford"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: [22, 4, "Welford.set_m2", 1]: observed [["Welford"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L75 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L75 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L51 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L27 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L28 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L59 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L59 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L60 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L76 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L76 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L61 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L33 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L79 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L79 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L92 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L112 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L112 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/monte_carlo.sake: L114 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L4 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L6 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L16 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L18 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L18 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L63 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L68 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L75 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L79 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L79 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L79 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L21 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L24 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L25 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L26 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L33 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L33 Comparable.<= pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L119 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L103 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L103 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L127 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numeric_integration.sake: L127 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L1 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L3 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L4 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L4 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L12 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L53 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L36 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L27 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L70 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L70 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L5 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L5 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L84 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L84 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L84 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L96 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/numerical_derivatives.sake: L104 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L29 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L6 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L40 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L55 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L56 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L16 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L16 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L23 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L61 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L63 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L63 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L74 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L74 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L74 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L80 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L92 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L93 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L94 Math.log2 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L40 State.set_t result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/ode_solver.sake: L76 State.set_t result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L15 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L98 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L98 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L98 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L19 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L30 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L30 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L30 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L35 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L99 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L100 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L100 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L38 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L38 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L43 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L55 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L71 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L75 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L77 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L78 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L82 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/optimization.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L54 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L92 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L142 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L142 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/polynomial.sake: L142 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L16 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L16 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L18 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L20 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L22 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L22 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L69 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L38 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [39, 11, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [40, 4, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [41, 45, "Float.abs", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [41, 45, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [50, 8, "Comparable.<", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [51, 4, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [52, 12, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [53, 59, "Kernel.==", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [54, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [54, 14, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [54, 14, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [54, 9, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [55, 52, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [55, 42, "Float.abs", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [55, 42, "Comparable.<", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [75, 49, "Math.cos", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [75, 49, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [76, 46, "Math.cos", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [76, 46, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [76, 64, "Math.sin", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [76, 63, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [80, 11, "Float[]", "elem"]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [80, 0, "Array.each", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 44, "Math.sin", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 38, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 34, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 73, "Math.cos", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 67, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [81, 61, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [82, 53, "Result.root", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [82, 69, "Result.iterations", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [82, 7, "Kernel.format", 1]: observed [["String"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [86, 11, "Float[]", "elem"]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [86, 0, "Array.each", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [88, 19, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [88, 41, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [88, 41, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [89, 32, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [89, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [89, 43, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [90, 16, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [90, 42, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [90, 42, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [92, 10, "Array.max_by", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [92, 43, "Result.root", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [92, 60, "Math.sqrt", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [92, 43, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [92, 33, "Float.abs", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [93, 20, "Array.map", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [93, 40, "Result.iterations", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [93, 10, "Array.sum", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 65, "Result.method", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 97, "Result.root", 1]: observed [["Result"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 118, "Math.sqrt", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 97, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 87, "Float.abs", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [94, 7, "Kernel.format", 1]: observed [["String"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [99, 34, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [99, 34, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [101, 46, "BadBracket.a", 1]: observed [["BadBracket"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [101, 63, "BadBracket.b", 1]: observed [["BadBracket"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [101, 7, "Kernel.format", 1]: observed [["String"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 32, "Arithmetic.**", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 41, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 32, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 62, "Arithmetic.**", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 56, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [105, 56, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [107, 10, "NoConvergence.method", 1]: observed [["NoConvergence"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [107, 50, "NoConvergence.iterations", 1]: observed [["NoConvergence"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [111, 32, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [111, 32, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [111, 45, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [113, 10, "NoConvergence.method", 1]: observed [["NoConvergence"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: [113, 50, "NoConvergence.iterations", 1]: observed [["NoConvergence"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L65 Result.root result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L41 Float.abs result: observed ["Float"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/root_finding.sake: L41 Result.new result: observed ["Result"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L21 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L22 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L22 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L22 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L90 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L90 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L93 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L15 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L34 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L35 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L35 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L105 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L107 Float.infinite? 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L42 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L48 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L55 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L113 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L70 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L70 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L122 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L126 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L126 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L127 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L133 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L133 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L139 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L75 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L75 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/special_functions.sake: L75 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L79 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L44 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L56 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L57 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L57 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L18 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L26 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L26 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L35 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L36 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L36 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L36 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L68 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L68 Comparable.> pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L70 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L70 Comparable.< pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L111 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L112 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L112 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L113 Float.abs 1: observed [["Float"]], static nil | Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L79 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L18 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L35 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L36 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L107 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L112 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/time_series.sake: L112 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L21 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L30 Math.atan2 2: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L33 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L33 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L79 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/vector_geometry.sake: L93 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monte_carlo.sake | 2 | 124 | 0 | 1 | 0 | 121 | 3 | 39 |
| numeric_integration.sake | 2 | 123 | 5 | 5 | 2 | 115 | 0 | 46 |
| numerical_derivatives.sake | 2 | 140 | 19 | 8 | 0 | 130 | 0 | 29 |
| ode_solver.sake | 3 | 127 | 20 | 6 | 0 | 92 | 0 | 29 |
| optimization.sake | 2 | 157 | 15 | 1 | 0 | 139 | 0 | 43 |
| polynomial.sake | 3 | 180 | 11 | 3 | 0 | 142 | 0 | 9 |
| root_finding.sake | 2 | 27 | 0 | 1 | 0 | 103 | 76 | 90 |
| special_functions.sake | 2 | 152 | 7 | 3 | 0 | 146 | 0 | 48 |
| time_series.sake | 3 | 156 | 25 | 3 | 0 | 130 | 0 | 29 |
| vector_geometry.sake | 2 | 124 | 2 | 1 | 0 | 117 | 0 | 14 |
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L46 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L38 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L38 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L61 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L61 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L103 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L47 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L47 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L47 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L55 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L59 Arithmetic.+ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/temperature_units.sake: L103 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L7 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L7 Arithmetic.- pair: observed [["Integer", "Integer"], ["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L31 Arithmetic./ pair: observed [["Vec", "Float"]], static [Vec, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L9 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L9 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L12 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L12 Arithmetic.* pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L12 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L14 Math.sqrt 1: observed [["Integer"], ["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L64 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L64 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L65 Comparable.< pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L110 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L111 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L7 Vec.x result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L7 Vec.y result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L18 Vec.x result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L18 Vec.y result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L12 Vec.x result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/vector_polygon.sake: L12 Vec.y result: observed ["Integer", "Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| stack_vm.sake | 4 | 116 | 8 | 0 | 0 | 95 | 0 | 0 |
| task_heap.sake | 3 | 137 | 10 | 0 | 0 | 109 | 0 | 0 |
| temperature_units.sake | 3 | 131 | 7 | 2 | 0 | 111 | 0 | 18 |
| vector_polygon.sake | 3 | 159 | 8 | 0 | 0 | 138 | 0 | 20 |
| version_constraints.sake | 3 | 112 | 4 | 0 | 0 | 95 | 0 | 0 |
| bank_transfers.sake | 2 | 66 | 1 | 0 | 0 | 56 | 0 | 0 |
| card_validation.sake | 2 | 68 | 2 | 0 | 0 | 54 | 0 | 0 |
| circuit_breaker.sake | 2 | 47 | 0 | 0 | 0 | 38 | 0 | 0 |
| config_loader.sake | 2 | 47 | 0 | 2 | 0 | 38 | 0 | 0 |
| contracts.sake | 2 | 60 | 0 | 0 | 0 | 57 | 0 | 0 |
../2026-10-05-review/corpus-v3/08-graphs/currency_paths.sake: L60 Rational.to_f 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/currency_paths.sake: L49 Kernel.!= pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/currency_paths.sake: L50 Rational.to_s 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/dijkstra_routes.sake: [4, 4, "MinHeap.set_items", 1]: observed [["MinHeap"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/dijkstra_routes.sake: [5, 4, "MinHeap.set_items", 1]: observed [["MinHeap"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/dijkstra_routes.sake: L131 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/floyd_transit.sake: L38 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/08-graphs/friend_groups.sake: L47 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/kruskal_network.sake: [6, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/kruskal_network.sake: [7, 4, "UnionFind.set_rank", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/kruskal_network.sake: [8, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/kruskal_network.sake: [9, 4, "UnionFind.set_rank", 1]: observed [["UnionFind"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| critical_path.sake | 2 | 69 | 17 | 0 | 0 | 63 | 0 | 0 |
| currency_paths.sake | 2 | 57 | 12 | 2 | 0 | 46 | 0 | 3 |
| dijkstra_routes.sake | 3 | 87 | 6 | 1 | 0 | 66 | 2 | 3 |
| dot_stats.sake | 2 | 86 | 2 | 0 | 0 | 56 | 0 | 0 |
| euler_itinerary.sake | 2 | 60 | 2 | 0 | 0 | 48 | 0 | 0 |
| exam_slots.sake | 3 | 79 | 16 | 0 | 0 | 72 | 0 | 0 |
| floyd_transit.sake | 2 | 102 | 26 | 0 | 0 | 64 | 0 | 1 |
| friend_groups.sake | 2 | 81 | 9 | 0 | 0 | 69 | 0 | 1 |
| intern_matching.sake | 2 | 55 | 5 | 0 | 0 | 46 | 0 | 0 |
| kruskal_network.sake | 3 | 86 | 12 | 0 | 0 | 63 | 4 | 4 |
../2026-10-05-review/corpus-v3/01-text/ascii_table.sake: L122 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/ascii_table.sake: L90 Array.sum result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/01-text/bwt_rle.sake: L78 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/classic_ciphers.sake: L59 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/01-text/classic_ciphers.sake: L60 Arithmetic.- pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/classic_ciphers.sake: L61 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/classic_ciphers.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/classic_ciphers.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/csv_report.sake: L88 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/csv_report.sake: L76 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/csv_report.sake: L87 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L13 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L21 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L22 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L22 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L22 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L58 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L62 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L66 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L68 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L68 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/01-text/human_format.sake: L81 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii_table.sake | 2 | 91 | 8 | 1 | 0 | 76 | 0 | 2 |
| bwt_rle.sake | 2 | 96 | 9 | 0 | 0 | 76 | 0 | 1 |
| case_convert.sake | 2 | 93 | 8 | 0 | 0 | 92 | 0 | 0 |
| classic_ciphers.sake | 2 | 110 | 5 | 0 | 0 | 98 | 0 | 5 |
| columnize.sake | 2 | 69 | 2 | 0 | 0 | 61 | 0 | 0 |
| csv_report.sake | 2 | 97 | 14 | 1 | 0 | 82 | 0 | 3 |
| date_format.sake | 2 | 142 | 19 | 0 | 0 | 124 | 0 | 0 |
| doc_pretty.sake | 2 | 76 | 3 | 0 | 0 | 68 | 0 | 0 |
| human_format.sake | 2 | 119 | 1 | 7 | 0 | 118 | 0 | 11 |
| inflector.sake | 2 | 71 | 1 | 0 | 0 | 60 | 0 | 0 |
../2026-10-05-review/corpus-v3/15-data/fulfillment_report.sake: L127 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fulfillment_report.sake: L138 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: [50, 30, "Rational.to_f", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L76 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L77 Comparable.< pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L78 Arithmetic.+ pair: observed [["Rational", "Rational"], ["Rational", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L82 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L88 Rational.abs 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L89 Rational.abs 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L90 Rational.abs 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L91 Arithmetic./ pair: observed [["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L91 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L91 Rational.to_f 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L76 Array.sum result: observed ["Rational", "Integer"], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L77 Array.sum result: observed ["Rational", "Integer"], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L80 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L88 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L89 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/fx_conversion.sake: L90 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L36 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L40 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L65 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L65 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L44 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L45 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L46 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L47 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L56 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L56 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L56 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L56 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L108 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L40 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L52 Array.sum result: observed ["Float", "Integer"], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L56 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L89 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/15-data/grade_book.sake: L89 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/15-data/groupby_query.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/groupby_query.sake: L50 Array.sum result: observed ["Float", "Integer"], static Integer
../2026-10-05-review/corpus-v3/15-data/groupby_query.sake: L51 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Float | Integer | String]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L98 Comparable.<= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L102 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | String]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L102 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L102 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L106 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L102 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/inventory_diff.sake: L64 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/invoice_totals.sake: [8, 26, "Float.round", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L31 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L51 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L51 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L51 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L57 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L62 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L81 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L82 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: [83, 90, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L92 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L92 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Float]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L92 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L51 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L83 Kernel.format result: observed ["String"], static (none)
../2026-10-05-review/corpus-v3/15-data/metric_anomalies.sake: L83 Kernel.puts result: observed ["Nil"], static (none)
../2026-10-05-review/corpus-v3/15-data/quality_rules.sake: L107 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/sales_by_region.sake: L56 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| fulfillment_report.sake | 2 | 141 | 0 | 0 | 0 | 120 | 0 | 2 |
| fx_conversion.sake | 2 | 80 | 3 | 4 | 0 | 73 | 1 | 17 |
| grade_book.sake | 2 | 86 | 0 | 2 | 0 | 78 | 0 | 19 |
| groupby_query.sake | 2 | 86 | 5 | 0 | 0 | 75 | 0 | 3 |
| inventory_diff.sake | 2 | 135 | 4 | 0 | 0 | 130 | 0 | 8 |
| invoice_totals.sake | 2 | 103 | 0 | 0 | 0 | 82 | 1 | 1 |
| league_standings.sake | 3 | 123 | 4 | 0 | 0 | 103 | 0 | 0 |
| metric_anomalies.sake | 2 | 116 | 7 | 6 | 0 | 118 | 1 | 18 |
| quality_rules.sake | 2 | 89 | 0 | 0 | 0 | 74 | 0 | 1 |
| sales_by_region.sake | 2 | 83 | 2 | 0 | 0 | 59 | 0 | 1 |
../2026-10-05-review/corpus-v3/19-statemachines/bank_queue_sim.sake: [15, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/bank_queue_sim.sake: [16, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/bank_queue_sim.sake: L118 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/19-statemachines/button_debounce.sake: [12, 4, "Debouncer.set_edges", 1]: observed [["Debouncer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/button_debounce.sake: [13, 4, "Debouncer.set_state", 1]: observed [["Debouncer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/button_debounce.sake: [14, 4, "Debouncer.set_count", 1]: observed [["Debouncer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/button_debounce.sake: [15, 4, "Debouncer.set_edges", 1]: observed [["Debouncer"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [11, 22, "Service.set_calls", 1]: observed [["Service"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [23, 4, "Breaker.set_state", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [24, 4, "Breaker.set_failures", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [25, 4, "Breaker.set_opened_at", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [26, 4, "Breaker.set_trial_ok", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [27, 4, "Breaker.set_log", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/circuit_breaker.sake: [28, 4, "Breaker.set_log", 1]: observed [["Breaker"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/csv_parser.sake: L106 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [10, 4, "Elevator.set_floor", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [11, 4, "Elevator.set_direction", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [12, 4, "Elevator.set_door", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [13, 4, "Elevator.set_dwell", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [14, 4, "Elevator.set_stops", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [15, 4, "Elevator.set_moved", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [16, 4, "Elevator.set_served", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [17, 4, "Elevator.set_stops", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/elevator.sake: [18, 4, "Elevator.set_served", 1]: observed [["Elevator"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/enemy_ai.sake: [18, 4, "Enemy.set_hp", 1]: observed [["Enemy"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/enemy_ai.sake: [19, 4, "Enemy.set_state", 1]: observed [["Enemy"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/enemy_ai.sake: [20, 4, "Enemy.set_waypoint", 1]: observed [["Enemy"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/enemy_ai.sake: [21, 4, "Enemy.set_transitions", 1]: observed [["Enemy"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bank_queue_sim.sake | 2 | 139 | 7 | 0 | 0 | 114 | 2 | 3 |
| bracket_checker.sake | 2 | 53 | 1 | 0 | 0 | 51 | 0 | 0 |
| button_debounce.sake | 5 | 72 | 4 | 0 | 0 | 79 | 4 | 4 |
| circuit_breaker.sake | 2 | 70 | 4 | 0 | 0 | 73 | 7 | 7 |
| csv_parser.sake | 2 | 74 | 4 | 0 | 0 | 71 | 0 | 1 |
| dfa_minimize.sake | 3 | 92 | 1 | 0 | 0 | 78 | 0 | 0 |
| divisibility_dfa.sake | 4 | 78 | 1 | 0 | 4 | 71 | 0 | 0 |
| elevator.sake | 3 | 95 | 4 | 0 | 0 | 102 | 9 | 9 |
| enemy_ai.sake | 4 | 106 | 8 | 0 | 0 | 111 | 4 | 4 |
| event_sourcing.sake | 2 | 81 | 0 | 0 | 0 | 70 | 0 | 0 |
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: [36, 4, "Restaurant.set_tables", 1]: observed [["Restaurant"]] but no static check
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: [37, 4, "Restaurant.set_queue", 1]: observed [["Restaurant"]] but no static check
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: [38, 4, "Restaurant.set_tables", 1]: observed [["Restaurant"]] but no static check
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: [39, 4, "Restaurant.set_queue", 1]: observed [["Restaurant"]] but no static check
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: L68 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: L69 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/restaurant_orders.sake: L81 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: [33, 4, "Schedule.set_bookings", 1]: observed [["Schedule"]] but no static check
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: [34, 4, "Schedule.set_last_id", 1]: observed [["Schedule"]] but no static check
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: [35, 4, "Schedule.set_bookings", 1]: observed [["Schedule"]] but no static check
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: L147 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: L148 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/room_reservations.sake: L147 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L57 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer | nil]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L63 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L31 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L31 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L92 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L52 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L69 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L70 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L79 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/sales_report.sake: L89 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: [43, 4, "Cart.set_lines", 1]: observed [["Cart"]] but no static check
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: [44, 4, "Cart.set_coupon", 1]: observed [["Cart"]] but no static check
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: [45, 4, "Cart.set_lines", 1]: observed [["Cart"]] but no static check
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: L89 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: [8, 26, "Float.round", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: L133 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/shopping_cart.sake: L136 Arithmetic.* pair: observed [["Money", "Integer"], ["Money", "Float"]], static [Money, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L36 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L36 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Rational]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L51 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L51 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L102 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L27 Rational.round 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L27 Rational.to_f 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L121 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L50 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L99 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/subscription_billing.sake: L117 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [59, 4, "Desk.set_tickets", 1]: observed [["Desk"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [60, 4, "Desk.set_tickets", 1]: observed [["Desk"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [27, 4, "Ticket.set_status", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [28, 4, "Ticket.set_agent", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [29, 4, "Ticket.set_first_reply_at", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [30, 4, "Ticket.set_closed_at", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [31, 4, "Ticket.set_log", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/ticket_helpdesk.sake: [32, 4, "Ticket.set_log", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L83 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L83 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L83 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L91 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L91 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/timesheet.sake: L89 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/todo_list.sake: [25, 4, "TodoList.set_items", 1]: observed [["TodoList"]] but no static check
../2026-10-05-review/corpus-v3/20-business/todo_list.sake: [26, 4, "TodoList.set_next_id", 1]: observed [["TodoList"]] but no static check
../2026-10-05-review/corpus-v3/20-business/todo_list.sake: [27, 4, "TodoList.set_items", 1]: observed [["TodoList"]] but no static check
../2026-10-05-review/corpus-v3/20-business/todo_list.sake: L134 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L15 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L15 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L91 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L91 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L76 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/vendor_quotes.sake: L90 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| restaurant_orders.sake | 2 | 101 | 0 | 3 | 0 | 99 | 4 | 8 |
| room_reservations.sake | 3 | 103 | 4 | 0 | 0 | 102 | 3 | 6 |
| sales_report.sake | 2 | 119 | 11 | 1 | 0 | 113 | 0 | 16 |
| shopping_cart.sake | 3 | 137 | 3 | 0 | 0 | 129 | 4 | 7 |
| subscription_billing.sake | 2 | 111 | 1 | 2 | 0 | 90 | 0 | 11 |
| ticket_helpdesk.sake | 3 | 97 | 2 | 0 | 0 | 100 | 8 | 8 |
| timesheet.sake | 2 | 74 | 15 | 0 | 0 | 82 | 0 | 6 |
| todo_list.sake | 2 | 96 | 3 | 0 | 0 | 94 | 3 | 4 |
| vendor_quotes.sake | 2 | 81 | 6 | 0 | 0 | 78 | 0 | 7 |
| warehouse_picking.sake | 2 | 93 | 11 | 0 | 0 | 97 | 0 | 0 |
../2026-10-05-review/corpus-v3/10-grids/hex_game.sake: [23, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/10-grids/hex_game.sake: [24, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| flood_fill.sake | 2 | 92 | 9 | 0 | 0 | 77 | 0 | 0 |
| game_2048.sake | 4 | 97 | 7 | 0 | 0 | 80 | 0 | 0 |
| game_of_life.sake | 2 | 73 | 3 | 0 | 0 | 62 | 0 | 0 |
| hex_game.sake | 2 | 133 | 0 | 0 | 0 | 114 | 2 | 2 |
| knights_tour.sake | 2 | 90 | 7 | 0 | 0 | 84 | 0 | 0 |
| langtons_ant.sake | 2 | 86 | 1 | 0 | 0 | 73 | 0 | 0 |
| lights_out.sake | 2 | 79 | 0 | 0 | 0 | 74 | 0 | 0 |
| magic_square.sake | 2 | 101 | 8 | 0 | 0 | 82 | 0 | 0 |
| matrix_spiral.sake | 3 | 130 | 7 | 0 | 0 | 102 | 0 | 0 |
| maze_bfs.sake | 2 | 67 | 4 | 0 | 0 | 55 | 0 | 0 |
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L28 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/collision_check.sake: L36 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L51 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L52 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L54 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L54 Arithmetic.- pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L55 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L57 Kernel.== pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L60 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L62 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L32 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L32 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L32 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L32 Arithmetic.** pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L35 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L35 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L56 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L56 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L56 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L58 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L58 Arithmetic.+ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L32 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L11 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L28 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L28 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L28 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L73 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L73 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L74 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: [75, 58, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L40 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L41 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L42 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L42 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L42 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L121 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L122 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L123 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L123 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L49 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/13-polymorphism/color_palette.sake: L50 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/13-polymorphism/duration_timesheet.sake: L36 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/duration_timesheet.sake: L126 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/duration_timesheet.sake: L32 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/duration_timesheet.sake: L32 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/fraction_math.sake: L50 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/interval_arith.sake: L84 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Float"], ["Float", "Integer"], ["Interval", "Interval"], ["Interval", "Integer"]], static [Integer | Interval, Integer | Interval]
../2026-10-05-review/corpus-v3/13-polymorphism/interval_arith.sake: L89 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/interval_arith.sake: L53 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/interval_arith.sake: L30 Array.min result: observed ["Integer", "Float"], static Integer | nil
../2026-10-05-review/corpus-v3/13-polymorphism/interval_arith.sake: L30 Array.max result: observed ["Integer", "Float"], static Integer | nil
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bitset_permissions.sake | 2 | 90 | 10 | 0 | 0 | 73 | 0 | 0 |
| calendar_dates.sake | 3 | 143 | 8 | 0 | 0 | 132 | 0 | 0 |
| collision_check.sake | 3 | 176 | 0 | 0 | 0 | 149 | 0 | 9 |
| color_palette.sake | 2 | 163 | 16 | 4 | 0 | 162 | 1 | 55 |
| doc_render.sake | 2 | 138 | 7 | 0 | 0 | 118 | 0 | 0 |
| duration_timesheet.sake | 2 | 154 | 5 | 1 | 0 | 132 | 0 | 4 |
| expr_tree.sake | 3 | 192 | 1 | 0 | 0 | 125 | 0 | 0 |
| fraction_math.sake | 2 | 166 | 1 | 0 | 0 | 125 | 0 | 1 |
| interval_arith.sake | 3 | 122 | 32 | 0 | 0 | 124 | 0 | 5 |
| life_grid.sake | 2 | 80 | 6 | 0 | 0 | 64 | 0 | 0 |
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [76, 4, "Cron.set_minutes", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [77, 4, "Cron.set_hours", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [78, 4, "Cron.set_doms", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [79, 4, "Cron.set_months", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [80, 4, "Cron.set_dows", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [81, 4, "Cron.set_dom_any", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [82, 4, "Cron.set_dow_any", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [84, 4, "Cron.set_minutes", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [85, 4, "Cron.set_hours", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [86, 4, "Cron.set_doms", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [87, 4, "Cron.set_months", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [88, 4, "Cron.set_dows", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [89, 4, "Cron.set_dom_any", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/cron_schedule.sake: [90, 4, "Cron.set_dow_any", 1]: observed [["Cron"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/durations.sake: L21 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/16-dates/fiscal_quarters.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cron_schedule.sake | 2 | 150 | 4 | 0 | 0 | 154 | 14 | 14 |
| date_arith.sake | 2 | 119 | 4 | 0 | 0 | 102 | 0 | 0 |
| date_parser.sake | 2 | 126 | 24 | 0 | 0 | 111 | 0 | 0 |
| day_of_week.sake | 2 | 70 | 15 | 0 | 0 | 60 | 0 | 0 |
| durations.sake | 2 | 103 | 5 | 1 | 0 | 94 | 0 | 1 |
| easter.sake | 2 | 130 | 2 | 0 | 0 | 107 | 0 | 0 |
| fiscal_quarters.sake | 2 | 110 | 15 | 0 | 0 | 106 | 0 | 1 |
| iso_week.sake | 2 | 106 | 13 | 0 | 0 | 99 | 0 | 0 |
| meeting_scheduler.sake | 3 | 102 | 17 | 0 | 0 | 111 | 0 | 0 |
| month_calendar.sake | 2 | 81 | 3 | 0 | 0 | 70 | 0 | 0 |
../2026-10-05-review/corpus-v3/06-linked/deque_sliding_window.sake: [6, 4, "Deque.set_front", 1]: observed [["Deque"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/deque_sliding_window.sake: [7, 4, "Deque.set_back", 1]: observed [["Deque"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/deque_sliding_window.sake: [8, 4, "Deque.set_length", 1]: observed [["Deque"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [15, 4, "Pool.set_names", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [16, 4, "Pool.set_links", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [17, 4, "Pool.set_prevs", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [18, 4, "Pool.set_live", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [19, 4, "Pool.set_free_head", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [20, 4, "Pool.set_used_head", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [21, 4, "Pool.set_in_use", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [22, 4, "Pool.set_peak", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [24, 4, "Pool.set_names", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [25, 4, "Pool.set_links", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [26, 4, "Pool.set_prevs", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/free_list_pool.sake: [27, 4, "Pool.set_live", 1]: observed [["Pool"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lfu_cache_buckets.sake: [42, 4, "LFU.set_items", 1]: observed [["LFU"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lfu_cache_buckets.sake: [43, 4, "LFU.set_lowest", 1]: observed [["LFU"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lfu_cache_buckets.sake: [44, 4, "LFU.set_log", 1]: observed [["LFU"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lfu_cache_buckets.sake: [45, 4, "LFU.set_items", 1]: observed [["LFU"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lfu_cache_buckets.sake: [46, 4, "LFU.set_log", 1]: observed [["LFU"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [7, 4, "LRUCache.set_index", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [8, 4, "LRUCache.set_newest", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [9, 4, "LRUCache.set_oldest", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [10, 4, "LRUCache.set_hits", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [11, 4, "LRUCache.set_misses", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [12, 4, "LRUCache.set_evicted", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [13, 4, "LRUCache.set_index", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: [14, 4, "LRUCache.set_evicted", 1]: observed [["LRUCache"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/lru_cache.sake: L92 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| cycle_detection.sake | 2 | 65 | 13 | 0 | 0 | 66 | 0 | 0 |
| deque_sliding_window.sake | 3 | 91 | 9 | 0 | 0 | 87 | 3 | 3 |
| digit_list_bignum.sake | 2 | 98 | 0 | 0 | 0 | 84 | 0 | 0 |
| free_list_pool.sake | 3 | 102 | 10 | 0 | 0 | 94 | 12 | 12 |
| josephus_circle.sake | 2 | 55 | 5 | 0 | 0 | 46 | 0 | 0 |
| lfu_cache_buckets.sake | 4 | 85 | 3 | 0 | 0 | 90 | 5 | 5 |
| list_toolkit.sake | 3 | 62 | 12 | 1 | 0 | 73 | 0 | 0 |
| lru_cache.sake | 3 | 73 | 1 | 0 | 0 | 72 | 8 | 9 |
| markup_tag_checker.sake | 2 | 62 | 2 | 0 | 0 | 58 | 0 | 0 |
| merge_log_streams.sake | 3 | 82 | 6 | 0 | 0 | 69 | 0 | 0 |
../2026-10-05-review/corpus-v3/10-grids/sliding_puzzle.sake: [12, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/10-grids/sliding_puzzle.sake: [13, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/10-grids/terrain_dijkstra.sake: L51 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| minesweeper.sake | 3 | 74 | 11 | 0 | 0 | 75 | 0 | 0 |
| n_queens.sake | 2 | 69 | 0 | 0 | 0 | 62 | 0 | 0 |
| nonogram.sake | 4 | 106 | 4 | 0 | 0 | 86 | 0 | 0 |
| othello.sake | 2 | 102 | 10 | 0 | 0 | 75 | 0 | 0 |
| sliding_puzzle.sake | 2 | 156 | 12 | 0 | 0 | 117 | 2 | 2 |
| sokoban.sake | 3 | 122 | 1 | 0 | 0 | 111 | 0 | 0 |
| sudoku_solver.sake | 2 | 94 | 4 | 0 | 0 | 77 | 0 | 0 |
| terrain_dijkstra.sake | 3 | 77 | 8 | 0 | 0 | 59 | 0 | 1 |
| tic_tac_toe.sake | 3 | 79 | 5 | 0 | 0 | 59 | 0 | 0 |
| word_search.sake | 2 | 94 | 3 | 0 | 0 | 76 | 0 | 0 |
../2026-10-05-review/corpus-v3/15-data/access_log_report.sake: L68 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/access_log_report.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/access_log_report.sake: L48 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/access_log_report.sake: L48 Float.ceil 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/bank_reconcile.sake: L41 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/bank_reconcile.sake: L41 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/bank_reconcile.sake: L47 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/15-data/bank_reconcile.sake: L69 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/15-data/budget_variance.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/budget_variance.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/budget_variance.sake: L21 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/budget_variance.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/budget_variance.sake: L54 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/clickstream_sessions.sake: L86 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/clickstream_sessions.sake: L110 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/15-data/csv_import_validation.sake: L110 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/customer_dedupe.sake: [9, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/15-data/customer_dedupe.sake: [10, 4, "UnionFind.set_size", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/15-data/customer_dedupe.sake: [11, 4, "UnionFind.set_parent", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/15-data/customer_dedupe.sake: [12, 4, "UnionFind.set_size", 1]: observed [["UnionFind"]] but no static check
../2026-10-05-review/corpus-v3/15-data/customer_dedupe.sake: L126 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/employee_dept_join.sake: L52 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/etl_star_schema.sake: [9, 4, "Dimension.set_by_natural", 1]: observed [["Dimension"]] but no static check
../2026-10-05-review/corpus-v3/15-data/etl_star_schema.sake: [10, 4, "Dimension.set_rows", 1]: observed [["Dimension"]] but no static check
../2026-10-05-review/corpus-v3/15-data/etl_star_schema.sake: [11, 4, "Dimension.set_by_natural", 1]: observed [["Dimension"]] but no static check
../2026-10-05-review/corpus-v3/15-data/etl_star_schema.sake: [12, 4, "Dimension.set_rows", 1]: observed [["Dimension"]] but no static check
../2026-10-05-review/corpus-v3/15-data/etl_star_schema.sake: L134 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [6, 4, "Pivot.set_cells", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [7, 4, "Pivot.set_rows", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [8, 4, "Pivot.set_cols", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [9, 4, "Pivot.set_cells", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [10, 4, "Pivot.set_rows", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: [11, 4, "Pivot.set_cols", 1]: observed [["Pivot"]] but no static check
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L52 Arithmetic.+ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L47 Kernel.== pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L66 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L85 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L85 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L85 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L88 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L23 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L25 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/expense_pivot.sake: L24 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| access_log_report.sake | 2 | 110 | 7 | 1 | 0 | 99 | 0 | 4 |
| bank_reconcile.sake | 2 | 108 | 5 | 3 | 0 | 108 | 0 | 4 |
| budget_variance.sake | 2 | 52 | 0 | 0 | 0 | 41 | 0 | 5 |
| clickstream_sessions.sake | 2 | 111 | 5 | 0 | 0 | 105 | 0 | 2 |
| cohort_retention.sake | 2 | 90 | 7 | 0 | 0 | 89 | 0 | 0 |
| csv_import_validation.sake | 2 | 99 | 6 | 0 | 0 | 94 | 0 | 1 |
| customer_dedupe.sake | 3 | 134 | 0 | 0 | 0 | 110 | 4 | 5 |
| employee_dept_join.sake | 2 | 97 | 0 | 0 | 0 | 87 | 0 | 1 |
| etl_star_schema.sake | 2 | 160 | 8 | 0 | 0 | 119 | 4 | 5 |
| expense_pivot.sake | 2 | 91 | 3 | 0 | 0 | 78 | 6 | 17 |
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L4 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L31 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L31 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L33 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L33 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L10 Math.hypot 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L10 Math.hypot 2: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L55 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L65 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L67 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L71 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L82 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/bezier_curves.sake: L90 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L19 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L20 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L26 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L28 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L29 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L29 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L32 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L43 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L82 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L95 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L102 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L102 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L102 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L102 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L104 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L104 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L106 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L106 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L106 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L107 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L107 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L107 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L113 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L19 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/correlation_matrix.sake: L20 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L97 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L95 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L95 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L95 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L34 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L34 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L15 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L18 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L102 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L60 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L60 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L50 Comparable.<= pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L63 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L63 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L64 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L91 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L91 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L92 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L92 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L81 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L81 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L81 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L82 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L109 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L111 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L111 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L112 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L112 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L113 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L113 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L71 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L71 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L72 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L72 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L73 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L119 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L119 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L119 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L60 Array.first result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L60 Array.last result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/cubic_spline.sake: L89 Array.last result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L68 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L56 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L55 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L55 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L59 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L59 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L76 Math.exp 1: observed [["Float"]], static nil | Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L19 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L7 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L7 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L11 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L12 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L27 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L105 Float.abs 1: observed [["Float"]], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L67 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L68 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L7 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/curve_fitting.sake: L11 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L5 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L16 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [17, 7, "Float.ceil", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [18, 23, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L9 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L9 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L9 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L12 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [19, 9, "Arithmetic.-", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [20, 16, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [20, 2, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [20, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: [20, 2, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L29 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L29 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L92 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L5 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L17 Float.ceil result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L9 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/descriptive_stats.sake: L29 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| pythagorean_triples.sake | 2 | 158 | 3 | 0 | 0 | 147 | 0 | 0 |
| quadratic_residues.sake | 2 | 148 | 2 | 0 | 0 | 129 | 0 | 0 |
| repeating_decimals.sake | 2 | 85 | 14 | 0 | 0 | 69 | 0 | 0 |
| rsa_toy.sake | 2 | 98 | 0 | 0 | 0 | 92 | 0 | 0 |
| sieve_primes.sake | 2 | 86 | 2 | 0 | 0 | 72 | 0 | 0 |
| bezier_curves.sake | 2 | 126 | 14 | 0 | 4 | 110 | 0 | 22 |
| correlation_matrix.sake | 2 | 144 | 11 | 3 | 0 | 115 | 0 | 44 |
| cubic_spline.sake | 2 | 274 | 43 | 11 | 0 | 199 | 0 | 81 |
| curve_fitting.sake | 2 | 149 | 29 | 1 | 0 | 113 | 0 | 24 |
| descriptive_stats.sake | 2 | 73 | 1 | 2 | 19 | 82 | 7 | 22 |
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L76 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L77 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L67 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L68 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L68 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L69 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L69 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L79 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L85 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bisect_on_answer.sake: L135 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L9 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L11 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L13 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L14 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L15 Float.clamp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L35 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L57 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L87 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L88 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/bucket_sort_ratings.sake: L88 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/heap_scheduler.sake: [19, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/heap_scheduler.sake: [20, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/leaderboard_insert.sake: [19, 4, "Board.set_entries", 1]: observed [["Board"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/leaderboard_insert.sake: [20, 4, "Board.set_scores", 1]: observed [["Board"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/leaderboard_insert.sake: [21, 4, "Board.set_moves", 1]: observed [["Board"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/leaderboard_insert.sake: [22, 4, "Board.set_entries", 1]: observed [["Board"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/leaderboard_insert.sake: [23, 4, "Board.set_scores", 1]: observed [["Board"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| autocomplete_msd.sake | 2 | 77 | 16 | 0 | 0 | 66 | 0 | 0 |
| bisect_on_answer.sake | 2 | 81 | 11 | 0 | 0 | 78 | 0 | 11 |
| bucket_sort_ratings.sake | 2 | 91 | 9 | 6 | 0 | 87 | 0 | 21 |
| external_sort_sim.sake | 3 | 116 | 19 | 0 | 0 | 98 | 0 | 0 |
| gift_two_pointers.sake | 2 | 114 | 19 | 0 | 0 | 92 | 0 | 0 |
| gradebook_insertion.sake | 2 | 67 | 6 | 0 | 0 | 56 | 0 | 0 |
| hashtag_trends.sake | 2 | 65 | 5 | 0 | 0 | 57 | 0 | 0 |
| heap_scheduler.sake | 3 | 106 | 5 | 0 | 0 | 71 | 2 | 2 |
| kway_log_merge.sake | 2 | 146 | 11 | 0 | 0 | 104 | 0 | 0 |
| leaderboard_insert.sake | 2 | 77 | 6 | 0 | 0 | 77 | 5 | 5 |
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L7 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L17 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L107 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L67 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L67 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [67, 72, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [67, 62, "Math.sqrt", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [67, 43, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [67, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [68, 28, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [68, 18, "Math.sqrt", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [68, 12, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [69, 12, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [73, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [73, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [74, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [74, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [79, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [79, 20, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [80, 30, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: [80, 20, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L27 Float.abs 1: observed [["Float"]], static nil | Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L30 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L31 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L126 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L126 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L126 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L5 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L6 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L67 Math.sqrt result: observed ["Float"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L68 Math.sqrt result: observed ["Float"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L121 Range.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/eigenvalues.sake: L122 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L40 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L40 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L69 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L69 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L56 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L57 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L58 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [4, 4, "Summer.set_sum", 1]: observed [["Summer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [5, 4, "Summer.set_comp", 1]: observed [["Summer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L14 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L45 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L50 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L50 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L51 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L52 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L52 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L94 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L94 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L94 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L95 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L95 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L95 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L101 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L101 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L102 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L102 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L107 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L109 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L109 Float.nan? 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L109 Float.finite? 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [110, 21, "Float.infinite?", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [110, 45, "Float.infinite?", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [111, 18, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [111, 41, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: [113, 2, "Float.to_i", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L110 Float.infinite? result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/float_accuracy.sake: L110 Float.infinite? result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L62 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L62 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L62 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L28 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L7 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L7 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L73 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L75 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L55 Arithmetic.* pair: observed [["Cpx", "Float"]], static [Cpx, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [14, 26, "Cpx.re", 1]: observed [["Cpx"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [14, 26, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [14, 35, "Cpx.im", 1]: observed [["Cpx"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [14, 35, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [87, 68, "Arithmetic.-", "pair"]: observed [["Cpx", "Cpx"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L93 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L93 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [98, 24, "Arithmetic.*", "pair"]: observed [["Float", "Float"], ["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [98, 24, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [98, 15, "Math.sin", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [98, 9, "Arithmetic.*", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [98, 9, "Arithmetic.+", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [99, 43, "Cpx.re", 1]: observed [["Cpx"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [99, 43, "Arithmetic.-", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [99, 33, "Float.abs", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [99, 20, "Float[]", "elem"]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: [99, 10, "Array.max", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L82 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L83 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/fourier_spectrum.sake: L87 Array.max result: observed ["Float"], static nil
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L22 Kernel.== pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L23 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L23 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L24 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L24 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L30 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L62 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L53 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L91 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L94 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L109 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/gaussian_elimination.sake: L59 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L8 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L14 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L14 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L14 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L14 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L73 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L73 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L73 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L36 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L37 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L37 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L39 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L39 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L39 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L31 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L24 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L25 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L26 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L26 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L28 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L28 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L31 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L31 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L83 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L83 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L84 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L84 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L84 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L84 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L84 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L91 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L49 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L49 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L98 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L98 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L105 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L105 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L105 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L105 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L111 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L112 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L57 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L58 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L112 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L72 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L73 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L74 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L74 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L34 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L35 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L83 Bin.hi result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L83 Bin.lo result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L85 Bin.lo result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L85 Bin.hi result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/histogram_fit.sake: L50 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L31 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L46 Float[] elem: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L58 Arithmetic.* pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L58 Arithmetic.* pair: observed [["Interval", "Float"], ["Float", "Float"]], static [Integer | Interval, Float]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L58 Arithmetic.- pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L58 Arithmetic.+ pair: observed [["Interval", "Interval"], ["Float", "Float"]], static [Integer | Interval, Integer | Interval | nil]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L127 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L60 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L51 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L73 Comparable.> pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L79 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L83 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L94 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L96 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L128 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/interval_arithmetic.sake: L128 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L15 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L16 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L21 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L21 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L21 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L22 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L22 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L22 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L22 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L23 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L23 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L23 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L27 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L28 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L28 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L29 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L29 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L30 Arithmetic./ pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L30 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L8 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L8 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L67 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L67 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L68 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L37 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L41 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L41 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L41 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L41 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L42 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L42 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L42 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L42 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L45 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L15 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L16 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L28 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L35 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L36 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L37 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/linear_regression.sake: L92 Fit.r2 result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L17 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L17 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L13 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L28 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L31 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L32 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L104 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L106 Comparable.< pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L55 Comparable.> pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L56 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L58 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L59 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L65 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L113 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L78 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L104 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/loan_amortization.sake: L104 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L69 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L91 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil | Integer]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L38 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L103 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L109 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L44 Range.reduce result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L65 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/lu_decomposition.sake: L65 Array.max result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L58 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L88 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L92 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L108 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L72 Range.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/04-numeric/matrix_ops.sake: L108 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| eigenvalues.sake | 2 | 176 | 43 | 2 | 0 | 149 | 22 | 48 |
| float_accuracy.sake | 2 | 114 | 5 | 5 | 0 | 120 | 7 | 45 |
| fourier_spectrum.sake | 2 | 146 | 8 | 1 | 0 | 142 | 15 | 36 |
| gaussian_elimination.sake | 2 | 168 | 47 | 7 | 0 | 120 | 0 | 13 |
| histogram_fit.sake | 2 | 165 | 11 | 3 | 0 | 158 | 0 | 81 |
| interval_arithmetic.sake | 2 | 101 | 47 | 2 | 0 | 123 | 0 | 16 |
| linear_regression.sake | 2 | 120 | 9 | 1 | 0 | 111 | 0 | 45 |
| loan_amortization.sake | 2 | 111 | 5 | 1 | 0 | 102 | 0 | 18 |
| lu_decomposition.sake | 3 | 171 | 36 | 7 | 0 | 115 | 0 | 11 |
| matrix_ops.sake | 3 | 173 | 12 | 0 | 0 | 140 | 0 | 6 |
../2026-10-05-review/corpus-v3/11-simulation/bakery_shift.sake: [8, 22, "Order.set_ready_at", 1]: observed [["Order"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/bakery_shift.sake: [15, 4, "Oven.set_busy_until", 1]: observed [["Oven"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/bakery_shift.sake: [16, 4, "Oven.set_batches", 1]: observed [["Oven"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/bank_ledger.sake: [13, 4, "Account.set_balance", 1]: observed [["Account"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/bank_ledger.sake: [14, 4, "Account.set_frozen", 1]: observed [["Account"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [36, 4, "Car.set_bookings", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [37, 4, "Car.set_bookings", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [52, 4, "Fleet.set_log", 1]: observed [["Fleet"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [53, 4, "Fleet.set_log", 1]: observed [["Fleet"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [5, 4, "Booking.set_car", 1]: observed [["Booking"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [6, 4, "Booking.set_price", 1]: observed [["Booking"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/car_rental.sake: [7, 4, "Booking.set_upgraded", 1]: observed [["Booking"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/checkout_lanes.sake: [5, 4, "Lane.set_queue", 1]: observed [["Lane"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/checkout_lanes.sake: [6, 4, "Lane.set_busy_until", 1]: observed [["Lane"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/checkout_lanes.sake: [7, 4, "Lane.set_served", 1]: observed [["Lane"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/checkout_lanes.sake: [8, 4, "Lane.set_open", 1]: observed [["Lane"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/checkout_lanes.sake: [9, 4, "Lane.set_queue", 1]: observed [["Lane"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/cpu_scheduler.sake: [5, 4, "Job.set_remaining", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/cpu_scheduler.sake: [6, 4, "Job.set_finished", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/cpu_scheduler.sake: [7, 4, "Job.set_first_run", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/cpu_scheduler.sake: [8, 4, "Job.set_remaining", 1]: observed [["Job"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L16 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L21 Float.clamp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L21 Float.clamp 3: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L23 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L26 Float.clamp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L26 Float.clamp 3: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L27 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L27 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L30 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L30 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L45 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L46 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L50 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L54 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L55 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L77 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L78 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L79 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L54 Patch.set_rabbits result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L55 Patch.set_rabbits result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L83 Census.grass result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L83 Census.rabbits result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L83 Census.foxes result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/ecosystem_patches.sake: L87 Census.rabbits result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [5, 4, "Rider.set_boarded_at", 1]: observed [["Rider"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [6, 4, "Rider.set_arrived_at", 1]: observed [["Rider"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [26, 4, "Car.set_dir", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [27, 4, "Car.set_riders", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [28, 4, "Car.set_stops", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [29, 4, "Car.set_moves", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [30, 4, "Car.set_riders", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/elevator_scan.sake: [31, 4, "Car.set_stops", 1]: observed [["Car"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/epidemic_network.sake: [5, 4, "Person.set_days_sick", 1]: observed [["Person"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/epidemic_network.sake: [6, 4, "Person.set_infected_by", 1]: observed [["Person"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/epidemic_network.sake: [7, 4, "Person.set_infected_on", 1]: observed [["Person"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/epidemic_network.sake: L122 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/forest_fire.sake: [8, 4, "Forest.set_burned", 1]: observed [["Forest"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/forest_fire.sake: [9, 4, "Forest.set_fires_started", 1]: observed [["Forest"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/forest_fire.sake: [10, 4, "Forest.set_cells", 1]: observed [["Forest"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/forest_fire.sake: [11, 4, "Forest.set_cells", 1]: observed [["Forest"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/forest_fire.sake: L85 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [25, 4, "Room.set_stays", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [26, 4, "Room.set_stays", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [41, 4, "Hotel.set_waitlist", 1]: observed [["Hotel"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [42, 4, "Hotel.set_ledger", 1]: observed [["Hotel"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [43, 4, "Hotel.set_next_ref", 1]: observed [["Hotel"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [44, 4, "Hotel.set_waitlist", 1]: observed [["Hotel"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [45, 4, "Hotel.set_ledger", 1]: observed [["Hotel"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L121 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L30 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L49 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L9 Time.friday? 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [10, 9, "Time.month", 1]: observed [["Time"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [10, 9, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [10, 32, "Time.day", 1]: observed [["Time"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [10, 32, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [9, 31, "Time.saturday?", 1]: observed [["Time"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [17, 22, "Stay.set_status", 1]: observed [["Stay"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L64 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L19 Arithmetic.+ pair: observed [["Time", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L57 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [81, 30, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [81, 29, "Arithmetic./", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [81, 18, "Float.to_i", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [82, 17, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: [84, 20, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L137 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L10 Time.month result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L10 Time.day result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L9 Time.saturday? result: observed ["Boolean"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L81 Stay.first_night result: observed ["Time"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/hotel_bookings.sake: L81 Float.to_i result: observed ["Integer"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| bakery_shift.sake | 2 | 91 | 8 | 0 | 0 | 87 | 3 | 3 |
| bank_ledger.sake | 2 | 90 | 0 | 0 | 0 | 78 | 2 | 2 |
| car_rental.sake | 2 | 122 | 3 | 0 | 0 | 119 | 7 | 7 |
| checkout_lanes.sake | 2 | 98 | 1 | 0 | 0 | 85 | 5 | 5 |
| cpu_scheduler.sake | 2 | 91 | 2 | 0 | 0 | 83 | 4 | 4 |
| ecosystem_patches.sake | 2 | 128 | 1 | 4 | 0 | 123 | 0 | 25 |
| elevator_scan.sake | 2 | 154 | 5 | 0 | 0 | 159 | 8 | 8 |
| epidemic_network.sake | 2 | 112 | 5 | 0 | 0 | 98 | 3 | 4 |
| forest_fire.sake | 3 | 95 | 8 | 0 | 0 | 82 | 4 | 5 |
| hotel_bookings.sake | 3 | 115 | 2 | 5 | 0 | 124 | 18 | 31 |
../2026-10-05-review/corpus-v3/08-graphs/land_islands.sake: [6, 4, "Islands.set_count", 1]: observed [["Islands"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/land_islands.sake: [7, 4, "Islands.set_parent", 1]: observed [["Islands"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/land_islands.sake: [8, 4, "Islands.set_size", 1]: observed [["Islands"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/land_islands.sake: [9, 4, "Islands.set_parent", 1]: observed [["Islands"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/land_islands.sake: [10, 4, "Islands.set_size", 1]: observed [["Islands"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [5, 4, "FlowNet.set_cap", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [6, 4, "FlowNet.set_flow", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [7, 4, "FlowNet.set_nodes", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [8, 4, "FlowNet.set_cap", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [9, 4, "FlowNet.set_flow", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/pipeline_flow.sake: [10, 4, "FlowNet.set_nodes", 1]: observed [["FlowNet"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/prim_cables.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/prim_cables.sake: L84 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/prim_cables.sake: L84 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/prim_cables.sake: L84 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/prim_cables.sake: L84 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [6, 4, "Tarjan.set_index", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [7, 4, "Tarjan.set_low", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [8, 4, "Tarjan.set_on_stack", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [9, 4, "Tarjan.set_stack", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [10, 4, "Tarjan.set_counter", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [11, 4, "Tarjan.set_sccs", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [12, 4, "Tarjan.set_index", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [13, 4, "Tarjan.set_low", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [14, 4, "Tarjan.set_on_stack", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [15, 4, "Tarjan.set_stack", 1]: observed [["Tarjan"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/tarjan_scc.sake: [16, 4, "Tarjan.set_sccs", 1]: observed [["Tarjan"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| land_islands.sake | 2 | 97 | 6 | 0 | 0 | 89 | 5 | 5 |
| make_rebuild.sake | 2 | 63 | 5 | 0 | 0 | 54 | 0 | 0 |
| maze_bfs.sake | 2 | 47 | 5 | 0 | 0 | 40 | 0 | 0 |
| metro_transfers.sake | 2 | 78 | 8 | 0 | 0 | 64 | 0 | 0 |
| org_chart_lca.sake | 2 | 121 | 36 | 0 | 0 | 84 | 0 | 0 |
| pipeline_flow.sake | 3 | 72 | 3 | 0 | 0 | 64 | 6 | 6 |
| prim_cables.sake | 3 | 96 | 19 | 2 | 0 | 68 | 0 | 5 |
| rival_teams.sake | 2 | 55 | 3 | 0 | 0 | 39 | 0 | 0 |
| tarjan_scc.sake | 3 | 101 | 9 | 0 | 0 | 93 | 11 | 11 |
| word_ladder.sake | 2 | 50 | 4 | 0 | 0 | 40 | 0 | 0 |
../2026-10-05-review/corpus-v3/02-analytics/csv_pivot.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/csv_pivot.sake: L94 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/csv_pivot.sake: L66 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/csv_pivot.sake: L93 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/hashtag_trends.sake: L54 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/markov_text.sake: L93 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/naive_bayes.sake: L59 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/naive_bayes.sake: L59 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/naive_bayes.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/naive_bayes.sake: L52 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/naive_bayes.sake: L103 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/near_duplicates.sake: L24 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/near_duplicates.sake: L42 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/near_duplicates.sake: L79 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_pivot.sake | 2 | 97 | 4 | 0 | 0 | 81 | 0 | 4 |
| email_domains.sake | 2 | 92 | 4 | 0 | 0 | 81 | 0 | 0 |
| hashtag_trends.sake | 2 | 99 | 6 | 0 | 0 | 79 | 0 | 1 |
| inverted_index.sake | 2 | 81 | 8 | 0 | 0 | 70 | 0 | 0 |
| kwic_concordance.sake | 2 | 87 | 6 | 0 | 0 | 69 | 0 | 0 |
| language_guess.sake | 2 | 70 | 4 | 0 | 0 | 57 | 0 | 0 |
| log_summary.sake | 3 | 84 | 9 | 0 | 0 | 71 | 0 | 0 |
| markov_text.sake | 2 | 105 | 2 | 0 | 0 | 89 | 0 | 1 |
| naive_bayes.sake | 2 | 97 | 2 | 0 | 0 | 80 | 0 | 5 |
| near_duplicates.sake | 2 | 85 | 9 | 0 | 0 | 72 | 0 | 3 |
../2026-10-05-review/corpus-v3/11-simulation/teller_queue_des.sake: [30, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/teller_queue_des.sake: [31, 4, "Heap.set_items", 1]: observed [["Heap"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/teller_queue_des.sake: [14, 4, "Customer.set_started", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/teller_queue_des.sake: [15, 4, "Customer.set_teller", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/teller_queue_des.sake: L129 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: [7, 4, "Room.set_heating", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: [8, 4, "Room.set_on_minutes", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L45 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L46 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L54 Comparable.<= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L59 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L60 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L60 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L61 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L52 Comparable.>= pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L81 Comparable.< pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L92 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L93 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/thermostat_house.sake: L61 Room.set_temp result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/traffic_intersection.sake: [12, 4, "Controller.set_index", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/traffic_intersection.sake: [13, 4, "Controller.set_elapsed", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/traffic_intersection.sake: [14, 4, "Controller.set_in_yellow", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/traffic_intersection.sake: [15, 4, "Controller.set_switches", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [20, 4, "Machine.set_sales", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [21, 4, "Machine.set_state", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [22, 4, "Machine.set_credit", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [23, 4, "Machine.set_inserted", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [24, 4, "Machine.set_sales", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/vending_machine.sake: [25, 4, "Machine.set_inserted", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: [5, 4, "Tank.set_overflowed", 1]: observed [["Tank"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: [6, 4, "Tank.set_drawn", 1]: observed [["Tank"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: [36, 22, "Pump.set_running", 1]: observed [["Pump"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L12 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer | nil, Float]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L12 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L56 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L57 Comparable.<= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L58 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L22 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer | nil, Float]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L22 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L73 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer | nil]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L74 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L95 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L14 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L16 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L21 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/11-simulation/water_tanks.sake: L73 Tank.set_drawn result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/12-parsers/calc_rd.sake: [11, 22, "Calc.set_pos", 1]: observed [["Calc"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/chem_formula.sake: L53 Hash.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| teller_queue_des.sake | 3 | 147 | 9 | 0 | 0 | 124 | 4 | 5 |
| thermostat_house.sake | 2 | 93 | 3 | 0 | 0 | 76 | 2 | 17 |
| traffic_intersection.sake | 2 | 106 | 4 | 0 | 0 | 91 | 4 | 4 |
| vending_machine.sake | 2 | 117 | 4 | 0 | 0 | 112 | 6 | 6 |
| water_tanks.sake | 2 | 95 | 32 | 0 | 0 | 114 | 3 | 17 |
| assembler.sake | 2 | 129 | 20 | 0 | 0 | 83 | 0 | 0 |
| brainfuck.sake | 2 | 61 | 6 | 0 | 0 | 39 | 0 | 0 |
| calc_rd.sake | 4 | 120 | 12 | 0 | 0 | 109 | 1 | 1 |
| chem_formula.sake | 3 | 78 | 11 | 0 | 0 | 71 | 0 | 1 |
| cmdline_parser.sake | 2 | 94 | 7 | 0 | 0 | 80 | 0 | 0 |
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L49 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L51 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L64 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L65 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L66 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L66 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L49 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/17-encodings/vigenere.sake: L51 Array.find result: observed ["{ic: Float, period: Integer}"], static nil | {ic: Integer, period: Integer}
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| run_length.sake | 2 | 63 | 1 | 0 | 0 | 58 | 0 | 0 |
| transposition.sake | 2 | 75 | 1 | 0 | 0 | 57 | 0 | 0 |
| utf8_codec.sake | 2 | 95 | 15 | 0 | 0 | 100 | 0 | 0 |
| vigenere.sake | 2 | 94 | 2 | 0 | 0 | 75 | 0 | 9 |
| xor_breaker.sake | 2 | 90 | 7 | 0 | 0 | 80 | 0 | 0 |
| access_log.sake | 2 | 113 | 7 | 0 | 0 | 106 | 0 | 0 |
| build_order.sake | 3 | 79 | 7 | 0 | 0 | 74 | 0 | 0 |
| cart_discounts.sake | 2 | 76 | 4 | 0 | 0 | 60 | 0 | 0 |
| contact_dedupe.sake | 3 | 158 | 7 | 0 | 0 | 123 | 0 | 0 |
| course_overlap.sake | 2 | 117 | 7 | 0 | 0 | 118 | 0 | 0 |
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [22, 4, "Warehouse.set_pending", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [23, 4, "Warehouse.set_backorders", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [24, 4, "Warehouse.set_log", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [25, 4, "Warehouse.set_spent", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [26, 4, "Warehouse.set_revenue", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [27, 4, "Warehouse.set_lost", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [28, 4, "Warehouse.set_pending", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [29, 4, "Warehouse.set_backorders", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/inventory_reorder.sake: [30, 4, "Warehouse.set_log", 1]: observed [["Warehouse"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/langton_ants.sake: [6, 22, "Ant.set_steps", 1]: observed [["Ant"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [40, 4, "Library.set_titles", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [41, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [42, 4, "Library.set_log", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [43, 4, "Library.set_collected", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [44, 4, "Library.set_titles", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [45, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [46, 4, "Library.set_log", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [6, 4, "Title.set_holds", 1]: observed [["Title"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [7, 4, "Title.set_holds", 1]: observed [["Title"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [16, 4, "Member.set_fines", 1]: observed [["Member"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [17, 4, "Member.set_loans", 1]: observed [["Member"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [18, 4, "Member.set_loans", 1]: observed [["Member"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/library_loans.sake: [25, 22, "Loan.set_renewals", 1]: observed [["Loan"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [19, 4, "Book.set_bids", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [20, 4, "Book.set_asks", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [21, 4, "Book.set_trades", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [22, 4, "Book.set_seq", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [23, 4, "Book.set_bids", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [24, 4, "Book.set_asks", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: [25, 4, "Book.set_trades", 1]: observed [["Book"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/order_book.sake: L131 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [14, 22, "Link.set_up", 1]: observed [["Link"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [21, 4, "Router.set_queue", 1]: observed [["Router"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [22, 4, "Router.set_dropped", 1]: observed [["Router"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [23, 4, "Router.set_forwarded", 1]: observed [["Router"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [24, 4, "Router.set_queue", 1]: observed [["Router"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [6, 4, "Packet.set_hops", 1]: observed [["Packet"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/packet_network.sake: [7, 4, "Packet.set_hops", 1]: observed [["Packet"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [21, 4, "Garage.set_tickets", 1]: observed [["Garage"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [22, 4, "Garage.set_receipts", 1]: observed [["Garage"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [23, 4, "Garage.set_tickets", 1]: observed [["Garage"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [24, 4, "Garage.set_receipts", 1]: observed [["Garage"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L101 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L41 Kernel.== pair: observed [["Ticket", "Nil"]], static [nil, nil]
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [42, 11, "Ticket.spot", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [43, 4, "Spot.set_plate", 1]: observed [["Spot"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [44, 31, "Ticket.entered", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [44, 26, "Arithmetic.-", "pair"]: observed [["Time", "Time"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [44, 25, "Arithmetic./", "pair"]: observed [["Float", "Float"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [44, 14, "Float.to_i", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [45, 26, "Ticket.kind", 1]: observed [["Ticket"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [61, 14, "Comparable.<=", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [62, 10, "Integer.ceildiv", 1]: observed [["Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [68, 15, "Integer.divmod", 1]: observed [["Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [70, 28, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [70, 12, "Array.min", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [71, 2, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [71, 2, "Arithmetic.+", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [130, 33, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: [130, 49, "Arithmetic.%", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L35 Ticket.new result: observed ["Ticket"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L40 Hash.delete result: observed ["Ticket", "Nil"], static nil
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L42 Ticket.spot result: observed ["Spot"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L43 Spot.set_plate result: observed ["Nil"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L44 Ticket.entered result: observed ["Time"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L44 Float.to_i result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L45 Ticket.kind result: observed ["Symbol"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L62 Integer.ceildiv result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L68 Integer.divmod result: observed ["Tuple"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L70 Array[] result: observed ["Array"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/parking_garage.sake: L70 Array.min result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: [17, 4, "Road.set_cars", 1]: observed [["Road"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: [7, 4, "Vehicle.set_speed", 1]: observed [["Vehicle"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: [8, 4, "Vehicle.set_laps", 1]: observed [["Vehicle"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: [9, 4, "Vehicle.set_stops", 1]: observed [["Vehicle"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: [19, 4, "Road.set_cars", 1]: observed [["Road"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: L37 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: L74 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/11-simulation/ring_road_traffic.sake: L74 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/11-simulation/runway_ops.sake: [8, 4, "Flight.set_done_at", 1]: observed [["Flight"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/runway_ops.sake: [9, 4, "Flight.set_emergency", 1]: observed [["Flight"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/sandpile.sake: [6, 4, "Pile.set_grid", 1]: observed [["Pile"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/sandpile.sake: [7, 4, "Pile.set_lost", 1]: observed [["Pile"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/sandpile.sake: [8, 4, "Pile.set_topples", 1]: observed [["Pile"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/sandpile.sake: [9, 4, "Pile.set_grid", 1]: observed [["Pile"]] but no static check
../2026-10-05-review/corpus-v3/11-simulation/sandpile.sake: L88 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| inventory_reorder.sake | 3 | 140 | 9 | 0 | 0 | 143 | 9 | 9 |
| langton_ants.sake | 2 | 117 | 9 | 0 | 0 | 88 | 1 | 1 |
| library_loans.sake | 2 | 136 | 10 | 0 | 0 | 135 | 13 | 13 |
| life_torus.sake | 2 | 102 | 1 | 0 | 0 | 89 | 0 | 0 |
| order_book.sake | 2 | 118 | 10 | 0 | 0 | 122 | 7 | 8 |
| packet_network.sake | 2 | 132 | 14 | 0 | 0 | 125 | 7 | 7 |
| parking_garage.sake | 2 | 85 | 1 | 1 | 0 | 101 | 20 | 33 |
| ring_road_traffic.sake | 2 | 112 | 13 | 1 | 0 | 113 | 5 | 8 |
| runway_ops.sake | 2 | 110 | 6 | 0 | 0 | 108 | 2 | 2 |
| sandpile.sake | 2 | 107 | 14 | 0 | 0 | 100 | 4 | 5 |
../2026-10-05-review/corpus-v3/09-dp/sequence_alignment.sake: L10 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L19 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L20 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L43 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float | nil]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L69 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L69 Arithmetic./ pair: observed [["Float", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L69 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L43 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/09-dp/viterbi.sake: L47 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sequence_alignment.sake | 2 | 120 | 16 | 0 | 0 | 91 | 0 | 1 |
| stock_trading.sake | 2 | 85 | 30 | 0 | 0 | 69 | 0 | 0 |
| subset_partition.sake | 2 | 76 | 5 | 0 | 0 | 53 | 0 | 0 |
| viterbi.sake | 2 | 67 | 15 | 0 | 0 | 58 | 0 | 9 |
| word_break.sake | 3 | 89 | 5 | 0 | 0 | 63 | 0 | 0 |
| battleship.sake | 3 | 108 | 2 | 0 | 0 | 87 | 0 | 0 |
| chess_attacks.sake | 2 | 98 | 0 | 0 | 0 | 82 | 0 | 0 |
| connect_four.sake | 2 | 70 | 13 | 0 | 0 | 63 | 0 | 0 |
| crossword.sake | 2 | 112 | 1 | 0 | 0 | 96 | 0 | 0 |
| falling_sand.sake | 3 | 86 | 7 | 0 | 0 | 69 | 0 | 0 |
../2026-10-05-review/corpus-v3/17-encodings/ascii85.sake: L74 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/ascii85.sake: L74 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/17-encodings/bloom_filter.sake: L43 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/17-encodings/bloom_filter.sake: L43 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/caesar_cracker.sake: L43 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/17-encodings/caesar_cracker.sake: L45 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/caesar_cracker.sake: L46 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/caesar_cracker.sake: L46 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/caesar_cracker.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/17-encodings/frame_parser.sake: L117 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Integer"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ascii85.sake | 2 | 102 | 1 | 0 | 0 | 94 | 0 | 2 |
| base32_ids.sake | 2 | 89 | 5 | 0 | 0 | 72 | 0 | 0 |
| base64_codec.sake | 2 | 70 | 7 | 0 | 0 | 60 | 0 | 0 |
| bitset.sake | 2 | 125 | 1 | 0 | 0 | 103 | 0 | 0 |
| bloom_filter.sake | 2 | 82 | 2 | 0 | 0 | 75 | 0 | 2 |
| caesar_cracker.sake | 2 | 55 | 3 | 0 | 0 | 46 | 0 | 5 |
| check_digits.sake | 2 | 81 | 0 | 0 | 0 | 72 | 0 | 0 |
| crc_catalog.sake | 2 | 98 | 1 | 0 | 0 | 89 | 0 | 0 |
| frame_parser.sake | 2 | 162 | 18 | 0 | 0 | 133 | 0 | 1 |
| hamming_secded.sake | 2 | 90 | 0 | 0 | 0 | 74 | 0 | 0 |
../2026-10-05-review/corpus-v3/01-text/text_stats.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/01-text/text_stats.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/text_stats.sake: L25 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/01-text/text_stats.sake: L53 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/01-text/text_stats.sake: L53 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/caesar_crack.sake: L34 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/caesar_crack.sake: L35 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/caesar_crack.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/caesar_crack.sake: L36 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/caesar_crack.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/cooccurrence_pmi.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/cooccurrence_pmi.sake: L46 Math.log2 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| template_render.sake | 2 | 49 | 3 | 0 | 0 | 42 | 0 | 0 |
| text_box.sake | 3 | 100 | 6 | 0 | 0 | 91 | 0 | 0 |
| text_stats.sake | 2 | 73 | 2 | 0 | 0 | 66 | 0 | 5 |
| whitespace_tidy.sake | 2 | 106 | 5 | 0 | 0 | 95 | 0 | 0 |
| word_wrap.sake | 2 | 71 | 6 | 0 | 0 | 70 | 0 | 0 |
| access_log_urls.sake | 2 | 133 | 11 | 0 | 0 | 109 | 0 | 0 |
| anagram_groups.sake | 2 | 73 | 3 | 0 | 0 | 62 | 0 | 0 |
| autocomplete.sake | 2 | 58 | 11 | 0 | 0 | 55 | 0 | 0 |
| caesar_crack.sake | 2 | 56 | 2 | 0 | 0 | 48 | 0 | 5 |
| cooccurrence_pmi.sake | 2 | 74 | 0 | 0 | 0 | 58 | 0 | 2 |
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L27 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [nil | Integer, Float]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L70 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer | nil]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L71 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L73 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer | nil, Float | Integer]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L73 Float.clamp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L86 Comparable.>= pair: observed [["Float", "Float"]], static [Integer | nil, Float]
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L27 Array.sum result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/grade_book.sake: L38 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L45 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L52 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L60 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L52 Kernel.format result: observed ["String"], static (none)
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L52 Array.push result: observed ["Array"], static (none)
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L58 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/inventory_diff.sake: L59 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/ip_ranges.sake: L86 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/latency_buckets.sake: L30 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/latency_buckets.sake: L30 Float.ceil 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/18-collections/latency_buckets.sake: L73 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [39, 4, "Library.set_books", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [40, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [41, 4, "Library.set_loans", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [42, 4, "Library.set_queues", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [43, 4, "Library.set_books", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [44, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [45, 4, "Library.set_loans", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: [46, 4, "Library.set_queues", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/18-collections/library_loans.sake: L32 Float.clamp 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| friend_graph.sake | 2 | 103 | 12 | 0 | 0 | 91 | 0 | 0 |
| grade_book.sake | 2 | 109 | 8 | 1 | 0 | 78 | 0 | 9 |
| inventory_diff.sake | 2 | 95 | 8 | 2 | 0 | 91 | 0 | 7 |
| ip_ranges.sake | 2 | 102 | 14 | 0 | 0 | 105 | 0 | 1 |
| latency_buckets.sake | 2 | 91 | 2 | 1 | 0 | 75 | 0 | 3 |
| leaderboard.sake | 2 | 88 | 6 | 0 | 0 | 77 | 0 | 0 |
| library_loans.sake | 3 | 169 | 16 | 1 | 0 | 163 | 8 | 9 |
| lottery.sake | 2 | 80 | 3 | 0 | 0 | 74 | 0 | 0 |
| paginate.sake | 2 | 106 | 10 | 0 | 0 | 98 | 0 | 0 |
| prime_sets.sake | 2 | 122 | 5 | 0 | 0 | 106 | 0 | 0 |
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L16 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L31 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L31 Rational.round 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L54 Rational.to_s 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L69 Rational.to_s 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L72 Rational.to_s 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: [72, 75, "Rational.to_f", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L43 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L43 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L44 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L78 Rational.to_f 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L23 Hash.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L25 Hash.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L72 Rational.to_f result: observed ["Float"], static (none)
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L72 Kernel.format result: observed ["String"], static (none)
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L72 Kernel.puts result: observed ["Nil"], static (none)
../2026-10-05-review/corpus-v3/09-dp/dice_odds.sake: L48 Array.sum result: observed ["Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| coin_change.sake | 2 | 76 | 2 | 0 | 0 | 53 | 0 | 0 |
| company_party.sake | 3 | 67 | 3 | 0 | 0 | 48 | 0 | 0 |
| critical_path.sake | 2 | 89 | 14 | 0 | 0 | 65 | 0 | 0 |
| decode_ways.sake | 3 | 107 | 10 | 0 | 0 | 83 | 0 | 0 |
| dice_odds.sake | 2 | 71 | 8 | 5 | 0 | 69 | 1 | 17 |
| digit_counting.sake | 2 | 60 | 7 | 0 | 0 | 49 | 0 | 0 |
| edit_distance.sake | 2 | 120 | 17 | 0 | 0 | 96 | 0 | 0 |
| egg_drop.sake | 3 | 82 | 17 | 0 | 0 | 63 | 0 | 0 |
| floyd_warshall.sake | 2 | 93 | 25 | 0 | 0 | 57 | 0 | 0 |
| grid_paths.sake | 2 | 114 | 20 | 0 | 0 | 80 | 0 | 0 |
../2026-10-05-review/corpus-v3/06-linked/monotonic_stack_prices.sake: [8, 4, "MinMaxStack.set_top", 1]: observed [["MinMaxStack"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/monotonic_stack_prices.sake: [9, 4, "MinMaxStack.set_size", 1]: observed [["MinMaxStack"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: [11, 4, "Ring.set_start", 1]: observed [["Ring"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: [12, 4, "Ring.set_count", 1]: observed [["Ring"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: [13, 4, "Ring.set_dropped", 1]: observed [["Ring"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: [14, 4, "Ring.set_slots", 1]: observed [["Ring"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: [15, 4, "Ring.set_slots", 1]: observed [["Ring"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/ring_buffer_metrics.sake: L76 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/06-linked/rpn_stack_calculator.sake: [16, 4, "Stack.set_top", 1]: observed [["Stack"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/rpn_stack_calculator.sake: [17, 4, "Stack.set_depth", 1]: observed [["Stack"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/singly_linked_list.sake: [6, 4, "LinkedList.set_head", 1]: observed [["LinkedList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/singly_linked_list.sake: [7, 4, "LinkedList.set_tail", 1]: observed [["LinkedList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/singly_linked_list.sake: [8, 4, "LinkedList.set_size", 1]: observed [["LinkedList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [8, 4, "SkipList.set_head", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [9, 4, "SkipList.set_level", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [10, 4, "SkipList.set_seed", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [11, 4, "SkipList.set_size", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [12, 4, "SkipList.set_steps", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/skip_list_index.sake: [13, 4, "SkipList.set_head", 1]: observed [["SkipList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/sparse_matrix_rows.sake: [13, 4, "Sparse.set_rows", 1]: observed [["Sparse"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/sparse_matrix_rows.sake: [14, 4, "Sparse.set_rows", 1]: observed [["Sparse"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: [5, 22, "Poly.set_terms", 1]: observed [["Poly"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: L15 Kernel.== pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: L90 Comparable.< pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: L70 Arithmetic.* pair: observed [["Integer", "Integer"], ["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: L70 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: [91, 24, "Rational.abs", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/sparse_polynomial.sake: L39 Term.coef result: observed ["Integer", "Rational"], static Integer
../2026-10-05-review/corpus-v3/06-linked/triage_priority_list.sake: [20, 4, "WaitList.set_first", 1]: observed [["WaitList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/triage_priority_list.sake: [21, 4, "WaitList.set_count", 1]: observed [["WaitList"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/two_stack_print_queue.sake: [16, 4, "TwoStackQueue.set_inbox", 1]: observed [["TwoStackQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/two_stack_print_queue.sake: [17, 4, "TwoStackQueue.set_outbox", 1]: observed [["TwoStackQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/two_stack_print_queue.sake: [18, 4, "TwoStackQueue.set_size", 1]: observed [["TwoStackQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/two_stack_print_queue.sake: [19, 4, "TwoStackQueue.set_transfers", 1]: observed [["TwoStackQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/undo_redo_editor.sake: [24, 4, "Editor.set_undos", 1]: observed [["Editor"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/undo_redo_editor.sake: [25, 4, "Editor.set_redos", 1]: observed [["Editor"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/undo_redo_editor.sake: [26, 4, "Editor.set_saved_depth", 1]: observed [["Editor"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/undo_redo_editor.sake: [27, 4, "Editor.set_depth", 1]: observed [["Editor"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| monotonic_stack_prices.sake | 3 | 56 | 12 | 0 | 0 | 55 | 2 | 2 |
| ring_buffer_metrics.sake | 3 | 81 | 8 | 0 | 0 | 80 | 5 | 6 |
| rpn_stack_calculator.sake | 3 | 60 | 1 | 0 | 0 | 60 | 2 | 2 |
| singly_linked_list.sake | 3 | 90 | 8 | 0 | 0 | 92 | 3 | 3 |
| skip_list_index.sake | 3 | 138 | 9 | 0 | 0 | 113 | 6 | 6 |
| sparse_matrix_rows.sake | 3 | 135 | 2 | 0 | 0 | 95 | 2 | 2 |
| sparse_polynomial.sake | 3 | 73 | 1 | 0 | 0 | 61 | 2 | 7 |
| triage_priority_list.sake | 3 | 93 | 6 | 0 | 0 | 75 | 2 | 2 |
| two_stack_print_queue.sake | 2 | 63 | 0 | 0 | 0 | 57 | 4 | 4 |
| undo_redo_editor.sake | 3 | 74 | 6 | 0 | 0 | 75 | 4 | 4 |
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L66 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L94 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer | nil, Integer | nil]
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L94 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L94 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L71 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L74 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L75 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sales_pivot.sake: L83 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L29 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L63 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L63 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L72 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L29 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sensor_merge.sake: L72 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/18-collections/sparse_vectors.sake: L57 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/18-collections/survey_venn.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| range_set.sake | 2 | 110 | 15 | 0 | 0 | 113 | 0 | 0 |
| role_permissions.sake | 2 | 91 | 8 | 0 | 0 | 81 | 0 | 0 |
| room_bookings.sake | 2 | 101 | 22 | 0 | 0 | 108 | 0 | 0 |
| sales_pivot.sake | 2 | 129 | 13 | 0 | 0 | 94 | 0 | 9 |
| sensor_merge.sake | 2 | 119 | 4 | 1 | 0 | 99 | 0 | 6 |
| sparse_vectors.sake | 3 | 111 | 7 | 0 | 0 | 90 | 0 | 1 |
| survey_venn.sake | 2 | 101 | 3 | 0 | 0 | 98 | 0 | 1 |
| tag_recommender.sake | 2 | 114 | 3 | 0 | 0 | 105 | 0 | 0 |
| word_pipeline.sake | 2 | 102 | 2 | 0 | 0 | 93 | 0 | 0 |
| word_rack.sake | 2 | 122 | 3 | 0 | 0 | 115 | 0 | 0 |
../2026-10-05-review/corpus-v3/09-dp/held_karp.sake: L89 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer | nil]
../2026-10-05-review/corpus-v3/09-dp/held_karp.sake: L89 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/interval_scheduling.sake: L89 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/interval_scheduling.sake: L88 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/09-dp/knapsack_01.sake: L83 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/09-dp/matrix_chain.sake: L81 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/optimal_bst.sake: L18 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/09-dp/optimal_bst.sake: L22 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/09-dp/optimal_bst.sake: L22 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/optimal_bst.sake: L47 Arithmetic.* pair: observed [["Float", "Integer"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/09-dp/optimal_bst.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| held_karp.sake | 2 | 89 | 31 | 1 | 0 | 74 | 0 | 2 |
| house_robber.sake | 3 | 75 | 4 | 0 | 0 | 61 | 0 | 0 |
| interval_scheduling.sake | 3 | 106 | 17 | 0 | 0 | 79 | 0 | 2 |
| knapsack_01.sake | 2 | 58 | 12 | 1 | 0 | 50 | 0 | 1 |
| lcs_diff.sake | 3 | 126 | 13 | 0 | 0 | 80 | 0 | 0 |
| line_breaking.sake | 2 | 77 | 7 | 0 | 0 | 61 | 0 | 0 |
| longest_increasing.sake | 3 | 88 | 8 | 0 | 0 | 66 | 0 | 0 |
| matrix_chain.sake | 3 | 99 | 20 | 0 | 0 | 81 | 0 | 1 |
| optimal_bst.sake | 4 | 111 | 24 | 0 | 0 | 87 | 0 | 5 |
| palindromes.sake | 3 | 122 | 16 | 0 | 0 | 85 | 0 | 0 |
../2026-10-05-review/corpus-v3/05-sorting/merge_sort_inversions.sake: L52 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/merge_sort_inversions.sake: L52 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/radix_order_ids.sake: L43 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/radix_order_ids.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/radix_order_ids.sake: L98 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/radix_order_ids.sake: L98 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: L61 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: L66 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: L66 Float.ceil 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: L98 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: [98, 29, "Comparable.>", "pair"]: observed [["Float", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: [98, 48, "Float.round", 1]: observed [["Float"]] but no static check
../2026-10-05-review/corpus-v3/05-sorting/sensor_quickselect.sake: L98 Float.round result: observed ["Float"], static (none)
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| library_catalog.sake | 2 | 87 | 6 | 0 | 0 | 79 | 0 | 0 |
| log_time_bisect.sake | 2 | 73 | 10 | 0 | 0 | 64 | 0 | 0 |
| meeting_intervals.sake | 2 | 99 | 8 | 0 | 0 | 88 | 0 | 0 |
| merge_sort_inversions.sake | 4 | 84 | 5 | 0 | 0 | 66 | 0 | 2 |
| natural_runs_sort.sake | 2 | 180 | 15 | 0 | 0 | 128 | 0 | 0 |
| probe_count_search.sake | 2 | 96 | 13 | 0 | 0 | 82 | 0 | 0 |
| quicksort_median3.sake | 2 | 82 | 11 | 0 | 0 | 70 | 0 | 0 |
| radix_order_ids.sake | 2 | 71 | 5 | 2 | 0 | 60 | 0 | 4 |
| sensor_quickselect.sake | 3 | 105 | 11 | 2 | 0 | 83 | 2 | 7 |
| shell_sort_gaps.sake | 2 | 78 | 2 | 0 | 0 | 52 | 0 | 0 |
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| ini_config.sake | 3 | 83 | 3 | 0 | 0 | 70 | 0 | 0 |
| json_pretty.sake | 4 | 152 | 6 | 0 | 0 | 128 | 0 | 0 |
| justify_text.sake | 2 | 68 | 1 | 0 | 0 | 66 | 0 | 0 |
| line_diff.sake | 2 | 126 | 15 | 0 | 0 | 98 | 0 | 0 |
| markdown_html.sake | 2 | 97 | 8 | 0 | 0 | 94 | 0 | 0 |
| markdown_table.sake | 2 | 112 | 10 | 0 | 0 | 101 | 0 | 0 |
| number_words.sake | 2 | 86 | 1 | 0 | 0 | 68 | 0 | 0 |
| outline_number.sake | 2 | 93 | 9 | 0 | 0 | 93 | 0 | 0 |
| slugify.sake | 2 | 68 | 1 | 0 | 0 | 61 | 0 | 0 |
| spell_suggest.sake | 2 | 113 | 12 | 0 | 0 | 86 | 0 | 0 |
../2026-10-05-review/corpus-v3/14-errors/matrix_checks.sake: L41 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/14-errors/matrix_checks.sake: L18 Array.fetch result: observed ["Integer", "Rational"], static Integer
../2026-10-05-review/corpus-v3/14-errors/matrix_checks.sake: L41 Range.sum result: observed ["Integer", "Rational"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_import.sake | 2 | 66 | 15 | 0 | 0 | 57 | 0 | 0 |
| dependency_resolver.sake | 3 | 31 | 1 | 0 | 0 | 28 | 0 | 0 |
| error_wrapping.sake | 2 | 47 | 0 | 0 | 0 | 34 | 0 | 0 |
| expr_calculator.sake | 3 | 92 | 8 | 0 | 9 | 84 | 0 | 0 |
| http_error_mapping.sake | 2 | 59 | 1 | 0 | 0 | 38 | 0 | 0 |
| job_queue.sake | 2 | 80 | 0 | 0 | 0 | 74 | 0 | 0 |
| ledger_reconcile.sake | 2 | 66 | 3 | 0 | 0 | 58 | 0 | 0 |
| log_triage.sake | 2 | 66 | 6 | 0 | 0 | 58 | 0 | 0 |
| matrix_checks.sake | 3 | 101 | 5 | 0 | 0 | 71 | 0 | 3 |
| nested_schema.sake | 2 | 43 | 3 | 0 | 0 | 40 | 0 | 0 |
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L67 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L68 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L68 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L69 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L69 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L61 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L62 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L70 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/05-sorting/trail_peak_search.sake: L77 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [12, 4, "Graph.set_names", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [13, 4, "Graph.set_ids", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [14, 4, "Graph.set_heads", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [15, 4, "Graph.set_indegree", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [16, 4, "Graph.set_names", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [17, 4, "Graph.set_ids", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [18, 4, "Graph.set_heads", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/adjacency_list_courses.sake: [19, 4, "Graph.set_indegree", 1]: observed [["Graph"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/bank_teller_sim.sake: [22, 4, "WaitQueue.set_head", 1]: observed [["WaitQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/bank_teller_sim.sake: [23, 4, "WaitQueue.set_tail", 1]: observed [["WaitQueue"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/browser_history.sake: [5, 22, "Tab.set_opened", 1]: observed [["Tab"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/chained_hash_table.sake: [7, 4, "Table.set_size", 1]: observed [["Table"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/chained_hash_table.sake: [8, 4, "Table.set_resizes", 1]: observed [["Table"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/chained_hash_table.sake: [9, 4, "Table.set_probes", 1]: observed [["Table"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/circular_playlist.sake: [10, 4, "Playlist.set_now", 1]: observed [["Playlist"]] but no static check
../2026-10-05-review/corpus-v3/06-linked/circular_playlist.sake: [11, 4, "Playlist.set_count", 1]: observed [["Playlist"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| sorted_matrix_search.sake | 2 | 80 | 13 | 0 | 0 | 67 | 0 | 0 |
| staff_multikey_sort.sake | 2 | 56 | 6 | 0 | 14 | 60 | 0 | 0 |
| trail_peak_search.sake | 2 | 89 | 7 | 0 | 0 | 69 | 0 | 11 |
| triage_partition.sake | 2 | 90 | 11 | 0 | 0 | 74 | 0 | 0 |
| version_resolver.sake | 2 | 81 | 14 | 0 | 0 | 66 | 0 | 0 |
| adjacency_list_courses.sake | 3 | 119 | 12 | 0 | 0 | 95 | 8 | 8 |
| bank_teller_sim.sake | 3 | 109 | 1 | 0 | 0 | 102 | 2 | 2 |
| browser_history.sake | 2 | 62 | 1 | 0 | 0 | 60 | 1 | 1 |
| chained_hash_table.sake | 3 | 117 | 0 | 0 | 0 | 97 | 3 | 3 |
| circular_playlist.sake | 2 | 92 | 13 | 0 | 0 | 97 | 2 | 2 |
../2026-10-05-review/corpus-v3/02-analytics/ngram_counts.sake: L46 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/ngram_counts.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/ngram_counts.sake: L63 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L43 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L6 Comparable.<=> pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L133 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L102 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L6 Keyword.score result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L137 Keyword.score result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L133 Keyword.score result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L133 Keyword.score result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/rake_keywords.sake: L133 Keyword.set_score result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L5 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L6 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L7 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L7 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L57 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L11 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L12 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L13 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L59 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/readability.sake: L61 Comparable.>= pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L53 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L102 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L104 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L53 Score.set_total result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L102 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/sentiment_lexicon.sake: L104 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L34 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L34 Math.log 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L22 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L38 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float | nil]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L60 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L50 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L50 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L44 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L44 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L55 Arithmetic./ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L44 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/tf_idf.sake: L100 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L58 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L31 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L32 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L36 Arithmetic.- pair: observed [["Float", "Float"]], static [Float | nil, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L36 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L36 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L37 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L37 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L37 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L40 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L40 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L40 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L62 Arithmetic.** pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L31 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/vocabulary_growth.sake: L32 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/02-analytics/word_frequency.sake: L63 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/02-analytics/word_frequency.sake: L63 Float.round 1: observed [["Float"]], static Integer
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
../2026-10-05-review/corpus-v3/07-trees/spanning_tree.sake: [5, 4, "DisjointSet.set_parent", 1]: observed [["DisjointSet"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/spanning_tree.sake: [6, 4, "DisjointSet.set_rank", 1]: observed [["DisjointSet"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/spanning_tree.sake: [7, 4, "DisjointSet.set_parent", 1]: observed [["DisjointSet"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/spanning_tree.sake: [8, 4, "DisjointSet.set_rank", 1]: observed [["DisjointSet"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [17, 4, "Trie.set_root", 1]: observed [["Trie"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [18, 4, "Trie.set_words", 1]: observed [["Trie"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [5, 4, "TrieNode.set_children", 1]: observed [["TrieNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [6, 4, "TrieNode.set_terminal", 1]: observed [["TrieNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [7, 4, "TrieNode.set_freq", 1]: observed [["TrieNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [8, 4, "TrieNode.set_pass", 1]: observed [["TrieNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [9, 4, "TrieNode.set_children", 1]: observed [["TrieNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/trie_autocomplete.sake: [19, 4, "Trie.set_root", 1]: observed [["Trie"]] but no static check
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L64 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L64 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L70 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L78 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L97 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/08-graphs/centrality.sake: L97 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| spanning_tree.sake | 3 | 149 | 42 | 0 | 0 | 106 | 4 | 4 |
| taxonomy_lca.sake | 3 | 132 | 28 | 0 | 0 | 96 | 0 | 0 |
| traversals.sake | 3 | 141 | 3 | 0 | 0 | 136 | 0 | 0 |
| tree_codec.sake | 4 | 98 | 3 | 0 | 0 | 96 | 0 | 0 |
| trie_autocomplete.sake | 3 | 81 | 5 | 0 | 0 | 87 | 8 | 8 |
| astar_terrain.sake | 3 | 74 | 8 | 0 | 0 | 56 | 0 | 0 |
| bellman_ford.sake | 2 | 66 | 2 | 0 | 0 | 50 | 0 | 0 |
| centrality.sake | 2 | 100 | 11 | 0 | 0 | 77 | 0 | 7 |
| course_schedule.sake | 2 | 73 | 6 | 0 | 0 | 62 | 0 | 0 |
| critical_links.sake | 2 | 90 | 8 | 0 | 0 | 57 | 0 | 0 |
../2026-10-05-review/corpus-v3/14-errors/quote_fallback.sake: L86 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/14-errors/spreadsheet_errors.sake: L69 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/14-errors/spreadsheet_errors.sake: L64 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/14-errors/spreadsheet_errors.sake: L69 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/14-errors/unit_quantities.sake: L47 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/14-errors/unit_quantities.sake: L79 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/14-errors/unit_quantities.sake: L78 Array.sum result: observed ["Float"], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| order_lifecycle.sake | 3 | 31 | 3 | 0 | 0 | 31 | 0 | 0 |
| param_coercion.sake | 2 | 50 | 1 | 0 | 0 | 42 | 0 | 0 |
| password_policy.sake | 2 | 94 | 0 | 0 | 0 | 88 | 0 | 0 |
| quote_fallback.sake | 2 | 48 | 2 | 1 | 0 | 44 | 0 | 1 |
| registration_form.sake | 2 | 74 | 2 | 0 | 0 | 70 | 0 | 0 |
| result_pipeline.sake | 2 | 58 | 1 | 0 | 0 | 31 | 0 | 0 |
| retry_backoff.sake | 2 | 42 | 4 | 0 | 0 | 36 | 0 | 0 |
| spreadsheet_errors.sake | 3 | 82 | 14 | 0 | 0 | 71 | 0 | 3 |
| unit_quantities.sake | 2 | 59 | 6 | 1 | 0 | 50 | 0 | 3 |
| warehouse_reservation.sake | 2 | 67 | 2 | 0 | 0 | 61 | 0 | 0 |
../2026-10-05-review/corpus-v3/16-dates/project_gantt.sake: [10, 4, "Task.set_start", 1]: observed [["Task"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/project_gantt.sake: [11, 4, "Task.set_finish", 1]: observed [["Task"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/project_gantt.sake: [12, 4, "Task.set_late_start", 1]: observed [["Task"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/room_booking.sake: [44, 4, "Calendar.set_bookings", 1]: observed [["Calendar"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/room_booking.sake: [45, 4, "Calendar.set_next_id", 1]: observed [["Calendar"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/room_booking.sake: [46, 4, "Calendar.set_bookings", 1]: observed [["Calendar"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/shift_rota.sake: [16, 4, "Worker.set_assigned", 1]: observed [["Worker"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/shift_rota.sake: [17, 4, "Worker.set_hours", 1]: observed [["Worker"]] but no static check
../2026-10-05-review/corpus-v3/16-dates/shift_rota.sake: [18, 4, "Worker.set_assigned", 1]: observed [["Worker"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| moon_phases.sake | 2 | 162 | 0 | 0 | 0 | 142 | 0 | 0 |
| parking_fees.sake | 2 | 92 | 21 | 0 | 0 | 100 | 0 | 0 |
| project_gantt.sake | 3 | 161 | 8 | 0 | 0 | 157 | 3 | 3 |
| public_holidays.sake | 2 | 170 | 0 | 0 | 0 | 153 | 0 | 0 |
| recurring_events.sake | 2 | 135 | 8 | 0 | 0 | 131 | 0 | 0 |
| room_booking.sake | 2 | 108 | 2 | 0 | 0 | 94 | 3 | 3 |
| shift_rota.sake | 3 | 111 | 3 | 0 | 0 | 98 | 3 | 3 |
| time_zones.sake | 2 | 139 | 0 | 0 | 0 | 130 | 0 | 0 |
| timesheet.sake | 3 | 117 | 19 | 0 | 0 | 122 | 0 | 0 |
| timetable.sake | 2 | 61 | 11 | 0 | 0 | 59 | 0 | 0 |
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L112 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L125 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L138 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L138 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L138 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L103 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L136 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/expense_tracker.sake: L137 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L47 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L62 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L62 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L12 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L13 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L14 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L15 Comparable.>= pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L112 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L71 Arithmetic.+ pair: observed [["Float", "Float"]], static [nil | Integer, nil | Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L71 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L75 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L76 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L76 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L76 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L76 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L121 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L121 Float.clamp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L123 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L124 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L128 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L128 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L50 Array.min result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L51 Array.delete_at result: observed ["Float"], static Integer | nil
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L53 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L112 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L75 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L76 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/grade_book.sake: L128 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/gym_membership.sake: L60 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [32, 4, "Folio.set_charges", 1]: observed [["Folio"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [33, 4, "Folio.set_payments", 1]: observed [["Folio"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [34, 4, "Folio.set_charges", 1]: observed [["Folio"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [35, 4, "Folio.set_payments", 1]: observed [["Folio"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L19 Time.month 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L52 Time.friday? 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [52, 41, "Time.saturday?", 1]: observed [["Time"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: [53, 36, "Time.strftime", 1]: observed [["Time"]] but no static check
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L52 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L72 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L79 Comparable.> pair: observed [["Float", "Integer"], ["Integer", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L63 Arithmetic.- pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L63 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L131 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L132 Arithmetic.+ pair: observed [["Float", "Float"], ["Integer", "Float"], ["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L52 Time.saturday? result: observed ["Boolean"], static (none)
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L53 Time.strftime result: observed ["String"], static (none)
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L39 Array.sum result: observed ["Float", "Integer"], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L61 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L62 Array.sum result: observed ["Integer", "Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L129 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/hotel_billing.sake: L132 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L36 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L40 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L40 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L40 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L92 Float.ceil 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L93 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L93 Float.ceil 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L94 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L96 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L96 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L96 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L113 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L40 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L108 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/inventory_reorder.sake: L120 Hash.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L49 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Rational]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L61 Time.strftime 1: observed [["Time"]], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L21 Rational.round 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L69 Arithmetic.* pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L69 Arithmetic./ pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L70 Arithmetic.- pair: observed [["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L71 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L72 Arithmetic.+ pair: observed [["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L75 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L128 Rational.to_f 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L133 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L134 Float.to_i 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L46 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L68 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/invoice_generator.sake: L127 Array.sum result: observed ["Rational"], static Integer
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [32, 4, "Library.set_books", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [33, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [34, 4, "Library.set_loans", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [35, 4, "Library.set_books", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [36, 4, "Library.set_members", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/library_loans.sake: [37, 4, "Library.set_loans", 1]: observed [["Library"]] but no static check
../2026-10-05-review/corpus-v3/20-business/parking_garage.sake: [36, 22, "Garage.set_seq", 1]: observed [["Garage"]] but no static check
../2026-10-05-review/corpus-v3/20-business/parking_garage.sake: L31 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/parking_garage.sake: L62 Ticket.set_charged_kwh result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L25 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L59 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L60 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L60 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L42 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L47 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L48 Arithmetic.- pair: observed [["Integer", "Integer"], ["Float", "Integer"]], static [Integer | nil, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L48 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L52 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L62 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L100 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L100 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L111 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L112 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L112 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L48 Array.min result: observed ["Integer", "Float"], static Integer | nil
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L96 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L97 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/payroll.sake: L99 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/20-business/rental_fleet.sake: [36, 4, "Fleet.set_rentals", 1]: observed [["Fleet"]] but no static check
../2026-10-05-review/corpus-v3/20-business/rental_fleet.sake: [37, 4, "Fleet.set_next_id", 1]: observed [["Fleet"]] but no static check
../2026-10-05-review/corpus-v3/20-business/rental_fleet.sake: [38, 4, "Fleet.set_rentals", 1]: observed [["Fleet"]] but no static check
../2026-10-05-review/corpus-v3/20-business/rental_fleet.sake: L111 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/20-business/rental_fleet.sake: L112 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| expense_tracker.sake | 2 | 135 | 7 | 0 | 0 | 120 | 0 | 8 |
| grade_book.sake | 2 | 137 | 7 | 1 | 0 | 119 | 0 | 29 |
| gym_membership.sake | 2 | 45 | 2 | 0 | 0 | 43 | 0 | 1 |
| hotel_billing.sake | 2 | 131 | 0 | 5 | 0 | 128 | 6 | 22 |
| inventory_reorder.sake | 2 | 98 | 1 | 2 | 0 | 91 | 0 | 16 |
| invoice_generator.sake | 2 | 121 | 15 | 4 | 0 | 126 | 0 | 15 |
| library_loans.sake | 2 | 124 | 0 | 0 | 0 | 122 | 6 | 6 |
| parking_garage.sake | 2 | 100 | 6 | 1 | 0 | 95 | 1 | 3 |
| payroll.sake | 2 | 92 | 4 | 4 | 0 | 82 | 0 | 20 |
| rental_fleet.sake | 2 | 105 | 5 | 0 | 0 | 106 | 3 | 5 |
../2026-10-05-review/corpus-v3/15-data/size_histogram.sake: L44 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/size_histogram.sake: L51 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L53 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L54 Comparable.> pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L54 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L54 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L54 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L54 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L84 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/survey_crosstab.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/table_renderer.sake: L99 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/table_renderer.sake: L98 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/15-data/timesheet_payroll.sake: L80 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/timesheet_payroll.sake: L80 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/15-data/timesheet_payroll.sake: L80 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/timesheet_payroll.sake: L85 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/top_products.sake: L45 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/top_products.sake: L40 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/top_products.sake: L40 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/top_products.sake: L40 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/15-data/top_products.sake: L57 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| size_histogram.sake | 2 | 51 | 3 | 0 | 0 | 47 | 0 | 2 |
| survey_crosstab.sake | 2 | 96 | 0 | 0 | 0 | 71 | 0 | 10 |
| table_renderer.sake | 2 | 101 | 13 | 0 | 0 | 97 | 0 | 2 |
| timesheet_payroll.sake | 2 | 83 | 6 | 0 | 0 | 80 | 0 | 4 |
| top_products.sake | 2 | 94 | 0 | 1 | 0 | 84 | 0 | 5 |
| activity_heatmap.sake | 2 | 168 | 5 | 0 | 0 | 134 | 0 | 0 |
| age_calculator.sake | 2 | 117 | 5 | 0 | 0 | 100 | 0 | 0 |
| billing_cycles.sake | 2 | 126 | 14 | 0 | 0 | 114 | 0 | 0 |
| business_days.sake | 2 | 102 | 3 | 0 | 0 | 99 | 0 | 0 |
| calendar_systems.sake | 3 | 194 | 2 | 0 | 0 | 172 | 0 | 0 |
../2026-10-05-review/corpus-v3/07-trees/avl_tree.sake: [4, 4, "AvlNode.set_height", 1]: observed [["AvlNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/avl_tree.sake: [5, 4, "AvlNode.set_left", 1]: observed [["AvlNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/avl_tree.sake: [6, 4, "AvlNode.set_right", 1]: observed [["AvlNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/bill_of_materials.sake: L46 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/07-trees/btree.sake: [13, 4, "BTree.set_root", 1]: observed [["BTree"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/btree.sake: [14, 4, "BTree.set_splits", 1]: observed [["BTree"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/btree.sake: [15, 4, "BTree.set_root", 1]: observed [["BTree"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L12 Math.log2 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L12 Arithmetic.- pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L24 Arithmetic.* pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L24 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L25 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L34 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L109 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L12 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/07-trees/decision_tree.sake: L24 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/07-trees/expression_tree.sake: [23, 22, "Parser.set_pos", 1]: observed [["Parser"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/fenwick_ranks.sake: [5, 4, "Fenwick.set_tree", 1]: observed [["Fenwick"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/fenwick_ranks.sake: [6, 4, "Fenwick.set_tree", 1]: observed [["Fenwick"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/fenwick_ranks.sake: L90 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/filesystem_du.sake: [5, 4, "Dir.set_subdirs", 1]: observed [["Dir"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/filesystem_du.sake: [6, 4, "Dir.set_files", 1]: observed [["Dir"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/filesystem_du.sake: [7, 4, "Dir.set_subdirs", 1]: observed [["Dir"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/filesystem_du.sake: [8, 4, "Dir.set_files", 1]: observed [["Dir"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/filesystem_du.sake: L44 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/heap_scheduler.sake: [15, 4, "MinHeap.set_items", 1]: observed [["MinHeap"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/heap_scheduler.sake: [16, 4, "MinHeap.set_items", 1]: observed [["MinHeap"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| avl_tree.sake | 3 | 112 | 11 | 0 | 0 | 120 | 3 | 3 |
| bill_of_materials.sake | 2 | 84 | 13 | 0 | 0 | 77 | 0 | 1 |
| bst_basic.sake | 3 | 84 | 2 | 0 | 0 | 84 | 0 | 0 |
| btree.sake | 2 | 106 | 9 | 0 | 0 | 96 | 3 | 3 |
| decision_tree.sake | 3 | 105 | 3 | 0 | 0 | 87 | 0 | 10 |
| dom_tree.sake | 3 | 115 | 13 | 0 | 0 | 103 | 0 | 0 |
| expression_tree.sake | 3 | 93 | 0 | 0 | 0 | 82 | 1 | 1 |
| fenwick_ranks.sake | 2 | 80 | 7 | 0 | 0 | 69 | 2 | 3 |
| filesystem_du.sake | 3 | 105 | 3 | 0 | 0 | 98 | 4 | 5 |
| heap_scheduler.sake | 3 | 114 | 13 | 0 | 0 | 95 | 2 | 2 |
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [10, 4, "Session.set_state", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [11, 4, "Session.set_client", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [12, 4, "Session.set_from", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [13, 4, "Session.set_rcpts", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [14, 4, "Session.set_data", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [15, 4, "Session.set_delivered", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [16, 4, "Session.set_errors", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/smtp_session.sake: [17, 4, "Session.set_delivered", 1]: observed [["Session"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/tcp_states.sake: [34, 4, "Conn.set_state", 1]: observed [["Conn"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/tcp_states.sake: [35, 4, "Conn.set_history", 1]: observed [["Conn"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/tcp_states.sake: [36, 4, "Conn.set_history", 1]: observed [["Conn"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [34, 4, "Controller.set_phase", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [35, 4, "Controller.set_elapsed", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [36, 4, "Controller.set_ped_waiting", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [37, 4, "Controller.set_preempt", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [38, 4, "Controller.set_history", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/traffic_light.sake: [39, 4, "Controller.set_history", 1]: observed [["Controller"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/turnstile.sake: [4, 4, "Turnstile.set_state", 1]: observed [["Turnstile"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/turnstile.sake: [5, 4, "Turnstile.set_coins", 1]: observed [["Turnstile"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/turnstile.sake: [6, 4, "Turnstile.set_passes", 1]: observed [["Turnstile"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/turnstile.sake: [7, 4, "Turnstile.set_alarms", 1]: observed [["Turnstile"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [11, 4, "Machine.set_state", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [12, 4, "Machine.set_credit", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [13, 4, "Machine.set_coins", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [14, 4, "Machine.set_sales", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [15, 4, "Machine.set_log", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [16, 4, "Machine.set_coins", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/19-statemachines/vending_machine.sake: [18, 4, "Machine.set_log", 1]: observed [["Machine"]] but no static check
../2026-10-05-review/corpus-v3/20-business/course_enrollment.sake: [4, 4, "Course.set_roster", 1]: observed [["Course"]] but no static check
../2026-10-05-review/corpus-v3/20-business/course_enrollment.sake: [5, 4, "Course.set_waitlist", 1]: observed [["Course"]] but no static check
../2026-10-05-review/corpus-v3/20-business/course_enrollment.sake: [6, 4, "Course.set_roster", 1]: observed [["Course"]] but no static check
../2026-10-05-review/corpus-v3/20-business/course_enrollment.sake: [7, 4, "Course.set_waitlist", 1]: observed [["Course"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [18, 4, "Customer.set_tier", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [19, 4, "Customer.set_spend", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [20, 4, "Customer.set_lots", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [21, 4, "Customer.set_history", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [22, 4, "Customer.set_lots", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: [23, 4, "Customer.set_history", 1]: observed [["Customer"]] but no static check
../2026-10-05-review/corpus-v3/20-business/customer_loyalty.sake: L31 Float.floor 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/20-business/event_registration.sake: L70 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| smtp_session.sake | 3 | 74 | 6 | 0 | 0 | 77 | 8 | 8 |
| tcp_states.sake | 3 | 53 | 0 | 0 | 0 | 44 | 3 | 3 |
| traffic_light.sake | 3 | 81 | 4 | 0 | 0 | 86 | 6 | 6 |
| turnstile.sake | 2 | 31 | 0 | 0 | 0 | 32 | 4 | 4 |
| vending_machine.sake | 2 | 85 | 1 | 0 | 0 | 79 | 7 | 7 |
| appointment_scheduler.sake | 2 | 79 | 1 | 0 | 0 | 63 | 0 | 0 |
| bank_ledger.sake | 3 | 122 | 5 | 0 | 0 | 114 | 0 | 0 |
| course_enrollment.sake | 2 | 104 | 0 | 0 | 0 | 103 | 4 | 4 |
| customer_loyalty.sake | 3 | 99 | 3 | 1 | 0 | 104 | 6 | 7 |
| event_registration.sake | 2 | 78 | 0 | 0 | 0 | 73 | 0 | 1 |
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [10, 4, "Forth.set_stack", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [11, 4, "Forth.set_dict", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [12, 4, "Forth.set_out", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [13, 4, "Forth.set_loops", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [14, 4, "Forth.set_stack", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [15, 4, "Forth.set_dict", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/forth.sake: [16, 4, "Forth.set_loops", 1]: observed [["Forth"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/indent_lexer.sake: [8, 4, "Outline.set_children", 1]: observed [["Outline"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/indent_lexer.sake: [9, 4, "Outline.set_children", 1]: observed [["Outline"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/json_parser.sake: [7, 22, "Json.set_pos", 1]: observed [["Json"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/json_parser.sake: L192 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/12-parsers/json_parser.sake: L191 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/12-parsers/lisp_interp.sake: [8, 4, "Env.set_vars", 1]: observed [["Env"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/lisp_interp.sake: [9, 4, "Env.set_vars", 1]: observed [["Env"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/markdown.sake: [4, 4, "Block.set_level", 1]: observed [["Block"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/pratt_parser.sake: [25, 22, "Parser.set_pos", 1]: observed [["Parser"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [31, 22, "Cursor.set_pos", 1]: observed [["Cursor"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [7, 4, "Query.set_where", 1]: observed [["Query"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [8, 4, "Query.set_group_by", 1]: observed [["Query"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [9, 4, "Query.set_order_by", 1]: observed [["Query"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [10, 4, "Query.set_desc", 1]: observed [["Query"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: [11, 4, "Query.set_limit", 1]: observed [["Query"]] but no static check
../2026-10-05-review/corpus-v3/12-parsers/query_engine.sake: L151 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| csv_parser.sake | 2 | 80 | 2 | 0 | 0 | 67 | 0 | 0 |
| forth.sake | 3 | 116 | 16 | 0 | 0 | 103 | 7 | 7 |
| indent_lexer.sake | 3 | 69 | 5 | 0 | 0 | 68 | 2 | 2 |
| ini_parser.sake | 2 | 99 | 3 | 0 | 0 | 83 | 0 | 0 |
| json_parser.sake | 3 | 191 | 15 | 5 | 0 | 154 | 1 | 3 |
| lisp_interp.sake | 7 | 136 | 17 | 0 | 0 | 86 | 2 | 2 |
| markdown.sake | 2 | 131 | 6 | 0 | 0 | 110 | 1 | 1 |
| pratt_parser.sake | 4 | 134 | 24 | 0 | 0 | 97 | 1 | 1 |
| query_engine.sake | 2 | 111 | 10 | 1 | 0 | 109 | 6 | 7 |
| regex_matcher.sake | 2 | 146 | 7 | 0 | 0 | 105 | 0 | 0 |
../2026-10-05-review/corpus-v3/07-trees/huffman.sake: L87 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/interval_bookings.sake: [64, 4, "Room.set_root", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/interval_bookings.sake: [65, 4, "Room.set_count", 1]: observed [["Room"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [39, 4, "RouteTable.set_root", 1]: observed [["RouteTable"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [40, 4, "RouteTable.set_size", 1]: observed [["RouteTable"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [4, 4, "BitNode.set_zero", 1]: observed [["BitNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [5, 4, "BitNode.set_one", 1]: observed [["BitNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [6, 4, "BitNode.set_route", 1]: observed [["BitNode"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/ip_route_trie.sake: [41, 4, "RouteTable.set_root", 1]: observed [["RouteTable"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L5 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L5 Arithmetic.** pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L5 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L37 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L31 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L39 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L55 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L46 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L58 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L58 Comparable.< pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L119 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/07-trees/kd_tree.sake: L33 Search.set_best_d2 result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/07-trees/lazy_seat_inventory.sake: L111 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/07-trees/org_chart.sake: [6, 4, "Employee.set_reports", 1]: observed [["Employee"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/org_chart.sake: [7, 4, "Employee.set_reports", 1]: observed [["Employee"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/quadtree.sake: [24, 4, "Quad.set_points", 1]: observed [["Quad"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/quadtree.sake: [25, 4, "Quad.set_kids", 1]: observed [["Quad"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/quadtree.sake: [26, 4, "Quad.set_points", 1]: observed [["Quad"]] but no static check
../2026-10-05-review/corpus-v3/07-trees/quadtree.sake: [27, 4, "Quad.set_kids", 1]: observed [["Quad"]] but no static check
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| huffman.sake | 3 | 90 | 10 | 0 | 0 | 85 | 0 | 1 |
| interval_bookings.sake | 3 | 92 | 2 | 0 | 0 | 91 | 2 | 2 |
| ip_route_trie.sake | 2 | 95 | 9 | 0 | 0 | 105 | 6 | 6 |
| kd_tree.sake | 3 | 118 | 14 | 0 | 0 | 122 | 0 | 13 |
| lazy_seat_inventory.sake | 3 | 151 | 12 | 0 | 0 | 122 | 0 | 1 |
| merkle_sync.sake | 3 | 81 | 6 | 0 | 0 | 65 | 0 | 0 |
| org_chart.sake | 3 | 107 | 12 | 0 | 0 | 110 | 2 | 2 |
| quadtree.sake | 3 | 121 | 19 | 0 | 0 | 134 | 4 | 4 |
| rope_editor.sake | 3 | 64 | 6 | 0 | 0 | 54 | 0 | 0 |
| segment_tree_stats.sake | 3 | 146 | 8 | 0 | 0 | 97 | 0 | 0 |
../2026-10-05-review/corpus-v3/13-polymorphism/matrix_ops.sake: L57 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/matrix_ops.sake: [124, 18, "Kernel.format", 1]: observed [["String"]] but no static check
../2026-10-05-review/corpus-v3/13-polymorphism/matrix_ops.sake: L95 Arithmetic.* pair: observed [["Rational", "Rational"]], static [Integer, nil | Integer | Rational]
../2026-10-05-review/corpus-v3/13-polymorphism/matrix_ops.sake: L95 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/matrix_ops.sake: L114 Arithmetic.- pair: observed [["Rational", "Rational"]], static [nil | Integer | Rational, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/money_ledger.sake: L67 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/money_ledger.sake: L29 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"], ["Integer", "Integer"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/money_ledger.sake: L29 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/payroll.sake: L20 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/payroll.sake: L56 Arithmetic.+ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/payroll.sake: L56 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/payroll.sake: L69 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/physical_quantities.sake: L49 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/polynomial.sake: L39 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/polynomial.sake: L66 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Rational"], ["Rational", "Rational"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer | Rational]
../2026-10-05-review/corpus-v3/13-polymorphism/polynomial.sake: L66 Arithmetic.+ pair: observed [["Integer", "Integer"], ["Rational", "Integer"], ["Float", "Integer"]], static [Integer, Integer | Rational]
../2026-10-05-review/corpus-v3/13-polymorphism/polynomial.sake: L66 Array.reduce result: observed ["Integer", "Rational", "Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L2 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L13 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L19 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L31 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L31 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L32 Math.cos 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L32 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L55 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L56 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L45 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L46 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L47 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L47 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L48 Arithmetic.+ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L48 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L57 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L90 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L90 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L15 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L16 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L17 Arithmetic.- pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L124 Arithmetic.* pair: observed [["Vec3", "Float"]], static [Vec3, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L12 Arithmetic.* pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L69 Comparable.< pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L73 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L4 Arithmetic.- pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L4 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L4 Math.atan2 2: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L75 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L75 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L76 Math.sin 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L77 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L77 Arithmetic.* pair: observed [["Quat", "Float"]], static [Quat, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L132 Arithmetic.* pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L132 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/quaternion_rotation.sake: L137 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L20 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L29 Arithmetic.* pair: observed [["Float", "Integer"], ["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L38 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L39 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L39 Arithmetic.- pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L39 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L50 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L50 Math.tan 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L50 Arithmetic./ pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L51 Arithmetic.* pair: observed [["Integer", "Integer"], ["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Integer", "Float"], ["Float", "Float"]], static [Integer, Float | Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L13 Arithmetic.* pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L13 Arithmetic./ pair: observed [["Float", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L88 Comparable.> pair: observed [["Float", "Float"]], static [Integer, Float]
../2026-10-05-review/corpus-v3/13-polymorphism/shapes_area.sake: L75 Array.sum result: observed ["Float"], static Integer
../2026-10-05-review/corpus-v3/13-polymorphism/sparse_vector.sake: L48 Kernel.== pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/13-polymorphism/sparse_vector.sake: L48 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| matrix_ops.sake | 3 | 161 | 21 | 0 | 0 | 107 | 1 | 5 |
| modint_combinatorics.sake | 2 | 157 | 5 | 0 | 0 | 124 | 0 | 0 |
| money_ledger.sake | 2 | 122 | 3 | 2 | 0 | 101 | 0 | 3 |
| notify_channels.sake | 2 | 69 | 1 | 0 | 0 | 53 | 0 | 0 |
| payroll.sake | 2 | 83 | 5 | 2 | 0 | 66 | 0 | 4 |
| physical_quantities.sake | 2 | 169 | 4 | 0 | 0 | 103 | 0 | 1 |
| polynomial.sake | 3 | 162 | 9 | 0 | 0 | 133 | 0 | 4 |
| quaternion_rotation.sake | 2 | 253 | 3 | 2 | 0 | 211 | 0 | 43 |
| shapes_area.sake | 2 | 130 | 1 | 0 | 0 | 109 | 0 | 18 |
| sparse_vector.sake | 2 | 99 | 3 | 0 | 0 | 77 | 0 | 2 |
../2026-10-05-review/corpus-v3/03-numtheory/collatz_stats.sake: L80 Float.round 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/continued_fractions.sake: L19 Arithmetic.+ pair: observed [["Integer", "Rational"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/continued_fractions.sake: L97 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L80 Rational.to_s 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [80, 64, "Rational.to_f", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L86 Arithmetic.+ pair: observed [["Float", "Float"]], static [Float | Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L35 Comparable.> pair: observed [["Rational", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L36 Rational.denominator 1: observed [["Rational"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [36, 69, "Rational.numerator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [36, 27, "Integer.ceildiv", 2]: observed [["Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [36, 11, "Array.max", 1]: observed [["Array"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [37, 15, "Rational.denominator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [37, 11, "Arithmetic.*", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [37, 42, "Rational.numerator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [37, 11, "Arithmetic./", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [39, 16, "Kernel.Rational", 2]: observed [["Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [39, 11, "Arithmetic.-", "pair"]: observed [["Rational", "Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 49, "Comparable.>", "pair"]: observed [["Rational", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 59, "Rational.numerator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 59, "Kernel.==", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 90, "Rational.denominator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 90, "Comparable.>=", "pair"]: observed [["Integer", "Integer"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: [40, 20, "Rational.denominator", 1]: observed [["Rational"]] but no static check
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L80 Rational.to_f result: observed ["Float"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L80 Kernel.format result: observed ["String"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L80 Kernel.puts result: observed ["Nil"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L36 Rational.numerator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L36 Integer.ceildiv result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L36 Array[] result: observed ["Array"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L36 Array.max result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L37 Rational.denominator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L37 Rational.numerator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L39 Kernel.Rational result: observed ["Rational"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L40 Rational.numerator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L40 Rational.denominator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/egyptian_fractions.sake: L40 Rational.denominator result: observed ["Integer"], static (none)
../2026-10-05-review/corpus-v3/03-numtheory/farey_stern_brocot.sake: L76 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/farey_stern_brocot.sake: L76 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/farey_stern_brocot.sake: L111 Float.abs 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/fibonacci_numbers.sake: L111 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| base_conversion.sake | 2 | 72 | 1 | 0 | 0 | 65 | 0 | 0 |
| calendar_congruences.sake | 2 | 132 | 6 | 0 | 0 | 106 | 0 | 0 |
| check_digits.sake | 2 | 116 | 4 | 0 | 0 | 93 | 0 | 0 |
| collatz_stats.sake | 2 | 70 | 7 | 1 | 0 | 66 | 0 | 1 |
| continued_fractions.sake | 2 | 102 | 4 | 1 | 0 | 88 | 0 | 2 |
| digit_curiosities.sake | 2 | 89 | 0 | 0 | 0 | 76 | 0 | 0 |
| egyptian_fractions.sake | 2 | 120 | 2 | 2 | 0 | 120 | 16 | 33 |
| factor_functions.sake | 2 | 101 | 1 | 0 | 0 | 87 | 0 | 0 |
| farey_stern_brocot.sake | 2 | 128 | 6 | 3 | 0 | 120 | 0 | 3 |
| fibonacci_numbers.sake | 2 | 159 | 3 | 0 | 0 | 137 | 0 | 1 |
../2026-10-05-review/corpus-v3/03-numtheory/integer_partitions.sake: L83 Arithmetic./ pair: observed [["Float", "Integer"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/integer_partitions.sake: L83 Math.sqrt 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/integer_partitions.sake: L83 Math.exp 1: observed [["Float"]], static Integer
../2026-10-05-review/corpus-v3/03-numtheory/integer_partitions.sake: L83 Arithmetic./ pair: observed [["Float", "Float"]], static [Float, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/integer_partitions.sake: L84 Arithmetic./ pair: observed [["Integer", "Float"]], static [nil | Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/linear_sieve.sake: L65 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/linear_sieve.sake: L73 Arithmetic./ pair: observed [["Integer", "Float"]], static [Integer, Integer]
../2026-10-05-review/corpus-v3/03-numtheory/linear_sieve.sake: L73 Float.round 1: observed [["Float"]], static Integer
| program | passes | proven | partial | error | unknown | observed sites | unchecked observed | violations |
|---|---|---|---|---|---|---|---|---|
| goldbach.sake | 2 | 100 | 4 | 0 | 0 | 70 | 0 | 0 |
| happy_cycles.sake | 2 | 73 | 4 | 0 | 0 | 58 | 0 | 0 |
| integer_partitions.sake | 2 | 122 | 8 | 0 | 0 | 96 | 0 | 5 |
| linear_diophantine.sake | 2 | 94 | 0 | 0 | 0 | 67 | 0 | 0 |
| linear_sieve.sake | 2 | 138 | 11 | 1 | 0 | 91 | 0 | 3 |
| miller_rabin.sake | 2 | 86 | 0 | 0 | 0 | 79 | 0 | 0 |
| modular_crt.sake | 2 | 110 | 0 | 0 | 0 | 94 | 0 | 0 |
| perfect_amicable.sake | 2 | 81 | 10 | 0 | 0 | 62 | 0 | 0 |
| pollard_rho.sake | 3 | 110 | 0 | 0 | 0 | 104 | 0 | 0 |
| primitive_roots.sake | 2 | 141 | 2 | 0 | 0 | 126 | 0 | 0 |
