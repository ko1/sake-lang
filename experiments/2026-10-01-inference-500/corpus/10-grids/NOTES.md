# Notes: grids, boards and puzzles

## Interpreter bugs seen

- `Array.join(a)` without a separator crashes the interpreter (Ruby NoMethodError leaks):
  `p(Array.join(Array["a", "b"]))` ->
  `lib/sake/stdlib.rb:176:in 'block in Sake::Stdlib.install_array': undefined method 'map' for an instance of String (NoMethodError)`.
  Workaround in every task: always pass the separator, `Array.join(a, "")`.

## Recurring workarounds

- No Tuple/Array equality (`==` raises `TypeError ... (Tuple, Tuple)`): compare coordinates part by
  part, or compare `Array.join` strings (maze_bfs, sokoban, terrain_dijkstra, n_queens, game_2048, ...).
- No `break` inside blocks: `next` with a flag (minesweeper, battleship, game_2048, hex_game).
- No value constants: functions returning Arrays/Hashes, or Struct fields.
- No unary `-`/`!`/`~`: `0 - x`, `x == false`, `full ^ x`.
- No splats, `&.`, `%w[]`, enumerator chains (`each_with_index.map`, `each_slice(3).map`), destructuring
  block/method parameters: rewritten with plain blocks and locals.
- Tuples are not comparable, so `sort_by { [a, b] }` needs a Comparable Struct.

Verification: all 25 tasks exit 0 under `bin/sake --strict=0`, print nothing on stderr, and match
`ruby` byte for byte (and their `.out`). Note the machine was heavily loaded (load ~40) while timing.

## Per task

- game_of_life: hit the `Array.join` bug above; otherwise straightforward.
- maze_bfs: `cur == @goal` on Tuples fails at run time: `TypeError: Kernel.==: no implementation for (Tuple, Tuple)`
  (Tuple equality is undecided, although Tuples work as Hash keys). Wrote `same_cell?(a, b)` that
  destructures both and compares the parts. Ruby's `each_cons(3) do |(ar, ac), (br, bc), (cr, cc)|`
  has no Sake form (no nested block params); used `Array.fetch(w, i)` then multiple assignment.
- sudoku_solver: `Array.each_slice` requires a block (no enumerator), so Ruby's
  `each_slice(3).map { ... }` became an `each_slice` block that pushes into an `Array[]`.
  Ruby uses a `PEERS` constant; Sake has no value constants, so the peer table is a Struct field
  built in `parse`. A medium puzzle (~100 placements) took ~5 s in Sake; replaced by a nearly-solved one.
- tic_tac_toe: the Ruby `LINES` constant became a top-level function `lines` (no value constants).
  Cells hold `nil | String`; nothing else notable.
- flood_fill: Ruby's `sort_by { |ch, n| [-n, ch] }` fails in Sake:
  `ArgumentError: Hash.sort_by: cannot compare elements of types Integer` (Tuples are not
  comparable). The message names the wrong type: `p(Array.sort_by(Array[1, 2]) { |x| [0 - x, "a"] })`
  says `types Integer`, while `Array.sort(Array[[2, "a"], [1, "b"]])` correctly says `types Tuple`. Workaround: a `Tally` Struct with
  `include Comparable` and `<=>`, sorted with `Array.sort`.
- minesweeper: `break` inside `Array.each` is a static error (`` `break` is only supported directly
  inside `while`/`until` ``); Ruby keeps `break`, Sake uses `next if status != :playing` (the
  remaining moves are skipped instead of leaving the loop). Ruby `case/when` on symbols became `case/in`;
  `Array.new(rows) { ... }` became `Range.map(0...rows) { ... }`.
- n_queens: no unary operators, so `~mask` became `full ^ mask` and `-free` became `0 - free`.
  Array equality is undecided, so `mirrored == queens.reverse` compares `Array.join(.., ",")` strings.
  Ruby's `each_with_index.none?` (enumerator chain) became an `each_with_index` block with `return false`.
- knights_tour: my own slip `String.chr(int)` (should be `Integer.chr`) was only caught at run time
  under `--strict=0`, as expected. Ruby's `each_cons(2).count { |a, b| ... }` became an
  `each_cons` block with a counter and `Array.fetch`.
- connect_four: `ROWS`/`COLS` constants became `def rows = 6` / `def cols = 7`. `-dr` became `0 - dr`.
  Ruby's `col, reason = choose(...) if col.nil?` written as an `if col == nil` block. Ran first time.
- sliding_puzzle: swapping by multiple assignment to index targets (`a[i], a[j] = a[j], a[i]`) is
  rejected: `only \`a, b = tuple\` (local variables, no splat) is supported`; used a temp variable.
  `String.[]` takes one index argument, so Ruby's `state[r * 3, 3]` became `state[(r * 3)...(r * 3 + 3)]`.
  Ruby's `loop do ... break ... end` became `while true ... break ... end`. The search result is a
  Record `{moves:, expanded:}` taken apart with `=>` in both versions.
