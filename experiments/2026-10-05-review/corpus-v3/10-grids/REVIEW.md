# REVIEW (10-grids, corpus-v3)

All 25 programs exit 0 under `bin/sake --strict=0` with stdout identical to `.out` (and nothing on stderr).

Note: the `.rb` files in this directory are symlinks to `../../corpus/10-grids/`, which does not exist
(dangling links). The Ruby references were read from `experiments/2026-10-01-inference-500/corpus/10-grids/`.

- battleship: `class PlacementError/BadCoordinate < StandardError` + `attr_reader`; `Ship`/`Ocean` as `class` + `attr_reader`; `break` in the shot loop instead of a `finished` flag; `Array[header, *rows]` instead of `Array.unshift`; `case @shots[[r, c]] in :hit ... else` as Ruby's `case/when`.
- chess_attacks: `Piece` as `class` + `attr_reader`; Ruby's `LETTERS`/`VALUES`/`KINDS` hashes and `STRAIGHT`/`DIAGONAL` as `once` tables (replacing per-call `case` and per-call arrays); `straight + diagonal` (Array `+`); `Integer.between?`; `attacks_from` steps as a `.Array.map`/`.Array.select` chain; `Array.sum(xs) { }`; `else Array[]` as Ruby's `else []`.
- connect_four: `class ColumnFull < StandardError`; `Board` as `class` + `attr_reader`; `Array.new(rows) { Array.new(cols, ".") }`, `Array.new(cols, 0)`; `Range.select`; modifier `if` for `col, reason = choose(...)` and the win check.
- crossword: `class Conflict < StandardError`; `Entry`/`Crossword` as `class` + `attr_reader`; `n += 1 while ...` modifier.
- falling_sand: `World` as `class` + `attr_reader`; swap by multiple assignment to elements; `elsif (diag = Array.find(...))` as Ruby.
- flood_fill: `Region`/`Canvas` as `class` + `attr_reader`; `neighbours` is one `Array.select`; `Array.concat(stack, ...)`; `until Array.empty?`; `cr, cc = Array.shift(queue)`.
- game_2048: `Game` as `class` + `attr_reader`; direction table as `Hash.fetch(Hash[...], dir)` (Ruby's hash) instead of `case`; `break if Game.stuck?(g)` in the block instead of `next`; `Integer.zero?`.
- game_of_life: `Board` as `class` + `attr_reader`; `@cells = Range.map ...` with the ternary rule; `Array.sum(xs) { }`; `Hash[key => 0]`; `if (prev = seen[k])`.
- hex_game: `hex_dirs` via `once`; `UnionFind` with `def initialize(uf) = @parent ||= Hash[]` so it is `UnionFind.new` as in Ruby; `Game` as `class` + `attr_reader`; `break` instead of `next if winner`; `Range.flat_map`; `end.Array.join` chains.
- knights_tour: `jumps` via `once`; `Board` as `class` + `attr_reader`; `Array.new(size) { Array.new(size, 0) }`; `inside?` without temporaries; `moves_from` as a chain.
- langtons_ant: `class Ant` with `attr_accessor`; `turn_right`/`turn_left` via `once`; `World` as `class` + `attr_reader`; `bounds` returns nil on empty first, as Ruby; `Array.tally`; `picture` with the ternary and `end.Array.join`.
- lights_out: `Grid` as `class` + `attr_reader`.
- magic_square: `class NotSupported < StandardError`; `Array.new(n) { Array.new(n, 0) }`; `Integer.odd?`; `Integer.between?`; `Array.sum(sq) { }`/`Range.sum(0...n) { }`; `rescue` directly in the `do` block (no `begin`); `Check.report(sq) => {...}` without a temporary.
- matrix_spiral: two-index `def [](m, r, c)` / `def []=(m, r, c, v)` and `m[r, c]` everywhere instead of `m[[r, c]]`; `Array.new(h * w, v)`; `@data[r * @width, @width]`; `Range.sum`.
- maze_bfs: `Maze` as `class` + `attr_reader` with `dirs` via `once`; `Hash[@start => @start]`; `until Array.empty?`; nested block parameters `|(ar, ac), (br, bc), (cr, cc)|`; `Array.sum(xs) { }`.
- minesweeper: `class Cell`/`class Field` with `attr_accessor` (as Ruby); `class MineHit < StandardError`; `Array.new(rows) { Array.new(cols) { ... } }`; `Array.concat`; `break` instead of `next` once the game ends; ternary for the shown state; `Array.sum(xs) { }`.
- n_queens: `Search` as `class` + `attr_reader`; `free ^= bit`; `symmetric?` as one comparison.
- nonogram: `clue` as a chain; `first, *rest = clues`; `Array.new(n, v)` and Array `+` for the arrangements; `Array.transpose`; `Puzzle` as `class` + `attr_reader`; `Array.count(row, nil)`; `end.Array.join`.
- othello: `dirs` via `once`; `Board` as `class` + `attr_reader`; `Array.new(size) { Array.new(size) }`; `flips` as `Array.flat_map` (as Ruby); `Array.count(row, color)`; `Array[header, *rows]`.
- sliding_puzzle: `Node` as `class` + `attr_reader`; `Heap` with `initialize` defaulting `@items` (so `Heap.new` as Ruby); swaps by multiple assignment (heap and tiles); `state[r * 3, 3]`; `Integer.zero?`.
- sokoban: `Snapshot`/`Level` as `class` + `attr_reader`; one-line `raise ... if`; `String.each_char`; `to_s` with `end.Array.join.String.rstrip` chains.
- sudoku_solver: `class InvalidPuzzle < StandardError`; Ruby's `PEERS` table via `once` (the `peers` field each Sudoku carried is gone; `Sudoku.new(cells, 0)` as Ruby); `Array.flat_map` in `parse`; `r, c = Integer.divmod(i, 9)`; `Array.to_set`; `@cells[r * 9, 9]`.
- terrain_dijkstra: `Route`/`Terrain` as `class` + `attr_reader`; `best_i = Range.min_by(...)` (Ruby's `each_index.min_by`); `unshift ... while` modifier; `Array.include?(Array["S", "G"], ...)` (Ruby's `%w[S G].include?`); `Array.tally`; `else nil` in `tile_cost`.
- tic_tac_toe: `lines` via `once`; `Game` as `class` + `attr_reader`; `Range.select`; `Array.count(@cells, "X")`; `@memo[k] = result` as the value; `if (w = Game.winner(g))`; `@cells[r * 3, 3]`.
- word_search: `Hit`/`Puzzle` as `class` + `attr_reader`; `directions` via `once`; `matches?` as one `Range.all?`; `if (hit = Puzzle.find(pz, w))`; `end.Array.join`.

Changed: 25. Unchanged: 0.

## Friction

- **Record fields cannot be indexed.** word_search.sake:49 wants Ruby's `x[:name] == hit.dir` and
  `d[:dr]` (word_search.rb `mark`); `d[:name]` raises `TypeError: {...} cannot be indexed`, so it
  writes `{ |x| x => {name:}; name == ... }` and `d => {dr:, dc:}` (word_search.sake:49, 51).
- **A field default must be a literal.** Ruby's `def initialize(parent = {})` / `items = []`
  (hex_game.rb `UnionFind`, sliding_puzzle.rb `Heap`) wants `attr_reader parent = Hash[]`; that is
  a static error ("a default must be a literal ..."), so the class declares `= nil` and fills it in
  `def initialize(uf) = @parent ||= Hash[]` (hex_game.sake:22, sliding_puzzle.sake:11).
- **No splat into a user function.** `open?(*nxt)` / `cost_at(*nxt)` / `Conflict.new(msg, *cell)`
  is rejected (only built-ins take splats), so each takes the Tuple apart first
  (maze_bfs.sake:38, terrain_dijkstra.sake:46, crossword.sake:62).
- **No enumerator chains.** `each_with_index.map`, `each_slice(3).map`, `each_with_index.none?`,
  `each_with_index.all?` have no block-less form, so they become push loops or index ranges
  (magic_square.sake:59, sudoku_solver.sake:68, n_queens.sake:28, tic_tac_toe.sake:71,
  word_search `matches?` uses `Range.all?` over indexes).
- **No `&.`.** `board[[r, f]]&.letter || "."`, `find {...}&.first`, `@letters[r]&.[](c)` become
  ternaries/`&&` (chess_attacks.sake:103, 94; word_search.sake:27).
- **No `+=` on another type's field.** `@ant.x += dx` / `cells[nr][nc].adjacent += 1` become
  `Ant.set_x(ant, Ant.get_x(ant) + dx)` (langtons_ant.sake:35) and
  `Cell.set_adjacent(cell, Cell.get_adjacent(cell) + 1)` (minesweeper.sake:19); `@x +=` works only
  on the function's first argument.
- **No parameter destructuring in `def`.** chess_attacks.rb `def square_name((rank, file))` →
  `rank, file = sq` in the body (chess_attacks.sake:37).
- **`case/in` has no implicit nil.** Ruby's `case ... when` without `else` gives nil; Sake needs an
  explicit `in :open then nil` (minesweeper.sake:62) or `else nil` (terrain_dijkstra.sake:11).

## Ruby comparison

- Every call names its type: `Board.drop(b, col, piece)` for `b.drop(col, piece)`, and every
  type's functions take the instance first (`def drop(b, col, piece)`); `&:sym` blocks become
  `{ T.f(it) }` (e.g. battleship.sake `Array.reject(...) { Ship.sunk?(it) }`).
- Class-body constants (`DIRS`, `LETTERS`, `PEERS`, `TURN_RIGHT`) are `def name = once { ... }`
  functions, called as `dirs` / `peers[i]`.
- Fields are declared bare (`attr_reader grid, start, goal`) and the hand-written `initialize`
  that only stores them disappears; `new` is positional over all fields.
- Exception classes are `class E < StandardError` + `attr_reader`, with `message` as the implicit
  first field: `E.new("msg", row, col)` matches Ruby's custom initializers here.
- `[]` / `{}` literals are Tuples/Records, so growable collections are `Array[...]` / `Hash[...]`;
  `%w[...]` is spelled out as `Array["a", ...]`.
- A method chain reads as a `.T.f` chain with the type at each step
  (`end.Array.join("\n")`, `.Array.select { ... }`).
