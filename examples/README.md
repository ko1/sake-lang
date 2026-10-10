# Examples

Example programs in Sake, one directory per category. Each `NAME.sake` has a header comment that
says what it does and which features of the language it shows, and a `NAME.expected` with exactly
what `bin/sake NAME.sake` prints. [first.sake](first.sake) is the smallest tour; the SQL engine in
[apps/sql/](apps/sql/README.md) is the largest program.

Run one with

```
bin/sake examples/text/doc_pretty.sake
bin/sake --strict=2 examples/text/doc_pretty.sake   # with the stricter checks (a maybe-nil value used unchecked)
```

and all of them with `ruby test/test_examples.rb`, which compares every program's output with its
`.expected` (`UPDATE=1` rewrites them).

## Where the programs come from

The programs were written by AI (Claude) for the experiments in [experiments/](../experiments/),
from the language documents alone (`docs/`): the writer could not read the interpreter's source.
Each one was written twice, in Sake and in idiomatic Ruby, and the two outputs had to match
exactly; the `.expected` files here are those outputs (they also equal the Ruby twin's output).

- The programs in the category directories come from
  [experiments/2026-10-05-review/corpus-v3/](../experiments/2026-10-05-review/README.md), the
  2026-10-05 revision of the 500-program corpus of
  [experiments/2026-10-01-inference-500/](../experiments/2026-10-01-inference-500/README.md)
  (20 domains x 25 tasks; the `src` column below names the domain and task). The writers ran
  their programs at `--strict=0` only, so the strictness levels below were measured afterwards.
- The SQL engine comes from the AI-writability evaluation
  ([experiments/2026-10-05-ai-writability/](../experiments/2026-10-05-ai-writability/README.md),
  P10/P11): see [apps/sql/README.md](apps/sql/README.md).

Selection (2026-10-10): 58 of the 500 programs, 45-190 lines each, self-contained (no input, no
files, no network, deterministic output), chosen to cover the language's features. Every program
runs unchanged with the interpreter of 2026-10-10 and prints its recorded output. **No program
was adjusted**; the only edit is the header comment (where the author had written one, it was
folded into the new header). Of the 500 programs, 435 print their recorded output at level 1
(the default) and 311 at `--strict=2`; the 65 others are stopped before running by the checks
(64 of them still print the right output at `--strict=0`; one defines `class Record`, a name that
is a built-in type since the corpus was written).

**Level** is the highest `--strict` level at which the program passes the checks before running
and prints its `.expected`: 2 for all programs except where the table says otherwise.

## Text

Text processing and text analytics (domains 01-text, 02-analytics).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [word_frequency.sake](text/word_frequency.sake) | Counts the content words of a paragraph (stopwords removed) and prints the top 10, a word-length histogram and the hapax share. | Hash.new(0) tallies, a Set of stopwords, sort_by with a Tuple key, format. | 68 | 02-analytics/word_frequency |
| [kwic_concordance.sake](text/kwic_concordance.sake) | Builds a keyword-in-context concordance of a short text: aligned context lines, collocates within a window and sentence dispersion. | a Hash of Arrays keyed by word, Tuples of [sentence, position], Set, String.scan and String.center. | 84 | 02-analytics/kwic_concordance |
| [line_diff.sake](text/line_diff.sake) | Produces a unified diff of two texts: an LCS table, Edit records for keep/delete/add, context hunks and insertion/deletion counts. | a class with attr_reader fields, 2-D tables from Array.new, case/in on Symbol operations, while loops. | 111 | 01-text/line_diff |
| [template_render.sake](text/template_render.sake) | Renders `{{path \| filter:arg}}` templates against a nested Hash context, with filters and a TemplateError for unknown names. | an exception class with a field, raise/rescue, case/in on Strings, (Array\|String).size dispatch over a union. | 102 | 01-text/template_render |
| [doc_pretty.sake](text/doc_pretty.sake) | A Wadler-style pretty printer: text/line/nest/group documents joined by a user-defined `+`, laid out at several widths. | include Arithmetic with `def +`, a document tree held in one class, case/in on Symbol kinds, the typed array Doc[]. | 123 | 01-text/doc_pretty |
| [inflector.sake](text/inflector.sake) | English pluralization and singularization by regex rules with irregular and uncountable words, count phrases and Oxford-comma lists. | Regexp literals with back-references in String.sub, a Set of uncountables, Rule[] arrays of a class. | 111 | 01-text/inflector |

## Numbers

Number theory and numerical methods (03-numtheory, 04-numeric).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [miller_rabin.sake](numbers/miller_rabin.sake) | Compares primality tests: trial division, Fermat and deterministic Miller-Rabin; finds Carmichael numbers and base-2 strong pseudoprimes. | Integer.pow with a modulus, functions returning Tuples (`return a, b`), while loops, format. | 84 | 03-numtheory/miller_rabin |
| [modular_crt.sake](numbers/modular_crt.sake) | A Mod type for modular arithmetic (+ - * / **), modular inverses and the Chinese Remainder Theorem for systems of congruences. | include Arithmetic and Comparable on a class, exception classes with fields (NotInvertible, ModulusMismatch), to_s, raise/rescue. | 124 | 03-numtheory/modular_crt |
| [continued_fractions.sake](numbers/continued_fractions.sake) | Continued fractions: expansions of Rationals and of square roots (with periods), convergents with their errors, and Pell equation solutions. | Rational values and Rational.numerator/denominator, Records read with `=> {a:, b:}` patterns, Tuples. | 114 | 03-numtheory/continued_fractions |
| [root_finding.sake](numbers/root_finding.sake) | Bisection, Newton and secant root finders that take the function as a block, run on cubics, cos x = x, Kepler's equation and square roots. | yield for the function argument, exception classes with fields (BadBracket, NoConvergence), rescue, Float formatting. | 119 | 04-numeric/root_finding |
| [polynomial.sake](numbers/polynomial.sake) | A Poly type with + - * (scalar or polynomial), Horner evaluation, derivative, long division, pretty printing, real roots by Newton and deflation, and Chebyshev polynomials. | include Arithmetic where `*` accepts a Poly or a number through `case b in Poly / in Integer \| Float`, to_s, rescue. | 147 | 04-numeric/polynomial |

## Algorithms

Sorting and searching, graphs, dynamic programming (05-sorting, 08-graphs, 09-dp).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [merge_sort_inversions.sake](algorithms/merge_sort_inversions.sake) | Counts inversions with a merge sort to compute the Kendall tau distance between judges' rankings, and builds a consensus board. | recursion returning a [sorted, count] Tuple, destructuring assignment, Hash.fetch with rescue KeyError. | 91 | 05-sorting/merge_sort_inversions |
| [version_resolver.sake](algorithms/version_resolver.sake) | Parses semantic versions, sorts them with a Comparable `<=>` (pre-releases first) and resolves constraints like `~> 2.3` by binary search. | include Comparable with `def <=>`, Regexp parsing, case/in on operator Strings, a function that yields, an exception class. | 104 | 05-sorting/version_resolver |
| [kruskal_network.sake](algorithms/kruskal_network.sake) | Kruskal's minimum spanning tree over links parsed with a regexp, using a union-find with rank and path compression; Edge is Comparable. | initialize filling fields after `new`, include Comparable, Record literals and patterns, Regexp match groups. | 112 | 08-graphs/kruskal_network |
| [tarjan_scc.sake](algorithms/tarjan_scc.sake) | Finds dependency cycles between modules with Tarjan's strongly connected components and lists the links of the condensed DAG. | a recursive DFS with its state in a class set up by initialize, Set, a heredoc as input, a Hash of Arrays. | 117 | 08-graphs/tarjan_scc |
| [knapsack_01.sake](algorithms/knapsack_01.sake) | 0/1 knapsack over Item objects with table-based reconstruction of the chosen items for several capacities. | a class whose to_s is used by string interpolation, 2-D tables from Array.new, format. | 89 | 09-dp/knapsack_01 |
| [edit_distance.sake](algorithms/edit_distance.sake) | Levenshtein distance with the edit script, spelling suggestions from a dictionary and a distance matrix. | a module_function module (Costs), 2-D tables, Array.min, format. | 93 | 09-dp/edit_distance |

## Data structures

Linked structures and trees (06-linked, 07-trees).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [lru_cache.sake](data-structures/lru_cache.sake) | An LRU cache from a Hash plus a doubly linked recency list, used directly, to memoize a slow function at several sizes, and to cache pages by Symbol. | the Struct.new shorthand for the list entry, initialize setting fields after `new`, nil-able links (`nil \| Entry`), Regexp. | 147 | 06-linked/lru_cache |
| [ring_buffer_metrics.sake](data-structures/ring_buffer_metrics.sake) | Fixed-capacity ring buffers that overwrite or raise when full keep sliding windows of metric readings and raise alerts on high averages. | attr_accessor fields, initialize, an exception class (BufferFull), iteration with yield, once for a constant table. | 110 | 06-linked/ring_buffer_metrics |
| [undo_redo_editor.sake](data-structures/undo_redo_editor.sake) | A text editor whose Insert/Delete/Replace commands live on linked undo/redo stacks, with inverses, save points and a dirty flag. | one class per command told apart with case/in, linked cells ending in nil, an exception class, initialize. | 131 | 06-linked/undo_redo_editor |
| [fenwick_ranks.sake](data-structures/fenwick_ranks.sake) | A Fenwick (binary indexed) tree with prefix sums and k-th search, used to count inversions and to keep a live leaderboard with ranks, percentiles and median. | a class whose initialize builds its array, the `i & -i` bit trick, format. | 107 | 07-trees/fenwick_ranks |
| [tree_codec.sake](data-structures/tree_codec.sake) | Binary tree codecs: level-order `[1,null,2]` and preorder `#` formats with round-trip checks, mirror/symmetry tests, and height, diameter and max path sum in one recursive pass. | attr_accessor tree nodes with nil children, functions returning Tuples, an exception class (DecodeError), Regexp tokenizing. | 130 | 07-trees/tree_codec |
| [huffman.sake](data-structures/huffman.sake) | Huffman codes: a frequency tally, an ordered queue of Leaf/Internal nodes with deterministic tie-breaking, a code table and an encode/decode round trip. | two node classes dispatched with (Leaf\|Internal).weight(node), `case node in Leaf / in Internal`, `node in Leaf` tests. Passes level 1; level 2 warns that Internal.left can hold a Leaf. | 100 (level 1) | 07-trees/huffman |

## Grids and games

Cellular automata, puzzles and board games on grids (10-grids).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [game_of_life.sake](grids-and-games/game_of_life.sake) | Conway's Life on small toroidal boards, detecting still lifes and cycles via a Hash of seen states. | a Board class with to_s, nested Arrays of booleans, a Hash keyed by the board's String form, while. | 86 | 10-grids/game_of_life |
| [n_queens.sake](grids-and-games/n_queens.sake) | Counts N-queens solutions for n = 1..8 with bitmask backtracking and prints the first array-based solution for some sizes. | Integer bit operations (& \| << >>), a class holding the search counters, recursion, format. | 84 | 10-grids/n_queens |
| [knights_tour.sake](grids-and-games/knights_tour.sake) | Warnsdorff's knight's tours on 5x5 to 8x8 boards with a Pos type that defines + and -, plus validity and closed-tour checks. | include Arithmetic on a two-field class, to_s for algebraic notation, once for the move table, sort_by. | 88 | 10-grids/knights_tour |
| [minesweeper.sake](grids-and-games/minesweeper.sake) | Builds a minefield from mine coordinates and plays scripted open/flag moves with cascading reveals, a MineHit exception and win detection. | attr_accessor cells, an exception class with row/col fields, rescue, case/in on move kinds. | 120 | 10-grids/minesweeper |
| [langtons_ant.sake](grids-and-games/langtons_ant.sake) | Langton's ant and other turmites (rules like RL, LLRR) on an unbounded grid stored as a Hash from coordinate Tuples to colours, with checkpoints and a picture. | the chain form `x.T.f(...)`, a Hash keyed by Tuples, Symbols for headings, once. | 83 | 10-grids/langtons_ant |
| [flood_fill.sake](grids-and-games/flood_fill.sake) | A paint-bucket canvas: stack-based fills, BFS region labelling with a Set of visited cells, and region statistics grouped by colour. | `_` (the previous statement's value), a Set of Tuples, a class with to_s, group_by. | 103 | 10-grids/flood_fill |

## Simulation and state machines

Discrete simulations and state machines (11-simulation, 19-statemachines).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [turnstile.sake](simulation/turnstile.sake) | A coin-operated turnstile (locked/unlocked) driven by an event list, with counters and an action tally. | initialize setting the initial state, case/in on [state, event] Tuples, Symbols. | 49 | 19-statemachines/turnstile |
| [tcp_states.sake](simulation/tcp_states.sake) | The TCP connection state machine as a (state, event) => (next state, reply) table, with scenario runs, invalid-transition exceptions and BFS reachability. | once for the transition table, a Hash keyed by Tuples with Tuple values, an exception class, Set. | 108 | 19-statemachines/tcp_states |
| [machine_mixin.sake](simulation/machine_mixin.sake) | A reusable StateMachine mixin (fire / can? / events_available) shared by Door, Light and Ticket types, each with its own transition table and on-enter hook. | a mixin module included by three classes, required functions (raise NotImplementedError), StateMachine.fire(m, e) dispatching to m's type, case/in. | 108 | 19-statemachines/machine_mixin |
| [event_sourcing.sake](simulation/event_sourcing.sake) | A bank ledger rebuilt by replaying typed events (opened, deposited, withdrawn, transferred, closed) with rejection rules, snapshots and replay-from-snapshot checks. | one class per event kind told apart with case/in, an exception class, to_s, `x in T` tests. | 122 | 19-statemachines/event_sourcing |
| [vending_machine.sake](simulation/vending_machine.sake) | A coin-operated vending machine state machine driven by Record events (insert/select/cancel/restock), with greedy change from a limited coin box and SoldOut/NoChange exceptions. | Record literals matched with case/in, exception classes with fields, attr_accessor, once. | 141 | 11-simulation/vending_machine |
| [ring_road_traffic.sake](simulation/ring_road_traffic.sake) | Nagel-Schreckenberg traffic on a ring road with mixed top speeds and random slowdowns: a space-time diagram and a flow/speed/jam table over densities. | initialize with defaults, attr_accessor, Records returned and destructured with `=> {...}`, a deterministic LCG. | 98 | 11-simulation/ring_road_traffic |

## Parsers and codecs

Interpreters, parsers and encodings (12-parsers, 17-encodings).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [brainfuck.sake](parsers-and-codecs/brainfuck.sake) | A Brainfuck interpreter with a precomputed bracket jump table, wrapping tape, embedded input and bracket-mismatch errors. | Records for the programs, an exception class with a position, rescue, case/in on characters, once. | 77 | 12-parsers/brainfuck |
| [calc_rd.sake](parsers-and-codecs/calc_rd.sake) | A recursive-descent calculator with precedence, right-associative power, unary minus, variables, built-in functions and typed parse errors. | a Parser class with a position, two exception classes, `x in T` narrowing of Integer \| Float, (Integer\|Float).abs dispatch, Regexp tokenizing. | 188 | 12-parsers/calc_rd |
| [forth.sake](parsers-and-codecs/forth.sake) | A Forth interpreter session with colon definitions, recursion, IF/ELSE/THEN, DO/LOOP with I, string output and per-line error recovery. | a class with attr_accessor state, an exception class (ForthError), raise/rescue per input line, case/in on words, once. | 184 | 12-parsers/forth |
| [base64_codec.sake](parsers-and-codecs/base64_codec.sake) | A hand-written Base64 encoder/decoder (standard and URL-safe alphabets, padding, whitespace) with a positioned DecodeError. | bit operations on bytes, an exception class with a position field, raise/rescue, String.ord/chr. | 99 | 17-encodings/base64_codec |
| [utf8_codec.sake](parsers-and-codecs/utf8_codec.sake) | A UTF-8 encoder and validating decoder over byte arrays, reporting overlong, surrogate, truncated and bad-continuation sequences with offsets. | bit operations, Tuples, an exception class (Utf8Error), rescue. | 109 | 17-encodings/utf8_codec |
| [lzw.sake](parsers-and-codecs/lzw.sake) | LZW compression with a growing dictionary (variable code width, frozen once full) and the matching decompressor, including the cScSc case. | Hash dictionaries in both directions, once, raise/rescue for corrupt streams, format. | 107 | 17-encodings/lzw |

## Types and errors

Operators and mixins on user-defined types, and error handling (13-polymorphism, 14-errors).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [shapes_area.sake](types-and-errors/shapes_area.sake) | A shape catalogue (circle, rect, triangle, regular polygon) sharing a Shape mixin: areas, perimeters, compactness, scaling and grouping through module dispatch. | a mixin module whose default functions raise, Shape.area(s) dispatching to s's type, group_by, format. | 115 | 13-polymorphism/shapes_area |
| [money_ledger.sake](types-and-errors/money_ledger.sake) | A Money type with currency-checked + - <=> and scaling: a multi-currency ledger, conversion with a rate table that may miss, allocation and per-person totals. | include Arithmetic and Comparable, exception classes with fields, a Hash keyed by Tuples, once, to_s. | 142 | 13-polymorphism/money_ledger |
| [vector_polygon.sake](types-and-errors/vector_polygon.sake) | A 2-D vector type with + - * / and lexicographic <=>: convex hull (monotone chain), shoelace area, centroid and point-in-polygon. | include Arithmetic and Comparable on one class, to_s, Array.sort of Comparable values, format. | 117 | 13-polymorphism/vector_polygon |
| [retry_backoff.sake](types-and-errors/retry_backoff.sake) | Calls scripted flaky services with retry, exponential backoff with a cap, and distinguishes transient, fatal and give-up errors. | `retry` inside rescue, ensure, three exception classes, yield, case/in. | 92 | 14-errors/retry_backoff |
| [error_wrapping.sake](types-and-errors/error_wrapping.sake) | Loads profiles through storage and decode layers, wrapping low-level errors into higher-level ones and printing the cause chain. | exception classes holding a cause field, `rescue => e` and re-raising, case/in on exception types, Records. | 98 | 14-errors/error_wrapping |
| [result_pipeline.sake](types-and-errors/result_pipeline.sake) | Railway-style validation: each step returns an {ok:} or {error:} Record and steps chain until one fails, instead of raising. | Record literals and `in {ok:}` / `in {error:}` patterns, combinators built on yield, once. | 95 | 14-errors/result_pipeline |

## Data

Tables, pivots, dates and collections (15-data, 16-dates, 18-collections).

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [size_histogram.sake](data/size_histogram.sake) | Buckets file sizes into power-of-two ranges and prints a bar histogram with cumulative percentages, human-readable sizes, median and p90. | the typed array Integer[], Tuples, format with widths, while. | 55 | 15-data/size_histogram |
| [league_standings.sake](data/league_standings.sake) | Builds a league table from match results round by round with a Comparable Team type (points, goal difference, goals, name), recent form, rank movement and rank history. | include Comparable with a multi-key `<=>` written as a Tuple comparison, a heredoc parsed with Regexp, format. | 102 | 15-data/league_standings |
| [expense_pivot.sake](data/expense_pivot.sake) | Pivots dated expenses into a category x month table through a Pivot type indexed by [category, month] Tuples, with totals, shares and month-over-month change. | include Indexable with `def []` and `def []=`, initialize, Tuple keys, format. | 93 | 15-data/expense_pivot |
| [month_calendar.sake](data/month_calendar.sake) | Prints cal-style month grids three across, marking special days, and reports week-row counts. | once for the name tables, a Set of marked days, Zeller's congruence, String padding. | 98 | 16-dates/month_calendar |
| [date_arith.sake](data/date_arith.sake) | A small Date type on Julian Day Numbers: validation, + days, - a date or days, ordering, and event countdowns. | include Arithmetic and Comparable where `-` accepts a Date or an Integer through case/in, an exception class (InvalidDate), Regexp parsing, once. | 127 | 16-dates/date_arith |
| [survey_venn.sake](data/survey_venn.sake) | A feature-usage survey: all eight Venn regions of three Sets by chained - & \|, an inclusion-exclusion check, exactly-k counts and per-plan percentages. | Set operators and Set.size, Regexp split, format. | 71 | 18-collections/survey_venn |
| [cart_discounts.sake](data/cart_discounts.sake) | Prices shopping carts from a catalog Hash; promotion rules of four Record shapes dispatched with case/in (BOGO, category percent, bundle by Set subset, spend threshold), and coupons that may be invalid. | Record patterns such as `in {kind: :bogo, sku:}`, Set.subset?, an exception class (UnknownItem), rescue. | 95 | 18-collections/cart_discounts |

## Apps

Small business applications (20-business), and a sql engine of 4,500 lines.

| file | what it does | what it shows | lines | src |
|---|---|---|---|---|
| [event_registration.sake](apps/event_registration.sake) | Conference orders with early-bird and group pricing, per-ticket-type capacity (SoldOutError), name badges sorted by last name, catering tallies and companies sending several people. | attr_accessor stock, an exception class, rescue per order, sort_by with Tuples, group_by. | 77 | 20-business/event_registration |
| [payroll.sake](apps/payroll.sake) | Bi-weekly payroll for hourly and salaried employees sharing an Employee mixin: overtime, retirement deduction, progressive tax brackets, skipped timecards and year-to-date totals. | a mixin over two classes and (Hourly\|Salaried).name(e) dispatch, an exception class, `x in T`, once for a bracket table whose top limit is nil. | 119 | 20-business/payroll |
| [bank_ledger.sake](apps/bank_ledger.sake) | Double-entry bookkeeping: a journal parsed from indented text, validation (unknown account, unbalanced entry) with LedgerError, trial balance, net income and the accounting equation. | a heredoc parsed with Regexp, an exception class, attr_accessor running totals, once, money formatting. | 157 | 20-business/bank_ledger |
| [restaurant_orders.sake](apps/restaurant_orders.sake) | Restaurant tables ordering from a menu with modifiers and limited stock (SoldOut), a kitchen queue served per station, and bills split evenly or by seat. | several classes with attr_accessor, initialize, an exception class, case/in, group_by, format. | 141 | 20-business/restaurant_orders |
| [sql/main.sake](apps/sql/main.sake) | A SQL engine (a SQLite subset: DDL, DML, joins, aggregates, window functions, CTEs, views, indexes, transactions, BLOBs) that runs the script on standard input; see [apps/sql/README.md](apps/sql/README.md). | a 46-file program (`require "sql/*"`), one module per concern, exceptions for SQL errors; written by AI in six stages from a specification. | 4,563 | 2026-10-05-ai-writability, run p11f-t-sake-2-c2 |

## Notes from running the corpus with the 2026-10-10 interpreter

Measured while selecting (every program of corpus-v3 and of the original 10-01 corpus, at
`--strict=2` then `--strict=1`, output compared with its `.out`):

| corpus | programs | pass at level 2 | pass at level 1 | stopped at level 1 but right at level 0 | wrong or rejected at level 0 |
|---|---|---|---|---|---|
| 2026-10-01 corpus | 500 | 323 | 450 | 40 | 10 |
| 2026-10-05 corpus-v3 | 500 | 311 | 435 | 64 | 1 |

The 10 programs of the 10-01 corpus that no longer run use what the language has since removed or
renamed: `Struct.new` with field defaults (5), a class named like a built-in type (`Record`, `Dir`;
2), a field named `new` (1), and a mixin function whose implementations take different arguments
(2). The level-1 rejections are mostly `Float.round`/`Float.abs` on a value that may be an Integer,
`sort_by` keys that may hold nil, and `case/in` over Symbols without an `else`; the programs are
right at run time, so these are the checker's false positives on code written without it.