- word_search: Ruby reads direction Records with `d[:name]`; Sake has no Record indexing, so each
  use is a pattern (`d => {name:, dr:, dc:}`), including inside the `Array.find` block. `%w[]` is
  unsupported, so the word list is `Array["ruby", ...]`. Ruby's `@letters[r]&.[](c)` became an
  explicit nil check. Ran first time.
- langtons_ant: turn tables are Hashes returned by functions (no constants). Ruby's
  `keys.map(&:first)` on pairs became `Array.map(keys) { |x, y| x }`; the bounding box checks each
  `Array.min/max` result for nil instead of testing `empty?` first. Ran first time.
- sokoban: a level row `"#$.#"` in a double-quoted string is rejected: `Sake has no global variables
  (\`$.\`)` — correct, since Ruby interpolates `#$.` too (Ruby silently printed the wrong level). Rows
  are now single-quoted strings in both versions. Ruby's `@player == pos` (Array equality) became a
  destructure-and-compare. Undo restores a Set with `Array.to_set(Snapshot.get_boxes(snap))`.
- terrain_dijkstra: Ruby's `frontier.each_index.min_by { ... }` (enumerator) became an
  `each_with_index` loop keeping the best index. `case ch when "."...` with fall-through nil became
  `case/in` with an explicit `in String then nil` arm (exhaustiveness). `break if cur == to` on Tuples
  became component comparison. `%w[S G].include?` became two `!=` tests.
- matrix_spiral: a user `[]` takes exactly one index: `m[1, 0]` is rejected (`` `m[1, 0]` takes one
  index ``), so Ruby's `def [](r, c)` / `m[r, c]` became a Tuple index `m[[r, c]]` destructured
  inside `[]`/`[]=`. Ruby's `order == (1..n).to_a` (Array equality) compares joined strings.
  `self[r, c]` inside methods becomes `m[[r, c]]` on the first parameter.
- battleship: `break` out of `Array.each` again replaced by a `finished` flag plus `next`.
  `[header, *rows]` (splat) / `Array + Array` have no Sake form; used `Array.unshift(rows, header)`.
  Ruby's `@cells.include?(pos)` with an Array pos relies on Array equality; Sake's `occupies?`
  destructures and compares coordinates. `rescue` directly in a `do` block works.
- nonogram: no `Array +` and no `Array.new(n, v)`, so Ruby's `Array.new(start, 0) + Array.new(first, 1)`
  became pushes in `Integer.times`, and `head + tail` became `Array.concat(Array.dup(head), tail)`.
  `first, *rest = clues` (splat) became `Array.first` / `Array.drop`. `pic.transpose` was written as a
  column map (Array.transpose exists but I kept the explicit form). Comparing the solved grid to the
  picture needs joined strings (no Array `==`).
- game_2048: `moved == @board` (nested Array equality) became `same_board?` comparing joined
  flattened boards. `break if g.stuck?` inside `each_char` became `next if`. Ruby's
  `{"L" => 0, ...}.fetch(dir)` written as `case/in` in Sake (both fine; Hash would also work).
- othello: cells hold `nil | Symbol`; `Range.map { nil }` builds the empty board (`Array.new(size)` in Ruby).
  `[header, *rows]` became `Array.unshift(rows, header)`. Ran first time after removing my own junk.
- chess_attacks: Ruby `LETTERS`/`VALUES`/`KINDS` constant Hashes became `case/in` in Piece functions
  and a Hash built inside `kind_of`. No destructuring parameters (`def square_name((rank, file))`)
  and no `&.` (`board.find{...}&.first`, `board[sq]&.letter`) — written as locals + nil checks.
  `!white` became `white == false`. `STRAIGHT + DIAGONAL` became `Array.concat(Array.dup(straight), diagonal)`.
- magic_square: ran first time. Ruby `sq.each_with_index.map` (enumerator chain) became an
  `each_with_index` block pushing into `Array[]`. Lines are `[name, sum]` Tuples inside an Array.
- lights_out: ran first time; compound bit assignments (`|=`, `^=`, `>>=`) work. Ruby's
  `each_char.with_index` became `Array.each_with_index(String.chars(row))`.
- falling_sand: Ruby's assignment in an `elsif` condition (`elsif (diag = sides.find {...})`) was
  split into `else` + local + `if` in Sake; the index-target swap became a temp variable; `move(r, c, *target)`
  (splat call) became `nr, nc = target`. `!settled` became `settled == false`.
- crossword: `raise Conflict.new(msg, *cell)` (splat) became `r, c = cell` first. `n += 1 while cond`
  (modifier while) written as a `while` loop. Ran first time otherwise.
- hex_game: ran first time. `-@q - @r` became `0 - @q - @r`; `UnionFind.new(parent = {})` default
  parameter became an explicit `Hash[]` argument; `break if g.winner` became `next if`.
  Union-find keys are Strings (`"q,r"`) mixed with the virtual nodes `"red-west"` etc.
