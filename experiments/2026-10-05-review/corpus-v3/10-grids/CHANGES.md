# Changes: grids, boards and puzzles (corpus-v2)

Common to many programs: `Array.join(a, "")` became `Array.join(a)` (the no-separator crash is fixed).

- battleship: `Ship.occupies?` is `Array.include?(@cells, pos)` (Tuple equality) instead of destructure-and-compare; `Array.join(cells)`.
- chess_attacks: `!white` and `!Set.include?(...)` (unary `!`) instead of `== false`; `Array.join(line)`.
- connect_four: `-dr, -dc` (unary `-`) instead of `0 - dr, 0 - dc`; `Array.join(row)`.
- crossword: `!Set.include?(...)` / `!open?(...)` (unary `!`) instead of `== false`; `Array.join` without separator.
- falling_sand: `while !settled` / `if !settled` (unary `!`) instead of `settled == false`; `Array.join(row)`.
- flood_fill: the `Tally` Comparable Struct is gone: `Hash.sort_by(counts) { |ch, n| [-n, ch] }` (ordered Tuples, unary `-`), written as a `.Array.map`/`.Array.join` chain and `_`; `!Set.include?` instead of `== false`; `Array.join(row)`.
- game_2048: `same_board?` (joined flattened boards) removed, `moved == @board` (nested Array equality); `stuck?` uses `Array.none?` as Ruby does, instead of `all? { ... == false }`; `Array.join` without separator.
- game_of_life: `Array.join` without separator.
- hex_game: `-@q - @r` (unary `-`) instead of `0 - @q - @r`.
- knights_tour: `Array.each_cons(path, 2) { |a, b| ... }` (block destructures the Array) instead of `Array.fetch(pair, 0/1)`.
- langtons_ant: `Array.join` without separator.
- lights_out: `Array.join` without separator.
- magic_square: unchanged.
- matrix_spiral: `order == Range.to_a(1..(h * w))` (Array equality) instead of comparing joined strings.
- maze_bfs: `same_cell?` removed, `cur == @goal` / `node != @start` (Tuple equality); `Array.each_cons(path, 3) { |a, b, c| }` instead of three `Array.fetch`; `Array.join(row)`.
- minesweeper: `Array.join` without separator.
- n_queens: `~(cols | diag1 | diag2)` and `free & -free` (unary `~`/`-`) instead of `full ^ ...` / `0 - free`; `mirrored == Array.reverse(queens)` (Array equality) instead of joined strings.
- nonogram: the solved check compares the rendered rows to `lines` with Array `==` instead of joining both with `/`; `Array.join` without separator.
- othello: unchanged.
- sliding_puzzle: `Node.<=>` is one Tuple comparison `[@f, seq(b)] <=> [f(b), @seq]` instead of an if/else; `Array.join(chars)`.
- sokoban: `pos == @player` (Tuple equality) instead of destructuring the player; `Level.get_boxes(lv) & Level.get_goals(lv)` (Set operator) instead of `Set.&(...)`; `Array.join(row)`.
- sudoku_solver: unchanged.
- terrain_dijkstra: `break if cur == to` (Tuple equality) instead of component comparison; `Array.join(it)`.
- tic_tac_toe: `Array.join` without separator.
- word_search: `Array.join(out)`.
